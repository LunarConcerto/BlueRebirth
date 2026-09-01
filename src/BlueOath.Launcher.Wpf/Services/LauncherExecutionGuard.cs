using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

namespace BlueOath.Launcher.Wpf.Services;

/// <summary>
/// Prevents a second launcher from entering the installation directory while
/// the launcher or its external self-updater owns it.
/// </summary>
internal sealed class LauncherExecutionGuard : IDisposable
{
    private readonly Mutex _instanceMutex;
    private bool _ownsInstanceMutex;

    private LauncherExecutionGuard(Mutex instanceMutex)
    {
        _instanceMutex = instanceMutex;
        _ownsInstanceMutex = true;
    }

    internal static bool IsUpdateInProgress(string rootDir)
    {
        using var mutex = new Mutex(false, GetUpdateMutexName(rootDir));
        var acquired = false;
        try
        {
            try
            {
                acquired = mutex.WaitOne(0);
            }
            catch (AbandonedMutexException)
            {
                acquired = true;
            }

            return !acquired;
        }
        finally
        {
            if (acquired)
                mutex.ReleaseMutex();
        }
    }

    internal static bool TryAcquire(string rootDir, out LauncherExecutionGuard? guard)
    {
        var mutex = new Mutex(false, GetInstanceMutexName(rootDir));
        var acquired = false;
        try
        {
            try
            {
                acquired = mutex.WaitOne(0);
            }
            catch (AbandonedMutexException)
            {
                acquired = true;
            }

            if (!acquired)
            {
                mutex.Dispose();
                guard = null;
                return false;
            }

            guard = new LauncherExecutionGuard(mutex);
            return true;
        }
        catch
        {
            if (acquired)
                mutex.ReleaseMutex();
            mutex.Dispose();
            throw;
        }
    }

    internal static string GetUpdateMutexName(string rootDir)
        => $"Local\\BlueOath.Launcher.Update.{GetInstallationToken(rootDir)}";

    private static string GetInstanceMutexName(string rootDir)
        => $"Local\\BlueOath.Launcher.Instance.{GetInstallationToken(rootDir)}";

    private static string GetInstallationToken(string rootDir)
    {
        var normalized = Path.GetFullPath(rootDir)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
            .ToUpperInvariant();
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(normalized));
        return Convert.ToHexString(hash.AsSpan(0, 12));
    }

    public void Dispose()
    {
        if (_ownsInstanceMutex)
        {
            _instanceMutex.ReleaseMutex();
            _ownsInstanceMutex = false;
        }

        _instanceMutex.Dispose();
    }
}
