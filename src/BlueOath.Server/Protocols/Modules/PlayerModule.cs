using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>账号/登录模块：player.*（Login / GetUserList / CreateUser）。</summary>
internal sealed class PlayerModule : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["player"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        var ret = request.Method switch
        {
            "player.Login" => GameLoginCodec.Encode(new TRetLogin("ok", "1")),
            "player.GetUserList" => GameServices.EncodeGetUsers(await ctx.GetAccountAsync()),
            "player.CreateUser" => GameServices.EncodeCreateUser(await ctx.GetAccountAsync()),
            _ => []
        };
        return ModuleResult.Ok(ret);
    }
}
