using System.Reflection;
using System.Text.Json;

namespace BlueOath.Server.Protocols;

internal static class AnnouncementConfigLoader
{
    private static AnnouncementConfig? _config;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static AnnouncementConfig Load()
    {
        if (_config is not null) return _config;
        try
        {
            var assembly = Assembly.GetExecutingAssembly();
            using var stream = assembly.GetManifestResourceStream("BlueOath.Server.announcements.json");
            if (stream is null)
            {
                _config = new AnnouncementConfig();
                return _config;
            }
            using var reader = new StreamReader(stream);
            var json = reader.ReadToEnd();
            _config = JsonSerializer.Deserialize<AnnouncementConfig>(json, JsonOptions) ?? new AnnouncementConfig();
        }
        catch
        {
            _config = new AnnouncementConfig();
        }
        return _config;
    }
}