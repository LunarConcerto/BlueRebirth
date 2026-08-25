using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;

namespace BlueOath.Launcher.Wpf.Services;

internal sealed class LauncherUpdateService
{
    private readonly HttpClient _httpClient;
    private readonly string _rootDir;
    private readonly string _manifestUrl;
    private readonly bool _enabled;

    public LauncherUpdateService(string rootDir, string manifestUrl, bool enabled)
    {
        _httpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(12) };
        _rootDir = rootDir;
        _manifestUrl = manifestUrl;
        _enabled = enabled;
    }

    public async Task<bool> TrySelfUpdateAsync(Window owner, string localExecutable, CancellationToken cancellationToken = default)
    {
        if (!_enabled || string.IsNullOrWhiteSpace(_manifestUrl))
            return false;

        var manifest = await GetRemoteManifestAsync(cancellationToken);
        if (manifest is null) return false;

        var latestVersion = NormalizeVersion(manifest.Version);
        if (string.IsNullOrWhiteSpace(latestVersion))
            return false;

        var currentVersion = NormalizeVersion(VersionInfo.Version);
        if (!Version.TryParse(latestVersion, out var remoteVersion) || !Version.TryParse(currentVersion, out var localVersion))
            return false;

        if (remoteVersion <= localVersion)
            return false;

        var message = $"检测到新版本 {latestVersion}";
        if (!string.IsNullOrWhiteSpace(manifest.ReleaseNotes))
            message += $"\n\n更新说明：{manifest.ReleaseNotes}";

        if (!string.IsNullOrWhiteSpace(manifest.ConfidenceHint))
            message += $"\n\n{manifest.ConfidenceHint}";

        var updateAccepted = MessageBox.Show(
            owner,
            message + "\n\n是否立即更新？",
            "BlueOath 启动器更新",
            MessageBoxButton.YesNo,
            MessageBoxImage.Information) == MessageBoxResult.Yes;

        if (!updateAccepted) return false;

        if (string.IsNullOrWhiteSpace(manifest.PackageUrl))
        {
            MessageBox.Show(owner, "更新清单中缺少下载地址。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return false;
        }

        var packagePath = await DownloadPackageAsync(manifest.PackageUrl, cancellationToken);
        if (packagePath is null)
        {
            MessageBox.Show(owner, "下载更新包失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return false;
        }

        var configuredExecutable = manifest.ExecutableName;
        var exeName = Path.GetFileName(localExecutable);
        if (!string.IsNullOrWhiteSpace(configuredExecutable))
            exeName = configuredExecutable;
        if (string.IsNullOrWhiteSpace(exeName))
            exeName = "BlueOath.Launcher.Wpf.exe";

        var scriptPath = CreateUpdateScript(packagePath, exeName, Environment.ProcessId);
        if (scriptPath is null)
        {
            MessageBox.Show(owner, "生成更新脚本失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return false;
        }

        LaunchUpdateAndExit(scriptPath, packagePath, exeName);
        return true;
    }

    private static string? NormalizeVersion(string? version)
    {
        if (string.IsNullOrWhiteSpace(version))
            return null;

        var match = Regex.Match(version, @"\d+(?:\.\d+){0,2}");
        if (!match.Success)
            return version.Trim();

        var raw = match.Value.Split('.');
        var normalized = new StringBuilder();
        normalized.Append(raw.Length > 0 ? raw[0] : "0");
        normalized.Append('.');
        normalized.Append(raw.Length > 1 ? raw[1] : "0");
        normalized.Append('.');
        normalized.Append(raw.Length > 2 ? raw[2] : "0");
        return normalized.ToString();
    }

    private async Task<LauncherUpdateManifest?> GetRemoteManifestAsync(CancellationToken cancellationToken)
    {
        try
        {
            using var response = await _httpClient.GetAsync(_manifestUrl, cancellationToken);
            if (!response.IsSuccessStatusCode) return null;

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            return await JsonSerializer.DeserializeAsync<LauncherUpdateManifest>(
                stream,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true },
                cancellationToken);
        }
        catch
        {
            return null;
        }
    }

    private async Task<string?> DownloadPackageAsync(string packageUrl, CancellationToken cancellationToken)
    {
        try
        {
            using var response = await _httpClient.GetAsync(packageUrl, cancellationToken);
            if (!response.IsSuccessStatusCode)
                return null;

            var cacheDir = Path.Combine(Path.GetTempPath(), "BlueOathLauncherUpdate");
            Directory.CreateDirectory(cacheDir);
            var outputPath = Path.Combine(cacheDir, $"launcher-{DateTime.UtcNow:yyyyMMddHHmmssfff}.zip");

            await using var fs = new FileStream(outputPath, FileMode.Create, FileAccess.Write, FileShare.None);
            await using var netStream = await response.Content.ReadAsStreamAsync(cancellationToken);
            await netStream.CopyToAsync(fs, cancellationToken);
            return outputPath;
        }
        catch
        {
            return null;
        }
    }

    private string? CreateUpdateScript(string packagePath, string executableName, int currentProcessId)
    {
        try
        {
            var script = new StringBuilder();
            script.AppendLine("param(");
            script.AppendLine("    [string]$rootDir,");
            script.AppendLine("    [string]$zipPath,");
            script.AppendLine("    [string]$exeName,");
            script.AppendLine("    [int]$launcherPid");
            script.AppendLine(")");
            script.AppendLine("Start-Sleep -Seconds 1");
            script.AppendLine("$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ('blueoath-launcher-update-' + [System.Guid]::NewGuid())");
            script.AppendLine("New-Item -ItemType Directory -Path $workDir | Out-Null");
            script.AppendLine("Expand-Archive -Path $zipPath -DestinationPath $workDir -Force");
            script.AppendLine("while ($true)");
            script.AppendLine("{");
            script.AppendLine("    if ($launcherPid -gt 0)");
            script.AppendLine("    {");
            script.AppendLine("        $running = Get-Process -Id $launcherPid -ErrorAction SilentlyContinue");
            script.AppendLine("        if ($null -eq $running) { break }");
            script.AppendLine("    }");
            script.AppendLine("    else");
            script.AppendLine("    {");
            script.AppendLine("        break");
            script.AppendLine("    }");
            script.AppendLine("    Start-Sleep -Milliseconds 500");
            script.AppendLine("}");
            script.AppendLine("Copy-Item -Path (Join-Path $workDir '*') -Destination $rootDir -Recurse -Force");
            script.AppendLine("Remove-Item -Path $workDir -Recurse -Force");
            script.AppendLine("Remove-Item -Path $zipPath -Force");
            script.AppendLine("Start-Sleep -Milliseconds 250");
            script.AppendLine("$newExe = Join-Path $rootDir $exeName");
            script.AppendLine("if (Test-Path $newExe) { Start-Process -FilePath $newExe }");
            script.AppendLine("Remove-Item -Path $PSCommandPath -Force");

            var updateDir = Path.Combine(Path.GetTempPath(), "BlueOathLauncherUpdate", "scripts");
            Directory.CreateDirectory(updateDir);
            var scriptPath = Path.Combine(updateDir, $"apply-update-{Guid.NewGuid():N}.ps1");
            File.WriteAllText(scriptPath, script.ToString(), new UTF8Encoding(false));
            return scriptPath;
        }
        catch
        {
            return null;
        }
    }

    private void LaunchUpdateAndExit(string scriptPath, string packagePath, string executableName)
    {
        var psi = new ProcessStartInfo("powershell.exe")
        {
            UseShellExecute = false,
            CreateNoWindow = true
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-ExecutionPolicy");
        psi.ArgumentList.Add("Bypass");
        psi.ArgumentList.Add("-WindowStyle");
        psi.ArgumentList.Add("Hidden");
        psi.ArgumentList.Add("-File");
        psi.ArgumentList.Add(scriptPath);
        psi.ArgumentList.Add("-rootDir");
        psi.ArgumentList.Add(_rootDir);
        psi.ArgumentList.Add("-zipPath");
        psi.ArgumentList.Add(packagePath);
        psi.ArgumentList.Add("-exeName");
        psi.ArgumentList.Add(executableName);
        psi.ArgumentList.Add("-launcherPid");
        psi.ArgumentList.Add(Environment.ProcessId.ToString());

        Process.Start(psi);
        Application.Current.Shutdown();
    }

    private sealed class LauncherUpdateManifest
    {
        public string? Version { get; set; }
        public string? PackageUrl { get; set; }
        public string? ReleaseNotes { get; set; }
        public string? ConfidenceHint { get; set; }
        public string? ExecutableName { get; set; }
    }
}
