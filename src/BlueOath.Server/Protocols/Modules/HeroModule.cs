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
            case "hero.AddExp":
                result = await UpdateHero(ctx,
                    await hero.BuildAddExpRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "hero.Marry":
                HeroService.MarryResult marry =
                    await hero.BuildMarryRetAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                if (!marry.Changed || marry.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = marry.Ret,
                        Err = 1,
                        ErrMsg = marry.Error,
                    };
                    break;
                }
                PlayerAccount marryAccount = await ctx.GetAccountAsync();
                uint marryNow = (uint)ctx.Now;
                result = new ModuleResult
                {
                    Ret = marry.Ret,
                    // MarrySuccess 会立即读取 HeroData、BagData 和 MarriedNum。
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(
                                [GameServices.ToHeroGrid(marry.UpdatedHero)], marryAccount.Dock.BagSize)),
                            Time: marryNow)),
                        services.BuildBagPush(marryAccount, marryNow),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, marryNow, ctx.Ct),
                    ],
                };
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
                HeroService.ChangeNameResult rename =
                    await hero.BuildChangeNameRetAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                if (!rename.Changed || rename.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = rename.Ret,
                        Err = 1,
                        ErrMsg = rename.Error,
                    };
                    break;
                }
                PlayerAccount renameAccount = await ctx.GetAccountAsync();
                result = new ModuleResult
                {
                    Ret = rename.Ret,
                    // ChangeNameSuccess 会立刻从 HeroData 读取名称，必须先刷新客户端缓存。
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(
                                [GameServices.ToHeroGrid(rename.UpdatedHero)], renameAccount.Dock.BagSize)),
                            Time: (uint)ctx.Now)),
                    ],
                };
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
                HeroService.AdvanceResult advance =
                    await hero.BuildAdvanceRetAsync(request, ctx.ProfileId, ctx.Ct);
                if (!advance.Changed || advance.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = advance.Ret,
                        Err = 1,
                        ErrMsg = "advance failed",
                    };
                    break;
                }
                PlayerAccount advanceAccount = await ctx.GetAccountAsync();
                uint advanceNow = (uint)ctx.Now;
                // 突破会消耗素材舰娘。HeroData.SetData 只按增量合并，TemplateId=0 才是删除标记，
                // 不能只推送剩余全量；需为每个被消耗舰娘推送删除标记 + 更新后的主舰娘。
                List<HeroGrid> advanceHeroGrids =
                [
                    GameServices.ToHeroGrid(advance.UpdatedHero),
                    .. advance.ConsumedHeroIds.Select(id => new HeroGrid(HeroId: id, TemplateId: 0)),
                ];
                result = new ModuleResult
                {
                    Ret = advance.Ret,
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(advanceHeroGrids, advanceAccount.Dock.BagSize)),
                            Time: advanceNow)),
                        services.BuildBagPush(advanceAccount, advanceNow),
                        services.BuildEquipPush(advanceAccount, advanceNow),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, advanceNow, ctx.Ct),
                    ],
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
            case "hero.HeroRemould":
                HeroService.RemouldResult remould =
                    await hero.BuildHeroRemouldRetAsync(request, ctx.ProfileId, ctx.Ct);
                if (!remould.Changed || remould.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = remould.Ret,
                        Err = 1,
                        ErrMsg = remould.Error,
                    };
                    break;
                }
                PlayerAccount remouldAccount = await ctx.GetAccountAsync();
                uint remouldNow = (uint)ctx.Now;
                result = new ModuleResult
                {
                    Ret = remould.Ret,
                    // Lua 成功回调会立即重读节点、技能、背包和货币，均需在应答前刷新。
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(
                                [GameServices.ToHeroGrid(remould.UpdatedHero)], remouldAccount.Dock.BagSize)),
                            Time: remouldNow)),
                        services.BuildBagPush(remouldAccount, remouldNow),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, remouldNow, ctx.Ct),
                    ],
                };
                break;
            case "hero.HeroAdvanceMUB":
                HeroService.AdvanceResult advanceMub =
                    await hero.BuildAdvanceMubRetAsync(request, ctx.ProfileId, ctx.Ct);
                if (!advanceMub.Changed || advanceMub.UpdatedHero is null)
                {
                    result = new ModuleResult
                    {
                        Ret = advanceMub.Ret,
                        Err = 1,
                        ErrMsg = "advance mub failed",
                    };
                    break;
                }
                PlayerAccount mubAccount = await ctx.GetAccountAsync();
                uint mubNow = (uint)ctx.Now;
                result = new ModuleResult
                {
                    Ret = advanceMub.Ret,
                    // 彩色船突破只消耗道具，无消耗舰娘，推送更新后的主舰娘 + 背包 + 用户信息即可。
                    PrePushes =
                    [
                        TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(
                                [GameServices.ToHeroGrid(advanceMub.UpdatedHero)], mubAccount.Dock.BagSize)),
                            Time: mubNow)),
                        services.BuildBagPush(mubAccount, mubNow),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, mubNow, ctx.Ct),
                    ],
                };
                break;
            case "hero.HeroIntensify":
            case "hero.AutoEquip":
            case "hero.AutoUnEquip":
            case "hero.HeroAdvMaxLv":
            case "hero.HeroEquipEffect":
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
