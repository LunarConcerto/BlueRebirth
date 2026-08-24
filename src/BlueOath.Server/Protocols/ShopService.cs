using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>商店/仓库服务：bag.GetBagInfo 的领域逻辑。</summary>
internal sealed class ShopService(GameServices services)
{
    /// <summary>仓库信息响应（bag.GetBagInfo 使用）。</summary>
    internal async Task<byte[]> BuildGetBagInfoRetAsync(string profileId, CancellationToken ct)
    {
        var account = await services.GetOrCreateAccountAsync(profileId, ct);
        var bag = account.Bag ?? new PlayerBag([], 100);
        var info = bag.Items.Select(i => new BagGridInfo(i.TemplateId, i.Num)).ToList();
        return PlayerDataCodec.Encode(new BagInfoRet(BagType: 1, BagSize: bag.BagSize, BagInfo: info));
    }
}
