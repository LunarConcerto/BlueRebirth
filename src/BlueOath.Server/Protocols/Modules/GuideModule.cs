using BlueOath.Protocol;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>引导模块：guide.*（PlotReward / Setting）。</summary>
internal sealed class GuideModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["guide"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        byte[] ret = request.Method switch
        {
            "guide.PlotReward" => await BuildPlotRewardAsync(ctx, request.Args ?? []),
            "guide.Setting" => [],
            _ => []
        };
        return ModuleResult.Ok(ret);
    }

    private async Task<byte[]> BuildPlotRewardAsync(GameContext ctx, byte[] args)
    {
        int plotId = args.Length > 0 ? (int)ProtocolDecoder.DecodeVarint(args.AsSpan()) : 0;
        services.FileLogger.LogInformation("guide.PlotReward plotId={PlotId} argsLen={ArgsLen} hex={Hex}",
            plotId, args.Length, Convert.ToHexString(args));
        if (plotId == 0)
            return EncodePlotRewardRet(0);

        var account = await ctx.GetAccountAsync();
        var plotIds = account.PlotRewardIds?.ToList() ?? new List<int>();
        if (!plotIds.Contains(plotId))
        {
            plotIds.Add(plotId);
            account = account with { PlotRewardIds = plotIds };
            await services.SaveAccountAsync(account, ctx.Ct);
            services.FileLogger.LogInformation("guide.PlotReward stored plotId={PlotId} count={Count}", plotId, plotIds.Count);
        }
        else
        {
            services.FileLogger.LogInformation("guide.PlotReward plotId={PlotId} already stored", plotId);
        }

        return EncodePlotRewardRet(plotId);
    }

    private static byte[] EncodePlotRewardRet(int plotId)
    {
        ProtocolPackage ms = new();
        if (plotId != 0)
            ms.Write(0x08, unchecked((ulong)plotId));
        return ms.ToArray();
    }
}
