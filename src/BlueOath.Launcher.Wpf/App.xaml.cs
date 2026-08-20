using System.IO;
using System.Windows;

namespace BlueOath.Launcher.Wpf;

public partial class App : Application
{
    private static string FindRoot()
    {
        var current = new DirectoryInfo(AppContext.BaseDirectory);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "blueoath")))
                return current.FullName;
            current = current.Parent;
        }
        return Environment.CurrentDirectory;
    }
}