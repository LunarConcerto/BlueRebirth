using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 固定建造公式目录：从 config_ship_handbook 为每艘船生成唯一公式（金/钢/铝）。
/// 建造时若输入的公式精确命中目录，则必出对应船只；否则回退到原有权重随机逻辑。
/// </summary>
internal static class BuildFormulaCatalog
{
    internal const int MaterialSteel = 10029;
    internal const int MaterialAluminium = 10030;
    private const int MinRes = 30;
    private const int MaxRes = 999;

    /// <summary>templateId（sm_id）→ 公式 (Gold, Steel, Aluminium)。</summary>
    private static readonly Dictionary<int, (int Gold, int Steel, int Aluminium)> TemplateToFormula = new();

    /// <summary>公式 (Gold, Steel, Aluminium) → templateId。</summary>
    private static readonly Dictionary<(int Gold, int Steel, int Aluminium), int> FormulaToTemplate = new();

    /// <summary>sf_id（图鉴/评价系统 Htid）→ templateId。</summary>
    private static readonly Dictionary<int, int> SfIdToTemplate = new();

    /// <summary>ship_info_id（图鉴/评价系统另一入口 Htid）→ templateId。</summary>
    private static readonly Dictionary<int, int> ShipInfoToTemplate = new();

    private static bool _loaded;

    public static void Load(IReadOnlyDictionary<int, ConfigShipInfo> shipInfos)
    {
        if (_loaded) return;
        try
        {
            TemplateToFormula.Clear();
            FormulaToTemplate.Clear();
            SfIdToTemplate.Clear();
            ShipInfoToTemplate.Clear();

            // 按 ship_info_id 升序，保证公式生成确定性。
            // 仅收录图鉴「普通」(show_tag=0)、「联动/コラボ」(show_tag=2)、「穆伯尔/ムーバー」(show_tag=3)
            // 且 show_state == 1（开放/非废案，不含无立绘建模的占位配置）的船只。
            // 排除「改造/Remould」(show_tag=1) 与废案（show_state=0）；同时过滤 config_ship_main 中不存在
            // 对应 sm_id 的条目，避免生成无法落库的配方。
            const long ShowStateOpen = 1;
            var shipInfoIds = ShipHandbookLoader.All
                .Where(kv => kv.Value.ShowTag is 0 or 2 or 3)
                .Where(kv => kv.Value.ShowState == ShowStateOpen)
                .Where(kv => ShipMainLoader.Get(kv.Key * 10 + 1) is not null)
                .Select(kv => kv.Key)
                .OrderBy(id => id).ToList();
            for (int i = 0; i < shipInfoIds.Count; i++)
            {
                int shipInfoId = shipInfoIds[i];
                int templateId = shipInfoId * 10 + 1;
                int gold = MinRes + (i % (MaxRes - MinRes + 1));
                int steel = MinRes + ((i * 173 + 7) % (MaxRes - MinRes + 1));
                int aluminium = MinRes + ((i * 337 + 13) % (MaxRes - MinRes + 1));
                var formula = (gold, steel, aluminium);
                TemplateToFormula[templateId] = formula;
                FormulaToTemplate[formula] = templateId;
                ShipInfoToTemplate[shipInfoId] = templateId;
                if (shipInfos.TryGetValue(shipInfoId, out var info) && info.SfId != 0)
                    SfIdToTemplate[checked((int)info.SfId)] = templateId;
            }

            // 改造图鉴条目不会成为独立建造目标，但客户端从图鉴详情直接打开评价页时，
            // 会把当前 config_ship_handbook.id 作为 Htid 发送。它们的 sf_id 指向基础舰船，
            // 因此需要保留一层查询别名，否则同一艘船从船坞进入能看到公式、从改造图鉴
            // 进入却会得到空响应。
            foreach (var (shipInfoId, _) in ShipHandbookLoader.All)
            {
                if (ShipInfoToTemplate.ContainsKey(shipInfoId) ||
                    !shipInfos.TryGetValue(shipInfoId, out var info) || info.SfId == 0)
                    continue;
                int canonicalShipInfoId = checked((int)info.SfId);
                if (ShipInfoToTemplate.TryGetValue(canonicalShipInfoId, out int templateId))
                    ShipInfoToTemplate[shipInfoId] = templateId;
            }
        }
        catch { }
        _loaded = true;
    }

    /// <summary>尝试精确命中固定公式，返回对应 templateId；未命中返回 0。</summary>
    public static int TryGetTemplate(int gold, int steel, int aluminium)
        => FormulaToTemplate.TryGetValue((gold, steel, aluminium), out int templateId) ? templateId : 0;

    /// <summary>获取指定 templateId 的固定公式；未生成返回 null。</summary>
    public static (int Gold, int Steel, int Aluminium)? GetFormula(int templateId)
        => TemplateToFormula.TryGetValue(templateId, out var f) ? f : null;

    /// <summary>按图鉴/评价系统的 Htid（可能是 sf_id 或 ship_info_id）反查 templateId；未收录返回 0。</summary>
    public static int TryGetTemplateByHtid(int htid)
    {
        if (SfIdToTemplate.TryGetValue(htid, out int t1)) return t1;
        if (ShipInfoToTemplate.TryGetValue(htid, out int t2)) return t2;
        return 0;
    }

    /// <summary>全部已生成公式的 ship_info_id（升序），供 buildnotes 列出。</summary>
    public static IReadOnlyList<int> AllTemplateIds =>
        [.. TemplateToFormula.Keys.OrderBy(id => id)];
}
