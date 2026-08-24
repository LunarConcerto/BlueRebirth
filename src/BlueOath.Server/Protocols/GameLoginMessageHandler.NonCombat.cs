using BlueOath.Core;
using BlueOath.Protocol;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

internal sealed partial class GameLoginMessageHandler
{
    private byte[] BuildShopsInfoRet(uint now)
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

    private async Task<byte[]> BuildGetBagInfoRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var bagType = 1;
        if (request.Args is { Length: > 0 })
        {
            ProtoReader reader = new(request.Args);
            while (reader.TryReadField(out int field, out int wire))
                if (field == 1 && wire == 0) { bagType = checked((int)reader.ReadVarint()); break; }
                else reader.Skip(wire);
        }
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        return PlayerDataCodec.Encode(new BagInfoRet(BagType: bagType, BagSize: bag.BagSize, BagInfo: info));
    }

    private async Task<byte[]> BuildFashionEquipRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        if (request.Args is null) return [];
        var (fashionTid, _, heroId) = DecodeFashionEquipArg(request.Args);
        if (heroId == 0) return [];
        var account = await GetOrCreateAccountAsync(profileId, ct);
        var dock = account.Dock;
        var heroList = dock.Heroes.ToList();
        var idx = heroList.FindIndex(h => h.HeroId == heroId);
        if (idx < 0) return [];
        heroList[idx] = heroList[idx] with { Fashioning = fashionTid };
        account = account with { Dock = dock with { Heroes = heroList } };
        await _repo.SaveAccountAsync(account, ct);
        return [];
    }

    private static (int FashionTid, int EquipStatus, uint HeroId) DecodeFashionEquipArg(ReadOnlySpan<byte> data)
    {
        ProtoReader reader = new(data);
        int fashionTid = 0, equipStatus = 0;
        uint heroId = 0;
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0: fashionTid = checked((int)reader.ReadVarint()); break;
                case 2 when wire == 0: equipStatus = checked((int)reader.ReadVarint()); break;
                case 3 when wire == 0: heroId = checked((uint)reader.ReadVarint()); break;
                default: reader.Skip(wire); break;
            }
        return (fashionTid, equipStatus, heroId);
    }
}