using System.Net.Sockets;
using System.Text.Json;

namespace BlueOath.Protocol;

public sealed class LocalGameClient : IAsyncDisposable
{
    private readonly TcpClient _client = new();
    private int _requestNumber;
    public async Task ConnectAsync(string host, int port, CancellationToken ct = default) => await _client.ConnectAsync(host, port, ct);
    public async Task<T> SendAsync<T>(string type, object payload, CancellationToken ct = default)
    {
        if (!_client.Connected) throw new InvalidOperationException("Client is not connected");
        var id = Interlocked.Increment(ref _requestNumber).ToString();
        await FrameCodec.WriteAsync(_client.GetStream(), new ProtocolEnvelope(type, id, JsonSerializer.SerializeToElement(payload, JsonOptions.Default)), ct);
        using var document = await FrameCodec.ReadAsync(_client.GetStream(), ct) ?? throw new EndOfStreamException("Server closed connection");
        var response = document.RootElement;
        if (response.TryGetProperty("ok", out var ok) && !ok.GetBoolean()) throw new InvalidOperationException(response.TryGetProperty("error", out var error) ? error.GetString() : "Server request failed");
        return response.GetProperty("payload").Deserialize<T>(JsonOptions.Default) ?? throw new InvalidDataException("Invalid response payload");
    }
    public ValueTask DisposeAsync() { _client.Dispose(); return ValueTask.CompletedTask; }
}
