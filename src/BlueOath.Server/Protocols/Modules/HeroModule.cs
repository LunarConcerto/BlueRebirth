using BlueOath.Core;
using BlueOath.Protocol;

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
                byte[] lockRet = await hero.BuildLockHeroRetAsync(request, ctx.ProfileId, ctx.Ct);
                LockHeroArg lockArg = ProtocolDecoder.DecodeLockHeroArg(request.Args ?? []);
                PlayerAccount lockAccount = await ctx.GetAccountAsync();
                Hero? lockedHero = lockAccount.Dock.Heroes.FirstOrDefault(h => h.HeroId == lockArg.HeroId);
                result = new ModuleResult
                {
                    Ret = lockRet,
                    // _HeroSetLock 回调会立刻读取 Data.heroData；必须在应答前更新客户端缓存。
                    PrePushes = lockedHero is null
                        ? []
                        :
                        [
                            TMessageCodec.EncodeResponse(new TResponse(
                                Method: "hero.UpdateHeroBagData",
                                Ret: PlayerDataCodec.Encode(new HeroBag(
                                    [GameServices.ToHeroGrid(lockedHero)], lockAccount.Dock.BagSize)),
                                Time: (uint)ctx.Now)),
                        ],
                };
                break;
            case "hero.RetireHero":
                HeroService.RetireResult retire =
                    await hero.BuildRetireHeroRetAsync(request, ctx.ProfileId, ctx.Ct);
                if (!retire.Changed)
                {
                    result = ModuleResult.Ok(retire.Ret);
                    break;
                }
                PlayerAccount retireAccount = await ctx.GetAccountAsync();
                uint retireNow = (uint)ctx.Now;
                // HeroData.SetData 只按增量合并；TemplateId=0 才是删除标记，不能仅推送剩余全量。
                List<HeroGrid> deletedHeroes = retire.RetiredHeroIds
                    .Select(id => new HeroGrid(HeroId: id, TemplateId: 0))
                    .ToList();
                result = new ModuleResult
                {
                    Ret = retire.Ret,
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(deletedHeroes, retireAccount.Dock.BagSize)),
                            Time: retireNow)),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, retireNow, ctx.Ct),
                        services.BuildBagPush(retireAccount, retireNow),
                        services.BuildEquipPush(retireAccount, retireNow, retire.RemovedEquipIds),
                    ],
                };
                break;
            case "hero.ChangeName":
                result = ModuleResult.Ok(await hero.BuildChangeNameRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.AddAffection":
                HeroService.AddAffectionResult affection =
                    await hero.BuildAddAffectionRetAsync(request, ctx.ProfileId, ctx.Ct);
                if (!affection.Changed || affection.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = affection.Ret,
                        Err = 1,
                        ErrMsg = affection.Error,
                    };
                    break;
                }
                PlayerAccount affectionAccount = await ctx.GetAccountAsync();
                uint affectionNow = (uint)ctx.Now;
                result = new ModuleResult
                {
                    Ret = affection.Ret,
                    // Lua 成功回调会立刻读取 HeroData 和 BagData，必须先刷新两份缓存。
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(
                                [GameServices.ToHeroGrid(affection.UpdatedHero)], affectionAccount.Dock.BagSize)),
                            Time: affectionNow)),
                        services.BuildBagPush(affectionAccount, affectionNow),
                    ],
                };
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
                var advHeroes = advAccount.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
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
                var skillHeroes = skillAccount.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
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
        // Name carries only a player-defined nickname. For an unrenamed ship it must remain
        // empty so JP/CN clients can display the name from their own localized config.
        List<HeroGrid> updatedHeroes = updatedAccount.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
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

}
