using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Windows.Input;
using BlueOath.Launcher.Wpf.Models;
using BlueOath.Launcher.Wpf.Services;

namespace BlueOath.Launcher.Wpf.ViewModels;

public class GuardianViewModel : ViewModelBase
{
    private readonly ProcessManager _processManager;
    private readonly MainViewModel _mainViewModel;

    private object _selectedLogTab = null!;
    private bool _isStopping;

    public ObservableCollection<ProcessStateInfo> ProcessStates { get; }
    public ObservableCollection<LogTab> LogTabs { get; } = new();
    public ObservableCollection<LogEntry> SystemLogs { get; }

    public object SelectedLogTab
    {
        get => _selectedLogTab;
        set => SetProperty(ref _selectedLogTab, value);
    }

    public bool IsStopping
    {
        get => _isStopping;
        set => SetProperty(ref _isStopping, value);
    }

    public ICommand StopCommand { get; }
    public ICommand BackToLaunchCommand { get; }

    public GuardianViewModel(ProcessManager processManager, MainViewModel mainViewModel)
    {
        _processManager = processManager;
        _mainViewModel = mainViewModel;
        ProcessStates = processManager.ProcessStates;
        SystemLogs = processManager.SystemLogs;

        StopCommand = new RelayCommand(async () => await StopAll());
        BackToLaunchCommand = new RelayCommand(() => _mainViewModel.NavigateTo(0));

        LogTabs.Clear();
        LogTabs.Add(new LogTab("服务器", processManager.ServerLogs));
        LogTabs.Add(new LogTab("代理", processManager.ProxyLogs));
        LogTabs.Add(new LogTab("客户端", processManager.ClientLogs));
        LogTabs.Add(new LogTab("系统", processManager.SystemLogs));

        SelectedLogTab = LogTabs[0];
    }

    private async Task StopAll()
    {
        if (IsStopping) return;
        IsStopping = true;
        await _processManager.StopAllAsync();
        IsStopping = false;
    }
}

public class LogTab
{
    public string Header { get; }
    public ObservableCollection<LogEntry> Entries { get; }

    public LogTab(string header, ObservableCollection<LogEntry> entries)
    {
        Header = header;
        Entries = entries;
    }
}