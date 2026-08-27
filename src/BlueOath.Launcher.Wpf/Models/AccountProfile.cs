using System.ComponentModel;
using System.Text.Json.Serialization;

namespace BlueOath.Launcher.Wpf.Models;

public sealed class AccountProfile : INotifyPropertyChanged
{
    private string _name = "";

    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("name")]
    public string Name
    {
        get => _name;
        set
        {
            if (_name == value) return;
            _name = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Name)));
        }
    }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.Now;

    public event PropertyChangedEventHandler? PropertyChanged;
}
