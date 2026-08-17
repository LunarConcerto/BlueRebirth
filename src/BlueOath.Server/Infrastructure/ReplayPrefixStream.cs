namespace BlueOath.Server.Infrastructure;

/// <summary>
/// 一个只读流包装器：先把已读取的头部字节「回放」给调用方，再继续透传底层流。
/// 用于主端口在嗅探前 8 字节之后，把这些字节重新交给 JSON 帧解码器读取。
/// </summary>
internal sealed class ReplayPrefixStream : Stream
{
    private readonly ReadOnlyMemory<byte> _prefix;
    private readonly Stream _inner;
    private int _offset;

    public ReplayPrefixStream(ReadOnlyMemory<byte> prefix, Stream inner)
    {
        _prefix = prefix;
        _inner = inner;
    }

    public override bool CanRead => true;
    public override bool CanSeek => false;
    public override bool CanWrite => true;
    public override long Length => throw new NotSupportedException();
    public override long Position
    {
        get => throw new NotSupportedException();
        set => throw new NotSupportedException();
    }

    public override void Flush() => _inner.Flush();
    public override Task FlushAsync(CancellationToken cancellationToken) => _inner.FlushAsync(cancellationToken);
    public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
    public override void SetLength(long value) => throw new NotSupportedException();

    public override int Read(byte[] buffer, int offset, int count)
    {
        if (TryReadPrefix(buffer.AsSpan(offset, count), out var copied))
            return copied;
        return _inner.Read(buffer, offset, count);
    }

    public override int Read(Span<byte> buffer)
    {
        if (TryReadPrefix(buffer, out var copied))
            return copied;
        return _inner.Read(buffer);
    }

    public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default)
    {
        if (TryReadPrefix(buffer.Span, out var copied))
            return copied;
        return await _inner.ReadAsync(buffer, cancellationToken);
    }

    public override void Write(byte[] buffer, int offset, int count) => _inner.Write(buffer, offset, count);
    public override void Write(ReadOnlySpan<byte> buffer) => _inner.Write(buffer);
    public override Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken) =>
        _inner.WriteAsync(buffer, offset, count, cancellationToken);
    public override ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default) =>
        _inner.WriteAsync(buffer, cancellationToken);

    protected override void Dispose(bool disposing)
    {
        if (disposing)
            _inner.Dispose();
        base.Dispose(disposing);
    }

    public override async ValueTask DisposeAsync()
    {
        await _inner.DisposeAsync();
        await base.DisposeAsync();
    }

    private bool TryReadPrefix(Span<byte> buffer, out int copied)
    {
        if (_offset >= _prefix.Length)
        {
            copied = 0;
            return false;
        }

        copied = Math.Min(buffer.Length, _prefix.Length - _offset);
        _prefix.Span[_offset..(_offset + copied)].CopyTo(buffer);
        _offset += copied;
        return true;
    }
}
