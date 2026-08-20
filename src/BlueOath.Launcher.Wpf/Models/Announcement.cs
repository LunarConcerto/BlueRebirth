using System.Text.Json.Serialization;

namespace BlueOath.Launcher.Wpf.Models;

public class Announcement
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("title")]
    public string Title { get; set; } = "";

    [JsonPropertyName("content")]
    public string Content { get; set; } = "";

    [JsonPropertyName("severity")]
    public string Severity { get; set; } = "info";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "";
}