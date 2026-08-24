using System.Text;

namespace BlueOath.Protocol;

/// <summary>
/// 可变长 protobuf 写入包（writer）。把「MemoryStream + WriteVarint(key) + WriteVarint(value)」
/// 的两步写压缩为一次 <see cref="Write(int, ulong)"/>。key 传预编码 tag（如 0x08 = field1/varint、
/// 0x0A = field1/wire2），与手写 <c>WriteVarint(ms, key); WriteVarint(ms, value);</c> 字节完全一致。
/// 嵌套子消息通过 <c>Write(field, body.ToArray())</c> 先构建 body 再写入外层包。
/// </summary>
public sealed class ProtocolPackage
{
    private readonly MemoryStream _buffer = new();

    /// <summary>已写入的字节数。</summary>
    public int Length => (int)_buffer.Length;

    /// <summary>写 varint key + varint value（wire type 0）。</summary>
    public ProtocolPackage Write(int key, ulong value)
    {
        WriteVarint(_buffer, unchecked((uint)key));
        WriteVarint(_buffer, value);
        return this;
    }

    /// <summary>写 varint key + UTF-8 字符串（wire type 2）。空字符串也写 key + length(0)。</summary>
    public ProtocolPackage Write(int key, string value)
    {
        WriteVarint(_buffer, unchecked((uint)key));
        byte[] bytes = Encoding.UTF8.GetBytes(value);
        WriteVarint(_buffer, (uint)bytes.Length);
        _buffer.Write(bytes, 0, bytes.Length);
        return this;
    }

    /// <summary>写 varint key + length-delimited 字节（wire type 2），用于嵌入已编码的子消息 body。</summary>
    public ProtocolPackage Write(int key, ReadOnlySpan<byte> value)
    {
        WriteVarint(_buffer, unchecked((uint)key));
        WriteVarint(_buffer, (uint)value.Length);
        _buffer.Write(value);
        return this;
    }

    /// <summary>原样写入单个字节（零长度空子消息等）。</summary>
    public ProtocolPackage WriteRaw(byte value)
    {
        _buffer.WriteByte(value);
        return this;
    }

    /// <summary>原样写入字节序列。</summary>
    public ProtocolPackage WriteRaw(ReadOnlySpan<byte> value)
    {
        _buffer.Write(value);
        return this;
    }

    public byte[] ToArray() => _buffer.ToArray();

    /// <summary>把 ulong 编码为 protobuf varint 写入输出流。</summary>
    public static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80)
        {
            output.WriteByte((byte)(value | 0x80));
            value >>= 7;
        }
        output.WriteByte((byte)value);
    }
}
