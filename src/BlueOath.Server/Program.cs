using System.Buffers.Binary;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Storage;

namespace BlueOath.Server;

internal static class Program
{
    private static int _kcpGameLoginPort;
    private static int _gameLoginPort;
    private static readonly object GameLoginLogLock = new();
    private static string? _gameLoginLogPath;

    private static void LogGameLogin(string message)
    {
        lock (GameLoginLogLock)
        {
            _gameLoginLogPath ??= Path.Combine(AppContext.BaseDirectory, "game-login.log");
            File.AppendAllText(_gameLoginLogPath, message + Environment.NewLine);
        }
    }

    public static async Task Main(string[] args)
    {
        var options = ServerOptions.Parse(args);

        if (options.CaptureRoot is not null)
            Directory.CreateDirectory(options.CaptureRoot);

        if (options.TlsMaterialOnly)
        {
            using var material = DevelopmentTlsMaterial.Create(
                options.TlsOutputRoot ?? Path.Combine(options.DataRoot, "_tls"));
            Console.WriteLine(JsonSerializer.Serialize(new
            {
                ready = true,
                tlsMaterial = true,
                rootCertificate = material.RootCertificatePath,
                leafCertificate = material.LeafCertificatePath,
                leafPem = material.LeafPemPath,
                leafKeyPem = material.LeafKeyPemPath
            }));
            return;
        }

        var repo = new SqliteGameRepository(options.DataRoot);
        var game = new GameService(repo, options.Profile);
        using var tls = options.EnableTls
            ? DevelopmentTlsMaterial.Create(options.TlsOutputRoot ?? Path.Combine(options.DataRoot, "_tls"))
            : null;

        var listener = new TcpListener(IPAddress.Loopback, options.Port);
        listener.Start();
        var actualPort = ((IPEndPoint)listener.LocalEndpoint).Port;
        var gameLoginListener = options.GameLoginPort is not null
            ? new TcpListener(IPAddress.Loopback, options.GameLoginPort.Value)
            : null;
        gameLoginListener?.Start();
        var actualGameLoginPort = gameLoginListener is null
            ? (int?)null
            : ((IPEndPoint)gameLoginListener.LocalEndpoint).Port;
        var kcpGameLoginListener = options.KcpGameLoginPort is not null
            ? new UdpClient(new IPEndPoint(IPAddress.Loopback, options.KcpGameLoginPort.Value))
            : null;
        var actualKcpGameLoginPort = kcpGameLoginListener is null
            ? (int?)null
            : ((IPEndPoint)kcpGameLoginListener.Client.LocalEndPoint!).Port;
        _kcpGameLoginPort = actualKcpGameLoginPort ?? 0;
        _gameLoginPort = actualGameLoginPort ?? 0;
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            ready = true,
            port = actualPort,
            gameLoginPort = actualGameLoginPort,
            kcpGameLoginPort = actualKcpGameLoginPort,
            region = options.Profile.Region.ToString(),
            version = options.Profile.ClientVersion,
            tls = tls is not null,
            rootCertificate = tls?.RootCertificatePath,
            leafCertificate = tls?.LeafCertificatePath,
            leafPem = tls?.LeafPemPath,
            leafKeyPem = tls?.LeafKeyPemPath,
            capture = options.CaptureRoot
        }));
        Console.Out.Flush();

        using var stop = new CancellationTokenSource();
        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            stop.Cancel();
        };

        var connectionId = 0;
        var gameLoginTask = gameLoginListener is null
            ? Task.CompletedTask
            : AcceptGameLoginAsync(gameLoginListener, repo, stop.Token);
        var kcpGameLoginTask = kcpGameLoginListener is null
            ? Task.CompletedTask
            : AcceptKcpGameLoginAsync(kcpGameLoginListener, repo, stop.Token);
        try
        {
            while (!stop.IsCancellationRequested)
            {
                var client = await listener.AcceptTcpClientAsync(stop.Token);
                _ = HandleAsync(client, Interlocked.Increment(ref connectionId), game, repo, tls,
                    options.CaptureRoot, stop.Token);
            }
        }
        catch (OperationCanceledException)
        {
        }
        finally
        {
            listener.Stop();
            gameLoginListener?.Stop();
            kcpGameLoginListener?.Dispose();
            try { await gameLoginTask; } catch (OperationCanceledException) { }
            try { await kcpGameLoginTask; } catch (OperationCanceledException) { }
        }
    }

    private static async Task AcceptGameLoginAsync(TcpListener listener, SqliteGameRepository repo,
        CancellationToken ct)
    {
        var connectionId = 0;
        while (!ct.IsCancellationRequested)
        {
            var client = await listener.AcceptTcpClientAsync(ct);
            _ = HandleGameLoginAsync(client, Interlocked.Increment(ref connectionId), repo, ct);
        }
    }

    private static async Task HandleGameLoginAsync(TcpClient client, int connectionId,
        SqliteGameRepository repo, CancellationToken ct)
    {
        using (client)
        {
            var remote = client.Client.RemoteEndPoint?.ToString() ?? "unknown";
            LogGameLogin($"game-login[{connectionId}] accepted remote={remote}");
            try
            {
                var stream = client.GetStream();
                while (!ct.IsCancellationRequested)
                {
                    var frame = await NetSocketFrameCodec.ReadAsync(stream, ct);
                    if (frame is null) break;
                    var (type, payload) = frame.Value;
                    LogGameLogin($"game-login[{connectionId}] netsocket type={type} len={payload.Length} " +
                        $"preview={Convert.ToHexString(payload.AsSpan(0, Math.Min(payload.Length, 16)))}");
                    if (type == NetSocketFrameCodec.TypePing)
                    {
                        await NetSocketFrameCodec.WriteAsync(stream, ReadOnlyMemory<byte>.Empty,
                            NetSocketFrameCodec.TypePing, ct);
                        continue;
                    }
                    if (payload.Length == 0) continue;
                    var (_, responsePayload) = BuildC2SResponse(payload);
                    if (responsePayload.Length == 0) continue;
                    await NetSocketFrameCodec.WriteAsync(stream, responsePayload, NetSocketFrameCodec.TypeData, ct);
                    LogGameLogin($"game-login[{connectionId}] response bytes={responsePayload.Length} " +
                        $"hex={Convert.ToHexString(responsePayload)}");
                    if (TMessageCodec.DecodeRequest(payload).Method == "user.GetUserInfo")
                    {
                        var now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());

                        var push = BuildUpdateUserInfoPush(now);
                        await NetSocketFrameCodec.WriteAsync(stream, push, NetSocketFrameCodec.TypeData, ct);
                        LogGameLogin($"game-login[{connectionId}] push user.UpdateUserInfo bytes={push.Length} " +
                            $"hex={Convert.ToHexString(push)}");

                        foreach (var extra in BuildSyncPushes(now))
                        {
                            await NetSocketFrameCodec.WriteAsync(stream, extra, NetSocketFrameCodec.TypeData, ct);
                            LogGameLogin($"game-login[{connectionId}] push sync bytes={extra.Length} " +
                                $"hex={Convert.ToHexString(extra)}");
                        }
                    }
                }
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
            }
            catch (Exception ex)
            {
                LogGameLogin($"game-login[{connectionId}] failed: {ex}");
            }
        }
    }

    private static async Task<byte[]> ReadGamePacketAsync(NetworkStream stream, CancellationToken ct)
    {
        var buffer = new byte[64 * 1024];
        var length = await stream.ReadAsync(buffer, ct);
        if (length == 0) return [];
        while (length < buffer.Length)
        {
            using var idle = CancellationTokenSource.CreateLinkedTokenSource(ct);
            idle.CancelAfter(100);
            try
            {
                var read = await stream.ReadAsync(buffer.AsMemory(length), idle.Token);
                if (read == 0) break;
                length += read;
            }
            catch (OperationCanceledException) when (!ct.IsCancellationRequested)
            {
                break;
            }
        }
        if (length == buffer.Length) throw new InvalidDataException("Game login packet is too large");
        return buffer.AsSpan(0, length).ToArray();
    }

    private sealed class KcpPeer(KcpConnection connection, IPEndPoint endpoint)
    {
        public KcpConnection Connection { get; } = connection;
        public IPEndPoint Endpoint { get; set; } = endpoint;
    }

    private static uint NowMs() => (uint)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    private static async Task AcceptKcpGameLoginAsync(UdpClient listener, SqliteGameRepository repo,
        CancellationToken ct)
    {
        var peers = new ConcurrentDictionary<uint, KcpPeer>();
        var flushTask = FlushKcpConnectionsAsync(listener, peers, ct);
        try
        {
            while (!ct.IsCancellationRequested)
            {
                var result = await listener.ReceiveAsync(ct);
                await HandleKcpDatagramAsync(listener, result.Buffer, result.RemoteEndPoint, peers, repo, ct);
            }
        }
        catch (OperationCanceledException)
        {
        }
        finally
        {
            await flushTask;
        }
    }

    private static async Task FlushKcpConnectionsAsync(UdpClient listener,
        ConcurrentDictionary<uint, KcpPeer> peers, CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(100, ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var now = NowMs();
            foreach (var peer in peers.Values)
            {
                foreach (var datagram in peer.Connection.Flush(now))
                {
                    try { await listener.SendAsync(datagram, peer.Endpoint, ct); }
                    catch (Exception) { break; }
                }
            }
        }
    }

    private static async Task HandleKcpDatagramAsync(UdpClient listener, byte[] datagram, IPEndPoint remote,
        ConcurrentDictionary<uint, KcpPeer> peers, SqliteGameRepository repo, CancellationToken ct)
    {
        try
        {
            var now = NowMs();
            KcpPeer? touched = null;
            var offset = 0;
            while (offset < datagram.Length &&
                   KcpCodec.TryDecode(datagram.AsSpan(offset), out var packet, out var consumed))
            {
                offset += consumed;
                var peer = peers.GetOrAdd(packet.Conv, conv => new KcpPeer(new KcpConnection(conv), remote));
                touched = peer;
                foreach (var message in peer.Connection.Input(packet, now))
                {
                    var response = await BuildLoginResponseAsync(message, repo, ct);
                    if (response.Length == 0)
                        continue;
                    peer.Connection.Send(response, now);
                }
            }

            if (touched is not null)
            {
                foreach (var output in touched.Connection.Flush(now))
                    await listener.SendAsync(output, touched.Endpoint, ct);
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"kcp-game-login failed from {remote}: {ex}");
        }
    }

    private static async Task<byte[]> BuildLoginResponseAsync(byte[] message, SqliteGameRepository repo,
        CancellationToken ct)
    {
        var frame = ClientGameWireCodec.DecodeClientRequest(message);
        Console.Error.WriteLine($"kcp-game-login decoded channel={frame.Channel} operation={frame.Operation} " +
            $"session={frame.SessionId} state={frame.State}");
        if (frame.Channel != ClientGameWireCodec.DefaultChannel)
            return [];
        var (operation, payload) = frame.Operation switch
        {
            GameOperationCodes.Login => await BuildLoginPayloadAsync(frame.Payload, repo, ct),
            GameOperationCodes.C2S => BuildC2SResponse(frame.Payload),
            _ => (0, Array.Empty<byte>())
        };
        return operation == 0 ? [] : ClientGameWireCodec.EncodeServerResponse((byte)operation, payload);
    }

    private static async Task<(int Operation, byte[] Payload)> BuildLoginPayloadAsync(byte[] payload,
        SqliteGameRepository repo, CancellationToken ct)
    {
        var request = GameLoginCodec.DecodeLogin(payload);
        var profileId = string.IsNullOrWhiteSpace(request.Pid) ? "local-player" : request.Pid;
        Console.Error.WriteLine($"game-login login pid={profileId}");
        if (await repo.LoadAsync(profileId, ct) is null)
            await repo.CreateAsync(profileId, profileId, ct);
        var response = new TRetLogin("0", profileId);
        return (GameOperationCodes.Login, GameLoginCodec.Encode(response));
    }

    private static (int Operation, byte[] Payload) BuildC2SResponse(ReadOnlySpan<byte> payload)
    {
        var request = TMessageCodec.DecodeRequest(payload);
        LogGameLogin($"game-login C2S method={request.Method} " +
            $"callback={request.CallbackHandler} argsLen={request.Args?.Length ?? 0}");
        var now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        byte[] ret = request.Method switch
        {
            "player.Login" => GameLoginCodec.Encode(new TRetLogin("ok", "1")),
            "player.GetUserList" => [],
            "player.CreateUser" => UserInfoCodec.Encode(new TUserInfo(1, "test1", 1, 1)),
            "user.UserLogin" => TMessageCodec.EncodeRetUserLogin("ok", "", 0),
            "user.GetUserInfo" => TMessageCodec.EncodeRetGetUserInfo(1, "test1", 1, 1),
            "GetSvrTime" => TMessageCodec.EncodeRetGetSvrTime(now, 0),
            _ => []
        };
        var response = new TResponse(Method: request.Method, Ret: ret,
            CallbackHandler: request.CallbackHandler, Time: checked((uint)now),
            Token: request.Token, Seq: 0, IsResponse: 1);
        return (GameOperationCodes.S2C, TMessageCodec.EncodeResponse(response));
    }

    private static byte[] BuildUpdateUserInfoPush(uint now)
    {
        // Server push (not a response) carrying the full user info, so the client's
        // UserService._UpdateUserInfo sets Data.userData (used by HomeEnvManager._CheckLevel
        // during home-scene selection). CallbackHandler/IsResponse stay 0 = push.
        var push = new TResponse(Method: "user.UpdateUserInfo",
            Ret: TMessageCodec.EncodeRetGetUserInfo(1, "test1", 1, 1), Time: now);
        return TMessageCodec.EncodeResponse(push);
    }

    /// <summary>
    /// Player-scope data the client's home stage reads before it has a chance to request it
    /// (the build/bathroom queues are otherwise requested only after the HomePage opens, but
    /// PushAllNotice iterates them during MainStage.StageEnter and errors on nil). Values are
    /// minimal/empty now; each record is the extension point for real data later.
    /// </summary>
    private static IEnumerable<byte[]> BuildSyncPushes(uint now)
    {
        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "build.BuildsInfo",
            Ret: PlayerDataCodec.Encode(new BuildsInfoRet(
                BuildingList: [new BuildFormula(EndTime: 0)])),
            Time: now));

        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "bathroom.BathroomInfo",
            Ret: PlayerDataCodec.Encode(new BathroomInfo(
                HeroList: [new BathHeroInfo(HeroId: 0, StartTime: 0)])),
            Time: now));

        // The secretary hero (kanban ship girl). HeroId must match userData.SecretaryId.
        // TemplateId=10210511 is config_parameter[17] ("main_ship_girl", default secretary);
        // Fashioning=1021051 is its default fashion (limit_type=0) -> ship_show "u_cl_oakland".
        yield return TMessageCodec.EncodeResponse(new TResponse(
            Method: "hero.UpdateHeroBagData",
            Ret: PlayerDataCodec.Encode(new HeroBag(
                HeroInfo: [new HeroGrid(HeroId: 1, TemplateId: 10210511, Lvl: 1, Fashioning: 1021051)],
                HeroBagSize: 100)),
            Time: now));
    }

    private static async Task HandleAsync(TcpClient client, int connectionId, GameService game,
        SqliteGameRepository repo, DevelopmentTlsMaterial? tls, string? captureRoot, CancellationToken ct)
    {
        using var ownedClient = client;
        try
        {
            await using var stream = await OpenSessionStreamAsync(client, tls, ct);
            var header = await ReadPrefixAsync(stream, 8, ct);
            if (header.Length == 0)
                return;

            await using var replay = new ReplayPrefixStream(header, stream);
            if (LooksLikeLocalFrame(header))
            {
                while (!ct.IsCancellationRequested)
                {
                    using var doc = await FrameCodec.ReadAsync(replay, ct);
                    if (doc is null)
                        break;

                    var env = doc.RootElement.Deserialize<ProtocolEnvelope>(JsonOptions.Default) ??
                        throw new InvalidDataException("Invalid request");
                    try
                    {
                        var response = await DispatchAsync(env, game, repo, ct);
                        await FrameCodec.WriteAsync(replay, new
                        {
                            ok = true,
                            requestId = env.RequestId,
                            type = env.Type,
                            payload = response
                        }, ct);
                    }
                    catch (Exception e)
                    {
                        await FrameCodec.WriteAsync(replay, new
                        {
                            ok = false,
                            requestId = env.RequestId,
                            type = MessageTypes.Error,
                            error = e.Message
                        }, ct);
                    }
                }

                return;
            }

            await CaptureOpaqueAsync(stream, header, connectionId, captureRoot, ct);
        }
        catch (Exception e)
        {
            Console.Error.WriteLine($"session[{connectionId}]: {e.Message}");
        }
    }

    private static async Task<Stream> OpenSessionStreamAsync(TcpClient client,
        DevelopmentTlsMaterial? tls, CancellationToken ct)
    {
        Stream stream = client.GetStream();
        if (tls is null)
            return stream;

        var ssl = new SslStream(stream, leaveInnerStreamOpen: false);
        await ssl.AuthenticateAsServerAsync(new SslServerAuthenticationOptions
        {
            ServerCertificate = tls.ServerCertificate,
            ClientCertificateRequired = false,
            EnabledSslProtocols = SslProtocols.Tls12,
            CertificateRevocationCheckMode = X509RevocationMode.NoCheck
        }, ct);
        return ssl;
    }

    private static async Task<byte[]> ReadPrefixAsync(Stream stream, int count, CancellationToken ct)
    {
        var buffer = new byte[count];
        var offset = 0;
        while (offset < buffer.Length)
        {
            var read = await stream.ReadAsync(buffer.AsMemory(offset), ct);
            if (read == 0)
                break;
            offset += read;
            if (offset >= 4)
                break;
        }

        return offset == buffer.Length ? buffer : buffer[..offset];
    }

    private static bool LooksLikeLocalFrame(ReadOnlySpan<byte> prefix)
    {
        if (prefix.Length < 4)
            return false;

        var length = BinaryPrimitives.ReadInt32BigEndian(prefix[..4]);
        return length is > 0 and <= 4 * 1024 * 1024;
    }

    private static async Task CaptureOpaqueAsync(Stream stream, ReadOnlyMemory<byte> prefix,
        int connectionId, string? captureRoot, CancellationToken ct)
    {
        using var payload = new MemoryStream();
        await payload.WriteAsync(prefix, ct);
        var buffer = new byte[8192];
        var sentContinue = false;

        while (payload.Length < 64 * 1024 && !ct.IsCancellationRequested)
        {
            if (TryGetCompleteHttpLength(payload.GetBuffer().AsSpan(0, (int)payload.Length), out var completeLength) &&
                payload.Length >= completeLength)
                break;

            var headerSpan = payload.GetBuffer().AsSpan(0, (int)payload.Length);
            if (!sentContinue && headerSpan.IndexOf("\r\n\r\n"u8) >= 0 &&
                headerSpan.IndexOf("Expect: 100-continue"u8) >= 0)
            {
                sentContinue = true;
                await stream.WriteAsync("HTTP/1.1 100 Continue\r\n\r\n"u8.ToArray(), ct);
            }

            using var idle = CancellationTokenSource.CreateLinkedTokenSource(ct);
            idle.CancelAfter(500);
            try
            {
                var remaining = (int)Math.Min(buffer.Length, 64 * 1024 - payload.Length);
                var read = await stream.ReadAsync(buffer.AsMemory(0, remaining), idle.Token);
                if (read == 0)
                    break;
                await payload.WriteAsync(buffer.AsMemory(0, read), ct);
            }
            catch (OperationCanceledException) when (!ct.IsCancellationRequested)
            {
                break;
            }
            catch (IOException)
            {
                break;
            }
        }

        var data = payload.ToArray();
        var analysis = AnalyzePayload(data);
        Console.Error.WriteLine($"capture[{connectionId}] kind={analysis.Kind} detail={analysis.Detail} host={analysis.ServerName}");

        if (captureRoot is not null)
        {
            Directory.CreateDirectory(captureRoot);
            var stem = $"{DateTimeOffset.UtcNow:yyyyMMdd-HHmmss.fff}-{connectionId:D4}";
            var binPath = Path.Combine(captureRoot, stem + ".bin");
            var jsonPath = Path.Combine(captureRoot, stem + ".json");
            await File.WriteAllBytesAsync(binPath, data, CancellationToken.None);
            await File.WriteAllTextAsync(jsonPath, JsonSerializer.Serialize(new
            {
                id = connectionId,
                byteCount = data.Length,
                analysis.Kind,
                analysis.Detail,
                analysis.ServerName,
                previewHex = Convert.ToHexString(data.AsSpan(0, Math.Min(data.Length, 64))),
                file = Path.GetFileName(binPath)
            }), Encoding.UTF8, CancellationToken.None);
        }

        if (analysis.Kind == "http")
        {
            var response = BuildBootstrapHttpResponse(analysis.Detail, analysis.ServerName);
            var bodyBytes = Encoding.UTF8.GetBytes(response.Body);
            var responseHeader = Encoding.ASCII.GetBytes(
                $"HTTP/1.1 {response.StatusCode} {response.ReasonPhrase}\r\n" +
                $"Content-Type: {response.ContentType}\r\n" +
                $"Content-Length: {bodyBytes.Length}\r\nConnection: close\r\n\r\n");
            await stream.WriteAsync(responseHeader, ct);
            await stream.WriteAsync(bodyBytes, ct);
            await stream.FlushAsync(ct);
        }
    }

    private static bool TryGetCompleteHttpLength(ReadOnlySpan<byte> data, out int length)
    {
        length = 0;
        if (!LooksLikeHttp(data))
            return false;

        var headerEnd = data.IndexOf("\r\n\r\n"u8);
        if (headerEnd < 0)
            return false;

        var bodyStart = headerEnd + 4;
        var headers = Encoding.ASCII.GetString(data[..headerEnd]);
        var contentLength = 0;
        foreach (var line in headers.Split("\r\n", StringSplitOptions.None))
        {
            if (!line.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase))
                continue;
            if (!int.TryParse(line[15..].Trim(), out contentLength) || contentLength < 0)
                return false;
            break;
        }

        length = bodyStart + contentLength;
        return true;
    }

    private static BootstrapHttpResponse BuildBootstrapHttpResponse(string requestLine, string? host = null)
    {
        // public IP probe returns a fake IP so the SDK sees a network.
        if (host is not null && (host.Contains("ifconfig.io", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("ipify.org", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("ipinfo.io", StringComparison.OrdinalIgnoreCase) ||
            host.Contains("3322.net", StringComparison.OrdinalIgnoreCase)))
            return new(200, "OK", "text/plain; charset=utf-8", "203.0.113.1");

        if (requestLine.Contains("/phone/switch/getstate", StringComparison.OrdinalIgnoreCase))
            // switch (event 27) dispatches errornu:"-1" when its JSON parse fails. Live sample
            // (catalog id=27) shows errornu as a STRING, while DNS_sw.state is asInt()'d as a
            // number. Match that: errornu as string "0", state as number 1.
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"DNS_sw\":{\"state\":1}}");

        if (requestLine.Contains("/sdk/gettime", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"time\":" + DateTimeOffset.UtcNow.ToUnixTimeSeconds() + "}");

        if (requestLine.Contains("/phone/applereview", StringComparison.OrdinalIgnoreCase))
            // Live response (catalog.json id=19) uses errornu as a STRING "0" and
            // applereview as a NUMBER. applereview=1 makes BabelTimeSDKManager.AppleReview
            // == IS_REVIEW, which routes HotPatchFacade into OnlyInitHotPatchManager
            // (local assetmap init, no getversion) and makes Lua LoginLogic:CheckUpdate
            // skip the update check entirely -> straight to login. This avoids the
            // getversion hot-patch download entirely for offline play.
            return new(200, "OK", "application/json; charset=utf-8", "{\"errornu\":\"0\",\"applereview\":1}");

        if (requestLine.Contains("/phone/getversion/", StringComparison.OrdinalIgnoreCase))
            // "script" branch deserializes into SDK.ScriptInfo (not PackageUpdateInfo):
            //   errornu, script=VersionInfo[], static_url, spare_static_url.
            // VersionInfo: pl/os/groupbase/gn/path/src_version/tar_version/updateType/file/
            //   total_size/sizes/forceExit/forceUpdate. OnCallBack uses tar_version as the
            //   server version; == local assetmap version "1.4.0" => NO_NEED_DOWNLOAD => FinishCheck.
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"script\":[{\"pl\":\"google_windows\",\"os\":\"android\"," +
                "\"groupbase\":\"\",\"gn\":\"jpshipgirl\",\"path\":\"\"," +
                "\"src_version\":\"1.4.0\",\"tar_version\":\"1.4.0\",\"updateType\":\"0\"," +
                "\"file\":\"\",\"total_size\":0,\"sizes\":[],\"forceExit\":0,\"forceUpdate\":0}]," +
                "\"static_url\":\"\",\"spare_static_url\":\"\"}");

        if (requestLine.Contains("/phone/getPlData/getPlData", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":0,\"errordesc\":\"\",\"networkCheck\":\"1\"," +
                "\"uuid\":\"00000000-0000-4000-8000-000000000001\",\"pid\":\"local-player\"," +
                "\"serverId\":\"jp\",\"pl\":\"google_windows\",\"os\":\"android\",\"gn\":\"jpshipgirl\"," +
                "\"sensorInfo\":\"\",\"localInfo\":\"\",\"timeZoneId\":\"\"," +
                "\"screenWidth\":\"1920\",\"screenHeight\":\"1080\",\"dangerWidth\":\"0\",\"strDeviceInfo\":\"\"}");

        if (requestLine.Contains("/login?", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":0,\"errordesc\":\"\",\"Pid\":\"local-player\",\"UID\":\"local-player\"," +
                "\"uid\":\"local-player\",\"uuid\":\"00000000-0000-4000-8000-000000000001\"," +
                "\"token\":\"local-token\",\"openid\":\"local-player\",\"ServerID\":\"jp\"," +
                "\"serverid\":\"jp\",\"newuser\":\"0\",\"qid\":\"1\",\"id\":\"1\"}");

        if (requestLine.Contains("/gethash", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _gameLoginPort > 0 ? _gameLoginPort : 7201;
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"pid\":\"local-player\",\"serverID\":\"game1\"," +
                "\"feignRoleId\":\"1\",\"qid\":\"1\",\"uuid\":\"00000000-0000-4000-8000-000000000001\"," +
                "\"offset\":\"0\",\"host\":\"127.0.0.1\",\"port\":" + gamePort + "}");
        }

        if (requestLine.Contains("/phone/serverlist/", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _gameLoginPort > 0 ? _gameLoginPort : 7201;
            // The SDK (new_sdk.dll getServerList) does not parse the response body; it
            // stores the raw JSON and the Lua side (platformmanager.getServiceListAndAllServiceNotic)
            // reads result.root.notice + result.root.item[]. The Lua compares result.errornu
            // against the STRING "0", so errornu must be a quoted "0" here (unlike the SDK's
            // own getPlData which asInt()'s it as a number).
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"root\":{\"notice\":{\"open\":0,\"desc\":\"\"},\"item\":[" +
                "{\"name\":\"BlueoathRebirth\",\"serverIndex\":1,\"new\":0,\"groupid\":\"1\",\"openDateTime\":\"20171109140000\"," +
                "\"status\":1,\"hot\":0,\"host\":\"127.0.0.1\",\"port\":" + gamePort + ",\"recommend_weight\":1}" +
                "]}}");
        }

        if (requestLine.Contains("/phone/loginrole/", StringComparison.OrdinalIgnoreCase))
        {
            var gamePort = _gameLoginPort > 0 ? _gameLoginPort : 7201;
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"root\":{\"role\":[" +
                "{\"name\":\"BlueoathRebirth\",\"serverIndex\":1,\"groupid\":\"1\",\"serverId\":\"1\"," +
                "\"host\":\"127.0.0.1\",\"port\":" + gamePort + ",\"status\":1,\"openDateTime\":\"20171109140000\"}" +
                "]}}");
        }

        if (requestLine.Contains("/phone/platform/getPlatformUserInfo", StringComparison.OrdinalIgnoreCase))
            // Real-name / fast-user check (event 1002). LoginPage._CheckRealName treats
            // isFastUser == 1 or idcardStatus == 1 as "no real-name gate" and proceeds to
            // OnSDKEnterGame -> LoginLogic.CheckUpdate -> getHash -> KCP login.
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":{" +
                "\"isFastUser\":1,\"idcardStatus\":1,\"isAdult\":1,\"OnNoRealnameLogin\":0}}");

        if (requestLine.Contains("/phone/platform/getGameMaintainNotice", StringComparison.OrdinalIgnoreCase))
            // Game-maintenance / announcement notice (event 1006). AnnouncementManager.
            // _SuperNoticeCallBack reads result.data (an array); an empty array is a no-op.
            // The Lua getResult path requires errornu == "0" (string).
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":[]}");

        if (requestLine.Contains("/phone/innerbrowse", StringComparison.OrdinalIgnoreCase))
            // Browse-active info (event 22). PlatformManager.getBrowseActive reads
            // result.noticear (an array); an empty array yields no active banner.
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"noticear\":[]}");

        if (requestLine.Contains("/phone/getuserextra/", StringComparison.OrdinalIgnoreCase))
            // User extra function state (event 1008, after LoginOk).
            // PlatformManager.CheckUserExtraFunctionState reads result.data.userInfo.readQuestion,
            // result.data.payBack.returnGold/returnMonthCard and result.data.oldUser.returnUserReceiveGift.
            return new(200, "OK", "application/json; charset=utf-8",
                "{\"errornu\":\"0\",\"errordesc\":\"\",\"data\":{\"userInfo\":{\"readQuestion\":0}," +
                "\"payBack\":{\"returnGold\":0,\"returnMonthCard\":0}," +
                "\"oldUser\":{\"returnUserReceiveGift\":0}}}");

        if (requestLine.Contains("/c.gif", StringComparison.OrdinalIgnoreCase))
            return new(200, "OK", "text/plain; charset=utf-8", "ok");

        // CDN hosts (static1/static3.zuiyouxi.com) serve the download speed test during
        // SDK init (event 31) and, later, the hot-patch version manifest. Any path we do
        // not explicitly understand yet still gets a 200 so the speed test succeeds and
        // the request line + host above are logged for further analysis.
        if (host is not null && IsCdnHost(host))
            return new(200, "OK", "text/plain; charset=utf-8", "ok");

        return new(501, "Not Implemented", "text/plain; charset=utf-8", "");
    }

    private static bool IsCdnHost(string host) =>
        host.StartsWith("static", StringComparison.OrdinalIgnoreCase) &&
        host.EndsWith(".zuiyouxi.com", StringComparison.OrdinalIgnoreCase);

    private sealed record BootstrapHttpResponse(
        int StatusCode, string ReasonPhrase, string ContentType, string Body);

    private static TrafficAnalysis AnalyzePayload(ReadOnlySpan<byte> data)
    {
        if (data.Length == 0)
            return new("empty", "connection closed without data", null);
        if (LooksLikeHttp(data))
            return AnalyzeHttp(data);
        if (data.Length >= 5 && data[0] is >= 0x14 and <= 0x17 && data[1] == 0x03)
            return AnalyzeTls(data);
        return new("binary", $"firstByte=0x{data[0]:X2}", null);
    }

    private static bool LooksLikeHttp(ReadOnlySpan<byte> data)
    {
        var end = data.IndexOf((byte)' ');
        if (end <= 0)
            return false;

        var token = Encoding.ASCII.GetString(data[..Math.Min(end, 8)]);
        return token is "GET" or "POST" or "PUT" or "DELETE" or "HEAD" or "OPTIONS" or "CONNECT" or "PATCH";
    }

    private static TrafficAnalysis AnalyzeHttp(ReadOnlySpan<byte> data)
    {
        var text = Encoding.ASCII.GetString(data[..Math.Min(data.Length, 4096)]);
        var firstLineEnd = text.IndexOf("\r\n", StringComparison.Ordinal);
        var firstLine = firstLineEnd >= 0 ? text[..firstLineEnd] : text;
        var host = text.Split("\r\n", StringSplitOptions.None)
            .FirstOrDefault(x => x.StartsWith("Host:", StringComparison.OrdinalIgnoreCase))?[5..]?.Trim();
        return new("http", firstLine, host);
    }

    private static TrafficAnalysis AnalyzeTls(ReadOnlySpan<byte> data)
    {
        var version = data.Length >= 3 ? $"{data[1]}.{data[2]}" : "unknown";
        return new("tls", $"recordType=0x{data[0]:X2} version={version}", null);
    }

    private static async Task<object> DispatchAsync(ProtocolEnvelope envelope, GameService game,
        SqliteGameRepository repo, CancellationToken ct)
    {
        var payload = envelope.Payload;
        return envelope.Type switch
        {
            MessageTypes.Login => await LoginAsync(payload, game, repo, ct),
            MessageTypes.State => await StateAsync(payload, game, ct),
            MessageTypes.SetFormation => await FormationAsync(payload, game, ct),
            MessageTypes.EnterStage => await EnterAsync(payload, game, ct),
            MessageTypes.BattleResult => await BattleAsync(payload, game, ct),
            _ => throw new InvalidOperationException("Unknown message")
        };
    }

    private static async Task<object> LoginAsync(JsonElement payload, GameService game,
        SqliteGameRepository repo, CancellationToken ct)
    {
        var id = payload.GetProperty("profileId").GetString()!;
        if (await repo.LoadAsync(id, ct) is null)
        {
            var name = payload.TryGetProperty("name", out var rawName)
                ? rawName.GetString() ?? id
                : id;
            await repo.CreateAsync(id, name, ct);
        }

        return new { profileId = id, version = game.Profile.ClientVersion };
    }

    private static async Task<object> StateAsync(JsonElement payload, GameService game, CancellationToken ct) =>
        await game.GetStateAsync(payload.GetProperty("profileId").GetString()!, ct) ??
        throw new KeyNotFoundException("Profile not found");

    private static async Task<object> FormationAsync(JsonElement payload, GameService game, CancellationToken ct) =>
        await game.SetFormationAsync(
            payload.GetProperty("profileId").GetString()!,
            payload.GetProperty("shipIds").EnumerateArray().Select(x => x.GetInt32()).ToArray(),
            ct);

    private static async Task<object> EnterAsync(JsonElement payload, GameService game, CancellationToken ct) =>
        await game.EnterStageAsync(
            payload.GetProperty("profileId").GetString()!,
            payload.GetProperty("stageId").GetInt32(),
            ct);

    private static async Task<object> BattleAsync(JsonElement payload, GameService game, CancellationToken ct)
    {
        var result = await game.ResolveBattleAsync(
            payload.GetProperty("profileId").GetString()!,
            payload.GetProperty("stageId").GetInt32(),
            payload.GetProperty("win").GetBoolean(),
            ct);
        return new { state = result.State, outcome = result.Outcome };
    }

    private sealed record ServerOptions(
        int Port,
        ProtocolProfile Profile,
        string DataRoot,
        bool EnableTls,
        string? TlsOutputRoot,
        string? CaptureRoot,
        bool TlsMaterialOnly,
        int? GameLoginPort,
        int? KcpGameLoginPort)
    {
        public static ServerOptions Parse(string[] args)
        {
            var port = 0;
            var profile = ProtocolProfile.Japan;
            var dataRoot = Path.Combine(AppContext.BaseDirectory, "data");
            var enableTls = false;
            string? tlsOutputRoot = null;
            string? captureRoot = null;
            var tlsMaterialOnly = false;
            int? gameLoginPort = null;
            int? kcpGameLoginPort = null;

            foreach (var arg in args)
            {
                if (arg.StartsWith("--port=", StringComparison.OrdinalIgnoreCase))
                    int.TryParse(arg[7..], out port);
                else if (arg.StartsWith("--region=", StringComparison.OrdinalIgnoreCase) &&
                    arg[9..].Equals("cn", StringComparison.OrdinalIgnoreCase))
                    profile = ProtocolProfile.China;
                else if (arg.StartsWith("--data=", StringComparison.OrdinalIgnoreCase))
                    dataRoot = arg[7..];
                else if (arg.StartsWith("--capture=", StringComparison.OrdinalIgnoreCase))
                    captureRoot = Path.GetFullPath(arg[10..]);
                else if (arg.StartsWith("--tls-output=", StringComparison.OrdinalIgnoreCase))
                    tlsOutputRoot = Path.GetFullPath(arg[13..]);
                else if (arg.Equals("--tls-auto", StringComparison.OrdinalIgnoreCase))
                    enableTls = true;
                else if (arg.Equals("--tls-material-only", StringComparison.OrdinalIgnoreCase))
                    tlsMaterialOnly = true;
                else if (arg.StartsWith("--game-login-port=", StringComparison.OrdinalIgnoreCase) &&
                    int.TryParse(arg[18..], out var parsedGameLoginPort) && parsedGameLoginPort is >= 0 and <= 65535)
                    gameLoginPort = parsedGameLoginPort;
                else if (arg.StartsWith("--kcp-game-login-port=", StringComparison.OrdinalIgnoreCase) &&
                    int.TryParse(arg[22..], out var parsedKcpGameLoginPort) && parsedKcpGameLoginPort is >= 0 and <= 65535)
                    kcpGameLoginPort = parsedKcpGameLoginPort;
            }

            return new ServerOptions(port, profile, dataRoot, enableTls, tlsOutputRoot, captureRoot,
                tlsMaterialOnly, gameLoginPort, kcpGameLoginPort);
        }
    }

    private sealed record TrafficAnalysis(string Kind, string Detail, string? ServerName);
}
