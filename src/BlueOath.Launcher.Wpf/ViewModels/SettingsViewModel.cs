using System;
using System.Windows.Input;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public class SettingsViewModel : ViewModelBase
{
    private readonly SettingsService _settingsService;
    private readonly MainViewModel _mainViewModel;
    private SettingsConfig _settings;
    private string _validationMessage = "";

    public SettingsConfig Settings
    {
        get => _settings;
        set => SetProperty(ref _settings, value);
    }

    public string ValidationMessage
    {
        get => _validationMessage;
        set => SetProperty(ref _validationMessage, value);
    }

    public ICommand SaveCommand { get; }
    public ICommand ResetCommand { get; }
    public ICommand BrowseGameClientCommand { get; }
    public ICommand BrowseServerDllCommand { get; }
    public ICommand BrowseInjectorCommand { get; }
    public ICommand BrowsePayloadCommand { get; }
    public ICommand BrowseProxyScriptCommand { get; }
    public ICommand BrowseDataRootCommand { get; }
    public ICommand BrowseBaselineCommand { get; }
    public ICommand BackCommand { get; }

    public SettingsViewModel(SettingsService settingsService, MainViewModel mainViewModel)
    {
        _settingsService = settingsService;
        _mainViewModel = mainViewModel;
        _settings = settingsService.Load();

        SaveCommand = new RelayCommand(Save);
        ResetCommand = new RelayCommand(Reset);
        BackCommand = new RelayCommand(() => _mainViewModel.NavigateTo(0));

        BrowseGameClientCommand = new RelayCommand(() => BrowseFolder((s, v) => s.GameClientPath = v));
        BrowseServerDllCommand = new RelayCommand(() => BrowseFile("DLL 文件|*.dll", (s, v) => s.ServerDllPath = v));
        BrowseInjectorCommand = new RelayCommand(() => BrowseFile("EXE 文件|*.exe", (s, v) => s.InjectorPath = v));
        BrowsePayloadCommand = new RelayCommand(() => BrowseFile("DLL 文件|*.dll", (s, v) => s.PayloadPath = v));
        BrowseProxyScriptCommand = new RelayCommand(() => BrowseFile("Python 文件|*.py", (s, v) => s.ProxyScriptPath = v));
        BrowseDataRootCommand = new RelayCommand(() => BrowseFolder((s, v) => s.DataRoot = v));
        BrowseBaselineCommand = new RelayCommand(() => BrowseFile("JSON 文件|*.json", (s, v) => s.BaselinePath = v));
    }

    private void Save()
    {
        _settingsService.Save(_settings);
        _mainViewModel.UpdateLaunchConfig(_settings);
        ValidationMessage = "设置已保存";
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