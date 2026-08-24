using BlueOath.Core;
using BlueOath.Storage;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Protocols;

/// <summary>
/// GM 命令解析器：解析 WebUI 输入框的文本命令，调用 <see cref="GameServices"/>
/// 的实体操作方法，返回执行结果文本。
/// </summary>
internal sealed class GmCommandHandler
{
    private readonly SqliteGameRepository _repo;
    private readonly GameServices _handler;
    private readonly ILogger<GmCommandHandler> _logger;

    private static readonly Dictionary<string, int> CurrencyNames = new()
    {
        ["gold"] = 1, ["diamond"] = 2, ["supply"] = 5, ["maingun"] = 8,
        ["torpedo"] = 9, ["plane"] = 10, ["other"] = 11, ["retire"] = 12,
        ["bath"] = 13, ["strategy"] = 14, ["medal"] = 15, ["tower"] = 18,
        ["copytrain"] = 22, ["fashion"] = 23, ["guild"] = 24, ["lucky"] = 25,
        ["teacher"] = 26, ["teacherpop"] = 27, ["bp_exp"] = 28, ["bp_gold"] = 29,
        ["pvept"] = 30, ["guildcoin2"] = 31, ["urequip"] = 32, ["activity_bp"] = 33,
    };

    public GmCommandHandler(SqliteGameRepository repo, GameServices handler,
        ILogger<GmCommandHandler> logger)
    {
        _repo = repo;
        _handler = handler;
        _logger = logger;
    }

    public async Task<string> ExecuteAsync(string command, CancellationToken ct)
    {
        var parts = command.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0) return string.Empty;

        var cmd = parts[0].ToLowerInvariant();
        try
        {
            var result = cmd switch
            {
                "help" => Help(),
                "list_profiles" => await ListProfilesAsync(ct),
                "get_character" => await GetCharacterAsync(parts, ct),
                "get_dock" => await GetDockAsync(parts, ct),
                "get_bag" => await GetBagAsync(parts, ct),
                "add_currency" => await AddCurrencyAsync(parts, ct),
                "add_ship" => await AddShipAsync(parts, ct),
                "add_item" => await AddItemAsync(parts, ct),
                _ => $"unknown command: {cmd}. Type 'help' for available commands."
            };
            _logger.LogInformation("GM: {Command} -> {Result}", command, result);
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "GM command failed: {Command}", command);
            return $"error: {ex.Message}";
        }
    }

    private static string Help() =>
        string.Join('\n',
            "add_currency <profileId> <type> <amount>  — 加货币 (gold/diamond/supply/...)\n",
            "add_ship <profileId> <templateId> [level]  — 加舰娘到船坞\n",
            "add_item <profileId> <templateId> [count]  — 加道具到仓库\n",
            "list_profiles                                — 列出所有档案\n",
            "get_character <profileId>                    — 查看角色信息\n",
            "get_dock <profileId>                         — 查看船坞\n",
            "get_bag <profileId>                          — 查看仓库\n",
            "help                                         — 显示此帮助\n");

    private async Task<string> ListProfilesAsync(CancellationToken ct)
    {
        var profiles = await _repo.ListProfilesAsync(ct);
        return profiles.Count == 0
            ? "(no profiles)"
            : string.Join('\n', profiles);
    }

    private async Task<string> GetCharacterAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 2) return "usage: get_character <profileId>";
        var account = await _handler.GetOrCreateAccountAsync(parts[1], ct);
        var c = account.Character;
        return $"Uid={c.Uid} Name={c.Name} Level={c.Level} Class={c.Class} SecretaryId={c.SecretaryId}\n" +
               $"Diamond={c.Diamond} Gold={c.Gold} Supply={c.Supply} Medal={c.Medal} PvePt={c.PvePt}";
    }

    private async Task<string> GetDockAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 2) return "usage: get_dock <profileId>";
        var account = await _handler.GetOrCreateAccountAsync(parts[1], ct);
        var dock = account.Dock;
        var lines = dock.Heroes.Select(h =>
            $"HeroId={h.HeroId} TemplateId={h.TemplateId} Lv={h.Level} Fashioning={h.Fashioning} Affection={h.Affection}");
        return $"BagSize={dock.BagSize} Count={dock.Heroes.Count}\n" + string.Join('\n', lines);
    }

    private async Task<string> GetBagAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 2) return "usage: get_bag <profileId>";
        var account = await _handler.GetOrCreateAccountAsync(parts[1], ct);
        var bag = account.Bag;
        if (bag is null || bag.Items.Count == 0) return "(empty bag)";
        var lines = bag.Items.Select(i => $"TemplateId={i.TemplateId} Num={i.Num}");
        return $"BagSize={bag.BagSize} Count={bag.Items.Count}\n" + string.Join('\n', lines);
    }

    private async Task<string> AddCurrencyAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 4) return "usage: add_currency <profileId> <type> <amount>";
        var profileId = parts[1];
        if (!int.TryParse(parts[3], out var amount)) return "invalid amount";
        if (amount <= 0) return "amount must be > 0";

        if (!CurrencyNames.TryGetValue(parts[2].ToLowerInvariant(), out var currencyType))
            return $"unknown currency type: {parts[2]}. Available: {string.Join(' ', CurrencyNames.Keys)}";

        var account = await _handler.GetOrCreateAccountAsync(profileId, ct);
        account = GameServices.AddCurrency(account, currencyType, amount);
        await _repo.SaveAccountAsync(account, ct);
        return $"ok: {parts[2]} +{amount}";
    }

    private async Task<string> AddShipAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 3) return "usage: add_ship <profileId> <templateId> [level]";
        var profileId = parts[1];
        if (!int.TryParse(parts[2], out var templateId) || templateId <= 0) return "invalid templateId";
        var level = parts.Length > 3 && int.TryParse(parts[3], out var l) ? l : 1;

        var account = await _handler.GetOrCreateAccountAsync(profileId, ct);
        var heroId = _handler.NextHeroId();
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        account = GameServices.AddShip(account, heroId, templateId, now);
        // 如果指定了等级，单独设置
        if (level > 1)
        {
            var dock = account.Dock;
            var heroes = dock.Heroes.ToList();
            var idx = heroes.FindIndex(h => h.HeroId == heroId);
            if (idx >= 0)
                heroes[idx] = heroes[idx] with { Level = level };
            account = account with { Dock = dock with { Heroes = heroes } };
        }
        await _repo.SaveAccountAsync(account, ct);
        return $"ok: added ship HeroId={heroId} TemplateId={templateId} Level={level}";
    }

    private async Task<string> AddItemAsync(string[] parts, CancellationToken ct)
    {
        if (parts.Length < 3) return "usage: add_item <profileId> <templateId> [count]";
        var profileId = parts[1];
        if (!int.TryParse(parts[2], out var templateId) || templateId <= 0) return "invalid templateId";
        var count = parts.Length > 3 && int.TryParse(parts[3], out var c) ? c : 1;

        var account = await _handler.GetOrCreateAccountAsync(profileId, ct);
        account = GameServices.AddBagItem(account, templateId, count);
        await _repo.SaveAccountAsync(account, ct);
        return $"ok: item TemplateId={templateId} +{count}";
    }
}
