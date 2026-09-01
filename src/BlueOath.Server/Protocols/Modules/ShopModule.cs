using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>商店/仓库模块：shop.*（购买/商店信息）与 bag.GetBagInfo。</summary>
internal sealed class ShopModule(ShopService shop, GameServices services) : IGameModule
{
    /// <summary>发放结果：更新后的账号 + 生成的奖励（无效商品 Type=0）。</summary>
    private sealed record GoodsGrant(PlayerAccount Account, CommonReward Reward);
    /// <summary>本次购买发放的舰娘模板 ID，供推送侧同步图鉴（<see cref="GameServices.BuildBuyPushesAsync"/>）。</summary>
    private sealed record PurchaseResult(byte[] Ret, bool Changed, string Error,
        IReadOnlyList<int>? ShipTemplateIds = null);

    public IReadOnlyList<string> Prefixes => ["shop", "bag"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "shop.BuyGoods":
            case "shop.QualityBuyGoods":
                PurchaseResult purchase = request.Method == "shop.BuyGoods"
                    ? await BuildBuyGoodsRetAsync(ctx, request)
                    : await BuildQualityBuyGoodsRetAsync(ctx, request);
                result = new ModuleResult
                {
                    Ret = purchase.Ret,
                    Err = purchase.Changed ? 0 : 1,
                    ErrMsg = purchase.Error,
                    // Lua 购买成功回调会立即读取背包/货币，必须先刷新缓存。
                    PrePushes = purchase.Changed
                        ? await services.BuildBuyPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct,
                            newShipTemplateIds: purchase.ShipTemplateIds)
                        : [],
                };
                break;
            case "shop.GetShopsInfo":
                result = ModuleResult.Ok(services.BuildShopsInfoRet(checked((uint)ctx.Now)));
                break;
            case "bag.GetBagInfo":
                result = ModuleResult.Ok(await shop.BuildGetBagInfoRetAsync(ctx.ProfileId, ctx.Ct));
                break;
            case "bag.GetNormalTreasureInfo":
                ShopService.TreasureOpenResult treasure =
                    await shop.BuildOpenNormalTreasureRetAsync(request, ctx.ProfileId, ctx.Ct);
                result = new ModuleResult
                {
                    Ret = treasure.Ret,
                    Err = treasure.Changed ? 0 : 1,
                    ErrMsg = treasure.Error,
                    // 宝箱成功回调会立即重读背包并展示装备；先刷新所有可能受奖励影响的缓存。
                    PrePushes = treasure.Changed
                        ? await services.BuildBuyPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct,
                            treasure.RemovedTreasureTemplateId > 0
                                ? [treasure.RemovedTreasureTemplateId]
                                : null)
                        : [],
                };
                break;
            case "bag.GetSelectTreasureInfo":
                ShopService.TreasureOpenResult selected =
                    await shop.BuildOpenSelectTreasureRetAsync(request, ctx.ProfileId, ctx.Ct);
                // 非道具箱（舰船/装备选择箱）由 BuildOpenSelectTreasureRetAsync 返回
                // Changed=false 且 Error 为空，此处保持改动前的空响应，不引入新的错误码。
                result = !selected.Changed && selected.Error.Length == 0
                    ? ModuleResult.Empty
                    : new ModuleResult
                    {
                        Ret = selected.Ret,
                        Err = selected.Changed ? 0 : 1,
                        ErrMsg = selected.Error,
                        PrePushes = selected.Changed
                            ? await services.BuildBuyPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct,
                                selected.RemovedTreasureTemplateId > 0
                                    ? [selected.RemovedTreasureTemplateId]
                                    : null)
                            : [],
                    };
                break;
            case "shop.RefreshShop":
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    /// <summary>
    /// 处理 shop.BuyGoods：免费发放商品内容到对应存储（GM 功能，不扣货币）。
    /// - ITEM/EQUIP_ENHANCE_ITEM → 仓库（bag）
    /// - CURRENCY → 货币（UserInfo 对应字段）
    /// - FASHION → 时装解锁
    /// 返回 TBuyGoodsRet{Reward, GoodId, BuyNum}，并把更新后的账号落盘。
    /// </summary>
    private async Task<PurchaseResult> BuildBuyGoodsRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return new([], false, "purchase request is missing");
        BuyGoodsArg arg = TMessageCodec.DecodeBuyGoodsArg(request.Args);
        if (arg.BuyNum <= 0) arg = arg with { BuyNum = 1 };
        if (!services.GmGoodsMap.TryGetValue(arg.GoodId, out GmGoodConfig? goods) ||
            goods.ShopId != arg.ShopId)
            return new([], false, "shop goods were not found");

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await ctx.GetAccountAsync();
        GoodsGrant grant = ApplyGoods(account, arg.GoodId, arg.BuyNum, ctx.Now);
        if (grant.Reward.Type == 0) return new([], false, "shop goods could not be granted");
        await services.SaveAccountAsync(grant.Account, ctx.Ct);

        return new(TMessageCodec.EncodeBuyGoodsRet(grant.Reward, arg.GoodId, arg.BuyNum), true, "",
            grant.Reward.Type == GameServices.GoodsTypeShip ? [grant.Reward.ConfigId] : null);
    }

    /// <summary>处理 shop.QualityBuyGoods（多选/批量购买）：对每个 GoodId 免费发放。</summary>
    private async Task<PurchaseResult> BuildQualityBuyGoodsRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return new([], false, "purchase request is missing");
        QualityBuyGoodsArg arg = TMessageCodec.DecodeQualityBuyGoodsArg(request.Args);
        if (arg.GoodIdList.Count == 0) return new([], false, "purchase list is empty");

        using var _ = await services.LockAccountAsync(ctx.ProfileId, ctx.Ct);
        PlayerAccount account = await ctx.GetAccountAsync();
        var rewards = new List<CommonReward>();
        foreach (var goodId in arg.GoodIdList)
        {
            if (!services.GmGoodsMap.TryGetValue(goodId, out GmGoodConfig? goods) ||
                goods.ShopId != arg.ShopId)
                continue;
            var grant = ApplyGoods(account, goodId, 1, ctx.Now);
            if (grant.Reward.Type == 0) continue;
            account = grant.Account;
            rewards.Add(grant.Reward);
        }
        if (rewards.Count == 0) return new([], false, "shop goods were not found");
        await services.SaveAccountAsync(account, ctx.Ct);

        return new(TMessageCodec.EncodeQualityBuyGoodsRet(rewards, arg.GoodIdList), true, "",
            rewards.Where(reward => reward.Type == GameServices.GoodsTypeShip)
                .Select(reward => reward.ConfigId).ToList());
    }

    /// <summary>发放单个 GM 商品，返回更新后的账号和奖励。无效商品返回 Type=0 的空奖励。</summary>
    private GoodsGrant ApplyGoods(PlayerAccount account, int goodId, int buyNum, int now)
    {
        if (!services.GmGoodsMap.TryGetValue(goodId, out var goods))
            return new GoodsGrant(account, new CommonReward());
        if (buyNum <= 0) buyNum = 1;
        var totalNum = goods.Num * buyNum;

        if (goods.Type == GameServices.GoodsTypeCurrency)
        {
            account = GameServices.AddCurrency(account, goods.ItemId, totalNum);
        }
        else if (goods.Type == GameServices.GoodsTypeFashion)
        {
            account = services.AddFashion(account, goods.ItemId);
        }
        else if (goods.Type == GameServices.GoodsTypeShip)
        {
            // 舰娘购买 → 加入船坞（HeroDock），不能进背包（baglogic 按 config_table_index
            // 解析模板会崩溃）。reward.Id 携带最后一个生成的 HeroId 供客户端渲染。
            uint lastHeroId = 0;
            for (var i = 0; i < totalNum; i++)
            {
                uint heroId = services.NextHeroId();
                account = services.AddShip(account, heroId, goods.ItemId, now);
                lastHeroId = heroId;
            }
            return new GoodsGrant(account, new CommonReward(goods.Type, goods.ItemId, 1, checked((int)lastHeroId)));
        }
        else if (goods.Type == GameServices.GoodsTypeEquip)
        {
            for (var i = 0; i < totalNum; i++)
                account = AddEquipItem(account, goods.ItemId);
        }
        else
        {
            account = GameServices.AddBagItem(account, goods.ItemId, totalNum);
        }
        return new GoodsGrant(account, new CommonReward(goods.Type, goods.ItemId, totalNum));
    }

    /// <summary>装备入库：创建一件装备实例（EquipId 自增），存入装备仓库。</summary>
    private PlayerAccount AddEquipItem(PlayerAccount account, int templateId)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        var id = services.NextEquipId();
        items.Add(new EquipItem(EquipId: id, TemplateId: templateId));
        return account with { Equip = equip with { Items = items } };
    }

}
