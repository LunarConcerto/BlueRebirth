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
using System.Windows.Controls;
using System.Windows.Media;

namespace BlueOath.Launcher.Wpf.Services;

internal enum UpdateCheckResult
{
    UpToDate,
    Unavailable,
    Updating,
    Cancelled
}

internal sealed class LauncherUpdateService
{
    private readonly HttpClient _httpClient;
    private readonly HttpClient _manifestHttpClient;
    private readonly string _rootDir;
    private readonly string _manifestUrl;
    private readonly bool _enabled;

    public LauncherUpdateService(string rootDir, string manifestUrl, bool enabled)
    {
        // Manifest requests are small, but release packages can be tens or hundreds of MB.
        _httpClient = new HttpClient { Timeout = TimeSpan.FromMinutes(10) };
        _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("BlueOath-Launcher/1.0");
        _manifestHttpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        _manifestHttpClient.DefaultRequestHeaders.UserAgent.ParseAdd("BlueOath-Launcher/1.0");
        _rootDir = rootDir;
        _manifestUrl = manifestUrl;
        _enabled = enabled;
    }

    public async Task<UpdateCheckResult> TrySelfUpdateAsync(
        Window? owner,
        string localExecutable,
        CancellationToken cancellationToken = default,
        Action? afterUpdatePrompt = null)
    {
        if (!_enabled || string.IsNullOrWhiteSpace(_manifestUrl))
            return UpdateCheckResult.Unavailable;

        var manifest = await GetRemoteManifestAsync(cancellationToken);
        if (manifest is null) return UpdateCheckResult.Unavailable;

        var latestVersion = NormalizeVersion(manifest.Version);
        if (string.IsNullOrWhiteSpace(latestVersion))
            return UpdateCheckResult.Unavailable;

        var currentVersion = NormalizeVersion(VersionInfo.Version);
        if (!Version.TryParse(latestVersion, out var remoteVersion) || !Version.TryParse(currentVersion, out var localVersion))
            return UpdateCheckResult.Unavailable;

        if (remoteVersion <= localVersion)
            return UpdateCheckResult.UpToDate;

        var message = $"检测到新版本 {latestVersion}";
        if (!string.IsNullOrWhiteSpace(manifest.ReleaseNotes))
            message += $"\n\n更新说明：{manifest.ReleaseNotes}";

        if (!string.IsNullOrWhiteSpace(manifest.ConfidenceHint))
            message += $"\n\n{manifest.ConfidenceHint}";

        var updateAccepted = ShowMessage(
            owner,
            message + "\n\n是否立即更新？",
            "BlueOath 启动器更新",
            MessageBoxButton.YesNo,
            MessageBoxImage.Information) == MessageBoxResult.Yes;

        afterUpdatePrompt?.Invoke();

        if (!updateAccepted) return UpdateCheckResult.Cancelled;

        if (string.IsNullOrWhiteSpace(manifest.PackageUrl))
        {
            ShowMessage(owner, "更新清单中缺少下载地址。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
        }

        var packagePath = await DownloadPackageAsync(manifest.PackageUrl, owner, cancellationToken);
        if (packagePath is null)
        {
            ShowMessage(owner, "下载更新包失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
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
            ShowMessage(owner, "生成更新脚本失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
        }

        LaunchUpdateAndExit(scriptPath, packagePath, exeName);
        return UpdateCheckResult.Updating;
    }

    private static MessageBoxResult ShowMessage(
        Window? owner,
        string message,
        string caption,
        MessageBoxButton buttons,
        MessageBoxImage image)
    {
        return owner is null
            ? MessageBox.Show(message, caption, buttons, image)
            : MessageBox.Show(owner, message, caption, buttons, image);
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
            using var response = await _manifestHttpClient.GetAsync(_manifestUrl, cancellationToken);
            if (!response.IsSuccessStatusCode) return null;

            var json = await response.Content.ReadAsStringAsync(cancellationToken);
            using var document = JsonDocument.Parse(json);
            var root = document.RootElement;

            if (root.TryGetProperty("tag_name", out var tagName))
            {
                var packageUrl = string.Empty;
                if (root.TryGetProperty("assets", out var assets) && assets.ValueKind == JsonValueKind.Array)
                {
                    foreach (var asset in assets.EnumerateArray())
                    {
                        var assetName = asset.TryGetProperty("name", out var name) ? name.GetString() : null;
                        if (assetName?.EndsWith(".zip", StringComparison.OrdinalIgnoreCase) == true &&
                            asset.TryGetProperty("browser_download_url", out var downloadUrl))
                        {
                            packageUrl = downloadUrl.GetString() ?? string.Empty;
                            break;
                        }
                    }
                }

                var releaseVersion = tagName.GetString();
                var normalizedTagVersion = NormalizeVersion(releaseVersion);
                if ((!Version.TryParse(normalizedTagVersion, out _) || string.IsNullOrWhiteSpace(normalizedTagVersion)) &&
                    root.TryGetProperty("name", out var releaseName))
                {
                    releaseVersion = releaseName.GetString();
                }

                return new LauncherUpdateManifest
                {
                    Version = releaseVersion,
                    PackageUrl = packageUrl,
                    ReleaseNotes = root.TryGetProperty("body", out var body) ? body.GetString() : null,
                    ExecutableName = "BlueOath.Launcher.Wpf.exe"
                };
            }

            return JsonSerializer.Deserialize<LauncherUpdateManifest>(
                json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }
        catch
        {
            return null;
        }
    }

    private async Task<string?> DownloadPackageAsync(string packageUrl, Window? owner, CancellationToken cancellationToken)
    {
        DownloadProgressWindow? progressWindow = null;
        try
        {
            progressWindow = new DownloadProgressWindow(owner);
            progressWindow.Show();

            using var response = await _httpClient.GetAsync(
                packageUrl,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
                return null;

            var cacheDir = Path.Combine(_rootDir, ".update");
            Directory.CreateDirectory(cacheDir);
            var outputPath = Path.Combine(cacheDir, "launcher-update.zip");
            var totalBytes = response.Content.Headers.ContentLength;
            var downloadedBytes = 0L;

            await using var fs = new FileStream(outputPath, FileMode.Create, FileAccess.Write, FileShare.None);
            await using var netStream = await response.Content.ReadAsStreamAsync(cancellationToken);
            var buffer = new byte[81920];
            int bytesRead;
            while ((bytesRead = await netStream.ReadAsync(buffer, cancellationToken)) > 0)
            {
                await fs.WriteAsync(buffer.AsMemory(0, bytesRead), cancellationToken);
                downloadedBytes += bytesRead;
                progressWindow.UpdateProgress(downloadedBytes, totalBytes);
            }

            progressWindow.UpdateStatus("下载完成，正在准备替换文件...");
            return outputPath;
        }
        catch
        {
            return null;
        }
        finally
        {
            progressWindow?.Close();
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
            script.AppendLine("$updateDir = Split-Path -Parent $zipPath");
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
            script.AppendLine("Remove-Item -Path $updateDir -Recurse -Force");
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

    private sealed class DownloadProgressWindow : Window
    {
        private readonly TextBlock _statusText;
        private readonly ProgressBar _progressBar;

        public DownloadProgressWindow(Window? owner)
        {
            Title = "BlueOath 启动器更新";
            Width = 420;
            Height = 150;
            WindowStartupLocation = owner is null ? WindowStartupLocation.CenterScreen : WindowStartupLocation.CenterOwner;
            ResizeMode = ResizeMode.NoResize;
            ShowInTaskbar = false;
            Owner = owner;

            _statusText = new TextBlock
            {
                Text = "正在下载更新包...",
                Margin = new Thickness(0, 0, 0, 12),
                Foreground = Brushes.Black
            };
            _progressBar = new ProgressBar
            {
                Height = 18,
                Minimum = 0,
                Maximum = 100
            };

            Content = new Border
            {
                Padding = new Thickness(20),
                Child = new StackPanel
                {
                    Children = { _statusText, _progressBar }
                }
            };
        }

        public void UpdateProgress(long downloadedBytes, long? totalBytes)
        {
            Dispatcher.Invoke(() =>
            {
                if (totalBytes is > 0)
                {
                    var percent = downloadedBytes * 100d / totalBytes.Value;
                    _progressBar.Value = percent;
                    _statusText.Text = $"正在下载更新包... {percent:0.0}% ({FormatBytes(downloadedBytes)} / {FormatBytes(totalBytes.Value)})";
                }
                else
                {
                    _statusText.Text = $"正在下载更新包... {FormatBytes(downloadedBytes)}";
                }
            });
        }

        public void UpdateStatus(string status)
        {
            Dispatcher.Invoke(() => _statusText.Text = status);
        }

        private static string FormatBytes(long bytes)
        {
            if (bytes >= 1024 * 1024)
                return $"{bytes / 1024d / 1024d:0.0} MB";
            return $"{bytes / 1024d:0.0} KB";
        }
    }

    internal sealed class UpdateStatusWindow : Window
    {
        public UpdateStatusWindow()
        {
            Title = "BlueOath 启动器";
            Width = 320;
            Height = 110;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;
            ResizeMode = ResizeMode.NoResize;
            ShowInTaskbar = false;

            Content = new StackPanel
            {
                Margin = new Thickness(24),
                Children =
                {
                    new TextBlock
                    {
                        Text = "正在检查更新...",
                        Foreground = Brushes.Black,
                        Margin = new Thickness(0, 0, 0, 12)
                    },
                    new ProgressBar
                    {
                        Height = 16,
                        IsIndeterminate = true
                    }
                }
            };
        }
    }
}
