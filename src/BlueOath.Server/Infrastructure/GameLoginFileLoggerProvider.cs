using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

namespace BlueOath.Server.Infrastructure;

/// <summary>
/// 把游戏登录诊断信息追加写入服务器程序集旁的 <c>game-login.log</c> 文件。
/// 只有 <see cref="Category"/> 这个类别的日志才会落盘，其余类别拿到的是空日志器
/// （它们改用控制台日志器输出到 stderr）。用于替代旧版 <c>LogGameLogin</c> 文件输出。
/// </summary>
internal sealed class GameLoginFileLoggerProvider : ILoggerProvider
{
    /// <summary>游戏登录文件日志的日志类别名。</summary>
    public const string Category = "BlueOath.Server.GameLogin";

    private readonly object _lock = new();
    private readonly string _path = Path.Combine(AppContext.BaseDirectory, "game-login.log");

    public ILogger CreateLogger(string categoryName) =>
        categoryName == Category ? new GameLoginFileLogger(this) : NullLogger.Instance;

    public void Dispose()
    {
    }

    private void Write(string message)
    {
        lock (_lock)
        {
            File.AppendAllText(_path, message + Environment.NewLine);
        }
    }

    private sealed class GameLoginFileLogger(GameLoginFileLoggerProvider provider) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => logLevel != LogLevel.None;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel))
                return;

            var message = formatter(state, exception);
            if (exception is not null)
                message += Environment.NewLine + exception;
            provider.Write(message);
        }
    }
}
