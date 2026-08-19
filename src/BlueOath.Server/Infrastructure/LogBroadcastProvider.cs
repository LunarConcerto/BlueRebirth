using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace BlueOath.Server.Infrastructure;

/// <summary>
/// 日志广播器：捕获所有 ILogger 输出，缓冲最近 500 条，并支持 SSE 订阅端实时推送。
/// 供 GM WebUI 的日志流面板使用。
/// </summary>
internal sealed class LogBroadcastProvider : ILoggerProvider
{
    private readonly object _lock = new();
    private readonly List<LogEntry> _buffer = new();
    private readonly List<Action<LogEntry>> _subscribers = new();
    private const int MaxBuffer = 500;

    public IReadOnlyList<LogEntry> GetBuffer() { lock (_lock) return _buffer.ToList(); }

    public IDisposable Subscribe(Action<LogEntry> callback)
    {
        lock (_lock) _subscribers.Add(callback);
        return new Unsubscribe(this, callback);
    }

    public ILogger CreateLogger(string categoryName) => new BroadcastLogger(this);

    public void Dispose() { }

    internal void Post(LogEntry entry)
    {
        Action<LogEntry>[] subs;
        lock (_lock)
        {
            _buffer.Add(entry);
            if (_buffer.Count > MaxBuffer) _buffer.RemoveRange(0, _buffer.Count - MaxBuffer);
            subs = _subscribers.ToArray();
        }
        foreach (var s in subs)
        {
            try { s(entry); } catch { /* 客户端断开时忽略 */ }
        }
    }

    private sealed class Unsubscribe(LogBroadcastProvider owner, Action<LogEntry> callback) : IDisposable
    {
        public void Dispose() { lock (owner._lock) owner._subscribers.Remove(callback); }
    }

    private sealed class BroadcastLogger(LogBroadcastProvider provider) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            var message = formatter(state, exception);
            if (exception is not null)
                message += Environment.NewLine + exception;
            provider.Post(new LogEntry(logLevel.ToString().ToLowerInvariant(), message,
                DateTime.Now.ToString("HH:mm:ss")));
        }
    }
}

/// <summary>SSE 广播用的单条日志条目。</summary>
internal sealed record LogEntry(string Level, string Message, string Ts);