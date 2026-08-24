using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>时装模块：fashion.*（Equip / updateData / fashionReplaceReward）。</summary>
internal sealed class FashionModule(GameLoginMessageHandler services) : IGameModule
{
    public string Prefix => "fashion";

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        byte[] ret = request.Method switch
        {
            "fashion.Equip" => await BuildFashionEquipRetAsync(ctx, request),
            "fashion.updateData" => [],
            "fashion.fashionReplaceReward" => [],
            _ => []
        };
        return ModuleResult.Ok(ret);
    }

    private async Task<byte[]> BuildFashionEquipRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return [];
        var (fashionTid, _, heroId) = DecodeFashionEquipArg(request.Args);
        if (heroId == 0) return [];
        var account = await ctx.GetAccountAsync();
        var dock = account.Dock;
        var heroList = dock.Heroes.ToList();
        var idx = heroList.FindIndex(h => h.HeroId == heroId);
        if (idx < 0) return [];
        heroList[idx] = heroList[idx] with { Fashioning = fashionTid };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ctx.Ct);
        return [];
    }

    private static (int FashionTid, int EquipStatus, uint HeroId) DecodeFashionEquipArg(ReadOnlySpan<byte> data)
    {
        GameLoginMessageHandler.ProtoReader reader = new(data);
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
