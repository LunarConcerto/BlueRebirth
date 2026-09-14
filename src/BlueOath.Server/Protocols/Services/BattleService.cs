using System.Text;
using System.Text.Json;
using System.Linq;
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
        // 货物副本（物资大作战，copyType 10）是伤害测试器：敌人血量极高、必定超时，
        // 超时即无条件胜利，按最终伤害发放报酬。因此 copyType 10 强制视为胜利。
        bool isGoodsCopy = copyType == 10;
        bool isVictory = grade < 9 || isGoodsCopy;
        if (!isVictory)
        {
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(copyId, grade, 0, passTime);
        }

        // 关卡可能包含多支敌舰队：客户端每击破一支就会发一次 copy.PassBase。
        // 只有击破最后一支（config_fleet.is_last_fleet == 1）才算通关，届时才结算
        // 奖励与通关进度；否则仅落盘血量并返回空结果，避免第一支敌舰队就发奖励。
        // 货物副本（10）是单场伤害测试，按原逻辑即时结算，不做多舰队延迟。
        int enemyFleetId = passArg.FleetInfo is { Count: > 0 } fleetInfo ? fleetInfo[0].EnemyId : 0;
        bool isLastFleet = FleetDropLoader.IsLastFleet(enemyFleetId);
        services.FileLogger.LogInformation(
            "copy.PassBase copyId={CopyId} type={CopyType} enemyFleet={EnemyFleetId} isLastFleet={IsLastFleet} grade={Grade}",
            copyId, copyType, enemyFleetId, isLastFleet, grade);
        if (!isGoodsCopy && !isLastFleet)
        {
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(copyId, grade, 0, passTime);
        }

        if (copyType == 10)
        {
            // 物资大作战：超时无条件胜利，奖励来自 config_copy_display.drop_info_id 掉落池。
            // 客户端回传 grade=9（F，超时），但伤害测试器应视为胜利；回传一个成功评级
            // （grade 6=D 及以上即胜），避免客户端 SettlementPage 按 grade==9 判失败。
            int winGrade = grade >= 9 || grade <= 0 ? 6 : grade;
            (account, List<CommonReward> goodsRewards) = GrantCopyRewards(account, copyId, true, now);
            await services.SaveAccountAsync(account, ct);
            // 从 PassBaseArg.Evaluate 提取伤害：货物副本按 config_parameter[172]
            // wuzidazuozhan_min_damage=500 作为缩放基数，CurReward = floor(总伤害 / 500)。
            // Evaluate 是 TPassEvaluate{Type,Value} 列表，取所有 Value 之和作为总伤害。
            long totalDamage = passArg.Evaluate?.Sum(e => (long)e.Value) ?? 0;
            long minDamage = services.Parameter(172, 500);
            int rewardCount = totalDamage > 0 ? (int)Math.Max(1, totalDamage / Math.Max(1, minDamage)) : goodsRewards.Sum(r => r.Num);
            // ExReward 供 GoodsCopyResultPage 显示。RankPercent 必须非 nil（页面按 ==-1 判无排名，
            // nil 会触发 RankPercent/100 算术崩溃）。
            List<CommonExtraReward> exReward =
            [
                new CommonExtraReward("RankPercent", -1),
                new CommonExtraReward("CopyId", copyId),
                new CommonExtraReward("CurDamage", checked((int)totalDamage)),
                new CommonExtraReward("CurCopyMaxDamage", checked((int)totalDamage)),
                new CommonExtraReward("MaxDamage", checked((int)totalDamage)),
                new CommonExtraReward("CurReward", rewardCount),
                new CommonExtraReward("TotalReward", rewardCount),
                new CommonExtraReward("MonthCardBonus", 0),
            ];
            return ProtocolEncoder.EncodePassBaseRet(copyId, winGrade, 1, passTime, goodsRewards, exReward);
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
            (account, List<CommonReward> seaRewards) = GrantSeaCopyRewards(account, copyId, isFirstPass, now, enemyFleetId);
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

        // ムーボー防卫圈（Tower）：关卡不在 config_chapter.level_list，单独记录到
        // PlayerTowerProgress.SavePassCopyId；客户端据此判断已通关并解锁下一关。
        if (TowerCatalogLoader.IsTowerCopy(copyId))
        {
            PlayerTowerProgress tower = account.Tower ?? new PlayerTowerProgress([]);
            List<int> passList = tower.SavePassCopyId?.ToList() ?? [];
            bool towerFirstPass = !passList.Contains(copyId);
            if (towerFirstPass) passList.Add(copyId);
            account = account with { Tower = new PlayerTowerProgress(passList) };
            (account, List<CommonReward> towerRewards) = GrantCopyRewards(account, copyId, towerFirstPass, now);
            await services.SaveAccountAsync(account, ct);
            return ProtocolEncoder.EncodePassBaseRet(copyId, grade, towerFirstPass ? 1 : 0, passTime, towerRewards);
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
    /// 从 config_copy_display 读取首通奖励（first_reward → config_rewards）与掉落池
    /// （drop_info_id → config_drop_item），抽取并发放战利品，返回更新后的账号与奖励列表。
    /// 用于非海域副本（剧情/货物/防卫圈等）的既定行为。
    /// </summary>
    private (PlayerAccount Account, List<CommonReward> Rewards) GrantCopyRewards(
        PlayerAccount account, int copyId, bool isFirstPass, int now)
    {
        CopyDisplayLoader.CopyDropInfo? dropInfo = CopyDisplayLoader.Get(copyId);
        if (dropInfo is null) return (account, []);

        var pending = new List<DropEntry>();

        if (isFirstPass)
            foreach (int rewardId in dropInfo.FirstReward)
                AppendReward(rewardId, pending);

        foreach (int dropId in dropInfo.DropInfoId)
            pending.AddRange(DropPoolResolver.Resolve(dropId, services.DropItems, services.Rng));

        return ApplyPendingRewards(account, pending, now);
    }

    /// <summary>
    /// 海域（含周回海域，class_type=2）通关结算：
    /// <list type="bullet">
    /// <item>首通：<c>first_reward</c>（config_rewards）；</item>
    /// <item>每次通关：<c>period_drop</c>（config_drop_item，周回海域的周期掉落）；</item>
    /// <item>本次出击击破的整组敌舰队各自的 <c>drop_id</c>/<c>settle_drop_ids</c>/<c>other_drop_ids</c>。</item>
    /// </list>
    /// <c>drop_info_id</c> 只是客户端预览数据（config_drop_info），不参与发放。
    /// </summary>
    private (PlayerAccount Account, List<CommonReward> Rewards) GrantSeaCopyRewards(
        PlayerAccount account, int copyId, bool isFirstPass, int now, int enemyFleetId)
    {
        var pending = new List<DropEntry>();

        CopyDisplayLoader.CopyDropInfo? dropInfo = CopyDisplayLoader.Get(copyId);
        if (isFirstPass && dropInfo is not null)
            foreach (int rewardId in dropInfo.FirstReward)
                AppendReward(rewardId, pending);

        if (dropInfo is { PeriodDrop: > 0 })
            pending.AddRange(DropPoolResolver.Resolve(dropInfo.PeriodDrop, services.DropItems, services.Rng));

        foreach (int fleetId in FleetDropLoader.GetBattleFleets(copyId, enemyFleetId))
        {
            FleetDropLoader.FleetDropInfo? fleet = FleetDropLoader.Get(fleetId);
            if (fleet is null) continue;
            foreach (int dropId in fleet.DropIds)
                pending.AddRange(DropPoolResolver.Resolve(dropId, services.DropItems, services.Rng));
            foreach (int dropId in fleet.SettleDropIds)
                pending.AddRange(DropPoolResolver.Resolve(dropId, services.DropItems, services.Rng));
            foreach (int dropId in fleet.OtherDropIds)
                pending.AddRange(DropPoolResolver.Resolve(dropId, services.DropItems, services.Rng));
        }

        return ApplyPendingRewards(account, pending, now);
    }

    /// <summary>把已抽出的掉落条目发放到账号，返回更新后的账号与已发放奖励。</summary>
    private (PlayerAccount Account, List<CommonReward> Rewards) ApplyPendingRewards(
        PlayerAccount account, List<DropEntry> pending, int now)
    {
        var rewards = new List<CommonReward>();
        foreach (DropEntry entry in pending)
        {
            int type = entry.Type;
            int configId = entry.ConfigId;
            int num = entry.Num;
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

    private static void AppendReward(int rewardId, List<DropEntry> pending)
    {
        if (rewardId <= 0 ||
            DailyCopyRewardCatalog.GetReward(rewardId) is not { Rewards: { } rewards })
            return;
        foreach (List<long> entry in rewards)
            if (entry.Count >= 3 && entry[2] > 0)
                pending.Add(new DropEntry(checked((int)entry[0]), checked((int)entry[1]), checked((int)entry[2])));
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
