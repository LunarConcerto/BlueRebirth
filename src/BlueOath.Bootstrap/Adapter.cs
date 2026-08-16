using System.Security.Cryptography;

namespace BlueOath.Bootstrap;

public sealed record ClientAdapter(string Id, string Version, string GameAssemblySha256, string ExecutableName, bool SupportsNetworkRedirect);

public static class AdapterRegistry
{
    public static readonly IReadOnlyList<ClientAdapter> Known =
    [
        new("jp-1.4.0", "1.4.0", "8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404", "blueoath.exe", false),
        new("cn-1.5.20", "1.5.20", "AB1C009D1565F69B815703EAAE39F4FB4BD3533EF5FE823D620B355C62A1A9C0", "clsy.exe", false)
    ];

    public static ClientAdapter Resolve(string gameAssemblyPath, string executableName)
    {
        if (!File.Exists(gameAssemblyPath)) throw new FileNotFoundException("GameAssembly.dll not found", gameAssemblyPath);
        using var stream = File.OpenRead(gameAssemblyPath);
        var hash = Convert.ToHexString(SHA256.HashData(stream));
        var adapter = Known.FirstOrDefault(x => x.GameAssemblySha256.Equals(hash, StringComparison.OrdinalIgnoreCase) && x.ExecutableName.Equals(executableName, StringComparison.OrdinalIgnoreCase));
        return adapter ?? throw new InvalidOperationException($"Unsupported client build: {hash}");
    }
}

public sealed class PatchSession(ClientAdapter adapter, Action<string>? log = null)
{
    public ClientAdapter Adapter { get; } = adapter;
    public bool IsApplied { get; private set; }
    public void ApplyNetworkRedirect(string host, int port)
    {
        if (!Adapter.SupportsNetworkRedirect) throw new NotSupportedException($"No verified patch points for {Adapter.Id}");
        if (string.IsNullOrWhiteSpace(host) || port is < 1 or > 65535) throw new ArgumentOutOfRangeException(nameof(port));
        IsApplied = true; (log ?? Console.WriteLine)($"network redirect prepared: {host}:{port}");
    }
}
