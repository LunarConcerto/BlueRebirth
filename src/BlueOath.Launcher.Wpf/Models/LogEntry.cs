using System;

namespace BlueOath.Launcher.Wpf.Models;

public class LogEntry
{
    public DateTime Timestamp { get; init; } = DateTime.Now;
    public string Source { get; init; } = "";
    public string Level { get; init; } = "info";
    public string Content { get; init; } = "";

    public string DisplayText => $"[{Timestamp:HH:mm:ss}] [{Level.ToUpperInvariant()}] {Content}";
}