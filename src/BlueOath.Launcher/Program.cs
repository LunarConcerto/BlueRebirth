using System.Diagnostics;
using BlueOath.Bootstrap;
using BlueOath.Protocol;

var root = FindRoot();
var region = args.FirstOrDefault(a => a.StartsWith("--region=", StringComparison.OrdinalIgnoreCase))?[9..] ?? "jp";
var profile = region.Equals("cn", StringComparison.OrdinalIgnoreCase) ? ProtocolProfile.China : ProtocolProfile.Japan;
var clientRoot = region.Equals("cn", StringComparison.OrdinalIgnoreCase)
    ? Directory.GetDirectories(root, "clsy", SearchOption.AllDirectories).FirstOrDefault() ?? throw new DirectoryNotFoundException("CN client directory not found")
    : Path.Combine(root, "blueoath", "blueoath");
var executable = region.Equals("cn", StringComparison.OrdinalIgnoreCase) ? "clsy.exe" : "blueoath.exe";
var exe = Path.Combine(clientRoot, executable);
if (!File.Exists(exe)) { Console.Error.WriteLine($"Client not found: {exe}"); return 2; }
var adapter = AdapterRegistry.Resolve(Path.Combine(clientRoot, "GameAssembly.dll"), executable);
Console.WriteLine($"{profile.Region} {profile.ClientVersion} x86 adapter={adapter.Id}");
if (args.Contains("--original", StringComparer.OrdinalIgnoreCase))
{
    Process.Start(new ProcessStartInfo(exe) { WorkingDirectory = clientRoot });
    return 0;
}
Console.WriteLine("No verified runtime patch points are available for this build; refusing unsafe patch.");
Console.WriteLine("Use --original to launch the untouched client, or run BlueOath.Server directly for protocol testing.");
return 3;

static string FindRoot()
{
    var current = new DirectoryInfo(AppContext.BaseDirectory);
    while (current is not null)
    {
        if (Directory.Exists(Path.Combine(current.FullName, "blueoath"))) return current.FullName;
        current = current.Parent;
    }
    return Environment.CurrentDirectory;
}
