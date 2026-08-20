namespace BlueOath.Launcher.Wpf.Models;

public class LaunchConfig
{
    public string Region { get; set; } = "jp";
    public int ServerPort { get; set; } = 0;
    public int GameLoginPort { get; set; } = 7201;
    public int GmPort { get; set; } = 9780;
    public int ProxyPort { get; set; } = 0;
    public bool SkipBuild { get; set; } = true;
    public bool KeepLog { get; set; } = false;
}