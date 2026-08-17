using BlueOath.Protocol;
using BlueOath.Storage;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 处理游戏登录应用层（11 字节头 + protobuf），该层分别承载于 TCP 的 NetSocket 帧内
/// 与 UDP 的 KCP 流内。由两种登录传输共用，避免重复实现。
/// </summary>
internal sealed class GameLoginMessageHandler
{
    private readonly SqliteGameRepository _repo;
    private readonly ILogger _logger;
    private readonly ILogger _fileLogger;

    public GameLoginMessageHandler(SqliteGameRepository repo, ILoggerFactory loggerFactory)
    {
        _repo = repo;
        _logger = loggerFactory.CreateLogger<GameLoginMessageHandler>();
        _fileLogger = loggerFactory.CreateLogger(Infrastructure.GameLoginFileLoggerProvider.Category);
    }

    /// <summary>
    /// 处理登录操作码：解码 <c>TArgLogin</c>，按 <c>Pid</c> 创建/加载本地档案，
    /// 返回 <c>TRetLogin</c> 编码结果。
    /// </summary>
    public async Task<(int Operation, byte[] Payload)> BuildLoginPayloadAsync(byte[] payload, CancellationToken ct)
    {
        var request = GameLoginCodec.DecodeLogin(payload);
        var profileId = string.IsNullOrWhiteSpace(request.Pid) ? "local-player" : request.Pid;
        _logger.LogInformation("game-login login pid={ProfileId}", profileId);
        if (await _repo.LoadAsync(profileId, ct) is null)
            await _repo.CreateAsync(profileId, profileId, ct);
        var response = new TRetLogin("0", profileId);
        return (GameOperationCodes.Login, GameLoginCodec.Encode(response));
    }

    /// <summary>
    /// 处理 C2S 消息：解码 <c>TMessage</c> 请求，按方法名分发到对应的最小响应，再编码回
    /// S2C 响应。当前仅覆盖客户端在主流程中会调用到的少量方法，其余返回空。
    /// </summary>
    public (int Operation, byte[] Payload) BuildC2SResponse(ReadOnlySpan<byte> payload)
    {
        var request = TMessageCodec.DecodeRequest(payload);
        _fileLogger.LogInformation("game-login C2S method={Method} callback={Callback} argsLen={ArgsLen}",
            request.Method, request.CallbackHandler, request.Args?.Length ?? 0);
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        byte[] ret = request.Method switch
        {
            "player.Login" => GameLoginCodec.Encode(new TRetLogin("ok", "1")),
            "player.GetUserList" => [],
            "player.CreateUser" => UserInfoCodec.Encode(new TUserInfo(1, "test1", 1, 1)),
            "user.UserLogin" => TMessageCodec.EncodeRetUserLogin("ok", "", 0),
            "user.GetUserInfo" => TMessageCodec.EncodeRetGetUserInfo(1, "test1", 1, 1),
            "GetSvrTime" => TMessageCodec.EncodeRetGetSvrTime(now, 0),
            _ => []
        };
        var response = new TResponse(Method: request.Method, Ret: ret,
            CallbackHandler: request.CallbackHandler, Time: checked((uint)now),
            Token: request.Token, Seq: 0, IsResponse: 1);
        return (GameOperationCodes.S2C, TMessageCodec.EncodeResponse(response));
    }

    public byte[] BuildUpdateUserInfoPush(uint now)
    {
        // 这是一条服务器主动推送（非响应），携带完整用户信息，使客户端的
        // UserService._UpdateUserInfo 写入 Data.userData（HomeEnvManager._CheckLevel
        // 在选主界面场景时用到）。CallbackHandler/IsResponse 保持 0 = 推送。
        var push = new TResponse(Method: "user.UpdateUserInfo",
            Ret: TMessageCodec.EncodeRetGetUserInfo(1, "test1", 1, 1), Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>
    /// 客户端主界面在主动请求前就要读到的玩家域数据（建造/浴室队列原本只在打开主界面后才
    /// 请求，但 PushAllNotice 会在 MainStage.StageEnter 阶段遍历它们，遇到 nil 会报错）。
    /// 当前值为最小/空占位，每条记录都是将来填充真实数据的扩展点。
    /// </summary>
    public IEnumerable<byte[]> BuildSyncPushes(uint now)
    {
        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "build.BuildsInfo",
            Ret: PlayerDataCodec.Encode(new BuildsInfoRet(
                BuildingList: [new BuildFormula(EndTime: 0)])),
            Time: now));

        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "bathroom.BathroomInfo",
            Ret: PlayerDataCodec.Encode(new BathroomInfo(
                HeroList: [new BathHeroInfo(HeroId: 0, StartTime: 0)])),
            Time: now));

        // 秘书舰（看板娘）。HeroId 必须与 userData.SecretaryId 一致。
        // TemplateId=10210511 是 config_parameter[17]（"main_ship_girl"，默认秘书舰）；
        // Fashioning=1021051 是它的默认时装（limit_type=0）-> ship_show "u_cl_oakland"。
        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "hero.UpdateHeroBagData",
            Ret: PlayerDataCodec.Encode(new HeroBag(
                HeroInfo: [new HeroGrid(HeroId: 1, TemplateId: 10210511, Lvl: 1, Fashioning: 1021051)],
                HeroBagSize: 100)),
            Time: now));
    }
}
