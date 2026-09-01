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

        var activeOwner = owner is { IsVisible: true } ? owner : null;

        if (string.IsNullOrWhiteSpace(manifest.PackageUrl))
        {
            ShowMessage(activeOwner, "更新清单中缺少下载地址。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
        }

        var packagePath = await DownloadPackageAsync(manifest.PackageUrl, activeOwner, cancellationToken);
        if (packagePath is null)
        {
            ShowMessage(activeOwner, "下载更新包失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
        }

        var configuredExecutable = manifest.ExecutableName;
        var exeName = Path.GetFileName(localExecutable);
        if (!string.IsNullOrWhiteSpace(configuredExecutable))
            exeName = configuredExecutable;
        if (string.IsNullOrWhiteSpace(exeName))
            exeName = "BlueOath.Launcher.Wpf.exe";

        var scriptPath = CreateUpdateScript();
        if (scriptPath is null)
        {
            ShowMessage(activeOwner, "生成更新脚本失败。", "更新失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return UpdateCheckResult.Unavailable;
        }

        if (LaunchUpdateAndExit(scriptPath, packagePath, exeName))
            return UpdateCheckResult.Updating;

        ShowMessage(
            activeOwner,
            "更新安装程序未能安全启动，当前启动器将继续运行。请稍后重试；如果问题持续出现，请查看 launcher-update-error.log。",
            "更新失败",
            MessageBoxButton.OK,
            MessageBoxImage.Warning);
        return UpdateCheckResult.Unavailable;
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

    private string? CreateUpdateScript()
    {
        try
        {
            const string script = """
                param(
                    [string]$rootDir,
                    [string]$zipPath,
                    [string]$exeName,
                    [int]$launcherPid,
                    [string]$updateMutexName,
                    [string]$readyEventName,
                    [string]$failedEventName
                )

                $ErrorActionPreference = 'Stop'
                $installMutex = $null
                $readyEvent = $null
                $failedEvent = $null
                $ownsInstallMutex = $false
                $readySignaled = $false
                $launcherExited = $false
                $updateSucceeded = $false
                $workDir = $null
                $window = $null
                $statusText = $null
                $script:allowWindowClose = $false
                $errorLog = Join-Path $rootDir 'launcher-update-error.log'

                function Pump-UpdateWindow
                {
                    if ($null -ne $window)
                    {
                        $window.Dispatcher.Invoke(
                            [Action]{},
                            [System.Windows.Threading.DispatcherPriority]::Background)
                    }
                }

                function Set-UpdateStatus([string]$status)
                {
                    if ($null -ne $statusText)
                    {
                        $statusText.Text = $status
                        Pump-UpdateWindow
                    }
                }

                try
                {
                    $installMutex = [System.Threading.Mutex]::new($false, $updateMutexName)
                    try
                    {
                        $ownsInstallMutex = $installMutex.WaitOne([TimeSpan]::FromSeconds(10))
                    }
                    catch [System.Threading.AbandonedMutexException]
                    {
                        $ownsInstallMutex = $true
                    }
                    if (-not $ownsInstallMutex) { throw '另一更新进程已经占用安装目录。' }

                    $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($readyEventName)
                    $failedEvent = [System.Threading.EventWaitHandle]::OpenExisting($failedEventName)

                    Add-Type -AssemblyName PresentationFramework
                    $window = [System.Windows.Window]::new()
                    $window.Title = 'BlueOath 启动器更新'
                    $window.Width = 440
                    $window.Height = 150
                    $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
                    $window.ResizeMode = [System.Windows.ResizeMode]::NoResize
                    $window.ShowInTaskbar = $true
                    $window.Add_Closing({
                        param($sender, $eventArgs)
                        if (-not $script:allowWindowClose) { $eventArgs.Cancel = $true }
                    })

                    $statusText = [System.Windows.Controls.TextBlock]::new()
                    $statusText.Text = '正在校验更新包...'
                    $statusText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 14)
                    $statusText.TextWrapping = [System.Windows.TextWrapping]::Wrap

                    $progress = [System.Windows.Controls.ProgressBar]::new()
                    $progress.Height = 18
                    $progress.IsIndeterminate = $true

                    $panel = [System.Windows.Controls.StackPanel]::new()
                    $panel.Margin = [System.Windows.Thickness]::new(24)
                    [void]$panel.Children.Add($statusText)
                    [void]$panel.Children.Add($progress)
                    $window.Content = $panel
                    $window.Show()
                    Pump-UpdateWindow

                    $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ('blueoath-launcher-update-' + [System.Guid]::NewGuid())
                    New-Item -ItemType Directory -Path $workDir | Out-Null
                    Set-UpdateStatus '正在解压并校验更新包，请勿重新打开启动器...'
                    Expand-Archive -LiteralPath $zipPath -DestinationPath $workDir -Force
                    $stagedExe = Join-Path $workDir $exeName
                    if (-not (Test-Path -LiteralPath $stagedExe -PathType Leaf))
                    {
                        throw "更新包缺少启动器文件：$exeName"
                    }

                    [void]$readyEvent.Set()
                    $readySignaled = $true
                    Set-UpdateStatus '更新包已就绪，正在等待旧启动器退出...'

                    while ($launcherPid -gt 0)
                    {
                        $running = Get-Process -Id $launcherPid -ErrorAction SilentlyContinue
                        if ($null -eq $running) { break }
                        Pump-UpdateWindow
                        Start-Sleep -Milliseconds 200
                    }
                    $launcherExited = $true

                    Set-UpdateStatus '正在确认启动器文件已经释放...'
                    $launcherPath = [System.IO.Path]::GetFullPath((Join-Path $rootDir $exeName))
                    $launcherProcessName = [System.IO.Path]::GetFileNameWithoutExtension($exeName)
                    $releaseDeadline = [DateTime]::UtcNow.AddSeconds(30)
                    while ($true)
                    {
                        $blockingLaunchers = @(
                            Get-Process -Name $launcherProcessName -ErrorAction SilentlyContinue |
                                Where-Object {
                                    try
                                    {
                                        $_.Id -ne $launcherPid -and
                                            [string]::Equals(
                                                [System.IO.Path]::GetFullPath($_.Path),
                                                $launcherPath,
                                                [System.StringComparison]::OrdinalIgnoreCase)
                                    }
                                    catch
                                    {
                                        $false
                                    }
                                })
                        if ($blockingLaunchers.Count -eq 0) { break }
                        if ([DateTime]::UtcNow -ge $releaseDeadline)
                        {
                            throw '仍有启动器进程占用安装文件，无法安全覆盖更新。'
                        }
                        Pump-UpdateWindow
                        Start-Sleep -Milliseconds 200
                    }

                    $copied = $false
                    for ($attempt = 1; $attempt -le 5; $attempt++)
                    {
                        try
                        {
                            Set-UpdateStatus "正在覆盖安装更新（第 $attempt 次尝试）..."
                            Get-ChildItem -LiteralPath $workDir -Force |
                                Copy-Item -Destination $rootDir -Recurse -Force
                            $copied = $true
                            break
                        }
                        catch
                        {
                            if ($attempt -ge 5) { throw }
                            Set-UpdateStatus '部分文件暂时被占用，稍后自动重试...'
                            Start-Sleep -Seconds 1
                        }
                    }
                    if (-not $copied) { throw '覆盖安装未完成。' }

                    Set-UpdateStatus '更新安装完成，正在重新启动...'
                    Remove-Item -LiteralPath $errorLog -Force -ErrorAction SilentlyContinue
                    $updateSucceeded = $true
                    Pump-UpdateWindow
                    Start-Sleep -Milliseconds 500
                }
                catch
                {
                    $errorMessage = $_.Exception.ToString()
                    try
                    {
                        Set-Content -LiteralPath $errorLog -Encoding UTF8 -Value $errorMessage
                    }
                    catch { }

                    if (-not $readySignaled -and $null -ne $failedEvent)
                    {
                        [void]$failedEvent.Set()
                    }
                    elseif ($readySignaled)
                    {
                        [void][System.Windows.MessageBox]::Show(
                            "更新安装失败。请重新打开启动器后重试。`n`n详细信息：$errorLog",
                            'BlueOath 启动器更新失败',
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Error)
                    }
                }
                finally
                {
                    if ($null -ne $workDir -and (Test-Path -LiteralPath $workDir))
                    {
                        Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    if ($updateSucceeded)
                    {
                        $updateDir = Split-Path -Parent $zipPath
                        Remove-Item -LiteralPath $updateDir -Recurse -Force -ErrorAction SilentlyContinue
                    }

                    $script:allowWindowClose = $true
                    if ($null -ne $window) { $window.Close() }
                    if ($null -ne $readyEvent) { $readyEvent.Dispose() }
                    if ($null -ne $failedEvent) { $failedEvent.Dispose() }
                    if ($ownsInstallMutex) { $installMutex.ReleaseMutex() }
                    if ($null -ne $installMutex) { $installMutex.Dispose() }
                }

                if ($updateSucceeded)
                {
                    try
                    {
                        $newExe = Join-Path $rootDir $exeName
                        Start-Process -FilePath $newExe -WorkingDirectory $rootDir
                    }
                    catch
                    {
                        try
                        {
                            Set-Content -LiteralPath $errorLog -Encoding UTF8 -Value $_.Exception.ToString()
                        }
                        catch { }
                        [void][System.Windows.MessageBox]::Show(
                            "更新已安装，但启动器未能自动重启。请手动打开启动器。`n`n详细信息：$errorLog",
                            'BlueOath 启动器更新',
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Warning)
                    }
                }

                Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
                """;

            var updateDir = Path.Combine(Path.GetTempPath(), "BlueOathLauncherUpdate", "scripts");
            Directory.CreateDirectory(updateDir);
            var scriptPath = Path.Combine(updateDir, $"apply-update-{Guid.NewGuid():N}.ps1");
            // Windows PowerShell 5.1 treats UTF-8 without a BOM as the active
            // ANSI code page. The generated updater contains localized status
            // text, so it must carry a BOM to remain parseable on every locale.
            File.WriteAllText(scriptPath, script, new UTF8Encoding(true));
            return scriptPath;
        }
        catch
        {
            return null;
        }
    }

    private bool LaunchUpdateAndExit(string scriptPath, string packagePath, string executableName)
    {
        var updateMutexName = LauncherExecutionGuard.GetUpdateMutexName(_rootDir);
        var readyEventName = $"Local\\BlueOath.Launcher.UpdateReady.{Guid.NewGuid():N}";
        var failedEventName = $"Local\\BlueOath.Launcher.UpdateFailed.{Guid.NewGuid():N}";
        using var readyEvent = new EventWaitHandle(false, EventResetMode.ManualReset, readyEventName);
        using var failedEvent = new EventWaitHandle(false, EventResetMode.ManualReset, failedEventName);

        var psi = new ProcessStartInfo("powershell.exe")
        {
            UseShellExecute = false,
            CreateNoWindow = true
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-Sta");
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
        psi.ArgumentList.Add("-updateMutexName");
        psi.ArgumentList.Add(updateMutexName);
        psi.ArgumentList.Add("-readyEventName");
        psi.ArgumentList.Add(readyEventName);
        psi.ArgumentList.Add("-failedEventName");
        psi.ArgumentList.Add(failedEventName);

        Process? updater;
        try
        {
            updater = Process.Start(psi);
        }
        catch
        {
            return false;
        }

        if (updater is null)
            return false;

        using (updater)
        {
            var deadline = DateTime.UtcNow.AddMinutes(5);
            while (true)
            {
                var handshake = WaitHandle.WaitAny(
                    [readyEvent, failedEvent],
                    TimeSpan.FromMilliseconds(250));
                if (handshake == 0)
                {
                    Application.Current.Shutdown();
                    return true;
                }

                if (handshake == 1 || updater.HasExited)
                    return false;

                if (DateTime.UtcNow < deadline)
                    continue;

                try
                {
                    updater.Kill(entireProcessTree: true);
                }
                catch
                {
                    // The updater may have exited between HasExited and Kill.
                }
                return false;
            }
        }
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
