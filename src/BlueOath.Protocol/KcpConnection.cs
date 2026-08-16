namespace BlueOath.Protocol;

public sealed class KcpConnection
{
    private const int RtoInitial = 200;
    private const int RtoMax = 5000;
    private const int DeadLink = 20;
    private const int MaxPayload = 1400;
    private const ushort Window = 128;

    private readonly uint _conv;
    private readonly Dictionary<uint, PendingSend> _sendBuffer = [];
    private readonly Dictionary<uint, KcpPacket> _receiveBuffer = [];
    private readonly KcpReassembler _reassembler = new();
    private readonly List<uint> _ackList = [];
    private readonly object _sync = new();
    private uint _sendNext;
    private uint _sendUna;
    private uint _receiveNext;
    private uint _rto = RtoInitial;
    private uint _lastReceivedTs;
    private bool _dead;

    public KcpConnection(uint conv) => _conv = conv;

    public uint Conv => _conv;
    public bool Dead { get { lock (_sync) return _dead; } }
    public int PendingSendCount { get { lock (_sync) return _sendBuffer.Count; } }

    public IReadOnlyList<byte[]> Input(KcpPacket packet, uint nowMs)
    {
        lock (_sync)
        {
            if (_dead || packet.Conv != _conv)
                return [];

            if (packet.Command == KcpCommand.Ack)
            {
                OnAck(packet);
                return [];
            }

            if (packet.Command == KcpCommand.Push)
                return OnPush(packet);

            return [];
        }
    }

    public void Send(ReadOnlySpan<byte> message, uint nowMs)
    {
        lock (_sync)
        {
            if (_dead)
                return;
            var fragments = KcpCodec.FragmentPushMessage(
                _conv, _sendNext, nowMs, Window, _receiveNext, message, MaxPayload);
            for (var i = 0; i < fragments.Count; i++)
                _sendBuffer[_sendNext + (uint)i] = new PendingSend(fragments[i]);
            _sendNext += (uint)fragments.Count;
        }
    }

    public IReadOnlyList<byte[]> Flush(uint nowMs)
    {
        lock (_sync)
        {
            var output = new List<byte[]>();

            if (_ackList.Count > 0)
            {
                output.Add(BuildAck());
                _ackList.Clear();
            }

            foreach (var (sn, pending) in _sendBuffer)
            {
                if (pending.SentAt == uint.MaxValue)
                {
                    pending.SentAt = nowMs;
                    output.Add(pending.Data);
                    continue;
                }

                if (nowMs - pending.SentAt < _rto)
                    continue;

                pending.SentAt = nowMs;
                pending.RetransmitCount++;
                output.Add(pending.Data);
                if (pending.RetransmitCount >= DeadLink)
                {
                    _dead = true;
                    break;
                }
                _rto = Math.Min(_rto * 2, (uint)RtoMax);
            }

            return output;
        }
    }

    private IReadOnlyList<byte[]> OnPush(KcpPacket packet)
    {
        _lastReceivedTs = packet.Timestamp;

        if (packet.SequenceNumber < _receiveNext)
        {
            _ackList.Add(packet.SequenceNumber);
            return [];
        }

        if (!_receiveBuffer.TryAdd(packet.SequenceNumber, packet))
            return [];

        var messages = new List<byte[]>();
        while (_receiveBuffer.Remove(_receiveNext, out var next))
        {
            if (_reassembler.TryReassemble(next, out var message))
                messages.Add(message);
            _ackList.Add(next.SequenceNumber);
            _receiveNext++;
        }
        return messages;
    }

    private void OnAck(KcpPacket packet)
    {
        _sendUna = Math.Max(_sendUna, packet.Unacknowledged);
        foreach (var sn in _sendBuffer.Keys.Where(sn => sn < _sendUna).ToList())
            _sendBuffer.Remove(sn);
        if (_sendBuffer.Count == 0)
            _rto = RtoInitial;
    }

    private byte[] BuildAck()
    {
        var ackedSequence = _receiveNext > 0 ? _receiveNext - 1 : 0;
        var packet = new KcpPacket(_conv, KcpCommand.Ack, 0, Window,
            _lastReceivedTs, ackedSequence, _receiveNext, []);
        return KcpCodec.Encode(packet);
    }

    private sealed class PendingSend(byte[] data)
    {
        public byte[] Data { get; } = data;
        public uint SentAt { get; set; } = uint.MaxValue;
        public uint RetransmitCount { get; set; }
    }
}
