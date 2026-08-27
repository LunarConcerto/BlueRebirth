using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>装备模块：equip.*（Dismantle / 装备仓库推送）。</summary>
internal sealed class EquipModule(EquipService equip, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["equip"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "equip.Dismantle":
                var (ret, removedIds) = await equip.BuildDismantleRetAsync(request, ctx.ProfileId, ctx.Ct);
                var account = await ctx.GetAccountAsync();
                var now = (uint)ctx.Now;
                return new ModuleResult
                {
                    Ret = ret,
                    PrePushes = new[]
                    {
                        // removedIds 以 TemplateId=0 删除标记追加，客户端 equipdata.UpdateEquip 据此清除。
                        services.BuildEquipPush(account, now, removedIds),
                        services.BuildBagPush(account, now),
                    },
                };
            case "equip.Enhance":
                var (enhanceRet, enhanced, enhanceError) =
                    await equip.BuildEnhanceRetAsync(request, ctx.ProfileId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = enhanceRet,
                    Err = enhanced ? 0 : 1,
                    ErrMsg = enhanceError,
                    // The client handles EquipIntenstitySuccess as soon as the response arrives
                    // and reads Data.equipData to render the new level. Refresh that cache first.
                    PrePushes = await services.BuildEnhancePushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                };
            case "equip.EnhanceBind":
                var (bindRet, bindEnhanced, bindError) =
                    await equip.BuildEnhanceBindRetAsync(request, ctx.ProfileId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = bindRet,
                    Err = bindEnhanced ? 0 : 1,
                    ErrMsg = bindError,
                    PrePushes = bindEnhanced
                        ? await services.BuildBindEnhancePushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct)
                        : [],
                };
            case "equip.RiseStar":
                var (riseRet, changed) = await equip.BuildRiseStarRetAsync(request, ctx.ProfileId, ctx.Ct);
                return new ModuleResult
                {
                    Ret = riseRet,
                    Err = changed ? 0 : 1,
                    ErrMsg = changed ? "" : "equipment renovation requirements are not met",
                    // RiseStarSuccess immediately reads currency, bag, and equip caches.
                    PrePushes = changed
                        ? await services.BuildRiseStarPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct)
                        : [],
                };
            default:
                return ModuleResult.Empty;
        }
    }
}
