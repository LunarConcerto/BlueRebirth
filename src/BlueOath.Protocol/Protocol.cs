using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;

namespace BlueOath.Protocol;

public enum ClientRegion { Japan, China }

public sealed record ProtocolProfile(ClientRegion Region, string ClientVersion, int ProtocolVersion)
{
    public static ProtocolProfile Japan => new(ClientRegion.Japan, "1.4.0", 1);
    public static ProtocolProfile China => new(ClientRegion.China, "1.5.20", 1);
}

public sealed record ProtocolEnvelope(string Type, string RequestId, JsonElement Payload);

public static class MessageTypes
{
    public const string Login = "login";
    public const string State = "state";
    public const string SetFormation = "set_formation";
    public const string EnterStage = "enter_stage";
    public const string BattleResult = "battle_result";
    public const string Error = "error";
}

public static class FrameCodec
{
    public static async Task WriteAsync(Stream stream, object value, CancellationToken ct = default)
    {
        var bytes = JsonSerializer.SerializeToUtf8Bytes(value, JsonOptions.Default);
        if (bytes.Length > 4 * 1024 * 1024) throw new InvalidDataException("Frame is too large");
        var header = BitConverter.GetBytes(IPAddress.HostToNetworkOrder(bytes.Length));
        await stream.WriteAsync(header, ct);
        await stream.WriteAsync(bytes, ct);
        await stream.FlushAsync(ct);
    }

    public static async Task<JsonDocument?> ReadAsync(Stream stream, CancellationToken ct = default)
    {
        var header = new byte[4];
        if (!await ReadExactAsync(stream, header, ct)) return null;
        var length = IPAddress.NetworkToHostOrder(BitConverter.ToInt32(header));
        if (length is <= 0 or > 4 * 1024 * 1024) throw new InvalidDataException("Invalid frame length");
        var payload = new byte[length];
        if (!await ReadExactAsync(stream, payload, ct)) throw new EndOfStreamException();
        return JsonDocument.Parse(payload);
    }

    private static async Task<bool> ReadExactAsync(Stream stream, byte[] buffer, CancellationToken ct)
    {
        var offset = 0;
        while (offset < buffer.Length)
        {
            var read = await stream.ReadAsync(buffer.AsMemory(offset), ct);
            if (read == 0) return false;
            offset += read;
        }
        return true;
    }
}

public static class JsonOptions
{
    public static readonly JsonSerializerOptions Default = new(JsonSerializerDefaults.Web) { WriteIndented = false };
}
