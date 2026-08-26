using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;

namespace BlueOath.Launcher.Wpf.Models;

public class SettingsConfig : INotifyPropertyChanged
{
    private string _gameClientPath = "";
    private string _serverDllPath = "";
    private string _pythonPath = "python";
    private string _injectorPath = "";
    private string _payloadPath = "";
    private string _proxyScriptPath = "";
    private string _dataRoot = "";
    private string _baselinePath = "";
    private string _region = "jp";
    private string _updateManifestUrl = "";
    private bool _autoUpdateEnabled = true;
    private int _serverPort = 0;
    private int _gameLoginPort = 7201;
    private int _gmPort = 9780;
    private bool _skipBuild = true;
    private bool _keepLog = false;

    [JsonPropertyName("gameClientPath")]
    public string GameClientPath
    {
        get => _gameClientPath;
        set { _gameClientPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("serverDllPath")]
    public string ServerDllPath
    {
        get => _serverDllPath;
        set { _serverDllPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("pythonPath")]
    public string PythonPath
    {
        get => _pythonPath;
        set { _pythonPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("injectorPath")]
    public string InjectorPath
    {
        get => _injectorPath;
        set { _injectorPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("payloadPath")]
    public string PayloadPath
    {
        get => _payloadPath;
        set { _payloadPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("proxyScriptPath")]
    public string ProxyScriptPath
    {
        get => _proxyScriptPath;
        set { _proxyScriptPath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("dataRoot")]
    public string DataRoot
    {
        get => _dataRoot;
        set { _dataRoot = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("baselinePath")]
    public string BaselinePath
    {
        get => _baselinePath;
        set { _baselinePath = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("updateManifestUrl")]
    public string UpdateManifestUrl
    {
        get => _updateManifestUrl;
        set { _updateManifestUrl = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("autoUpdateEnabled")]
    public bool AutoUpdateEnabled
    {
        get => _autoUpdateEnabled;
        set { _autoUpdateEnabled = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("region")]
    public string Region
    {
        get => _region;
        set { _region = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("serverPort")]
    public int ServerPort
    {
        get => _serverPort;
        set { _serverPort = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("gameLoginPort")]
    public int GameLoginPort
    {
        get => _gameLoginPort;
        set { _gameLoginPort = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("gmPort")]
    public int GmPort
    {
        get => _gmPort;
        set { _gmPort = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("skipBuild")]
    public bool SkipBuild
    {
        get => _skipBuild;
        set { _skipBuild = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("keepLog")]
    public bool KeepLog
    {
        get => _keepLog;
        set { _keepLog = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
