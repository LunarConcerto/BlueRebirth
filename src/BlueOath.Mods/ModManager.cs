using System.Text.Json;
namespace BlueOath.Mods;

public sealed record ModManifest(string Id, string Version, string Entry, string[] TargetClients, string[] Dependencies, int LoadOrder, bool Enabled);
public sealed class ModManager
{
    private readonly string _root; private readonly string _clientId; private readonly Action<string> _log; private readonly List<LoadedMod> _loaded=[];
    public ModManager(string root, string clientId, Action<string>? log=null) { _root=root; _clientId=clientId; _log=log ?? Console.WriteLine; }
    public IReadOnlyList<string> LoadedIds => _loaded.Select(x=>x.Manifest.Id).ToArray();
    public IReadOnlyList<LoadedMod> Loaded => _loaded;
    public void LoadAll()
    {
        if(!Directory.Exists(_root)) return;
        var manifests=new List<(ModManifest Manifest, string Directory)>();
        foreach(var file in Directory.EnumerateFiles(_root,"mod.json",SearchOption.AllDirectories)) try { var m=JsonSerializer.Deserialize<ModManifest>(File.ReadAllText(file), JsonOptions); if(m is not null && m.Enabled && (m.TargetClients?.Length is null or 0 || m.TargetClients.Contains(_clientId,StringComparer.OrdinalIgnoreCase))) manifests.Add((m, Path.GetDirectoryName(file)!)); } catch(Exception e){_log($"mod manifest failed: {file}: {e.Message}");}
        var ids = manifests.Select(x => x.Manifest.Id).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach(var (m, dir) in manifests.OrderBy(x=>x.Manifest.LoadOrder).ThenBy(x=>x.Manifest.Id)) try { var path=Path.Combine(dir,m.Entry); if(!File.Exists(path)) throw new FileNotFoundException(path); if((m.Dependencies ?? []).Any(d => !ids.Contains(d))) throw new InvalidOperationException("Missing dependency"); _loaded.Add(new LoadedMod(m,path)); _log($"mod discovered: {m.Id} (xLua runtime handoff pending)"); } catch(Exception e){_log($"mod disabled: {m.Id}: {e.Message}");}
    }
    public void Emit(string eventName, object? payload=null)
    { foreach(var mod in _loaded) mod.Events.Enqueue((eventName, payload)); }

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
}

public sealed class LoadedMod(ModManifest manifest, string entryPath)
{
    public ModManifest Manifest { get; } = manifest;
    public string EntryPath { get; } = entryPath;
    public Queue<(string EventName, object? Payload)> Events { get; } = new();
}
