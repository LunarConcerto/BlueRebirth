using System.Buffers.Binary;

namespace BlueOath.Protocol;

/// <summary>
/// The game's NetSocket transport framing (outer layer): a 5-byte header
/// [payload-length (4 bytes, big-endian)][type (1 byte)], optionally followed by a
/// 16-byte MD5 hash (only when type == TypeDataWithHash), then the payload.
/// </summary>
public static class NetSocketFrameCodec
{
    public const int HeaderLength = 5;
    public const int HashLength = 16;
    public const byte TypeData = 0;
    public const byte TypeDataWithHash = 1;
    public const byte TypePing = 2;

    public static async Task<(byte Type, byte[] Payload)?> ReadAsync(Stream stream, CancellationToken ct = default)
    {
        var header = new byte[HeaderLength];
        if (!await ReadExactAsync(stream, header, ct)) return null;
        var length = BinaryPrimitives.ReadInt32BigEndian(header);
        var type = header[4];
        if (length is < 0 or > 4 * 1024 * 1024)
            throw new InvalidDataException("Invalid NetSocket frame length");
        if (type == TypeDataWithHash)
        {
            var hash = new byte[HashLength];
            if (!await ReadExactAsync(stream, hash, ct))
                throw new EndOfStreamException("Truncated NetSocket hash");
        }
        var payload = new byte[length];
        if (length > 0 && !await ReadExactAsync(stream, payload, ct))
            throw new EndOfStreamException("Truncated NetSocket payload");
        return (type, payload);
    }

    public static async Task WriteAsync(Stream stream, ReadOnlyMemory<byte> payload, byte type = TypeData, CancellationToken ct = default)
    {
        var header = new byte[HeaderLength];
        BinaryPrimitives.WriteInt32BigEndian(header, payload.Length);
        header[4] = type;
        await stream.WriteAsync(header, ct);
        await stream.WriteAsync(payload, ct);
        await stream.FlushAsync(ct);
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
