using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>ムーボー防卫圈（tower.*）。客户端 TowerService 发送 tower.GetTowerInfo 后，
/// 依赖 tower.TowerInfo 推送写入 Data.towerData；缺失时 TowerRoadPage/TowerRewardPage
/// 拿不到 ChapterId，config_chapter[nil] 崩溃。这里返回空应答并补发 tower.TowerInfo 推送。</summary>
internal sealed class TowerModule : IGameModule
{
    /// <summary>近乎不限时开放：ResetTime 设为 now + 10 年，GetLeftTime = ResetTime + reset_period - now ≈ 10 年。</summary>
    private const long TenYearsSeconds = 10L * 365 * 24 * 3600;

    /// <summary>无限出击次数：剩余 = daily_battle_time - (DailyCount - DailyCountEx)。DailyCount=0、DailyCountEx 取大值。</summary>
    private const ulong UnlimitedDailyCountEx = 9999;

    public IReadOnlyList<string> Prefixes => ["tower"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "tower.GetTowerInfo":
                result = new ModuleResult
                {
                    Ret = [],
                    PostPushes = [BuildTowerInfoPush(await ctx.GetAccountAsync(), (uint)ctx.Now)],
                };
                break;
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    internal static byte[] BuildTowerInfoPush(PlayerAccount account, uint now) =>
        TMessageCodec.EncodeResponse(new TResponse(
            Method: "tower.TowerInfo",
            Ret: EncodeTowerInfo(account, now),
            Time: now));

    /// <summary>编码 TTOWERINFORET。ChapterId=40001（config_parameter[203] tower_first_chapter，
    /// ムーボー防卫圈首章）。DailyCount/DailyCountEx/ResetTime 配置为无限次数与近无限开放时间。
    /// SavePassCopyId 记录已通关关卡，客户端据此解锁下一关。</summary>
    internal static byte[] EncodeTowerInfo(PlayerAccount account, uint now)
    {
        ProtocolPackage ms = new();
        ms.Write(0x08, 40001UL);   // ChapterId(1)=40001
        ms.Write(0x10, 0UL);       // AreaIndex(2)=0
        ms.Write(0x18, 0UL);       // CopyIndex(3)=0
        ms.Write(0x20, 1UL);       // TopicIndex(4)=1
        ms.Write(0x28, 0UL);       // DailyCount(5)=0（今日已用次数）
        ms.Write(0x30, (ulong)(now + TenYearsSeconds)); // ResetTime(6)=now+10年
        ms.Write(0x58, 0UL);       // PassLastChapterId(11)=0
        ms.Write(0x60, 0UL);       // IsReset(12)=false
        ms.Write(0x68, 1UL);       // MaxLevel(13)=1
        ms.Write(0x70, 0UL);       // MaxArea(14)=0
        ms.Write(0x78, 0UL);       // MaxCopy(15)=0
        ms.Write(0x80, UnlimitedDailyCountEx); // DailyCountEx(16)=9999（额外次数→无限）
        ms.Write(0x88, 0UL);       // IsNewLevel(17)=false
        // SavePassCopyId(18, repeated int32)：已通关关卡 id，key=(18<<3)|0=0x90。
        if (account.Tower?.SavePassCopyId is { Count: > 0 } passes)
            foreach (int copyId in passes)
                ms.Write(0x90, unchecked((ulong)copyId));
        return ms.ToArray();
    }
}
