using System;
using System.IO;
using System.Text.Json;
using BlueOath.Launcher.Wpf.Models;

namespace BlueOath.Launcher.Wpf.Services;

public class SettingsService
{
    private readonly string _filePath;

    public SettingsService()
    {
        _filePath = Path.Combine(AppContext.BaseDirectory, "launcher-settings.json");
    }

    public SettingsConfig Load()
    {
        try
        {
            if (File.Exists(_filePath))
            {
                var json = File.ReadAllText(_filePath);
                var settings = JsonSerializer.Deserialize<SettingsConfig>(json);
                if (settings is not null)
                    return settings;
            }
        }
        catch { }

        return CreateDefaults();
    }

    public void Save(SettingsConfig settings)
    {
        try
        {
            var options = new JsonSerializerOptions
            {
                WriteIndented = true,
                Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            };
            var json = JsonSerializer.Serialize(settings, options);
            File.WriteAllText(_filePath, json);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to save settings: {ex.Message}");
        }
    }

    public SettingsConfig CreateDefaults()
    {
        var rootDir = FindRoot();
        return new SettingsConfig
        {
            GameClientPath = Path.Combine(rootDir, "blueoath", "blueoath"),
            ServerDllPath = Path.Combine(rootDir, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll"),
            PythonPath = "python",
            InjectorPath = Path.Combine(rootDir, "native", "bin-x86", "BlueOath.Injector.exe"),
            PayloadPath = Path.Combine(rootDir, "native", "bin-x86", "BlueOath.Payload.dll"),
            ProxyScriptPath = Path.Combine(rootDir, "tools", "tls-loopback-proxy.py"),
            DataRoot = Path.Combine(rootDir, "runtime", "jp"),
            BaselinePath = Path.Combine(rootDir, "baseline.json"),
            Region = "jp",
            UpdateManifestUrl = "https://api.github.com/repos/BlueRebirth/BlueRebirth/releases/tags/debug-latest",
            AutoUpdateEnabled = true,
            ServerPort = 0,
            GameLoginPort = 7201,
            GmPort = 9780,
            SkipBuild = true,
            KeepLog = false
        };
    }

    private static string FindRoot()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "blueoath")))
                return current.FullName;
            current = current.Parent;
        }
        return Environment.CurrentDirectory;
    }
}
