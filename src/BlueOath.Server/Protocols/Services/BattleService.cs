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
internal sealed class BattleService(GameServices services, DailyCopyService dailyCopy)
{
    internal async Task<byte[]> BuildStartBaseRetAsync(TRequest request, string profileId, CancellationToken ct)
    {
        try
        {
            PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
            byte[] args = request.Args ?? [];
            StartBaseArg arg = ProtocolDecoder.DecodeStartBaseArg(args);
            services.FileLogger.LogInformation(
                "copy.StartBase argsLen={Len} hex={Hex} copyId={CopyId} deployHeroIds={Deploy} isRunningFight={IsRunning}",
                args.Length, Convert.ToHexString(args), arg.CopyId,
                arg.DeployHeroIds is null ? "<null>" : string.Join(",", arg.DeployHeroIds), arg.IsRunningFight);
            List<Hero> heroList = account.Dock.Heroes.ToList();
            // 关卡出战舰队必须回环客户端请求里的 HeroList（剧情关限制），
            // 而不是从玩家编队猜。请求未带时回退到全部船。
            services.CopyRandomFactors.TryGetValue(arg.CopyId, out List<RandomFactorEntry>? randomFactors);
            return ProtocolEncoder.EncodeStartBaseRet(arg.CopyId, heroList, account.Character, arg.DeployHeroIds, arg.IsRunningFight,
                arg.BattleMode, arg.MatchType, randomFactors, account.Equip);
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
        PassBaseArg passArg = ProtocolDecoder.DecodePassBaseArgAll(args);
        int copyId = passArg.BaseId;
        int grade = passArg.Grade;
        int battleTime = passArg.BattleTime;
        if (copyId == 0) return ProtocolEncoder.EncodePassBaseRet(0, 0, 0, 0);

        using IDisposable accountLock = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        int now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        int passTime = battleTime > 0 ? battleTime : 60;
        int copyType = ChapterCopyLoader.GetCopyType(copyId);

        // 保存战斗结束后的角色生命值（客户端回传 HerosInfo.Hp，与 StartBase 的 HpCoefficient 同尺度）。
        // 无论胜负都要落盘——战败也会掉血。
        account = SaveHeroHp(account, passArg.HerosInfo);

        // 评级（config_copy_grade_type）：SSS=1..E=8，F=9 为失败。失败不结算战利品、不记录通关进度。
        bool isVictory = grade < 9;
        if (!isVictory)
        {
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(copyId, grade, 0, passTime);
        }

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
            (account, List<CommonReward> seaRewards) = GrantCopyRewards(account, copyId, isFirstPass, now);
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(copyId, grade, isFirstPass ? 1 : 0, passTime, seaRewards);
        }

        if (copyType == 9)
        {
            DailyCopyPassMutation mutation = dailyCopy.RecordPass(account, copyId, grade, now);
            account = mutation.Account;
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(
                copyId, grade, mutation.FirstPass ? 1 : 0, passTime, mutation.Rewards);
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

        (account, List<CommonReward> plotRewards) = GrantCopyRewards(account, copyId, isPlotFirstPass, now);
        await services.SaveAccountAsync(account, ct);
        return ProtocolEncoder.EncodePassBaseRet(copyId, grade, isPlotFirstPass ? 1 : 0, passTime, plotRewards);
    }

    /// <summary>把客户端回传的战斗后生命值写回对应舰娘（HerosInfo.HeroId → Hero.CurHp）。</summary>
    private static PlayerAccount SaveHeroHp(PlayerAccount account, IReadOnlyList<BaseHeroInfo>? herosInfo)
    {
        if (herosInfo is null || herosInfo.Count == 0) return account;
        List<Hero> heroes = account.Dock.Heroes.ToList();
        bool changed = false;
        foreach (BaseHeroInfo info in herosInfo)
        {
            if (info.HeroId == 0) continue;
            int idx = heroes.FindIndex(h => h.HeroId == info.HeroId);
            if (idx < 0) continue;
            heroes[idx] = heroes[idx] with { CurHp = checked((long)info.Hp) };
            changed = true;
        }
        return changed ? account with { Dock = account.Dock with { Heroes = heroes } } : account;
    }

    /// <summary>
    /// 从 config_copy_display 读取掉落表（drop_info_id → config_drop_item 池）与首通奖励
    /// （first_reward → config_rewards），抽取并发放战利品，返回更新后的账号与奖励列表。
    /// </summary>
    private (PlayerAccount Account, List<CommonReward> Rewards) GrantCopyRewards(
        PlayerAccount account, int copyId, bool isFirstPass, int now)
    {
        CopyDisplayLoader.CopyDropInfo? dropInfo = CopyDisplayLoader.Get(copyId);
        if (dropInfo is null) return (account, []);

        var pending = new List<(int Type, int ConfigId, int Num)>();
        var path = new HashSet<int>();

        if (isFirstPass)
            foreach (int rewardId in dropInfo.FirstReward)
                AppendReward(rewardId, pending);

        foreach (int dropId in dropInfo.DropInfoId)
            DrawDropPool(dropId, pending, path, 0);

        var rewards = new List<CommonReward>();
        foreach ((int type, int configId, int num) in pending)
        {
            if (type == GameServices.GoodsTypeCurrency)
            {
                account = GameServices.AddCurrency(account, configId, num);
                rewards.Add(new CommonReward(type, configId, num));
            }
            else if (type == GameServices.GoodsTypeEquip)
            {
                for (int i = 0; i < num; i++)
                {
                    (account, uint equipId) = AddEquip(account, configId);
                    rewards.Add(new CommonReward(type, configId, 1, checked((int)equipId)));
                }
            }
            else if (type == GameServices.GoodsTypeShip)
            {
                uint heroId = services.NextHeroId();
                account = services.AddShip(account, heroId, configId, now);
                rewards.Add(new CommonReward(type, configId, 1, checked((int)heroId)));
            }
            else
            {
                account = GameServices.AddBagItem(account, configId, num);
                rewards.Add(new CommonReward(type, configId, num));
            }
        }
        return (account, rewards);
    }

    private static void AppendReward(int rewardId, List<(int Type, int ConfigId, int Num)> pending)
    {
        if (rewardId <= 0 ||
            DailyCopyRewardCatalog.GetReward(rewardId) is not { Rewards: { } rewards })
            return;
        foreach (List<long> entry in rewards)
            if (entry.Count >= 3 && entry[2] > 0)
                pending.Add((checked((int)entry[0]), checked((int)entry[1]), checked((int)entry[2])));
    }

    private bool DrawDropPool(
        int dropId, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (depth >= 16 || !path.Add(dropId) || !services.DropItems.TryGetValue(dropId, out var pool))
            return false;
        try
        {
            if (pool.DropRate > 0 && pool.Drop is { Count: > 0 })
                for (int i = 0; i < Math.Max(1, checked((int)pool.DropCount)); i++)
                    if (WeightedPick(pool.Drop) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
            if (pool.DropAloneCount > 0 && pool.DropAlone is { Count: > 0 })
                for (int i = 0; i < pool.DropAloneCount; i++)
                    if (WeightedPick(pool.DropAlone) is { } entry)
                        ResolveDropEntry(entry, result, path, depth + 1);
            return true;
        }
        finally
        {
            path.Remove(dropId);
        }
    }

    private void ResolveDropEntry(
        List<long> entry, List<(int Type, int ConfigId, int Num)> result, HashSet<int> path, int depth)
    {
        if (entry.Count < 5) return;
        int type = checked((int)entry[0]);
        int configId = checked((int)entry[1]);
        int min = checked((int)entry[2]);
        int max = checked((int)entry[3]);
        if (min <= 0 || max < min) return;
        int num = min == max ? min : services.Rng.Next(min, checked(max + 1));
        if (type == GameServices.GoodsTypeDrop)
        {
            for (int i = 0; i < num; i++) DrawDropPool(configId, result, path, depth);
            return;
        }
        result.Add((type, configId, num));
    }

    private List<long>? WeightedPick(List<List<long>> entries)
    {
        int totalWeight = entries.Sum(e => e.Count > 4 ? checked((int)e[4]) : 0);
        if (totalWeight <= 0) return entries.Count > 0 ? entries[0] : null;
        int roll = services.Rng.Next(totalWeight);
        int cumulative = 0;
        foreach (List<long> e in entries)
        {
            int w = e.Count > 4 ? checked((int)e[4]) : 0;
            cumulative += w;
            if (roll < cumulative) return e;
        }
        return entries[^1];
    }

    private (PlayerAccount Account, uint EquipId) AddEquip(PlayerAccount account, int templateId)
    {
        var equip = account.Equip ?? new PlayerEquip([], EquipBagSize: 2000);
        var items = equip.Items.ToList();
        uint equipId = services.NextEquipId();
        items.Add(new EquipItem(EquipId: equipId, TemplateId: templateId));
        account = account with { Equip = equip with { Items = items } };
        return (account, equipId);
    }
}
