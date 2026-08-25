using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>商店/仓库模块：shop.*（购买/商店信息）与 bag.GetBagInfo。</summary>
internal sealed class ShopModule(ShopService shop, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["shop", "bag"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "shop.BuyGoods":
            case "shop.QualityBuyGoods":
                result = new ModuleResult
                {
                    Ret = request.Method == "shop.BuyGoods"
                        ? await BuildBuyGoodsRetAsync(ctx, request)
                        : await BuildQualityBuyGoodsRetAsync(ctx, request),
                    PostPushes = await services.BuildPostBuyPushesAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
                };
                break;
            case "shop.GetShopsInfo":
                result = ModuleResult.Ok(services.BuildShopsInfoRet(checked((uint)ctx.Now)));
                break;
            case "bag.GetBagInfo":
                result = ModuleResult.Ok(await shop.BuildGetBagInfoRetAsync(ctx.ProfileId, ctx.Ct));
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
    private async Task<byte[]> BuildBuyGoodsRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return [];
        var (_, goodId, buyNum, _) = TMessageCodec.DecodeBuyGoodsArg(request.Args);
        if (buyNum <= 0) buyNum = 1;

        var account = await ctx.GetAccountAsync();
        var (newAccount, reward) = ApplyGoods(account, goodId, buyNum);
        if (reward.Type == 0) return [];
        await services.SaveAccountAsync(newAccount, ctx.Ct);

        return TMessageCodec.EncodeBuyGoodsRet(reward, goodId, buyNum);
    }

    /// <summary>处理 shop.QualityBuyGoods（多选/批量购买）：对每个 GoodId 免费发放。</summary>
    private async Task<byte[]> BuildQualityBuyGoodsRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return [];
        var (_, goodIds) = TMessageCodec.DecodeQualityBuyGoodsArg(request.Args);
        if (goodIds.Count == 0) return [];

        var account = await ctx.GetAccountAsync();
        var rewards = new List<CommonReward>();
        foreach (var goodId in goodIds)
        {
            var (newAccount, reward) = ApplyGoods(account, goodId, 1);
            if (reward.Type == 0) continue;
            account = newAccount;
            rewards.Add(reward);
        }
        await services.SaveAccountAsync(account, ctx.Ct);

        return TMessageCodec.EncodeQualityBuyGoodsRet(rewards, goodIds);
    }

    /// <summary>发放单个 GM 商品，返回更新后的账号和奖励。无效商品返回 Type=0 的空奖励。</summary>
    private (PlayerAccount Account, CommonReward Reward) ApplyGoods(PlayerAccount account, int goodId, int buyNum)
    {
        if (!services.GmGoodsMap.TryGetValue(goodId, out var goods))
            return (account, new CommonReward());
        if (buyNum <= 0) buyNum = 1;
        var totalNum = goods.Num * buyNum;

        if (goods.Type == GameServices.GoodsTypeCurrency)
        {
            account = GameServices.AddCurrency(account, goods.ConfigId, totalNum);
        }
        else if (goods.Type == GameServices.GoodsTypeFashion)
        {
            account = AddFashion(account, goods.ConfigId);
        }
        else if (goods.Type == GameServices.GoodsTypeEquip)
        {
            for (var i = 0; i < totalNum; i++)
                account = AddEquipItem(account, goods.ConfigId);
        }
        else
        {
            account = GameServices.AddBagItem(account, goods.ConfigId, totalNum);
        }
        return (account, new CommonReward(goods.Type, goods.ConfigId, totalNum));
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

    private PlayerAccount AddFashion(PlayerAccount account, int fashionTid)
    {
        var fashion = account.Fashion ?? new PlayerFashion([]);
        var entries = fashion.Entries.ToList();
        var sfId = services.FashionSfIdMap.GetValueOrDefault(fashionTid, fashionTid);
        var idx = entries.FindIndex(e => e.SfId == sfId);
        if (idx >= 0)
        {
            var tids = entries[idx].FashionTids.ToList();
            if (!tids.Contains(fashionTid))
                tids.Add(fashionTid);
            entries[idx] = entries[idx] with { FashionTids = tids };
        }
        else
        {
            entries.Add(new FashionEntry(sfId, [fashionTid]));
        }
        return account with { Fashion = fashion with { Entries = entries } };
    }
}
