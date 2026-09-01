using BlueOath.Core;
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
            "guide.Setting" => await BuildSettingAsync(ctx, request.Args ?? []),
            _ => []
        };
        return ModuleResult.Ok(ret);
    }

    /// <summary>
    /// 处理 guide.Setting：把客户端提交的键值写入存档，并回一个带全量设置的 TGuideInfo。
    /// 客户端 GuideService:_ReceiveUserSetting 按 TGUIDEINFO 解码应答，再用
    /// GuideData:SetSetting 逐键并入 m_setmap —— 应答不带 Setting，界面读到的就永远是 nil，
    /// 强化页的三个开关（LOGIC_HERO_INTENSIFY_*）因此恒为关闭。
    /// SetSetting 是逐键合并而非整表替换，回全量是安全的。
    /// </summary>
    private async Task<byte[]> BuildSettingAsync(GameContext ctx, byte[] args)
    {
        List<(string Key, string Value)> incoming = ProtocolDecoder.DecodeGuideSettingArg(args);
        if (incoming.Count == 0)
            return PlayerDataCodec.Encode(new GuideInfo(Setting: []));

        PlayerAccount account = await ctx.GetAccountAsync();
        Dictionary<string, string> settings = account.UserSettings is null
            ? new Dictionary<string, string>(StringComparer.Ordinal)
            : new Dictionary<string, string>(account.UserSettings, StringComparer.Ordinal);
        foreach ((string key, string value) in incoming)
            settings[key] = value;

        account = account with { UserSettings = settings };
        await services.SaveAccountAsync(account, ctx.Ct);
        services.FileLogger.LogInformation("guide.Setting stored {Count} key(s), total={Total}",
            incoming.Count, settings.Count);

        return PlayerDataCodec.Encode(new GuideInfo(
            Setting: [.. settings.Select(entry => new GuideSetting(entry.Key, entry.Value))]));
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
