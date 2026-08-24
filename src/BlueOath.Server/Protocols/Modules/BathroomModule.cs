using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>娴村妯″潡锛歜athroom.*锛堝紑濮?缁撴潫/鏈嶅姟/鑷姩/鎵归噺锛夈€?/summary>
internal sealed class BathroomModule(GameLoginMessageHandler services) : IGameModule
{
    public string Prefix => "bathroom";

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        byte[] ret;
        switch (request.Method)
        {
            case "bathroom.BathStart":
                ret = await BuildBathStartRetAsync(ctx, request);
                break;
            case "bathroom.BathEnd":
            case "bathroom.BathChangeHero":
                ret = await BuildBathEndRetAsync(ctx, request);
                break;
            case "bathroom.BathService":
                ret = await BuildBathServiceRetAsync(ctx, request);
                break;
            case "bathroom.BathAuto":
                ret = await BuildBathAutoRetAsync(ctx, request);
                break;
            case "bathroom.BathAllAuto":
                ret = await BuildBathAllAutoRetAsync(ctx, request);
                break;
            case "bathroom.GetBathroomInfo":
                ret = await BuildGetBathroomInfoRetAsync(ctx);
                break;
            case "bathroom.BathStartAll":
                ret = await BuildBathStartAllRetAsync(ctx, request);
                break;
            default:
                ret = [];
                break;
        }
        return ModuleResult.Ok(ret);
    }

    private async Task<byte[]> BuildBathStartRetAsync(GameContext ctx, TRequest request)
    {
        var arg = PlayerDataCodec.DecodeBathStartArg(request.Args!);
        var account = await ctx.GetAccountAsync();
        var dock = account.Dock;
        var hero = dock.Heroes.FirstOrDefault(h => h.HeroId == arg.HeroId);
        if (hero is null) throw new InvalidOperationException($"Hero {arg.HeroId} not found");
        var list = (account.Bath?.HeroList ?? []).ToList();
        list.RemoveAll(h => h.HeroId == arg.HeroId);
        list.Add(new BathHero(arg.HeroId, arg.Pos, StartTime: ctx.Now, BathTime: 0));
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await services.SaveAccountAsync(account, ctx.Ct);
        return PlayerDataCodec.Encode(GameLoginMessageHandler.ToBathroomInfo(account.Bath));
    }

    private async Task<byte[]> BuildBathEndRetAsync(GameContext ctx, TRequest request)
    {
        uint heroId;
        if (request.Method == "bathroom.BathEnd")
            heroId = PlayerDataCodec.DecodeBathEndArg(request.Args!);
        else
        {
            var arg = PlayerDataCodec.DecodeBathChangeHeroArg(request.Args!);
            heroId = arg.HeroId;
        }
        var account = await ctx.GetAccountAsync();
        var list = (account.Bath?.HeroList ?? []).ToList();
        var bathHero = list.FirstOrDefault(h => h.HeroId == heroId);
        if (bathHero is null) return PlayerDataCodec.EncodeBathEndRet(new BathHeroInfo(heroId, BathTime: 0));
        list.RemoveAll(h => h.HeroId == heroId);
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await services.SaveAccountAsync(account, ctx.Ct);
        return PlayerDataCodec.EncodeBathEndRet(GameLoginMessageHandler.ToBathHeroInfo(bathHero));
    }

    private async Task<byte[]> BuildBathServiceRetAsync(GameContext ctx, TRequest request)
    {
        var arg = PlayerDataCodec.DecodeBathServiceArg(request.Args!);
        var account = await ctx.GetAccountAsync();
        var bathHero = account.Bath?.HeroList.FirstOrDefault(h => h.HeroId == arg.HeroId);
        if (bathHero is null) return PlayerDataCodec.EncodeBathServiceRet(new BathHeroInfo(arg.HeroId), 0, false);
        // BuffId=0: skip buff lookup; GetBathAttrBuff checks heroBath.BuffId==0 鈫?ret=nil
        return PlayerDataCodec.EncodeBathServiceRet(GameLoginMessageHandler.ToBathHeroInfo(bathHero), 0, false);
    }

    private async Task<byte[]> BuildBathAutoRetAsync(GameContext ctx, TRequest request)
    {
        var arg = PlayerDataCodec.DecodeBathAutoArg(request.Args!);
        var account = await ctx.GetAccountAsync();
        var list = (account.Bath?.HeroList ?? []).ToList();
        var idx = list.FindIndex(h => h.HeroId == arg.HeroId);
        if (idx >= 0)
            list[idx] = list[idx] with { IsAuto = arg.Status };
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await services.SaveAccountAsync(account, ctx.Ct);
        return [];
    }

    private async Task<byte[]> BuildBathAllAutoRetAsync(GameContext ctx, TRequest request)
    {
        var status = PlayerDataCodec.DecodeBathAllAutoArg(request.Args!);
        var account = await ctx.GetAccountAsync();
        account = account with { Bath = new PlayerBath(account.Bath?.HeroList ?? [], status) };
        await services.SaveAccountAsync(account, ctx.Ct);
        return [];
    }

    private async Task<byte[]> BuildGetBathroomInfoRetAsync(GameContext ctx)
    {
        var account = await ctx.GetAccountAsync();
        return PlayerDataCodec.Encode(GameLoginMessageHandler.ToBathroomInfo(account.Bath));
    }

    private async Task<byte[]> BuildBathStartAllRetAsync(GameContext ctx, TRequest request)
    {
        var args = PlayerDataCodec.DecodeBathStartAllArg(request.Args!);
        var account = await ctx.GetAccountAsync();
        var list = (account.Bath?.HeroList ?? []).ToList();
        var result = new List<BathHero>();
        foreach (var a in args)
        {
            list.RemoveAll(h => h.HeroId == a.HeroId);
            var bh = new BathHero(a.HeroId, a.Pos, StartTime: ctx.Now, BathTime: 0);
            list.Add(bh);
            result.Add(bh);
        }
        account = account with { Bath = new PlayerBath(list, account.Bath?.IsAllAuto ?? 0) };
        await services.SaveAccountAsync(account, ctx.Ct);
        return PlayerDataCodec.EncodeBathStartAllRet(result.Select(GameLoginMessageHandler.ToBathHeroInfo).ToList());
    }
}
