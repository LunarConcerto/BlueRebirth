using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

internal sealed partial class GameLoginMessageHandler
{
    /// <summary>config_shop 全部商店 id（104 个）。</summary>
    internal static readonly int[] ShopIds =
    [
        1, 3, 5, 6, 7, 8, 9, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
        26, 27, 29, 30, 101, 102, 104, 105, 106, 107, 110, 111, 200, 201, 202, 205,
        206, 207, 208, 300, 302, 303, 305, 306, 401, 901, 902, 903, 911, 912, 913,
        914, 915, 916, 917, 918, 919, 920, 924, 930, 931, 934, 935, 936, 940, 950,
        951, 954, 955, 956, 957, 958, 1001, 1002, 1003, 1004, 1006, 1010, 1011, 1012,
        1013, 1014, 1015, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1030, 1040, 1041,
        1042, 1043, 1044, 1051, 1052, 1071, 1072, 1073, 1074, 1201, 1202,
    ];

    /// <summary>商店列表响应（shop.GetShopsInfo 使用）。</summary>
    internal byte[] BuildShopsInfoRet(uint now)
    {
        var goodsByShop = _gmGoods.Goods
            .GroupBy(g => g.ShopId)
            .ToDictionary(g => g.Key, g => g.Select(x => new ShopGoodsData(x.GoodId, 0, 0)).ToList());
        var shopInfo = ShopIds.Select(id =>
            goodsByShop.TryGetValue(id, out var goods)
                ? new RetShopInfo(id, goods)
                : new RetShopInfo(id)).ToList();
        return PlayerDataCodec.Encode(new RetShopsInfo(ShopInfo: shopInfo));
    }

    /// <summary>仓库信息响应（bag.GetBagInfo 使用）。</summary>
    internal async Task<byte[]> BuildGetBagInfoRetAsync(string profileId, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        return PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize, BagInfo: info));
    }

    /// <summary>
    /// 商店数据推送（shop.UpdateShopInfo）。让 Data.shopData.m_shopInfo 非空，否则
    /// ShopData.GetShopInfoById 里 m_shopInfo[shopId] 为 nil，红点系统（BrokenFashionShop
    /// → CheckShopNewFashion）在主页/商店页就崩溃。
    /// GM 商品按配置的 ShopId 分组放入对应商店（分页）。
    /// </summary>
public byte[] BuildShopInfoPush(uint now)
    {
        var push = new TResponse(Method: "shop.UpdateShopInfo",
            Ret: BuildShopsInfoRet(now),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    // GoodsType 常量（constants.lua）。ITEM=1, EQUIP=2, CURRENCY=5, EQUIP_ENHANCE_ITEM=6, FASHION=18。
    internal const int GoodsTypeCurrency = 5;
    internal const int GoodsTypeEquip = 2;
    internal const int GoodsTypeFashion = 18;
    private uint _nextEquipId = 1;
    private uint _nextHeroId = 2; // 1 是默认秘书舰

    /// <summary>为 GM 命令生成下一个可用的舰娘实例 ID（调用前需确保已加载账号）。</summary>
    public uint NextHeroId() => _nextHeroId++;

    /// <summary>生成下一个装备实例 ID。</summary>
    internal uint NextEquipId() => _nextEquipId++;

    /// <summary>初始化 _nextEquipId 为账号中最大装备 ID + 1（避免服务重启后 ID 重复）。</summary>
    internal void EnsureEquipIdFromAccount(PlayerAccount account)
    {
        if (account.Equip is { Items.Count: > 0 } equip)
        {
            var maxId = equip.Items.Max(e => e.EquipId);
            if (maxId >= _nextEquipId)
                _nextEquipId = maxId + 1;
        }
        if (account.Dock is { Heroes.Count: > 0 } dock)
        {
            var maxId = dock.Heroes.Max(h => h.HeroId);
            if (maxId >= _nextHeroId)
                _nextHeroId = maxId + 1;
        }
    }


    /// <summary>发放单个 GM 商品（已迁移到 ShopModule）。</summary>


    /// <summary>
    /// 货币发放（CurrencyType → UserInfo 字段）。覆盖客户端 UserInfo 里全部 24 种持久货币
    /// （constants.lua CurrencyType 与 user_pb.lua TGetUserInfoRet 字段的并集，排除非 UserInfo
    /// 的战斗/建筑临时值如 BULLET/GAS/ELECTRIC 等）。
    /// </summary>
    internal static PlayerAccount AddCurrency(PlayerAccount account, int currencyType, int num)
    {
        var c = account.Character;
        c = currencyType switch
        {
            1 => c with { Gold = c.Gold + num },
            2 => c with { Diamond = c.Diamond + num },
            5 => c with { Supply = c.Supply + num },
            8 => c with { MainGun = c.MainGun + num },
            9 => c with { Torpedo = c.Torpedo + num },
            10 => c with { Plane = c.Plane + num },
            11 => c with { Other = c.Other + num },
            12 => c with { Retire = c.Retire + num },
            13 => c with { Bath = c.Bath + num },
            14 => c with { Strategy = c.Strategy + num },
            15 => c with { Medal = c.Medal + num },
            18 => c with { Tower = c.Tower + num },
            22 => c with { CopyTrainPoint = c.CopyTrainPoint + num },
            23 => c with { FashionPoint = c.FashionPoint + num },
            24 => c with { GuildContri = c.GuildContri + num },
            25 => c with { Lucky = c.Lucky + num },
            26 => c with { TeacherMedal = c.TeacherMedal + num },
            27 => c with { TeacherPrestige = c.TeacherPrestige + num },
            28 => c with { BattlePassExp = c.BattlePassExp + num },
            29 => c with { BattlePassGold = c.BattlePassGold + num },
            30 => c with { PvePt = c.PvePt + num },
            31 => c with { GuildCoinII = c.GuildCoinII + num },
            32 => c with { UrEquipCoin = c.UrEquipCoin + num },
            33 => c with { ActivityBattlePassExp = c.ActivityBattlePassExp + num },
            _ => c with { Gold = c.Gold + num },
        };
        return account with { Character = c };
    }

    internal static PlayerAccount AddBagItem(PlayerAccount account, int templateId, int num)
    {
        var bag = account.Bag ?? new PlayerBag([], 100);
        var items = bag.Items.ToList();
        var idx = items.FindIndex(i => i.TemplateId == templateId);
        if (idx >= 0)
            items[idx] = items[idx] with { Num = items[idx].Num + num };
        else
            items.Add(new BagItem(templateId, num));
        return account with { Bag = bag with { Items = items } };
    }

    /// <summary>仓库数据推送（bag.UpdateBagData）。</summary>
    public byte[] BuildBagPush(PlayerAccount account, uint now)
    {
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        var push = new TResponse(Method: "bag.UpdateBagData",
            Ret: PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize, BagInfo: info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>时装数据推送（fashion.updateData）。</summary>
    public byte[] BuildFashionPush(PlayerAccount account, uint now)
    {
        var fashion = account.Fashion ?? new PlayerFashion([]);
        var info = fashion.Entries.Select(e => new FashionInfo(e.SfId, e.FashionTids)).ToList();
        var push = new TResponse(Method: "fashion.updateData",
            Ret: PlayerDataCodec.Encode(new FashionList(info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>装备仓库推送（equip.UpdateEquipBagData）。</summary>
    public byte[] BuildEquipPush(PlayerAccount account, uint now)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var info = equip.Items.Select(e => new EquipInfo(e.EquipId, e.TemplateId, e.EnhanceLv,
            e.Star, e.HeroId, e.EnhanceExp)).ToList();
        var push = new TResponse(Method: "equip.UpdateEquipBagData",
            Ret: PlayerDataCodec.Encode(new EquipList(EquipBagSize: equip.EquipBagSize, EquipInfo: info)),
            Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>购买后的数据推送（货币 + 仓库 + 时装 + 装备），供会话在 shop.BuyGoods 应答后发出。</summary>
    public async Task<IReadOnlyList<byte[]>> BuildPostBuyPushesAsync(string profileId, uint now, CancellationToken ct)
    {
        var account = await GetOrCreateAccountAsync(profileId, ct);
        return
        [
            await BuildUpdateUserInfoPushAsync(profileId, now, ct),
            BuildBagPush(account, now),
            BuildFashionPush(account, now),
            BuildEquipPush(account, now),
        ];
    }

}
