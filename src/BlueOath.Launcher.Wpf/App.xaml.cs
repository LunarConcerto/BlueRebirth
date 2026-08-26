using System;
using System.Diagnostics;
using System.IO;
using System.Windows;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf;

public partial class App : Application
{
    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        ShutdownMode = ShutdownMode.OnExplicitShutdown;

        try
        {
            var rootDir = AppContext.BaseDirectory;
            var settingsService = new SettingsService();
            var settings = settingsService.Load();
            var localExecutable = Process.GetCurrentProcess().MainModule?.FileName
                ?? Path.Combine(rootDir, "BlueOath.Launcher.Wpf.exe");

            if (settings.AutoUpdateEnabled && !string.IsNullOrWhiteSpace(settings.UpdateManifestUrl))
            {
                var checkWindow = new LauncherUpdateService.UpdateStatusWindow();
                checkWindow.Show();

                try
                {
                    var updateService = new LauncherUpdateService(rootDir, settings.UpdateManifestUrl, settings.AutoUpdateEnabled);
                    var result = await updateService.TrySelfUpdateAsync(
                        owner: checkWindow,
                        localExecutable: localExecutable,
                        afterUpdatePrompt: checkWindow.Close);

                    if (result == UpdateCheckResult.Updating)
                        return;
                }
                finally
                {
                    if (checkWindow.IsVisible)
                        checkWindow.Close();
                }
            }

            var mainWindow = new MainWindow();
            MainWindow = mainWindow;
            ShutdownMode = ShutdownMode.OnMainWindowClose;
            mainWindow.Show();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"启动器初始化失败：{ex.Message}", "BlueOath 启动器", MessageBoxButton.OK, MessageBoxImage.Error);
            Shutdown(1);
        }
    }
}
