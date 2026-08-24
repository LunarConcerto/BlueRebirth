using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>玩家模块：user.*（登录/信息/档案更新）。</summary>
internal sealed class UserModule(GameLoginMessageHandler services) : IGameModule
{
    public string Prefix => "user";

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "user.UserLogin":
                // 应答前推送完整用户信息 + 引导数据，确保 LoginOk 事件触发前
                // Data.userData 与 GUIDE_DONE_STAGES 已就绪。
                var loginAccount = await ctx.GetAccountAsync();
                result = new ModuleResult
                {
                    Ret = TMessageCodec.EncodeRetUserLogin("ok", "", 0),
                    PrePushes =
                    [
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                        services.BuildGuideInfoPush((uint)ctx.Now, loginAccount),
                    ],
                };
                break;
            case "user.GetUserInfo":
                result = new ModuleResult
                {
                    Ret = GameLoginMessageHandler.EncodeGetUserInfo(await ctx.GetAccountAsync()),
                    PostPushes = await services.BuildSyncPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                };
                break;
            case "user.SetUserSecretary":
            case "user.ChangeName":
            case "user.SetMessage":
            case "user.SetPlayerHeadFrame":
            case "user.SetHead":
                var field = request.Method switch
                {
                    "user.SetUserSecretary" => "Secretary",
                    "user.ChangeName" => "Name",
                    "user.SetMessage" => "Message",
                    "user.SetPlayerHeadFrame" => "HeadFrame",
                    _ => "Head",
                };
                result = new ModuleResult
                {
                    Ret = await services.BuildUserProfileUpdateAsync(request, ctx.ProfileId, ctx.Ct, field),
                    PostPushes = [await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct)],
                };
                break;
            case "user.GetHeadBuyCount":
                result = ModuleResult.Ok(new byte[] { 0x08, 0x00, 0x10, 0x00 }); // ShipFleetId=0, Count=0
                break;
            case "user.BuyHead":
            case "user.NewHeadUnlockedList":
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }
}
