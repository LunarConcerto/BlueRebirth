using System.IO;
using System.Windows;
using BlueOath.Launcher.Wpf.Services;
using BlueOath.Launcher.Wpf.ViewModels;

namespace BlueOath.Launcher.Wpf;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Title = $"BlueOath Rebirth 启动器 v{VersionInfo.Version}";

        var rootDir = FindRoot();
        var settingsService = new SettingsService();
        var settings = settingsService.Load();
        var processManager = new ProcessManager(rootDir, settings);

        var mainViewModel = new MainViewModel();

        var launchViewModel = new LaunchViewModel(processManager, mainViewModel, settingsService);
        mainViewModel.RegisterLaunchViewModel(launchViewModel);
        var announcementService = new AnnouncementService();
        launchViewModel.LoadAnnouncements(announcementService.LoadAnnouncements());

        var guardianViewModel = new GuardianViewModel(processManager, mainViewModel);
        var settingsViewModel = new SettingsViewModel(settingsService, mainViewModel);

        mainViewModel.AddPage(launchViewModel);
        mainViewModel.AddPage(guardianViewModel);
        mainViewModel.AddPage(settingsViewModel);
        mainViewModel.SelectedPageIndex = 0;

        DataContext = mainViewModel;
    }

    private static string FindRoot()
    {
        var exeDir = AppContext.BaseDirectory;

        // 发布包：launcher-settings.json 在 EXE 同级，直接使用 EXE 目录
        if (File.Exists(Path.Combine(exeDir, "launcher-settings.json")))
            return exeDir;

        // 开发环境：向上查找含 blueoath 目录的项目根
        var current = new DirectoryInfo(exeDir);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "blueoath")))
                return current.FullName;
            current = current.Parent;
        }
        return exeDir;
    }
}