using System.Text.Json;
namespace BlueOath.Mods;

public sealed record ModManifest(string Id, string Version, string Entry, string[] TargetClients, string[] Dependencies, int LoadOrder, bool Enabled);

/// <summary>发现的 mod 清单及其所在目录。</summary>
public sealed record ModDiscovery(ModManifest Manifest, string Directory);

/// <summary>mod 运行时事件（事件名 + 负载）。</summary>
public sealed record ModEvent(string EventName, object? Payload);

public sealed class ModManager
{
    private readonly string _root; private readonly string _clientId; private readonly Action<string> _log; private readonly List<LoadedMod> _loaded=[];
    public ModManager(string root, string clientId, Action<string>? log=null) { _root=root; _clientId=clientId; _log=log ?? Console.WriteLine; }
    public IReadOnlyList<string> LoadedIds => _loaded.Select(x=>x.Manifest.Id).ToArray();
    public IReadOnlyList<LoadedMod> Loaded => _loaded;
    public void LoadAll()
    {
        if(!Directory.Exists(_root)) return;
        var manifests=new List<ModDiscovery>();
        foreach(var file in Directory.EnumerateFiles(_root,"mod.json",SearchOption.AllDirectories)) try { var m=JsonSerializer.Deserialize<ModManifest>(File.ReadAllText(file), JsonOptions); if(m is not null && m.Enabled && (m.TargetClients?.Length is null or 0 || m.TargetClients.Contains(_clientId,StringComparer.OrdinalIgnoreCase))) manifests.Add(new ModDiscovery(m, Path.GetDirectoryName(file)!)); } catch(Exception e){_log($"mod manifest failed: {file}: {e.Message}");}
        var ids = manifests.Select(x => x.Manifest.Id).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach(var d in manifests.OrderBy(x=>x.Manifest.LoadOrder).ThenBy(x=>x.Manifest.Id)) try { var m=d.Manifest; var dir=d.Directory; var path=Path.Combine(dir,m.Entry); if(!File.Exists(path)) throw new FileNotFoundException(path); if((m.Dependencies ?? []).Any(dep => !ids.Contains(dep))) throw new InvalidOperationException("Missing dependency"); _loaded.Add(new LoadedMod(m,path)); _log($"mod discovered: {m.Id} (xLua runtime handoff pending)"); } catch(Exception e){_log($"mod disabled: {d.Manifest.Id}: {e.Message}");}
    }
    public void Emit(string eventName, object? payload=null)
    { foreach(var mod in _loaded) mod.Events.Enqueue(new ModEvent(eventName, payload)); }

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
}

public sealed class LoadedMod(ModManifest manifest, string entryPath)
{
    public ModManifest Manifest { get; } = manifest;
    public string EntryPath { get; } = entryPath;
    public Queue<ModEvent> Events { get; } = new();
}
