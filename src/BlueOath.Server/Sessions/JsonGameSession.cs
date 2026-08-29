using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Storage;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Sessions;

/// <summary>
/// 本地 JSON 帧游戏协议的每个连接处理器（<see cref="LocalGameClient"/> 与启动器使用的
/// 临时长度前缀 wire 格式）。
/// </summary>
internal sealed class JsonGameSession(
    GameService game,
    SqliteGameRepository repo,
    ServerOptions options,
    ILogger<JsonGameSession> logger)
{
    private readonly GameService _game = game;
    private readonly SqliteGameRepository _repo = repo;
    private readonly string _profileId = options.ProfileId;
    private readonly string _profileName = options.ProfileName;
    private readonly ILogger<JsonGameSession> _logger = logger;

    /// <summary>在单个连接上循环读取并分发 JSON 帧请求。</summary>
    public async Task RunAsync(Stream stream, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            using var doc = await FrameCodec.ReadAsync(stream, ct);
            if (doc is null)
                break;

            var env = doc.RootElement.Deserialize<ProtocolEnvelope>(JsonOptions.Default) ??
                throw new InvalidDataException("Invalid request");
            try
            {
                var response = await DispatchAsync(env, ct);
                await FrameCodec.WriteAsync(stream, new
                {
                    ok = true,
                    requestId = env.RequestId,
                    type = env.Type,
                    payload = response
                }, ct);
            }
            catch (Exception e)
            {
                await FrameCodec.WriteAsync(stream, new
                {
                    ok = false,
                    requestId = env.RequestId,
                    type = MessageTypes.Error,
                    error = e.Message
                }, ct);
            }
        }
    }

    private Task<object> DispatchAsync(ProtocolEnvelope envelope, CancellationToken ct)
    {
        var payload = envelope.Payload;
        return envelope.Type switch
        {
            MessageTypes.Login => LoginAsync(payload, ct),
            MessageTypes.State => StateAsync(payload, ct),
            MessageTypes.SetFormation => FormationAsync(payload, ct),
            MessageTypes.EnterStage => EnterAsync(payload, ct),
            MessageTypes.BattleResult => BattleAsync(payload, ct),
            _ => throw new InvalidOperationException("Unknown message")
        };
    }

    private async Task<object> LoginAsync(JsonElement payload, CancellationToken ct)
    {
        // The server process is scoped to the account selected in the launcher. The client can
        // retain a legacy/cached spelling (for example local_player), so accepting its profileId
        // here would create a second account alongside the selected local-player profile.
        _ = payload;
        if (await _repo.LoadAsync(_profileId, ct) is null)
            await _repo.CreateAsync(_profileId, _profileName, ct);

        return new { profileId = _profileId, version = _game.Profile.ClientVersion };
    }

    private async Task<object> StateAsync(JsonElement payload, CancellationToken ct) =>
        await _game.GetStateAsync(_profileId, ct) ??
        throw new KeyNotFoundException("Profile not found");

    private async Task<object> FormationAsync(JsonElement payload, CancellationToken ct) =>
        await _game.SetFormationAsync(
            _profileId,
            payload.GetProperty("shipIds").EnumerateArray().Select(x => x.GetInt32()).ToArray(),
            ct);

    private async Task<object> EnterAsync(JsonElement payload, CancellationToken ct) =>
        await _game.EnterStageAsync(
            _profileId,
            payload.GetProperty("stageId").GetInt32(),
            ct);

    private async Task<object> BattleAsync(JsonElement payload, CancellationToken ct)
    {
        var result = await _game.ResolveBattleAsync(
            _profileId,
            payload.GetProperty("stageId").GetInt32(),
            payload.GetProperty("win").GetBoolean(),
            ct);
        return new { state = result.State, outcome = result.Outcome };
    }
}
