using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;
using BlueOath.Storage;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>关卡/战斗服务：copy.StartBase / copy.PassBase 的领域逻辑。</summary>
internal sealed class BattleService(GameServices services)
{
    internal async Task<byte[]> BuildStartBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        try
        {
            PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
            byte[] args = request.Args ?? [];
            (int copyId, List<int>? deployHeroIds, bool isRunningFight, int battleMode, int matchType) =
                GameServices.DecodeStartBaseArg(args);
            services.FileLogger.LogInformation(
                "copy.StartBase argsLen={Len} hex={Hex} copyId={CopyId} deployHeroIds={Deploy} isRunningFight={IsRunning}",
                args.Length, Convert.ToHexString(args), copyId,
                deployHeroIds is null ? "<null>" : string.Join(",", deployHeroIds), isRunningFight);
            List<Hero> heroList = account.Dock.Heroes.ToList();
            // 关卡出战舰队必须回环客户端请求里的 HeroList（剧情关限制），
            // 而不是从玩家编队猜。请求未带时回退到全部船。
            services.CopyRandomFactors.TryGetValue(copyId, out List<RandomFactorEntry>? randomFactors);
            return GameServices.EncodeStartBaseRet(copyId, heroList, account.Character, deployHeroIds, isRunningFight,
                battleMode, matchType, randomFactors);
        }
        catch (Exception ex)
        {
            services.FileLogger.LogError(ex, "BuildStartBaseRetAsync failed");
            return [];
        }
    }

    internal async Task<byte[]> BuildPassBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        byte[] args = request.Args ?? [];
        PassBaseArg passArg = GameServices.DecodePassBaseArgAll(args);
        int copyId = passArg.BaseId;
        int grade = passArg.Grade;
        int battleTime = passArg.BattleTime;
        if (copyId == 0) return GameServices.EncodePassBaseRet(0, 0, 0, 0);

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        int passTime = battleTime > 0 ? battleTime : 60;
        int copyType = ChapterCopyLoader.GetCopyType(copyId);

        if (copyType == 2)
        {
            PlayerSeaCopyProgress seaProgress = account.SeaProgress ?? new PlayerSeaCopyProgress([]);
            List<CopyRecord> seaRecords = seaProgress.Records.ToList();
            int seaIdx = seaRecords.FindIndex(r => r.CopyId == copyId);
            bool isFirstPass = seaIdx < 0;
            int starLevel = grade > 0 ? 7 : 0;

            if (isFirstPass)
                seaRecords.Add(new CopyRecord(copyId, starLevel, grade, now, passTime, 1));
            else
            {
                CopyRecord existing = seaRecords[seaIdx];
                seaRecords[seaIdx] = existing with
                {
                    StarLevel = Math.Max(existing.StarLevel, starLevel),
                    Grade = Math.Max(existing.Grade, grade),
                    PassTime = passTime,
                    PassCount = existing.PassCount + 1
                };
            }

            account = account with { SeaProgress = new PlayerSeaCopyProgress(seaRecords) };
            await services.SaveAccountAsync(account, ct);
            return GameServices.EncodePassBaseRet(copyId, grade, isFirstPass ? 1 : 0, passTime);
        }

        PlayerCopyProgress progress = account.CopyProgress ?? new PlayerCopyProgress([]);
        List<CopyRecord> records = progress.Records.ToList();
        int idx = records.FindIndex(r => r.CopyId == copyId);
        bool isPlotFirstPass = idx < 0;
        int plotStarLevel = grade > 0 ? 7 : 0;

        if (isPlotFirstPass)
        {
            records.Add(new CopyRecord(copyId, plotStarLevel, grade, now, passTime, 1));
        }
        else
        {
            CopyRecord existing = records[idx];
            records[idx] = existing with
            {
                StarLevel = Math.Max(existing.StarLevel, plotStarLevel),
                Grade = Math.Max(existing.Grade, grade),
                PassTime = passTime,
                PassCount = existing.PassCount + 1
            };
        }

        account = account with { CopyProgress = new PlayerCopyProgress(records) };

        PlayerCharacter c = account.Character;
        int bestChapter = GameServices.FindChapterForCopy(copyId, c.PlotChapterId);
        if (bestChapter > c.PlotChapterId)
        {
            c = c with { PlotChapterId = bestChapter };
            account = account with { Character = c };
        }

        await services.SaveAccountAsync(account, ct);
        return GameServices.EncodePassBaseRet(copyId, grade, isPlotFirstPass ? 1 : 0, passTime);
    }
}
