using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using BlueOath.Launcher.Wpf.Models;

namespace BlueOath.Launcher.Wpf.Services;

public class ModService
{
    private readonly string _modsRoot;

    public ModService(string rootDir)
    {
        _modsRoot = Path.Combine(rootDir, "Mods");
    }

    public List<ModInfo> LoadMods()
    {
        var result = new List<ModInfo>();
        if (!Directory.Exists(_modsRoot)) return result;

        foreach (var modDir in Directory.EnumerateDirectories(_modsRoot))
        {
            var manifestPath = Path.Combine(modDir, "mod.json");
            if (!File.Exists(manifestPath)) continue;

            try
            {
                var json = File.ReadAllText(manifestPath);
                var mod = JsonSerializer.Deserialize<ModInfo>(json, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                if (mod is null || string.IsNullOrEmpty(mod.Id)) continue;

                mod.Directory = modDir;
                result.Add(mod);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Failed to load mod manifest {manifestPath}: {ex.Message}");
            }
        }

        result.Sort((a, b) => a.LoadOrder.CompareTo(b.LoadOrder));
        return result;
    }

    public void SetEnabled(ModInfo mod, bool enabled)
    {
        var manifestPath = Path.Combine(mod.Directory, "mod.json");
        if (!File.Exists(manifestPath)) return;

        try
        {
            var json = File.ReadAllText(manifestPath);
            var node = JsonNode.Parse(json);
            if (node is JsonObject obj)
            {
                obj["enabled"] = enabled;
                var options = new JsonSerializerOptions { WriteIndented = true };
                File.WriteAllText(manifestPath, obj.ToJsonString(options));
                mod.Enabled = enabled;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to update mod manifest {manifestPath}: {ex.Message}");
        }
    }
}