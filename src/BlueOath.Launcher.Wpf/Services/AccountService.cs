using System.Collections.ObjectModel;
using System.IO;
using System.Text.Json;
using BlueOath.Launcher.Wpf.Models;

namespace BlueOath.Launcher.Wpf.Services;

public sealed class AccountService
{
    public const string DefaultProfileId = "local-player";
    public const int MaxNameLength = 32;

    private readonly string _filePath;
    private AccountProfile _activeAccount = null!;

    public ObservableCollection<AccountProfile> Accounts { get; } = new();
    public AccountProfile ActiveAccount
    {
        get => _activeAccount;
        private set
        {
            if (ReferenceEquals(_activeAccount, value)) return;
            _activeAccount = value;
            ActiveAccountChanged?.Invoke(this, EventArgs.Empty);
        }
    }

    public event EventHandler? ActiveAccountChanged;

    public AccountService()
        : this(Path.Combine(AppContext.BaseDirectory, "launcher-accounts.json"))
    {
    }

    internal AccountService(string filePath)
    {
        _filePath = filePath;
        Load();
    }

    public AccountProfile Add(string name)
    {
        string normalizedName = ValidateName(name, null);
        AccountProfile previousActive = ActiveAccount;
        var account = new AccountProfile
        {
            Id = "player-" + Guid.NewGuid().ToString("N"),
            Name = normalizedName,
            CreatedAt = DateTimeOffset.Now
        };
        Accounts.Add(account);
        ActiveAccount = account;
        try
        {
            Save();
        }
        catch
        {
            Accounts.Remove(account);
            ActiveAccount = previousActive;
            throw;
        }
        return account;
    }

    public void Rename(AccountProfile account, string name)
    {
        EnsureKnown(account);
        string previousName = account.Name;
        account.Name = ValidateName(name, account);
        try
        {
            Save();
        }
        catch
        {
            account.Name = previousName;
            throw;
        }
        ActiveAccountChanged?.Invoke(this, EventArgs.Empty);
    }

    public void Select(AccountProfile account)
    {
        EnsureKnown(account);
        AccountProfile previousActive = ActiveAccount;
        ActiveAccount = account;
        try
        {
            Save();
        }
        catch
        {
            ActiveAccount = previousActive;
            throw;
        }
    }

    public void Remove(AccountProfile account)
    {
        EnsureKnown(account);
        if (Accounts.Count <= 1)
            throw new InvalidOperationException("至少需要保留一个账号。");

        int removedIndex = Accounts.IndexOf(account);
        AccountProfile previousActive = ActiveAccount;
        bool wasActive = ReferenceEquals(account, ActiveAccount);
        Accounts.Remove(account);
        if (wasActive)
            ActiveAccount = Accounts[0];
        try
        {
            Save();
        }
        catch
        {
            Accounts.Insert(removedIndex, account);
            ActiveAccount = previousActive;
            throw;
        }
    }

    private void Load()
    {
        AccountStore? store = null;
        try
        {
            if (File.Exists(_filePath))
                store = JsonSerializer.Deserialize<AccountStore>(File.ReadAllText(_filePath));
        }
        catch
        {
            // Corrupt or partially written files fall back to the legacy default profile.
        }

        if (store?.Accounts is not null)
        {
            foreach (AccountProfile account in store.Accounts)
            {
                account.Id = NormalizeId(account.Id);
                account.Name = NormalizeLoadedName(account.Name);
                if (account.Id.Length == 0 || account.Name.Length == 0 ||
                    Accounts.Any(item => item.Id.Equals(account.Id, StringComparison.OrdinalIgnoreCase)))
                    continue;
                Accounts.Add(account);
            }
        }

        if (Accounts.Count == 0)
        {
            Accounts.Add(new AccountProfile
            {
                Id = DefaultProfileId,
                Name = "默认账号",
                CreatedAt = DateTimeOffset.Now
            });
        }

        _activeAccount = Accounts.FirstOrDefault(account =>
            account.Id.Equals(store?.ActiveAccountId, StringComparison.OrdinalIgnoreCase)) ?? Accounts[0];

        try { Save(); } catch { }
    }

    private void Save()
    {
        string? directory = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(directory))
            Directory.CreateDirectory(directory);

        var options = new JsonSerializerOptions { WriteIndented = true };
        string json = JsonSerializer.Serialize(new AccountStore
        {
            ActiveAccountId = ActiveAccount.Id,
            Accounts = Accounts.ToList()
        }, options);

        string temporaryPath = _filePath + ".tmp";
        File.WriteAllText(temporaryPath, json);
        File.Move(temporaryPath, _filePath, true);
    }

    private string ValidateName(string? name, AccountProfile? current)
    {
        string normalized = (name ?? "").Trim();
        if (normalized.Length == 0)
            throw new InvalidOperationException("账号名称不能为空。");
        if (normalized.Length > MaxNameLength)
            throw new InvalidOperationException($"账号名称不能超过 {MaxNameLength} 个字符。");
        if (Accounts.Any(account => !ReferenceEquals(account, current) &&
            account.Name.Equals(normalized, StringComparison.CurrentCultureIgnoreCase)))
            throw new InvalidOperationException("已存在同名账号。");
        return normalized;
    }

    private void EnsureKnown(AccountProfile account)
    {
        if (!Accounts.Contains(account))
            throw new InvalidOperationException("账号不存在或已被移除。");
    }

    private static string NormalizeLoadedName(string? name)
    {
        string normalized = (name ?? "").Trim();
        return normalized.Length <= MaxNameLength ? normalized : normalized[..MaxNameLength];
    }

    private static string NormalizeId(string? id)
    {
        if (string.IsNullOrWhiteSpace(id)) return "";
        string normalized = new(id.Trim().Where(character =>
            char.IsAsciiLetterOrDigit(character) || character is '-' or '_' or '.').ToArray());
        return normalized.Length <= 64 ? normalized : normalized[..64];
    }

    private sealed class AccountStore
    {
        public string ActiveAccountId { get; set; } = "";
        public List<AccountProfile> Accounts { get; set; } = [];
    }
}
