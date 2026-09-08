using System.Text.Json.Serialization;

namespace BlueOath.Launcher.Wpf.Models;

public class ModInfo
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "";

    [JsonPropertyName("description")]
    public string Description { get; set; } = "";

    [JsonPropertyName("entry")]
    public string Entry { get; set; } = "";

    [JsonPropertyName("targetClients")]
    public List<string> TargetClients { get; set; } = new();

    [JsonPropertyName("dependencies")]
    public List<string> Dependencies { get; set; } = new();

    [JsonPropertyName("loadOrder")]
    public int LoadOrder { get; set; }

    [JsonPropertyName("enabled")]
    public bool Enabled { get; set; } = true;

    public string Directory { get; set; } = "";

    public string DisplayName => string.IsNullOrEmpty(Name) ? Id : Name;
    public string TargetClientsText => TargetClients.Count == 0 ? "全部客户端" : string.Join(", ", TargetClients);
    public string DependenciesText => Dependencies.Count == 0 ? "无" : string.Join(", ", Dependencies);
    public string StatusText => Enabled ? "已启用" : "已禁用";
    public string ToggleActionText => Enabled ? "禁用" : "启用";
}