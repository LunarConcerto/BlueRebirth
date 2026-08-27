using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>时装模块：fashion.*（Equip / updateData / fashionReplaceReward）。</summary>
internal sealed class FashionModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["fashion"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "fashion.Equip":
                var ret = await BuildFashionEquipRetAsync(ctx, request);
                // 更换时装后推送船坞数据，让客户端 Data.heroData 的 Fashioning 立即更新。
                var account = await ctx.GetAccountAsync();
                var heroes = account.Dock.Heroes.Select(ToHeroGridWithName).ToList();
                var heroPush = TMessageCodec.EncodeResponse(new TResponse(
                    Method: "hero.UpdateHeroBagData",
                    Ret: PlayerDataCodec.Encode(new HeroBag(heroes.ToList(), account.Dock.BagSize)),
                    Time: (uint)ctx.Now));
                result = new ModuleResult { Ret = ret, PrePushes = [heroPush] };
                break;
            case "fashion.updateData":
            case "fashion.fashionReplaceReward":
            default:
                result = ModuleResult.Ok([]);
                break;
        }
        return result;
    }

    private async Task<byte[]> BuildFashionEquipRetAsync(GameContext ctx, TRequest request)
    {
        if (request.Args is null) return [];
        FashionEquipArg arg = DecodeFashionEquipArg(request.Args);
        if (arg.HeroId == 0) return [];
        var account = await ctx.GetAccountAsync();
        var dock = account.Dock;
        var heroList = dock.Heroes.ToList();
        var idx = heroList.FindIndex(h => h.HeroId == arg.HeroId);
        if (idx < 0) return [];
        heroList[idx] = heroList[idx] with { Fashioning = arg.FashionTid };
        account = account with { Dock = dock with { Heroes = heroList } };
        await services.SaveAccountAsync(account, ctx.Ct);
        return [];
    }

    private static FashionEquipArg DecodeFashionEquipArg(ReadOnlySpan<byte> data)
    {
        ProtocolDecoder.ProtoReader reader = new(data);
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
        return new FashionEquipArg(fashionTid, equipStatus, heroId);
    }

    private static HeroGrid ToHeroGridWithName(Hero h)
    {
        var grid = GameServices.ToHeroGrid(h);
        return grid with { Name = ShipHandbookLoader.GetShipName(h.TemplateId) };
    }
}