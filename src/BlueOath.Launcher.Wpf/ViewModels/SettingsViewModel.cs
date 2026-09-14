using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public class SettingsViewModel : ViewModelBase, INavigationAware
{
    private readonly SettingsService _settingsService;
    private readonly MainViewModel _mainViewModel;
    private SettingsConfig _settings;
    private string _validationMessage = "";
    private string _updateStatus = "尚未检测更新";
    private Brush _updateStatusBrush = Brushes.Gray;
    private bool _isEditing;

    public SettingsConfig Settings
    {
        get => _settings;
        set => SetProperty(ref _settings, value);
    }

    public bool IsEditing
    {
        get => _isEditing;
        set
        {
            if (SetProperty(ref _isEditing, value))
            {
                OnPropertyChanged(nameof(EditStateText));
                OnPropertyChanged(nameof(ShowUnlockButton));
                System.Windows.Input.CommandManager.InvalidateRequerySuggested();
            }
        }
    }

    public bool ShowUnlockButton => !IsEditing;

    public string EditStateText => IsEditing ? "当前处于可编辑状态，修改后请点击「保存设置」" : "设置已锁定，如需修改请点击「修改设置」";

    public string ValidationMessage
    {
        get => _validationMessage;
        set => SetProperty(ref _validationMessage, value);
    }

    public string UpdateStatus
    {
        get => _updateStatus;
        set => SetProperty(ref _updateStatus, value);
    }

    public Brush UpdateStatusBrush
    {
        get => _updateStatusBrush;
        set => SetProperty(ref _updateStatusBrush, value);
    }

    public string CurrentVersion => VersionInfo.Version;

    public ICommand SaveCommand { get; }
    public ICommand ResetCommand { get; }
    public ICommand UnlockCommand { get; }
    public ICommand BrowseGameClientCommand { get; }
    public ICommand BrowseServerDllCommand { get; }
    public ICommand BrowseInjectorCommand { get; }
    public ICommand BrowsePayloadCommand { get; }
    public ICommand BrowseProxyScriptCommand { get; }
    public ICommand BrowseDataRootCommand { get; }
    public ICommand BrowseBaselineCommand { get; }
    public ICommand BackCommand { get; }
    public ICommand CheckUpdateCommand { get; }

    public SettingsViewModel(SettingsService settingsService, MainViewModel mainViewModel, SettingsConfig settings)
    {
        _settingsService = settingsService;
        _mainViewModel = mainViewModel;
        _settings = settings;

        SaveCommand = new RelayCommand(Save, () => IsEditing);
        ResetCommand = new RelayCommand(Reset, () => IsEditing);
        UnlockCommand = new RelayCommand(Unlock, () => !IsEditing);
        BackCommand = new RelayCommand(() => _mainViewModel.NavigateTo(0));
        CheckUpdateCommand = new RelayCommand(async () => await CheckForUpdateAsync());

        BrowseGameClientCommand = new RelayCommand(() => BrowseFolder((s, v) => s.GameClientPath = v));
        BrowseServerDllCommand = new RelayCommand(() => BrowseFile("DLL 文件|*.dll", (s, v) => s.ServerDllPath = v));
        BrowseInjectorCommand = new RelayCommand(() => BrowseFile("EXE 文件|*.exe", (s, v) => s.InjectorPath = v));
        BrowsePayloadCommand = new RelayCommand(() => BrowseFile("DLL 文件|*.dll", (s, v) => s.PayloadPath = v));
        BrowseProxyScriptCommand = new RelayCommand(() => BrowseFile("Python 文件|*.py", (s, v) => s.ProxyScriptPath = v));
        BrowseDataRootCommand = new RelayCommand(() => BrowseFolder((s, v) => s.DataRoot = v));
        BrowseBaselineCommand = new RelayCommand(() => BrowseFile("JSON 文件|*.json", (s, v) => s.BaselinePath = v));
    }

    public void OnNavigatedTo()
    {
        // 每次进入设置页：丢弃未保存的修改，并重新锁定。
        var persisted = _settingsService.Load();
        _settings.CopyFrom(persisted);
        IsEditing = false;
        ValidationMessage = "";
    }

    private void Unlock()
    {
        var result = MessageBox.Show(
            "设置一般情况下不需要修改，已由程序自动配置好。请确认你完全了解这些配置的含义。然后点击确定进行修改。\n如果你不了解这些配置的含义，请点击取消来退出。",
            "修改设置确认",
            MessageBoxButton.OKCancel,
            MessageBoxImage.Warning);
        if (result == MessageBoxResult.OK)
        {
            IsEditing = true;
            ValidationMessage = "";
        }
    }

    private void Save()
    {
        _settingsService.Save(_settings);
        _mainViewModel.UpdateLaunchConfig(_settings);
        ValidationMessage = "设置已保存";
        IsEditing = false;
    }

    private async Task CheckForUpdateAsync()
    {
        if (string.IsNullOrWhiteSpace(Settings.UpdateManifestUrl))
        {
            UpdateStatus = "未配置更新地址";
            UpdateStatusBrush = Brushes.Red;
            return;
        }

        UpdateStatus = "正在检查更新...";
        try
        {
            var rootDir = AppContext.BaseDirectory;
            var executablePath = Path.Combine(rootDir, "BlueOath.Launcher.Wpf.exe");
            var updateService = new LauncherUpdateService(rootDir, Settings.UpdateManifestUrl, true);
            var result = await updateService.TrySelfUpdateAsync(Application.Current.MainWindow, executablePath);
            switch (result)
            {
                case UpdateCheckResult.UpToDate:
                    UpdateStatus = "当前已是最新版";
                    UpdateStatusBrush = Brushes.Gray;
                    break;
                case UpdateCheckResult.Updating:
                    UpdateStatus = "正在准备更新...";
                    UpdateStatusBrush = Brushes.Gray;
                    break;
                case UpdateCheckResult.Cancelled:
                    UpdateStatus = "已取消更新";
                    UpdateStatusBrush = Brushes.Gray;
                    break;
                default:
                    UpdateStatus = "无法连接更新服务";
                    UpdateStatusBrush = Brushes.Red;
                    break;
            }
        }
        catch (Exception ex)
        {
            UpdateStatus = $"更新检测失败：{ex.Message}";
            UpdateStatusBrush = Brushes.Red;
        }
    }

    private void Reset()
    {
        Settings = _settingsService.CreateDefaults();
        ValidationMessage = "已恢复默认设置";
    }

    private void BrowseFolder(Action<SettingsConfig, string> setter)
    {
        var dialog = new Microsoft.Win32.OpenFolderDialog();
        if (dialog.ShowDialog() == true)
        {
            setter(_settings, dialog.FolderName);
            OnPropertyChanged(nameof(Settings));
            ValidationMessage = "";
        }
    }

    private void BrowseFile(string filter, Action<SettingsConfig, string> setter)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = filter,
            CheckFileExists = true
        };
        if (dialog.ShowDialog() == true)
        {
            setter(_settings, dialog.FileName);
            OnPropertyChanged(nameof(Settings));
            ValidationMessage = "";
        }
    }
}
