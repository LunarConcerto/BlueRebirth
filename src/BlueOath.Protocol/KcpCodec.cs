using System.Buffers.Binary;

namespace BlueOath.Protocol;

public enum KcpCommand : byte
{
    Push = 81,
    Ack = 82,
    Wask = 83,
    Wins = 84,
}

public sealed record KcpPacket(
    uint Conv,
    KcpCommand Command,
    byte Fragment,
    ushort Window,
    uint Timestamp,
    uint SequenceNumber,
    uint Unacknowledged,
    byte[] Data);

public static class KcpCodec
{
    public const int HeaderLength = 24;
    public const int MaxDataLength = 16 * 1024 * 1024;

    public static byte[] Encode(KcpPacket packet)
    {
        if (packet.Data.Length > MaxDataLength)
            throw new ArgumentOutOfRangeException(nameof(packet), "KCP packet data is too large");
        var result = new byte[HeaderLength + packet.Data.Length];
        var span = result.AsSpan();
        BinaryPrimitives.WriteUInt32LittleEndian(span, packet.Conv);
        span[4] = (byte)packet.Command;
        span[5] = packet.Fragment;
        BinaryPrimitives.WriteUInt16LittleEndian(span[6..], packet.Window);
        BinaryPrimitives.WriteUInt32LittleEndian(span[8..], packet.Timestamp);
        BinaryPrimitives.WriteUInt32LittleEndian(span[12..], packet.SequenceNumber);
        BinaryPrimitives.WriteUInt32LittleEndian(span[16..], packet.Unacknowledged);
        BinaryPrimitives.WriteUInt32LittleEndian(span[20..], (uint)packet.Data.Length);
        packet.Data.CopyTo(result, HeaderLength);
        return result;
    }

    public static bool TryDecode(ReadOnlySpan<byte> buffer, out KcpPacket packet, out int consumed)
    {
        packet = null!;
        consumed = 0;
        if (buffer.Length < HeaderLength)
            return false;
        var length = BinaryPrimitives.ReadUInt32LittleEndian(buffer[20..24]);
        if (length > MaxDataLength || buffer.Length < HeaderLength + (int)length)
            return false;
        packet = new KcpPacket(
            BinaryPrimitives.ReadUInt32LittleEndian(buffer[0..4]),
            (KcpCommand)buffer[4],
            buffer[5],
            BinaryPrimitives.ReadUInt16LittleEndian(buffer[6..8]),
            BinaryPrimitives.ReadUInt32LittleEndian(buffer[8..12]),
            BinaryPrimitives.ReadUInt32LittleEndian(buffer[12..16]),
            BinaryPrimitives.ReadUInt32LittleEndian(buffer[16..20]),
            buffer.Slice(HeaderLength, (int)length).ToArray());
        consumed = HeaderLength + (int)length;
        return true;
    }

    public static IReadOnlyList<byte[]> FragmentPushMessage(
        uint conv, uint sequenceNumber, uint timestamp, ushort window, uint unacknowledged,
        ReadOnlySpan<byte> message, int maxPayload)
    {
        if (maxPayload <= 0)
            throw new ArgumentOutOfRangeException(nameof(maxPayload));
        var result = new List<byte[]>();
        if (message.Length == 0)
        {
            result.Add(Encode(new KcpPacket(conv, KcpCommand.Push, 0, window, timestamp, sequenceNumber, unacknowledged, [])));
            return result;
        }

        var totalFragments = (message.Length + maxPayload - 1) / maxPayload;
        var offset = 0;
        var fragmentIndex = 0;
        while (offset < message.Length)
        {
            var length = Math.Min(maxPayload, message.Length - offset);
            var remaining = totalFragments - 1 - fragmentIndex;
            var sequence = sequenceNumber + (uint)fragmentIndex;
            var data = message.Slice(offset, length).ToArray();
            result.Add(Encode(new KcpPacket(conv, KcpCommand.Push, (byte)remaining, window, timestamp, sequence, unacknowledged, data)));
            offset += length;
            fragmentIndex++;
        }
        return result;
    }
}

public sealed class KcpReassembler
{
    private readonly List<KcpPacket> _current = [];

    public bool TryReassemble(KcpPacket packet, out byte[] message)
    {
        message = [];
        if (packet.Command != KcpCommand.Push)
            return false;

        _current.Add(packet);

        if (packet.Fragment != 0)
            return false;

        var length = _current.Sum(p => p.Data.Length);
        message = new byte[length];
        var offset = 0;
        foreach (var fragment in _current)
        {
            fragment.Data.CopyTo(message, offset);
            offset += fragment.Data.Length;
        }
        _current.Clear();
        return true;
    }
}

public sealed class KcpStreamReader
{
    private byte[] _buffer = new byte[4096];
    private int _length;

    public IReadOnlyList<KcpPacket> Feed(ReadOnlySpan<byte> data)
    {
        if (_length + data.Length > _buffer.Length)
            Array.Resize(ref _buffer, Math.Max(_buffer.Length * 2, _length + data.Length));
        data.CopyTo(_buffer.AsSpan(_length));
        _length += data.Length;

        var packets = new List<KcpPacket>();
        var offset = 0;
        while (offset < _length &&
               KcpCodec.TryDecode(_buffer.AsSpan(offset, _length - offset), out var packet, out var consumed))
        {
            packets.Add(packet);
            offset += consumed;
        }

        if (offset > 0)
        {
            Buffer.BlockCopy(_buffer, offset, _buffer, 0, _length - offset);
            _length -= offset;
        }
        return packets;
    }
}
