using System.Collections.Generic;
using System.IO;
using System.Windows;
using System.Threading.Tasks;
using System.Windows.Input;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public class LaunchViewModel : ViewModelBase
{
    private readonly ProcessManager _processManager;
    private readonly MainViewModel _mainViewModel;
    private readonly SettingsService _settingsService;

    private List<Announcement> _announcements = new();
    private Announcement? _selectedAnnouncement;
    private bool _isLaunching;
    private string _statusText = "就绪";
    private LaunchConfig _config = new();

    public List<Announcement> Announcements
    {
        get => _announcements;
        set => SetProperty(ref _announcements, value);
    }

    public Announcement? SelectedAnnouncement
    {
        get => _selectedAnnouncement;
        set => SetProperty(ref _selectedAnnouncement, value);
    }

    public bool IsLaunching
    {
        get => _isLaunching;
        set => SetProperty(ref _isLaunching, value);
    }

    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public LaunchConfig Config
    {
        get => _config;
        set => SetProperty(ref _config, value);
    }

    public int ServerPort
    {
        get => _config.ServerPort;
        set { _config.ServerPort = value; OnPropertyChanged(); }
    }

    public ICommand LaunchCommand { get; }
    public ICommand DebugLaunchCommand { get; }

    public LaunchViewModel(ProcessManager processManager, MainViewModel mainViewModel, SettingsService settingsService)
    {
        _processManager = processManager;
        _mainViewModel = mainViewModel;
        _settingsService = settingsService;

        LaunchCommand = new RelayCommand(async () => await Launch(true));
        DebugLaunchCommand = new RelayCommand(async () => await Launch(false));

        _processManager.StageChanged += (s, stage) =>
        {
            StatusText = stage switch
            {
                ProcessStage.Idle => "就绪",
                ProcessStage.CleaningUp => "正在清理...",
                ProcessStage.GeneratingTls => "正在生成 TLS 证书...",
                ProcessStage.StartingServer => "正在启动服务器...",
                ProcessStage.StartingProxy => "正在启动代理...",
                ProcessStage.InjectingGame => "正在注入游戏...",
                ProcessStage.Running => "运行中",
                ProcessStage.Stopping => "正在停止...",
                ProcessStage.Failed => "失败",
                _ => stage.ToString()
            };
            IsLaunching = _processManager.IsRunning;
        };
    }

    public void LoadAnnouncements(List<Announcement> announcements)
    {
        Announcements = announcements;
        if (announcements.Count > 0)
            SelectedAnnouncement = announcements[0];
    }

    private bool TryResolveGameClientPath()
    {
        var settings = _settingsService.Load();
        var clientDir = _processManager.ResolvePath(settings.GameClientPath);
        string exe = settings.Region == "cn" ? "clsy.exe" : "blueoath.exe";
        string exePath = Path.Combine(clientDir, exe);
        if (File.Exists(exePath)) return true;

        var result = MessageBox.Show("游戏客户端路径未设置或无效，是否现在选择？", "路径缺失",
            MessageBoxButton.YesNo, MessageBoxImage.Question);
        if (result != MessageBoxResult.Yes) return false;

        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Title = "选择游戏客户端 (blueoath.exe 或 clsy.exe)",
            Filter = "游戏客户端|blueoath.exe;clsy.exe",
            CheckFileExists = true
        };
        if (dialog.ShowDialog() != true) return false;

        var selectedExe = dialog.FileName;
        var selectedDir = Path.GetDirectoryName(selectedExe) ?? "";
        settings.GameClientPath = _processManager.MakeRelativePath(selectedDir);
        if (Path.GetFileName(selectedExe).StartsWith("clsy", StringComparison.OrdinalIgnoreCase))
            settings.Region = "cn";
        _settingsService.Save(settings);
        _processManager.UpdateSettings(settings);
        return true;
    }

    private async Task Launch(bool startServer)
    {
        if (IsLaunching) return;

        if (!TryResolveGameClientPath()) return;

        var validationError = _processManager.ValidatePaths(_config, startServer);
        if (validationError is not null)
        {
            MessageBox.Show(validationError, "路径验证失败", MessageBoxButton.OK, MessageBoxImage.Warning);
            return;
        }

        IsLaunching = true;
        _mainViewModel.NavigateTo(1);

        await _processManager.LaunchAsync(_config, startServer);

        if (_processManager.Stage == ProcessStage.Failed)
        {
            var error = _processManager.LastError;
            if (!string.IsNullOrEmpty(error))
            {
                MessageBox.Show($"启动失败: {error}", "启动失败", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        IsLaunching = false;
    }
}