using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>舰娘模块：hero.* 与 tactic.*。</summary>
internal sealed class HeroModule(HeroService hero, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["hero", "tactic"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "hero.ChangeEquip":
                result = new ModuleResult
                {
                    Ret = await hero.BuildChangeEquipRetAsync(request, ctx.ProfileId, ctx.Ct),
                    PostPushes = await services.BuildPostEquipPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                };
                break;
            case "hero.Marry":
            case "hero.AddExp":
                byte[] ret = request.Method == "hero.AddExp" ?
                    await hero.BuildAddExpRetAsync(request, ctx.ProfileId, ctx.Ct) :
                    await hero.BuildMarryRetAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                result = await UpdateHero(ctx, ret);
                break;
            case "hero.LockHero":
                result = ModuleResult.Ok(await hero.BuildLockHeroRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.RetireHero":
                result = ModuleResult.Ok(await hero.BuildRetireHeroRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.ChangeName":
                result = ModuleResult.Ok(await hero.BuildChangeNameRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.AddAffection":
                result = ModuleResult.Ok(await hero.BuildAddAffectionRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.GetHeroInfo":
                result = ModuleResult.Ok(await hero.BuildGetHeroInfoRetAsync(ctx.ProfileId, ctx.Ct));
                break;
            case "hero.GetHeroInfoByHeroIdArray":
                result = ModuleResult.Ok(await hero.BuildGetHeroInfoByHeroIdArrayRetAsync(ctx.ProfileId, ctx.Ct));
                break;
            case "tactic.GetHerosTactic":
                result = ModuleResult.Ok(await hero.BuildGetHerosTacticAsync(ctx.ProfileId, ctx.Ct));
                break;
            case "tactic.SetHerosTactic":
                result = ModuleResult.Ok(await hero.BuildSetHerosTacticAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.HeroAdvance":
                result = new ModuleResult
                {
                    Ret = await hero.BuildAdvanceRetAsync(request, ctx.ProfileId, ctx.Ct),
                };
                var advAccount = await ctx.GetAccountAsync();
                var advHeroes = advAccount.Dock.Heroes.Select(ToHeroGridWithName).ToList();
                result = new ModuleResult
                {
                    Ret = result.Ret,
                    PrePushes = BuildHeroBagPushes(advAccount, advHeroes, (uint)ctx.Now),
                };
                break;
            case "hero.StudySkill":
                result = new ModuleResult
                {
                    Ret = await hero.BuildStudySkillRetAsync(request, ctx.ProfileId, ctx.Ct),
                };
                var skillAccount = await ctx.GetAccountAsync();
                var skillHeroes = skillAccount.Dock.Heroes.Select(ToHeroGridWithName).ToList();
                result = new ModuleResult
                {
                    Ret = result.Ret,
                    PrePushes = BuildHeroBagPushes(skillAccount, skillHeroes, (uint)ctx.Now),
                };
                break;
            case "hero.HeroIntensify":
            case "hero.HeroAdvanceMUB":
            case "hero.AutoEquip":
            case "hero.AutoUnEquip":
            case "hero.HeroAdvMaxLv":
            case "hero.HeroEquipEffect":
            case "hero.HeroRemould":
            case "hero.EquipBinding":
            case "hero.EquipUnBinding":
            case "hero.EquipLockTransplant":
            case "hero.HeroCombineUpLv":
            case "hero.HeroCombineQuickLevelUp":
            case "hero.HeroCombineBreak":
            case "hero.HeroCombine":
                result = ModuleResult.Ok(await GameServices.BuildSimpleRet());
                break;
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    private static async Task<ModuleResult> UpdateHero(GameContext ctx, byte[] ret) {
        PlayerAccount updatedAccount = await ctx.GetAccountAsync();
        List<HeroGrid> updatedHeroes = updatedAccount.Dock.Heroes.Select(ToHeroGridWithName).ToList();
        ModuleResult result = new()
        {
            Ret = ret,
            PrePushes = BuildHeroBagPushes(updatedAccount, updatedHeroes, (uint)ctx.Now),
        };
        return result;
    }

    /// <summary>船坞 + 仓库推送（hero.UpdateHeroBagData / bag.UpdateBagData），供 AddExp/Marry 后刷新。</summary>
    private static IReadOnlyList<byte[]> BuildHeroBagPushes(PlayerAccount account, IReadOnlyList<HeroGrid> heroes, uint now)
    {
        var heroPush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "hero.UpdateHeroBagData",
            Ret: PlayerDataCodec.Encode(new HeroBag(heroes.ToList(), account.Dock.BagSize)),
            Time: now));
        var bag = account.Bag ?? new PlayerBag([], 100);
        var bagPush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "bag.UpdateBagData",
            Ret: PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize,
                BagInfo: bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList())),
            Time: now));
        return [heroPush, bagPush];
    }

    private static HeroGrid ToHeroGridWithName(Hero h)
    {
        var grid = GameServices.ToHeroGrid(h);
        return grid with { Name = ShipHandbookLoader.GetShipName(h.TemplateId) };
    }
}
