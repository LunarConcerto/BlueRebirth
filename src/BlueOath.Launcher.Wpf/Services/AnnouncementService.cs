using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using BlueOath.Launcher.Wpf.Models;

namespace BlueOath.Launcher.Wpf.Services;

public class AnnouncementService
{
    public List<Announcement> LoadAnnouncements()
    {
        var assembly = Assembly.GetExecutingAssembly();
        var resourceName = assembly.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith("announcements.json"));

        if (resourceName is null) return new List<Announcement>();

        using var stream = assembly.GetManifestResourceStream(resourceName);
        if (stream is null) return new List<Announcement>();

        using var reader = new StreamReader(stream);
        var json = reader.ReadToEnd();

        var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
        return JsonSerializer.Deserialize<List<Announcement>>(json, options) ?? new List<Announcement>();
    }
}