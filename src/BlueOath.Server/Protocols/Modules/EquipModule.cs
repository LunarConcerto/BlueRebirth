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
                return new ModuleResult
                {
                    Ret = await equip.BuildEnhanceRetAsync(request, ctx.ProfileId, ctx.Ct),
                    PostPushes = await services.BuildPostEnhancePushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                };
            default:
                return ModuleResult.Empty;
        }
    }
}
