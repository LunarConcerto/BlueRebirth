using System.Text.Json.Serialization;

namespace BlueOath.Server.Protocols;

/// <summary>卡池启用配置：指定哪些卡池（config_extract_ship id）强制开启。</summary>
internal sealed class BuildPoolsConfig
{
    [JsonPropertyName("enabledPoolIds")]
    public List<int> EnabledPoolIds { get; set; } = [];
}

/// <summary>从内嵌资源加载卡池启用配置。</summary>
internal static class BuildPoolsConfigLoader
{
    public static BuildPoolsConfig Load()
    {
        try
        {
            var json = EmbeddedResourceHelper.TryLoadEmbedded("BlueOath.Server.build-pools.json");
            if (string.IsNullOrEmpty(json)) return new BuildPoolsConfig();
            return System.Text.Json.JsonSerializer.Deserialize<BuildPoolsConfig>(json)
                ?? new BuildPoolsConfig();
        }
        catch
        {
            return new BuildPoolsConfig();
        }
    }
}