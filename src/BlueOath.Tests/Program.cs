using BlueOath.Core;
using BlueOath.Mods;
using BlueOath.Protocol;
using BlueOath.Storage;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;

var tests = new (string Name, Func<Task> Run)[]
{
    ("frame codec handles fragmented input", FrameCodecTest),
    ("real login protobuf payload round-trips", LoginProtobufTest),
    ("client login wire envelope round-trips", ClientLoginWireTest),
    ("temporary game login frame round-trips", GameLoginFrameTest),
    ("equipment enhancement response contains required payload", EquipEnhanceRetCodecTest),
    ("equipment renovation request decodes consumed equipment ids", EquipRiseStarArgsCodecTest),
    ("sqlite repository persists and isolates profiles", StorageTest),
    ("sqlite repository persists player account (character + dock)", AccountStorageTest),
    ("game service resolves deterministic battle", GameTest),
    ("mod manager filters target and orders mods", ModTest),
    ("kcp fragments reassemble across sticky and split buffers", KcpReassemblyTest),
    ("tls material loads in OpenSSL proxy runtime", TlsCaptureIntegrationTest)
};
if (args.Contains("--integration", StringComparer.OrdinalIgnoreCase)) tests = [.. tests,
    ("tcp server completes local gameplay flow", TcpIntegrationTest),
    ("protobuf login server creates a local profile", GameLoginIntegrationTest),
    ("tactic SetHerosTactic persists formation", TacticIntegrationTest),
    ("all fashions unlocked on account creation", FashionUnlockIntegrationTest),
    ("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--retire-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--hero-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--affection-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--tactic-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("tactic SetHerosTactic persists formation", TacticIntegrationTest)];
var failed = 0;
foreach (var (name, run) in tests)
{
    try { await run(); Console.WriteLine($"PASS {name}"); }
    catch (Exception e) { failed++; Console.Error.WriteLine($"FAIL {name}: {e.Message}"); }
}
return failed;

static async Task FrameCodecTest()
{
    await using var output = new MemoryStream();
    await FrameCodec.WriteAsync(output, new { hello = "world" });
    await using var input = new FragmentedStream(output.ToArray(), 1);
    using var doc = await FrameCodec.ReadAsync(input);
    Assert(doc is not null && doc.RootElement.GetProperty("hello").GetString() == "world", "frame payload mismatch");
}

static Task LoginProtobufTest()
{
    var request = new TArgLogin("local-player", 1712345678, "2026-08-13", "offline-hash",
        new TSampleInfo("uuid", "desktop", "win", "loopback", "windows", "jp.local"));
    var bytes = GameLoginCodec.Encode(request);
    var decoded = GameLoginCodec.DecodeLogin(bytes);
    Assert(decoded == request, "login protobuf request mismatch");
    var response = new TRetLogin("0", "1");
    Assert(GameLoginCodec.DecodeLoginResponse(GameLoginCodec.Encode(response)) == response,
        "login protobuf response mismatch");
    Assert(GameOperationCodes.Login == 2, "login operation code changed");
    return Task.CompletedTask;
}

static async Task GameLoginFrameTest()
{
    var frame = new GameLoginFrame(GameOperationCodes.Login,
        GameLoginCodec.Encode(new TArgLogin("frame-player", 1, "open", "hash")));
    await using var output = new MemoryStream();
    await GameLoginFrameCodec.WriteAsync(output, frame);
    await using var input = new FragmentedStream(output.ToArray(), 1);
    var decoded = await GameLoginFrameCodec.ReadAsync(input);
    Assert(decoded?.Operation == GameOperationCodes.Login &&
        GameLoginCodec.DecodeLogin(decoded.Payload).Pid == "frame-player", "game login frame mismatch");
}

static Task EquipEnhanceRetCodecTest()
{
    var payload = TMessageCodec.EncodeEquipEnhanceRet(42, 3, 200);
    Assert(payload.AsSpan().SequenceEqual(new byte[] { 0x08, 0x2A, 0x10, 0x03, 0x18, 0xC8, 0x01 }),
        "equipment enhancement response protobuf mismatch");
    return Task.CompletedTask;
}

static Task EquipRiseStarArgsCodecTest()
{
    var args = TMessageCodec.DecodeEquipRiseStarArgs(new byte[] { 0x08, 0x08, 0x10, 0x0E, 0x10, 0x0F });
    Assert(args.EquipId == 8 && args.ConsumeIds!.SequenceEqual(new uint[] { 14, 15 }),
        "equipment renovation request protobuf mismatch");
    return Task.CompletedTask;
}

static Task ClientLoginWireTest()
{
    var requestPayload = GameLoginCodec.Encode(new TArgLogin("wire-player", 1, "open", "hash"));
    var requestPacket = ClientGameWireCodec.EncodeClientRequest(GameOperationCodes.Login, requestPayload, 42, 3);
    var request = ClientGameWireCodec.DecodeClientRequest(requestPacket);
    Assert(request.Channel == 0 && request.Operation == 2 && request.SessionId == 42 && request.State == 3 &&
        GameLoginCodec.DecodeLogin(request.Payload).Pid == "wire-player", "client request wire mismatch");
    var responsePacket = ClientGameWireCodec.EncodeServerResponse(GameOperationCodes.Login,
        GameLoginCodec.Encode(new TRetLogin("0", "wire-player")));
    var response = ClientGameWireCodec.DecodeServerResponse(responsePacket);
    Assert(response.Operation == 2 && GameLoginCodec.DecodeLoginResponse(response.Payload).FeignRoleId == "wire-player",
        "server response wire mismatch");
    return Task.CompletedTask;
}

static Task KcpReassemblyTest()
{
    var login = new TArgLogin("kcp-player", 1234567890, "2026-08-13", "hash",
        new TSampleInfo("uuid", "model", "release", "wifi", "windows", "jp.local"));
    var appMessage = ClientGameWireCodec.EncodeClientRequest(GameOperationCodes.Login,
        GameLoginCodec.Encode(login), sessionId: 42, state: 3);

    var fragments = KcpCodec.FragmentPushMessage(0x11223344, 7, 1000, 32, 0, appMessage, maxPayload: 8);
    Assert(fragments.Count > 1, "login message was not fragmented");

    var stream = fragments.SelectMany(f => f).ToArray();
    var reader = new KcpStreamReader();
    var reassembler = new KcpReassembler();
    byte[]? reassembled = null;
    var cursor = 0;
    while (cursor < stream.Length)
    {
        var chunk = Math.Min(Random.Shared.Next(1, 7), stream.Length - cursor);
        foreach (var packet in reader.Feed(stream.AsSpan(cursor, chunk)))
        {
            if (reassembler.TryReassemble(packet, out var message))
                reassembled = message;
        }
        cursor += chunk;
    }

    Assert(reassembled is not null, "reassembler produced no message");
    Assert(reassembled.AsSpan().SequenceEqual(appMessage), "reassembled application message mismatch");
    var request = ClientGameWireCodec.DecodeClientRequest(reassembled);
    Assert(request.Operation == GameOperationCodes.Login &&
        GameLoginCodec.DecodeLogin(request.Payload).Pid == "kcp-player", "login application wire mismatch");
    return Task.CompletedTask;
}

static async Task StorageTest()
{
    var root = Path.Combine(Path.GetTempPath(), "blueoath-tests-" + Guid.NewGuid().ToString("N"));
    var repo = new SqliteGameRepository(root);
    await repo.CreateAsync("one", "One"); await repo.CreateAsync("two", "Two");
    var one = await repo.LoadAsync("one"); var two = await repo.LoadAsync("two");
    Assert(one?.Name == "One" && two?.Name == "Two", "profiles were not isolated");
    await repo.ResetAsync("one"); Assert(await repo.LoadAsync("one") is null, "reset did not remove profile");
    Directory.Delete(root, true);
}

static async Task GameTest()
{
    var root = Path.Combine(Path.GetTempPath(), "blueoath-tests-" + Guid.NewGuid().ToString("N"));
    var repo = new SqliteGameRepository(root); await repo.CreateAsync("player", "Player");
    var game = new GameService(repo, ProtocolProfile.Japan);
    await game.SetFormationAsync("player", [1001, 1002]); await game.EnterStageAsync("player", 1);
    var result = await game.ResolveBattleAsync("player", 1, true);
    Assert(result.Outcome.Victory && result.State.Coins == 100 && result.State.Fuel == 90, "battle result mismatch");
    Directory.Delete(root, true);
}

static async Task AccountStorageTest()
{
    var root = Path.Combine(Path.GetTempPath(), "blueoath-tests-" + Guid.NewGuid().ToString("N"));
    var repo = new SqliteGameRepository(root);

    // 创建档案时应同时播种默认账号（角色 + 船坞）。
    await repo.CreateAsync("hero", "Hero");
    var account = await repo.LoadAccountAsync("hero");
    Assert(account is not null, "account was not created with profile");
    Assert(account!.Character.Uid == 1 && account.Character.Name == "hero", "character defaults mismatch");
    Assert(account.Character.SecretaryId == 1, "secretary id mismatch");
    Assert(account.Dock.Heroes.Count == 1, "dock should contain one hero");
    Assert(account.Dock.Heroes[0].HeroId == account.Character.SecretaryId, "secretary hero not in dock");

    // 修改并保存账号，验证往返持久化。
    var updated = account with
    {
        Character = account.Character with { Level = 10 },
        Dock = new HeroDock(
            [new Hero(1, PlayerAccountFactory.DefaultHeroTemplateId, 5), new Hero(2, 10210512, 3)],
            BagSize: 200)
    };
    await repo.SaveAccountAsync(updated);
    var reloaded = await repo.LoadAccountAsync("hero");
    Assert(reloaded is not null, "account was not reloaded");
    Assert(reloaded!.Character.Level == 10, "character update not persisted");
    Assert(reloaded.Dock.Heroes.Count == 2 && reloaded.Dock.BagSize == 200, "dock update not persisted");

    // Reset 应同时清除档案与账号。
    await repo.ResetAsync("hero");
    Assert(await repo.LoadAsync("hero") is null, "reset did not remove profile");
    Assert(await repo.LoadAccountAsync("hero") is null, "reset did not remove account");

    Directory.Delete(root, true);
}

static Task ModTest()
{
    var root = Path.Combine(Path.GetTempPath(), "blueoath-mod-tests-" + Guid.NewGuid().ToString("N")); Directory.CreateDirectory(root);
    var dir = Path.Combine(root, "sample"); Directory.CreateDirectory(dir);
    File.WriteAllText(Path.Combine(dir, "mod.json"), "{\"id\":\"sample\",\"version\":\"1\",\"entry\":\"main.lua\",\"targetClients\":[\"jp-1.4.0\"],\"dependencies\":[],\"loadOrder\":1,\"enabled\":true}");
    File.WriteAllText(Path.Combine(dir, "main.lua"), "function on_login() end");
    var manager = new ModManager(root, "jp-1.4.0"); manager.LoadAll(); Assert(manager.LoadedIds.SequenceEqual(["sample"]), "targeted mod was not loaded");
    Directory.Delete(root, true); return Task.CompletedTask;
}

static async Task TcpIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    var data = Path.Combine(Path.GetTempPath(), "blueoath-tcp-" + Guid.NewGuid().ToString("N"));
    var startInfo = new ProcessStartInfo("dotnet") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
    startInfo.ArgumentList.Add(serverDll); startInfo.ArgumentList.Add("--port=0"); startInfo.ArgumentList.Add("--region=jp"); startInfo.ArgumentList.Add("--data=" + data);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "server process did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("port").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        await using var client = new LocalGameClient(); await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        await client.SendAsync<JsonElement>(MessageTypes.Login, new { profileId = "tcp", name = "TCP" }, timeout.Token);
        var state = await client.SendAsync<PlayerState>(MessageTypes.State, new { profileId = "tcp" }, timeout.Token); Assert(state.Fuel == 100, "initial state mismatch");
        await client.SendAsync<PlayerState>(MessageTypes.SetFormation, new { profileId = "tcp", shipIds = new[] { 1001, 1002 } }, timeout.Token);
        await client.SendAsync<Stage>(MessageTypes.EnterStage, new { profileId = "tcp", stageId = 1 }, timeout.Token);
        var outcome = await client.SendAsync<JsonElement>(MessageTypes.BattleResult, new { profileId = "tcp", stageId = 1, win = true }, timeout.Token); Assert(outcome.GetProperty("outcome").GetProperty("victory").GetBoolean(), "battle response mismatch");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task GameLoginIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    var data = Path.Combine(Path.GetTempPath(), "blueoath-login-" + Guid.NewGuid().ToString("N"));
    var startInfo = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };
    startInfo.ArgumentList.Add(serverDll);
    startInfo.ArgumentList.Add("--port=0");
    startInfo.ArgumentList.Add("--game-login-port=0");
    startInfo.ArgumentList.Add("--region=jp");
    startInfo.ArgumentList.Add("--data=" + data);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "game login server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        var stream = client.GetStream();

        async Task<TResponse> RoundTrip(string method, byte[]? args)
        {
            var request = TMessageCodec.EncodeRequest(new TRequest(method, args, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                var response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                // 服务器可能在应答前主动推送（IsResponse == 0），跳过直到拿到真正响应。
                if (response.IsResponse == 1)
                    return response;
            }
        }

        var login = await RoundTrip("player.Login",
            GameLoginCodec.Encode(new TArgLogin("protobuf-player", 1, "open", "hash")));
        Assert(login.Method == "player.Login", "login response method mismatch");
        Assert(GameLoginCodec.DecodeLoginResponse(login.Ret!).Ret == "ok", "login response ret mismatch");

        var list = await RoundTrip("player.GetUserList", null);
        Assert(list.Method == "player.GetUserList", "get user list response method mismatch");

        var create = await RoundTrip("player.CreateUser",
            new byte[] { 0x0A, 0x05, (byte)'t', (byte)'e', (byte)'s', (byte)'t', (byte)'1', 0x10, 0x01 });
        Assert(create.Method == "player.CreateUser", "create user response method mismatch");

        var userLogin = await RoundTrip("user.UserLogin", new byte[] { 0x08, 0x01 });
        Assert(userLogin.Method == "user.UserLogin", "user login response method mismatch");
        Assert(TMessageCodec.DecodeRetUserLogin(userLogin.Ret!) == "ok", "user login response ret mismatch");

        var userInfo = await RoundTrip("user.GetUserInfo", null);
        Assert(userInfo.Method == "user.GetUserInfo", "get user info response method mismatch");
        Assert(userInfo.Ret is { Length: > 0 }, "get user info response was empty");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task TacticIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    var data = Path.Combine(Path.GetTempPath(), "blueoath-tactic-" + Guid.NewGuid().ToString("N"));
    var startInfo = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };
    startInfo.ArgumentList.Add(serverDll);
    startInfo.ArgumentList.Add("--port=0");
    startInfo.ArgumentList.Add("--game-login-port=0");
    startInfo.ArgumentList.Add("--region=jp");
    startInfo.ArgumentList.Add("--data=" + data);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "tactic test server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        var stream = client.GetStream();

        async Task<TResponse> RoundTrip(string method, byte[]? args)
        {
            var request = TMessageCodec.EncodeRequest(new TRequest(method, args, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                var response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                if (response.IsResponse == 1)
                    return response;
            }
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin("tactic-player", 1, "open", "hash")));
        await RoundTrip("player.GetUserList", null);
        await RoundTrip("player.CreateUser",
            new byte[] { 0x0A, 0x04, (byte)'t', (byte)'a', (byte)'c', (byte)'1', 0x10, 0x01 });
        await RoundTrip("user.UserLogin", new byte[] { 0x08, 0x01 });

        // An explicitly encoded empty tacticName lets the Lua client distinguish the default
        // name from nil and replace it with the localized First..Fifth Fleet text.
        var defaults = await RoundTrip("tactic.GetHerosTactic", null);
        for (byte fleetId = 1; fleetId <= 5; fleetId++)
            Assert(defaults.Ret is { Length: > 0 } &&
                ContainsSequence(defaults.Ret, new byte[] { 0x0A, 0x00, 0x18, fleetId }),
                $"default fleet {fleetId} did not contain an explicit empty localized-name marker");

        // tactic.SetHerosTactic: tactics[0] { heroInfo=[1], modeId=1, strategyId=0, formationId=2, type=1 }
        var entry = new ProtocolPackage();
        entry.Write(0x10, 1UL); // heroInfo (2)
        entry.Write(0x18, 1UL); // modeId (3)
        entry.Write(0x20, 0UL); // strategyId (4)
        entry.Write(0x28, 2UL); // formationId (5)
        entry.Write(0x30, 1UL); // type (6)
        var pkg = new ProtocolPackage();
        pkg.Write(0x0A, entry.ToArray()); // tactics (1)

        var set = await RoundTrip("tactic.SetHerosTactic", pkg.ToArray());
        Assert(set.Method == "tactic.SetHerosTactic", "set tactic response method mismatch");
        Assert(set.Ret is { Length: > 0 }, "set tactic response was empty");

        var get = await RoundTrip("tactic.GetHerosTactic", null);
        Assert(get.Method == "tactic.GetHerosTactic", "get tactic response method mismatch");
        byte[] marker = [0x10, 0x01, 0x18, 0x01]; // heroInfo=1 + modeId=1
        Assert(get.Ret is { Length: > 0 } && ContainsSequence(get.Ret, marker),
            "tactic.GetHerosTactic did not include saved hero info");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task FashionUnlockIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    // 数据目录必须位于项目根之下，ConfigDbLoader.FindConfigDir 向上最多 8 级才能命中
    // blueoath/.../StreamingAssets/config（临时目录在系统盘，永远找不到）。
    var data = Path.Combine(root, "test-fashion-tmp");
    Directory.CreateDirectory(data);
    var startInfo = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };
    startInfo.ArgumentList.Add(serverDll);
    startInfo.ArgumentList.Add("--port=0");
    startInfo.ArgumentList.Add("--game-login-port=0");
    startInfo.ArgumentList.Add("--region=jp");
    startInfo.ArgumentList.Add("--data=" + data);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "fashion test server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        var stream = client.GetStream();

        async Task<TResponse> RoundTrip(string method, byte[]? args)
        {
            var request = TMessageCodec.EncodeRequest(new TRequest(method, args, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                var response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                if (response.IsResponse == 1)
                    return response;
            }
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin("fashion-player", 1, "open", "hash")));
        await RoundTrip("player.GetUserList", null);
        await RoundTrip("player.CreateUser",
            new byte[] { 0x0A, 0x04, (byte)'f', (byte)'a', (byte)'s', (byte)'h', 0x10, 0x01 });
        await RoundTrip("user.UserLogin", new byte[] { 0x08, 0x01 });
        var userInfo = await RoundTrip("user.GetUserInfo", null);
        Assert(userInfo.Method == "user.GetUserInfo", "get user info response method mismatch");

        // user.GetUserInfo 应答后，服务器会通过 PostPushes 初始化技能训练数据并推送
        // fashion.updateData。若缺少 study.GetStudyInfo，退役页会对 nil ArrProgress
        // 执行 ipairs，从而显示空白候选列表。
        byte[]? fashionRet = null;
        byte[]? studyRet = null;
        for (var attempts = 0; attempts < 24 && (fashionRet is null || studyRet is null); attempts++)
        {
            var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
            Assert(frame is not null, "missing expected login synchronization push");
            var push = TMessageCodec.DecodeResponse(frame!.Value.Payload);
            if (push.Method == "fashion.updateData")
                fashionRet = push.Ret;
            else if (push.Method == "study.GetStudyInfo")
                studyRet = push.Ret;
        }
        Assert(studyRet is { Length: > 0 } && ContainsSequence(studyRet, new byte[] { 0x08, 0x02 }),
            "login synchronization did not initialize an empty study progress list");
        Assert(fashionRet is { Length: > 100 },
            $"fashion.updateData push did not contain unlocked fashions (ret length: {fashionRet?.Length ?? 0})");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static bool ContainsSequence(byte[] haystack, byte[] needle)
{
    for (int i = 0; i + needle.Length <= haystack.Length; i++)
    {
        bool match = true;
        for (int j = 0; j < needle.Length; j++)
            if (haystack[i + j] != needle[j]) { match = false; break; }
        if (match) return true;
    }
    return false;
}

static async Task HeroMutationIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    var data = Path.Combine(root, "test-retire-" + Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(data);
    const string profileId = "retire-player";

    // Seed a second ship with one equipped item. The normal client flow asks whether that item
    // should be dismantled after retirement, so retirement must leave it in the bag and unbind it.
    var repo = new SqliteGameRepository(data);
    await repo.CreateAsync(profileId, profileId);
    PlayerAccount seeded = await repo.LoadAccountAsync(profileId)
        ?? throw new InvalidDataException("failed to seed retirement account");
    Hero second = seeded.Dock.Heroes[0] with
    {
        HeroId = 2,
        EquipSlots = new uint[] { 77, 0, 0, 0, 0, 0 },
    };
    seeded = seeded with
    {
        Dock = seeded.Dock with { Heroes = [seeded.Dock.Heroes[0], second] },
        Equip = new PlayerEquip([new EquipItem(77, 30421, HeroId: 2)], 2000),
        // Existing profiles may predate affection gifts and therefore have an empty bag.
        Bag = new PlayerBag([], 100),
    };
    await repo.SaveAccountAsync(seeded);

    var startInfo = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true,
    };
    startInfo.ArgumentList.Add(serverDll);
    startInfo.ArgumentList.Add("--port=0");
    startInfo.ArgumentList.Add("--game-login-port=0");
    startInfo.ArgumentList.Add("--region=jp");
    startInfo.ArgumentList.Add("--data=" + data);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "retirement test server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(15));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        var stream = client.GetStream();

        async Task<(TResponse Response, List<TResponse> Pushes)> RoundTrip(string method, byte[]? requestArgs)
        {
            byte[] request = TMessageCodec.EncodeRequest(new TRequest(method, requestArgs, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            List<TResponse> pushes = [];
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                TResponse response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                if (response.IsResponse == 1) return (response, pushes);
                pushes.Add(response);
            }
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin(profileId, 1, "open", "hash")));

        int initialAffection = second.Affection;
        var giftArgs = new ProtocolPackage();
        giftArgs.Write(0x08, 2UL);
        giftArgs.Write(0x10, 280002UL);
        giftArgs.Write(0x18, 2UL);
        var (giftResponse, giftPushes) = await RoundTrip("hero.AddAffection", giftArgs.ToArray());
        Assert(giftResponse.Err == 0 && giftResponse.Ret is { Length: > 0 } &&
            ContainsSequence(giftResponse.Ret, new byte[] { 0x10, 0x02 }),
            "gift response did not identify HeroId=2");
        Assert(giftPushes.Any(p => p.Method == "hero.UpdateHeroBagData"),
            "gift did not refresh hero data before its response");
        Assert(giftPushes.Any(p => p.Method == "bag.UpdateBagData"),
            "gift did not refresh bag data before its response");
        PlayerAccount gifted = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("gift account disappeared");
        int giftedAffection = gifted.Dock.Heroes.Single(h => h.HeroId == 2).Affection;
        Assert(giftedAffection > initialAffection, "gift did not increase persisted affection");
        Assert(gifted.Bag?.Items.Single(i => i.TemplateId == 280002).Num == 997,
            "starter gift inventory was not provisioned and deducted atomically");
        Assert(gifted.Bag?.Items.Count(i => i.Num == 999) == 7,
            "not all configured affection gift types were provisioned for the existing profile");

        // A failed request must not grant affection or consume the final gift.
        var excessiveGiftArgs = new ProtocolPackage();
        excessiveGiftArgs.Write(0x08, 2UL);
        excessiveGiftArgs.Write(0x10, 280002UL);
        excessiveGiftArgs.Write(0x18, 1000UL);
        var (excessiveGiftResponse, excessiveGiftPushes) =
            await RoundTrip("hero.AddAffection", excessiveGiftArgs.ToArray());
        Assert(excessiveGiftResponse.Err != 0, "insufficient gift inventory was accepted");
        Assert(excessiveGiftPushes.Count == 0, "failed gift request unexpectedly pushed changed data");
        PlayerAccount giftRejected = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("gift rejection account disappeared");
        Assert(giftRejected.Dock.Heroes.Single(h => h.HeroId == 2).Affection == giftedAffection &&
            giftRejected.Bag?.Items.Single(i => i.TemplateId == 280002).Num == 997,
            "failed gift request changed persisted data");

        var lockArgs = new ProtocolPackage();
        lockArgs.Write(0x08, 2UL);
        lockArgs.Write(0x10, 1UL);
        var (lockResponse, lockPushes) = await RoundTrip("hero.LockHero", lockArgs.ToArray());
        Assert(lockResponse.Err == 0 && lockResponse.Ret is not null &&
            ContainsSequence(lockResponse.Ret, new byte[] { 0x08, 0x02 }),
            "lock response did not identify HeroId=2");
        TResponse lockHeroPush = lockPushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("lock did not refresh hero data before its response");
        Assert(lockHeroPush.Ret is { Length: > 0 } &&
            ContainsSequence(lockHeroPush.Ret, new byte[] { 0x60, 0x01 }),
            "lock update did not set Lock=true");
        PlayerAccount locked = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("lock account disappeared");
        Assert(locked.Dock.Heroes.Single(h => h.HeroId == 2).Lock, "lock state was not persisted");

        var unlockArgs = new ProtocolPackage();
        unlockArgs.Write(0x08, 2UL);
        unlockArgs.Write(0x10, 0UL);
        var (unlockResponse, unlockPushes) = await RoundTrip("hero.LockHero", unlockArgs.ToArray());
        Assert(unlockResponse.Err == 0 && unlockResponse.Ret is not null &&
            ContainsSequence(unlockResponse.Ret, new byte[] { 0x08, 0x02 }),
            "unlock response did not identify HeroId=2");
        TResponse unlockHeroPush = unlockPushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("unlock did not refresh hero data before its response");
        Assert(unlockHeroPush.Ret is { Length: > 0 } &&
            ContainsSequence(unlockHeroPush.Ret, new byte[] { 0x60, 0x00 }),
            "unlock update did not explicitly set Lock=false");
        PlayerAccount unlocked = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("unlock account disappeared");
        Assert(!unlocked.Dock.Heroes.Single(h => h.HeroId == 2).Lock, "unlock state was not persisted");

        // A hero mutation refreshes the full dock. HeroGrid.Name is a custom nickname, not the
        // handbook's Chinese display name; otherwise the JP client mixes Chinese and Japanese
        // names after a ship is built or updated.
        var marryArgs = new ProtocolPackage();
        marryArgs.Write(0x08, 2UL);
        marryArgs.Write(0x10, 1UL);
        var (_, marryPushes) = await RoundTrip("hero.Marry", marryArgs.ToArray());
        TResponse marryHeroPush = marryPushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("marriage did not refresh hero data");
        Assert(marryHeroPush.Ret is { Length: > 0 } &&
            !ContainsSequence(marryHeroPush.Ret, Encoding.UTF8.GetBytes("奥克兰")),
            "hero update incorrectly sent the Chinese handbook name as a custom nickname");

        // The shipped Lua protobuf runtime uses the proto2 unpacked representation for HeroIds.
        var retireArgs = new ProtocolPackage();
        retireArgs.Write(0x08, 2UL);
        retireArgs.Write(0x10, 0UL);
        var (retire, pushes) = await RoundTrip("hero.RetireHero", retireArgs.ToArray());

        Assert(retire.Err == 0 && retire.Ret is { Length: > 0 }, "retirement response did not contain rewards");
        TResponse heroPush = pushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("retirement did not push a hero deletion marker");
        Assert(heroPush.Ret is { Length: > 0 } &&
            ContainsSequence(heroPush.Ret, new byte[] { 0x08, 0x02, 0x10, 0x00 }),
            "hero deletion marker did not explicitly include HeroId=2 and TemplateId=0");
        Assert(pushes.Any(p => p.Method == "user.UpdateUserInfo"), "retirement did not refresh currencies");
        Assert(pushes.Any(p => p.Method == "equip.UpdateEquipBagData"), "retirement did not refresh equipment");

        PlayerAccount saved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("retirement account disappeared");
        Assert(saved.Dock.Heroes.All(h => h.HeroId != 2), "retired hero remained in persistent dock");
        EquipItem returnedEquip = saved.Equip?.Items.SingleOrDefault(e => e.EquipId == 77)
            ?? throw new InvalidDataException("retired hero equipment was deleted");
        Assert(returnedEquip.HeroId == 0, "retired hero equipment was not unbound");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task TlsCaptureIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    var material = Path.Combine(Path.GetTempPath(), "blueoath-tls-material-" + Guid.NewGuid().ToString("N"));
    var startInfo = new ProcessStartInfo("dotnet")
    {
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };
    startInfo.ArgumentList.Add(serverDll);
    startInfo.ArgumentList.Add("--tls-material-only");
    startInfo.ArgumentList.Add("--tls-output=" + material);
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "TLS material process did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        await process.WaitForExitAsync().WaitAsync(TimeSpan.FromSeconds(10));
        Assert(process.ExitCode == 0, "TLS material process failed: " + await process.StandardError.ReadToEndAsync());
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("TLS material process did not report ready"));
        var certificate = ready.RootElement.GetProperty("leafPem").GetString();
        var key = ready.RootElement.GetProperty("leafKeyPem").GetString();
        Assert(!string.IsNullOrWhiteSpace(certificate) && File.Exists(certificate), "leaf PEM was not emitted");
        Assert(!string.IsNullOrWhiteSpace(key) && File.Exists(key), "leaf private key PEM was not emitted");

        var python = new ProcessStartInfo("python")
        {
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        python.ArgumentList.Add("-c");
        python.ArgumentList.Add("import ssl,sys;c=ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER);c.load_cert_chain(sys.argv[1],sys.argv[2])");
        python.ArgumentList.Add(certificate!);
        python.ArgumentList.Add(key!);
        using var openssl = Process.Start(python) ?? throw new InvalidOperationException("Python TLS runtime did not start");
        await openssl.WaitForExitAsync().WaitAsync(TimeSpan.FromSeconds(10));
        Assert(openssl.ExitCode == 0, "OpenSSL rejected TLS material: " + await openssl.StandardError.ReadToEndAsync());
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(material)) Directory.Delete(material, true);
    }
}

static string FindRepositoryRoot()
{
    var current = new DirectoryInfo(AppContext.BaseDirectory);
    while (current is not null)
    {
        if (Directory.Exists(Path.Combine(current.FullName, "src", "BlueOath.Server"))) return current.FullName;
        current = current.Parent;
    }
    throw new DirectoryNotFoundException("Repository root not found");
}

static void Assert(bool condition, string message) { if (!condition) throw new InvalidOperationException(message); }

sealed class FragmentedStream(byte[] data, int chunk) : MemoryStream
{
    private readonly byte[] _data = data; private int _offset;
    public override int Read(Span<byte> buffer) { if (_offset >= _data.Length) return 0; var count = Math.Min(Math.Min(chunk, buffer.Length), _data.Length - _offset); _data.AsSpan(_offset, count).CopyTo(buffer); _offset += count; return count; }
    public override ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default) => new(Read(buffer.Span));
}
