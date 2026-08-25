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

        var rootDir = FindRoot();
        var settingsService = new SettingsService();
        var settings = settingsService.Load();
        var processManager = new ProcessManager(rootDir, settings);

        var mainViewModel = new MainViewModel();

        var launchViewModel = new LaunchViewModel(processManager, mainViewModel);
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
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "blueoath")))
                return current.FullName;
            current = current.Parent;
        }
        return AppContext.BaseDirectory;
    }
}