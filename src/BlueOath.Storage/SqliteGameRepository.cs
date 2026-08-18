using System.Text.Json;
using BlueOath.Core;
using Microsoft.Data.Sqlite;

namespace BlueOath.Storage;

public sealed class SqliteGameRepository : IGameRepository
{
    private readonly string _root;
    private readonly string _dbPath;

    public SqliteGameRepository(string? root = null)
    {
        _root = root ?? Path.Combine(AppContext.BaseDirectory, "profiles");
        Directory.CreateDirectory(_root);
        _dbPath = Path.Combine(_root, "profiles.db");
        using var c = Open();
        c.Open();
        using var cmd = c.CreateCommand();
        cmd.CommandText =
            "CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, name TEXT NOT NULL, state_json TEXT NOT NULL, updated_utc TEXT NOT NULL);" +
            "CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, account_json TEXT NOT NULL, updated_utc TEXT NOT NULL);";
        cmd.ExecuteNonQuery();
    }

    public async Task<PlayerState?> LoadAsync(string profileId, CancellationToken ct = default)
    {
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT state_json FROM profiles WHERE id=$id";
        cmd.Parameters.AddWithValue("$id", profileId);
        var value = await cmd.ExecuteScalarAsync(ct);
        return value is string json ? JsonSerializer.Deserialize<PlayerState>(json, JsonOptions) : null;
    }

    public async Task SaveAsync(PlayerState state, CancellationToken ct = default)
    {
        var json = JsonSerializer.Serialize(state, JsonOptions);
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var tx = (SqliteTransaction)await c.BeginTransactionAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = "INSERT INTO profiles(id,name,state_json,updated_utc) VALUES($id,$name,$json,$utc) ON CONFLICT(id) DO UPDATE SET name=$name,state_json=$json,updated_utc=$utc";
        cmd.Parameters.AddWithValue("$id", state.ProfileId);
        cmd.Parameters.AddWithValue("$name", state.Name);
        cmd.Parameters.AddWithValue("$json", json);
        cmd.Parameters.AddWithValue("$utc", DateTimeOffset.UtcNow.ToString("O"));
        await cmd.ExecuteNonQueryAsync(ct);
        await tx.CommitAsync(ct);
    }

    public async Task<IReadOnlyList<string>> ListProfilesAsync(CancellationToken ct = default)
    {
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT id FROM profiles ORDER BY id";
        var list = new List<string>();
        await using var r = await cmd.ExecuteReaderAsync(ct);
        while (await r.ReadAsync(ct))
            list.Add(r.GetString(0));
        return list;
    }

    public async Task CreateAsync(string profileId, string name, CancellationToken ct = default)
    {
        if (!System.Text.RegularExpressions.Regex.IsMatch(profileId, "^[A-Za-z0-9_-]{1,64}$"))
            throw new ArgumentException("Invalid profile id");
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        await SaveAsync(new PlayerState(profileId, name, 1, 100, 0,
            [new Ship(1001, "Starter", 1, 100), new Ship(1002, "Scout", 1, 80)],
            new Formation([1001]), 0), ct);
        await SaveAccountAsync(PlayerAccountFactory.CreateDefault(profileId, now), ct);
    }

    public async Task BackupAsync(string profileId, string destination, CancellationToken ct = default)
    {
        var state = await LoadAsync(profileId, ct) ?? throw new KeyNotFoundException("Profile not found");
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(destination))!);
        await File.WriteAllTextAsync(destination, JsonSerializer.Serialize(state, JsonOptions), ct);
    }

    public async Task ResetAsync(string profileId, CancellationToken ct = default)
    {
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "DELETE FROM profiles WHERE id=$id; DELETE FROM accounts WHERE id=$id;";
        cmd.Parameters.AddWithValue("$id", profileId);
        await cmd.ExecuteNonQueryAsync(ct);
    }

    public async Task<PlayerAccount?> LoadAccountAsync(string profileId, CancellationToken ct = default)
    {
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.CommandText = "SELECT account_json FROM accounts WHERE id=$id";
        cmd.Parameters.AddWithValue("$id", profileId);
        var value = await cmd.ExecuteScalarAsync(ct);
        return value is string json ? JsonSerializer.Deserialize<PlayerAccount>(json, JsonOptions) : null;
    }

    public async Task SaveAccountAsync(PlayerAccount account, CancellationToken ct = default)
    {
        var json = JsonSerializer.Serialize(account, JsonOptions);
        await using var c = Open();
        await c.OpenAsync(ct);
        await using var tx = (SqliteTransaction)await c.BeginTransactionAsync(ct);
        await using var cmd = c.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = "INSERT INTO accounts(id,account_json,updated_utc) VALUES($id,$json,$utc) ON CONFLICT(id) DO UPDATE SET account_json=$json,updated_utc=$utc";
        cmd.Parameters.AddWithValue("$id", account.ProfileId);
        cmd.Parameters.AddWithValue("$json", json);
        cmd.Parameters.AddWithValue("$utc", DateTimeOffset.UtcNow.ToString("O"));
        await cmd.ExecuteNonQueryAsync(ct);
        await tx.CommitAsync(ct);
    }

    private SqliteConnection Open() => new($"Data Source={_dbPath};Mode=ReadWriteCreate;Cache=Shared;Pooling=False");
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
}
