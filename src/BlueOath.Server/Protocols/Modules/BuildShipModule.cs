using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>抽卡模块：buildship.*（BuildShip 等）+ 许愿池 illustrate.ModiVowHeroList / VowHero。</summary>
internal sealed class BuildShipModule(BuildShipService buildShip, GameServices services, BuildPoolsConfig buildPoolsConfig) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["buildship", "illustrate"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "buildship.BuildShip":
                var ret = await buildShip.BuildBuildShipRetAsync(request, ctx.ProfileId, ctx.Ct);
                // 应答前推送抽卡结果：抽到舰娘推船坞/图鉴；无论如何都推装备仓库。
                var pre = new List<byte[]>();
                if (ret.Length != 0)
                {
                    var account = await ctx.GetAccountAsync();
                    var newIds = services.GetLastBuildHeroIds();
                    var newHeroes = account.Dock.Heroes
                        .Where(h => newIds.Contains(h.HeroId))
                        // HeroGrid.Name is the player-defined nickname. Leave it empty for an
                        // unrenamed ship so the client falls back to its localized ship_name.
                        .Select(GameServices.ToHeroGrid)
                        .ToList();
                    var now = (uint)ctx.Now;
                    if (newHeroes.Count > 0)
                    {
                        pre.Add(TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(newHeroes, account.Dock.BagSize)),
                            Time: now)));
                        pre.Add(TMessageCodec.EncodeResponse(new TResponse(
                            Method: "illustrate.IllustrateInfo",
                            Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                                IllustrateList: newHeroes
                                    .Select(h => GameServices.BuildUnlockedIllustrateInfo(
                                        GameServices.ToIllustrateId(h.TemplateId), now))
                                    .ToList(),
                                IllustrateEquipList: [new IllustrateEquipInfo()])),
                            Time: now)));
                    }
                    // 新舰娘自带默认装备（config_ship_info.equip1..equip6），纯装备抽卡也会新增
                    // EquipItem，推送完整装备仓库让客户端 equipdata 拿到新增装备。
                    pre.Add(services.BuildEquipPush(account, now));
                    // 推送最新累计抽数/领奖状态，客户端累计奖励 UI 无需重登即可刷新。
                    pre.Add(TMessageCodec.EncodeResponse(new TResponse(
                        Method: "buildship.BuildShipInfo",
                        Ret: ProtocolEncoder.EncodeBuildShipInfo(buildPoolsConfig.EnabledPoolIds, now, account.BuildState),
                        Time: now)));
                }
                result = new ModuleResult { Ret = ret, PrePushes = pre };
                break;
            case "buildship.BuildShipInfo":
                result = ModuleResult.Ok(new byte[] { 0x08, 0x00 }); // DrawInfo: empty
                break;
            case "illustrate.ModiVowHeroList":
                // 许愿墙列表由客户端本地维护（_OnModiVowHero 用 state 回显调用 SetPreHeroList），
                // 服务端只需返回成功。
                result = ModuleResult.Ok([]);
                break;
            case "illustrate.VowHero":
                result = await BuildVowHeroRetAsync(ctx, request);
                break;
            case "illustrate.AddBehaviour":
                result = ModuleResult.Ok(await buildShip.BuildAddBehaviourRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "buildship.BuildShipBox":
                result = ModuleResult.Ok(await buildShip.BuildBuildShipBoxRetAsync(request, ctx.ProfileId, ctx.Ct));
                result = await AttachBuildRewardPushesAsync(result, ctx);
                break;
            case "buildship.BuildShipReward":
                result = ModuleResult.Ok(await buildShip.BuildBuildShipRewardRetAsync(request, ctx.ProfileId, ctx.Ct));
                result = await AttachBuildRewardPushesAsync(result, ctx);
                break;
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    /// <summary>
    /// 处理 illustrate.VowHero：许愿获取舰娘。ChooseHeroList 为 ship_info_id（图鉴 id），
    /// 取第一个并映射 templateId = ship_info_id * 10 + 1，创建同名新舰娘，返回 TVowHeroRet。
    /// </summary>
    private async Task<ModuleResult> BuildVowHeroRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return ModuleResult.Empty;
        List<int> heroList = ProtocolDecoder.DecodeChooseHeroList(request.Args);
        if (heroList.Count == 0) return ModuleResult.Empty;

        int shipInfoId = heroList[0];
        int templateId = shipInfoId * 10 + 1;

        var account = await ctx.GetAccountAsync();
        int now = ctx.Now;
        uint heroId = services.NextHeroId();
        account = services.AddShip(account, heroId, templateId, now);
        await services.SaveAccountAsync(account, ctx.Ct);

        byte[] ret = ProtocolEncoder.EncodeVowHeroRet(GameServices.GoodsTypeShip, templateId, 1, (int)heroId);

        var updatedAccount = await ctx.GetAccountAsync();
        var heroes = updatedAccount.Dock.Heroes.Select(GameServices.ToHeroGrid).ToList();
        var heroPush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "hero.UpdateHeroBagData",
            Ret: PlayerDataCodec.Encode(new HeroBag(heroes, updatedAccount.Dock.BagSize)),
            Time: (uint)ctx.Now));
        var illustratePush = TMessageCodec.EncodeResponse(new TResponse(
            Method: "illustrate.IllustrateInfo",
            Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                IllustrateList: updatedAccount.Dock.Heroes
                    .Where(h => h.HeroId == heroId)
                    .Select(h => GameServices.BuildUnlockedIllustrateInfo(
                        GameServices.ToIllustrateId(h.TemplateId), ctx.Now))
                    .ToList(),
                IllustrateEquipList: [new IllustrateEquipInfo()])),
            Time: (uint)ctx.Now));
        return new ModuleResult { Ret = ret, PrePushes = [heroPush, illustratePush] };
    }

    /// <summary>领奖后附加推送：新舰娘（抽卡宝箱可能出船）推船坞/图鉴/装备，并推送累计奖状态。</summary>
    private async Task<ModuleResult> AttachBuildRewardPushesAsync(ModuleResult result, GameContext ctx)
    {
        if (result.Ret.Length == 0) return result;

        var account = await ctx.GetAccountAsync();
        var now = (uint)ctx.Now;
        var newIds = services.GetLastBuildHeroIds();
        var newHeroes = account.Dock.Heroes
            .Where(h => newIds.Contains(h.HeroId))
            .Select(GameServices.ToHeroGrid)
            .ToList();

        var pushes = new List<byte[]>();
        if (newHeroes.Count > 0)
        {
            pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
                Method: "hero.UpdateHeroBagData",
                Ret: PlayerDataCodec.Encode(new HeroBag(newHeroes, account.Dock.BagSize)),
                Time: now)));
            pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
                Method: "illustrate.IllustrateInfo",
                Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                    IllustrateList: newHeroes
                        .Select(h => new IllustrateInfo((h.TemplateId - 1) / 10, now, 0, false, null, 0))
                        .ToList(),
                    IllustrateEquipList: [new IllustrateEquipInfo()])),
                Time: now)));
        }
        pushes.Add(services.BuildEquipPush(account, now));
        // 推送最新累计抽数/领奖状态。
        pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
            Method: "buildship.BuildShipInfo",
            Ret: ProtocolEncoder.EncodeBuildShipInfo(buildPoolsConfig.EnabledPoolIds, now, account.BuildState),
            Time: now)));

        return new ModuleResult { Ret = result.Ret, PrePushes = pushes };
    }

}
