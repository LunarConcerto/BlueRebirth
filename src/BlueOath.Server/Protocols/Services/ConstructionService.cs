using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>传统舰船建造：配方投放、双建造位队列、快速完成与领取。</summary>
internal sealed class ConstructionService(GameServices services)
{
    internal const int MaterialSteel = 10029;
    internal const int MaterialAluminium = 10030;
    internal const int QuickFinishItem = 10031;
    internal const int ActiveSlotCount = 2;
    internal const int QueueCapacity = 10;

    internal sealed record MutationResult(
        byte[] Ret,
        bool Changed,
        string Error,
        IReadOnlyList<uint>? AddedHeroIds = null);

    internal async Task<byte[]> BuildInfoAsync(string profileId, int now, CancellationToken ct)
    {
        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerAccount refreshed = RefreshQueue(account, now);
        if (!ReferenceEquals(refreshed, account))
            await services.SaveAccountAsync(refreshed, ct);
        return EncodeInfo(refreshed.Construction);
    }

    /// <summary>处理 buildnotes.GetNotesList：返回全部舰船的固定建造公式。</summary>
    internal byte[] GetNotesList(int now)
    {
        var notes = new List<NotesInfo>();
        foreach (int templateId in BuildFormulaCatalog.AllTemplateIds)
        {
            if (BuildFormulaCatalog.GetFormula(templateId) is not { } formula) continue;
            var project = new BuildProject(
                [new BuildItem(MaterialSteel, formula.Steel), new BuildItem(MaterialAluminium, formula.Aluminium)],
                formula.Gold);
            // EndTime 用固定历史时间戳，避免客户端 formatTimeToYMDHM(0) 解析异常。
            var builded = new BuildFormula(EndTime: now, Project: project, HeroId: templateId);
            string name = ShipHandbookLoader.GetShipName(templateId);
            notes.Add(new NotesInfo(Name: name, BuildedInfo: builded, Count: 0, Head: 0, Uid: (ulong)templateId));
        }
        return PlayerDataCodec.Encode(new NotesListRet(notes));
    }

    /// <summary>处理 discuss.GetDiscuss：在图鉴评价区返回对应船只的固定建造配方。</summary>
    internal byte[] GetDiscuss(int htid)
    {
        int templateId = BuildFormulaCatalog.TryGetTemplateByHtid(htid);
        if (templateId <= 0 || BuildFormulaCatalog.GetFormula(templateId) is not { } formula)
            return PlayerDataCodec.Encode(new DiscussRet());
        string shipName = ShipHandbookLoader.GetShipName(templateId);
        string msg = FormatFormulaMessage(formula.Gold, formula.Steel, formula.Aluminium);
        Console.WriteLine(msg);
        var comments = new List<DiscussMsgInfo>
        {
            new(Name: shipName, Msg: msg, LikeNum: 0, MsgID: 0, LikeTime: 0, IsLiked: 0, IsDisLiked: 0, Level: 0),
        };
        return PlayerDataCodec.Encode(new DiscussRet(MsgInfo: comments));
    }

    /// <summary>
    /// 评价卡片的正文只有两行且不会自动扩宽；资源名使用单字缩写，确保三个三位数都能显示。
    /// </summary>
    internal static string FormatFormulaMessage(int gold, int steel, int aluminium) =>
        $"固定建造配方\n金{gold} 钢{steel} 铝{aluminium}";

    internal async Task<MutationResult> StartAsync(
        TRequest request, string profileId, int now, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], false, "construction request is missing");
        ConstructionProjectsArg arg = ProtocolDecoder.DecodeConstructionProjectsArg(request.Args);
        if (arg.Projects.Count is < 1 or > QueueCapacity)
            return new([], false, "construction project count is invalid");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = RefreshQueue(
            await services.GetOrCreateAccountAsync(profileId, ct), now);
        PlayerConstruction construction = account.Construction ?? new PlayerConstruction([]);
        if (construction.Jobs.Count + arg.Projects.Count > QueueCapacity)
            return new([], false, "construction queue is full");

        List<ConstructionProject> projects = [];
        foreach (ConstructionProjectArg projectArg in arg.Projects)
        {
            if (!TryNormalizeProject(projectArg, out ConstructionProject? project, out string error))
                return new([], false, error);
            projects.Add(project!);
        }

        long totalGold = projects.Sum(project => (long)project.Gold);
        long totalSteel = projects.Sum(project => (long)GetItemCount(project, MaterialSteel));
        long totalAluminium = projects.Sum(project => (long)GetItemCount(project, MaterialAluminium));
        if (account.Character.Gold < totalGold ||
            GetBagCount(account, MaterialSteel) < totalSteel ||
            GetBagCount(account, MaterialAluminium) < totalAluminium)
            return new([], false, "not enough construction resources");

        List<ConstructionJob> jobs = construction.Jobs.ToList();
        long nextSequence = Math.Max(1, construction.NextSequence);
        int activeCount = jobs.Count(job => !job.Completed && job.EndTime > 0);
        foreach (ConstructionProject project in projects)
        {
            int templateId = SelectTemplate(project);
            if (templateId <= 0)
                return new([], false, "no ship matches this construction formula");
            int duration = GetDurationSeconds(templateId);
            long endTime = activeCount < ActiveSlotCount ? checked((long)now + duration) : 0;
            if (endTime > 0) activeCount++;
            jobs.Add(new ConstructionJob(
                nextSequence++, templateId, duration, endTime, false, project));
        }

        account = GameServices.AddCurrency(account, 1, checked(-(int)totalGold));
        account = GameServices.AddBagItem(account, MaterialSteel, checked(-(int)totalSteel));
        account = GameServices.AddBagItem(account, MaterialAluminium, checked(-(int)totalAluminium));
        account = account with
        {
            Construction = new PlayerConstruction(jobs, projects[^1], nextSequence),
        };
        await services.SaveAccountAsync(account, ct);
        return new([], true, "");
    }

    internal async Task<MutationResult> QuicklyFinishAsync(
        TRequest request, string profileId, int now, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], false, "quick-finish request is missing");
        ConstructionIndexArg arg = ProtocolDecoder.DecodeConstructionIndexArg(request.Args);
        List<int> indexes = arg.Indexes.Distinct().ToList();
        if (indexes.Count == 0)
            return new([], false, "quick-finish index is missing");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = RefreshQueue(
            await services.GetOrCreateAccountAsync(profileId, ct), now);
        PlayerConstruction construction = account.Construction ?? new PlayerConstruction([]);
        List<ConstructionJob> building = construction.Jobs
            .Where(job => !job.Completed && job.EndTime > now)
            .OrderBy(job => job.Sequence).ToList();
        if (indexes.Any(index => index < 1 || index > building.Count))
            return new([], false, "quick-finish index is invalid");
        if (GetBagCount(account, QuickFinishItem) < indexes.Count)
            return new([], false, "not enough quick-finish items");

        HashSet<long> selected = indexes.Select(index => building[index - 1].Sequence).ToHashSet();
        List<ConstructionJob> jobs = construction.Jobs
            .Select(job => selected.Contains(job.Sequence)
                ? job with { Completed = true, EndTime = now }
                : job)
            .ToList();
        account = account with { Construction = construction with { Jobs = jobs } };
        account = RefreshQueue(account, now);
        account = GameServices.AddBagItem(account, QuickFinishItem, -indexes.Count);
        await services.SaveAccountAsync(account, ct);
        return new([], true, "");
    }

    internal async Task<MutationResult> ReceiveAsync(
        TRequest request, string profileId, int now, CancellationToken ct)
    {
        if (request.Args is null)
            return new([], false, "construction receive request is missing");
        ConstructionIndexArg arg = ProtocolDecoder.DecodeConstructionIndexArg(request.Args);
        List<int> indexes = arg.Indexes.Distinct().OrderBy(index => index).ToList();
        if (indexes.Count == 0)
            return new([], false, "construction receive index is missing");

        using var _ = await services.LockAccountAsync(profileId, ct);
        PlayerAccount account = RefreshQueue(
            await services.GetOrCreateAccountAsync(profileId, ct), now);
        PlayerConstruction construction = account.Construction ?? new PlayerConstruction([]);
        List<ConstructionJob> completed = construction.Jobs
            .Where(job => job.Completed).OrderBy(job => job.Sequence).ToList();
        if (indexes.Any(index => index < 1 || index > completed.Count))
            return new([], false, "construction receive index is invalid");
        if (account.Dock.Heroes.Count + indexes.Count > account.Dock.BagSize)
            return new([], false, "hero dock is full");

        List<ConstructionJob> selected = indexes.Select(index => completed[index - 1]).ToList();
        HashSet<long> selectedSequences = selected.Select(job => job.Sequence).ToHashSet();
        List<CommonReward> rewards = [];
        List<uint> heroIds = [];
        foreach (ConstructionJob job in selected)
        {
            uint heroId = services.NextHeroId();
            account = services.AddShip(account, heroId, job.TemplateId, now);
            heroIds.Add(heroId);
            rewards.Add(new CommonReward(GameServices.GoodsTypeShip, job.TemplateId, 1, checked((int)heroId)));
        }

        construction = construction with
        {
            Jobs = construction.Jobs.Where(job => !selectedSequences.Contains(job.Sequence)).ToList(),
        };
        account = account with { Construction = construction };
        await services.SaveAccountAsync(account, ct);
        return new(ProtocolEncoder.EncodeBuildReceiveRet(rewards), true, "", heroIds);
    }

    /// <summary>按完成时间推进任务，并将等待任务补入两个并行建造位。</summary>
    internal static PlayerAccount RefreshQueue(PlayerAccount account, long now)
    {
        PlayerConstruction construction = account.Construction ?? new PlayerConstruction([]);
        List<ConstructionJob> jobs = construction.Jobs.ToList();
        bool changed = false;

        while (true)
        {
            ConstructionJob? due = jobs
                .Where(job => !job.Completed && job.EndTime > 0 && job.EndTime <= now)
                .OrderBy(job => job.EndTime).ThenBy(job => job.Sequence).FirstOrDefault();
            if (due is null) break;
            long transitionTime = due.EndTime;
            for (int i = 0; i < jobs.Count; i++)
                if (!jobs[i].Completed && jobs[i].EndTime == transitionTime)
                {
                    jobs[i] = jobs[i] with { Completed = true };
                    changed = true;
                }
            changed |= PromoteWaiting(jobs, transitionTime);
        }

        changed |= PromoteWaiting(jobs, now);
        if (!changed && account.Construction is not null) return account;
        return account with { Construction = construction with { Jobs = jobs } };
    }

    internal static byte[] EncodeInfo(PlayerConstruction? construction)
    {
        PlayerConstruction value = construction ?? new PlayerConstruction([]);
        List<BuildFormula> completed = value.Jobs.Where(job => job.Completed)
            .OrderBy(job => job.Sequence).Select(ToFormula).ToList();
        List<BuildFormula> building = value.Jobs.Where(job => !job.Completed && job.EndTime > 0)
            .OrderBy(job => job.Sequence).Select(ToFormula).ToList();
        List<BuildFormula> waiting = value.Jobs.Where(job => !job.Completed && job.EndTime == 0)
            .OrderBy(job => job.Sequence).Select(ToFormula).ToList();
        BuildFormula? last = value.LastProject is null
            ? null
            : new BuildFormula(0, ToProtocolProject(value.LastProject));
        return PlayerDataCodec.Encode(new BuildsInfoRet(completed, building, waiting, last));
    }

    private static bool PromoteWaiting(List<ConstructionJob> jobs, long startTime)
    {
        int active = jobs.Count(job => !job.Completed && job.EndTime > 0);
        bool changed = false;
        foreach (ConstructionJob waiting in jobs
                     .Where(job => !job.Completed && job.EndTime == 0)
                     .OrderBy(job => job.Sequence).Take(Math.Max(0, ActiveSlotCount - active)).ToList())
        {
            int index = jobs.FindIndex(job => job.Sequence == waiting.Sequence);
            jobs[index] = waiting with { EndTime = checked(startTime + waiting.DurationSeconds) };
            changed = true;
        }
        return changed;
    }

    private static BuildFormula ToFormula(ConstructionJob job) =>
        new(job.EndTime, ToProtocolProject(job.Project), job.Completed ? job.TemplateId : 0);

    private static BuildProject ToProtocolProject(ConstructionProject project) =>
        new(project.Items.Select(item => new BuildItem(item.ResId, item.Count)).ToList(), project.Gold);

    private static bool TryNormalizeProject(
        ConstructionProjectArg arg, out ConstructionProject? project, out string error)
    {
        project = null;
        error = "";
        if (arg.Gold is < 30 or > 999)
        {
            error = "construction gold must be between 30 and 999";
            return false;
        }
        Dictionary<int, int> items = [];
        foreach (ConstructionItemArg item in arg.Items)
        {
            if (item.ResId is not (MaterialSteel or MaterialAluminium) || item.Count is < 30 or > 999 ||
                items.ContainsKey(item.ResId))
            {
                error = "construction material project is invalid";
                return false;
            }
            items[item.ResId] = item.Count;
        }
        if (!items.ContainsKey(MaterialSteel) || !items.ContainsKey(MaterialAluminium))
        {
            error = "both construction materials are required";
            return false;
        }
        project = new ConstructionProject(
            items.OrderBy(pair => pair.Key)
                .Select(pair => new ConstructionItem(pair.Key, pair.Value)).ToList(), arg.Gold);
        return true;
    }

    private int SelectTemplate(ConstructionProject project)
    {
        int steel = GetItemCount(project, MaterialSteel);
        int aluminium = GetItemCount(project, MaterialAluminium);

        // 优先精确命中固定公式：命中则必出对应船只。
        int fixedTemplate = BuildFormulaCatalog.TryGetTemplate(project.Gold, steel, aluminium);
        if (fixedTemplate > 0)
            return fixedTemplate;

        ConfigBuildFormula? formula = ConstructionConfigLoader.Formulas.Values.FirstOrDefault(value =>
            InRange(project.Gold, value.Res1) && InRange(steel, value.Res2) && InRange(aluminium, value.Res3));
        IReadOnlyList<long> qualityWeights;
        ConfigBuildQuality? qualityConfig = null;
        if (formula?.TagWeight is { Count: >= 4 } formulaWeights)
        {
            qualityWeights = formulaWeights;
        }
        else
        {
            int score = Math.Clamp(project.Gold + steel + aluminium - 89, 1,
                ConstructionConfigLoader.Qualities.Keys.DefaultIfEmpty(1).Max());
            qualityConfig = ConstructionConfigLoader.Qualities.GetValueOrDefault(score);
            qualityWeights = qualityConfig?.TagWeight ?? [0, 10_000, 0, 0];
        }
        int quality = WeightedIndex(qualityWeights) + 1;

        List<(ConfigBuildShip Config, long Weight)> candidates = ConstructionConfigLoader.Ships.Values
            .Where(config => config.BuildQualityId == quality &&
                InRange(project.Gold, config.Res1) && InRange(steel, config.Res2) &&
                InRange(aluminium, config.Res3) && config.ShipList is { Count: > 0 })
            .Select(config => (config, PackageWeight(config, formula, steel, aluminium)))
            .Where(entry => entry.Item2 > 0).ToList();
        ConfigBuildShip? package = candidates.Count > 0
            ? WeightedPick(candidates)
            : ConstructionConfigLoader.Ships.GetValueOrDefault(
                checked((int)(qualityConfig?.FailBuildShipId ?? 1)));
        if (package?.ShipList is not { Count: > 0 } ships) return 0;
        int shipIndex = WeightedIndex(package.ShipRatio ?? Enumerable.Repeat(1L, ships.Count).ToList());
        return shipIndex < ships.Count ? checked((int)ships[shipIndex]) : checked((int)ships[0]);
    }

    private ConfigBuildShip WeightedPick(List<(ConfigBuildShip Config, long Weight)> entries)
    {
        long total = entries.Sum(entry => entry.Weight);
        long roll = services.Rng.NextInt64(total);
        long cumulative = 0;
        foreach (var entry in entries)
        {
            cumulative += entry.Weight;
            if (roll < cumulative) return entry.Config;
        }
        return entries[^1].Config;
    }

    private int WeightedIndex(IReadOnlyList<long> weights)
    {
        long total = weights.Where(weight => weight > 0).Sum();
        if (total <= 0) return 0;
        long roll = services.Rng.NextInt64(total);
        long cumulative = 0;
        for (int i = 0; i < weights.Count; i++)
        {
            cumulative += Math.Max(0, weights[i]);
            if (roll < cumulative) return i;
        }
        return weights.Count - 1;
    }

    private static long PackageWeight(
        ConfigBuildShip config, ConfigBuildFormula? formula, int steel, int aluminium)
    {
        double weight = config.PackageWeight;
        weight += ((double)config.Res2PackageWeightArg * steel +
                   (double)config.Res3PackageWeightArg * aluminium) / 10_000d;
        if (formula?.CustomTagRevise is { Count: > 0 } revisions)
            foreach (long tag in config.CustomTag ?? [])
                if (tag > 0 && tag <= revisions.Count)
                    weight += revisions[checked((int)tag - 1)] / 100d;
        return Math.Max(0, checked((long)Math.Round(weight * 100d)));
    }

    private int GetDurationSeconds(int templateId)
    {
        int shipInfoId = GameServices.ToIllustrateId(templateId);
        long configured = services.ShipInfos.GetValueOrDefault(shipInfoId)?.BuildTime ?? 0;
        return checked((int)Math.Clamp(configured, 60, 7 * 24 * 60 * 60));
    }

    private static bool InRange(int value, IReadOnlyList<long>? range) =>
        range is { Count: >= 2 } && value >= range[0] && value <= range[1];

    private static int GetItemCount(ConstructionProject project, int templateId) =>
        project.Items.FirstOrDefault(item => item.ResId == templateId)?.Count ?? 0;

    private static int GetBagCount(PlayerAccount account, int templateId) =>
        account.Bag?.Items.FirstOrDefault(item => item.TemplateId == templateId)?.Num ?? 0;
}
