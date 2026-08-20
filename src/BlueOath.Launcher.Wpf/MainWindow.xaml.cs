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
        var processManager = new ProcessManager(rootDir);

        var mainViewModel = new MainViewModel();

        var launchViewModel = new LaunchViewModel(processManager, mainViewModel);
        var announcementService = new AnnouncementService();
        launchViewModel.LoadAnnouncements(announcementService.LoadAnnouncements());

        var guardianViewModel = new GuardianViewModel(processManager, mainViewModel);

        mainViewModel.AddPage(launchViewModel);
        mainViewModel.AddPage(guardianViewModel);
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
        return Environment.CurrentDirectory;
    }
}