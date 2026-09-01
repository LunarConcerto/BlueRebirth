using BlueOath.Core;
using BlueOath.Mods;
using BlueOath.Protocol;
using BlueOath.Server.Protocols;
using BlueOath.Server.Configs;
using BlueOath.Server;
using BlueOath.Server.Hosting;
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
    ("selected launcher profile flows through bootstrap login responses", AccountProfileBootstrapTest),
    ("launcher profile names initialize and migrate character names", AccountProfileNameMigrationTest),
    ("legacy hero-advance duplicate ids migrate to the upgraded survivor", DuplicateHeroMigrationTest),
    ("client login wire envelope round-trips", ClientLoginWireTest),
    ("temporary game login frame round-trips", GameLoginFrameTest),
    ("equipment enhancement response contains required payload", EquipEnhanceRetCodecTest),
    ("equipment renovation request decodes consumed equipment ids", EquipRiseStarArgsCodecTest),
    ("zero-count bag entries encode an explicit deletion marker", BagDeletionMarkerCodecTest),
    ("normal treasure request and equipment reward use client protobuf layout", TreasureCodecTest),
    ("hero advance preserves neighbors and unbinds consumed equipment", HeroAdvanceStateTest),
    ("build ship response omits empty special rewards", BuildShipRewardCodecTest),
    ("120-draw ship reward creates a hero instance and heals legacy bag pollution", BuildShipHundredRewardIntegrationTest),
    ("traditional construction config, protocol and queue match the client", ConstructionConfigAndCodecTest),
    ("building config, lifecycle and assignment codecs match the client", BuildingCodecTest),
    ("story unlock config includes event, side and personal stories", StoryUnlockConfigTest),
    ("illustrate entries unlock every configured behaviour", IllustrateBehaviourUnlockTest),
    ("ship acquisition keeps the client illustrate snapshot in sync", ShipAcquisitionIllustrateSyncTest),
    ("Mubar battle start preserves CopyType 33", MubarBattleStartCodecTest),
    ("sea-copy entries include non-nil safe-area state", SeaCopySafeAreaCodecTest),
    ("daily-copy gameplay unlocks and resets destroyer challenge progress", DailyCopyGameplayTest),
    ("tasks remain incomplete until persisted progress reaches the goal", TaskCompletionRequiresProgressTest),
    ("illustrate payload encodes unlocked personal stories", HeroMemoryCodecTest),
    ("remould config and hero protobuf fields match the client", RemouldConfigAndCodecTest),
    ("sqlite repository persists and isolates profiles", StorageTest),
    ("sqlite repository persists player account (character + dock)", AccountStorageTest),
    ("game service resolves deterministic battle", GameTest),
    ("mod manager filters target and orders mods", ModTest),
    ("equipment mod adds a client/server template and GM shop good", EquipmentModTest),
    ("fashion shop previews tolerate an unlocked skin without its hero", FashionPreviewModTest),
    ("native draw results only prompt to lock a genuinely new ship", BuildShipNewStateNativePatchTest),
    ("item selection boxes grant the chosen option", SelectTreasureTest),
    ("tls material loads in OpenSSL proxy runtime", TlsCaptureIntegrationTest)
};
if (args.Contains("--integration", StringComparer.OrdinalIgnoreCase)) tests = [.. tests,
    ("tcp server completes local gameplay flow", TcpIntegrationTest),
    ("protobuf login server creates a local profile", GameLoginIntegrationTest),
    ("tactic SetHerosTactic persists formation", TacticIntegrationTest),
    ("fashion synchronization and shops use configured catalog", FashionUnlockIntegrationTest),
    ("equipped UR equipment supports normal and bound enhancement", EquipEnhanceIntegrationTest),
    ("traditional construction consumes resources and persists its queue", ConstructionIntegrationTest),
    ("building construction and hero assignment persist and refresh the client", BuildingAssignmentIntegrationTest),
    ("hero remould consumes costs and persists its node", HeroRemouldIntegrationTest),
    ("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--tcp-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("tcp server pins legacy login ids to the selected launcher profile", TcpIntegrationTest)];
if (args.Contains("--equip-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("equipped UR equipment supports normal and bound enhancement", EquipEnhanceIntegrationTest)];
if (args.Contains("--equipment-mod", StringComparer.OrdinalIgnoreCase))
    tests = [("equipment mod adds a client/server template and GM shop good", EquipmentModTest)];
if (args.Contains("--equipment-mod-config", StringComparer.OrdinalIgnoreCase))
    tests = [("equipment mod overlays the real client equipment database", EquipmentModConfigIntegrationTest)];
if (args.Contains("--retire-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--hero-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--affection-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero gift, lock/unlock and retirement synchronize client state", HeroMutationIntegrationTest)];
if (args.Contains("--rename-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("hero rename supports Unicode, reset and client synchronization", HeroMutationIntegrationTest)];
if (args.Contains("--marry-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("oath ring purchase and consecutive marriages are atomic", HeroMutationIntegrationTest)];
if (args.Contains("--shop-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("oath ring purchase refreshes inventory before its response", HeroMutationIntegrationTest)];
if (args.Contains("--fashion-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("fashion synchronization and shops use configured catalog", FashionUnlockIntegrationTest)];
if (args.Contains("--treasure-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("equipment treasure consumes its box and persists a new equipment instance", TreasureIntegrationTest)];
if (args.Contains("--hero-advance", StringComparer.OrdinalIgnoreCase))
    tests = [("hero advance preserves neighbors and unbinds consumed equipment", HeroAdvanceStateTest)];
if (args.Contains("--buildship-codec", StringComparer.OrdinalIgnoreCase))
    tests = [("build ship response omits empty special rewards", BuildShipRewardCodecTest)];
if (args.Contains("--buildship-reward", StringComparer.OrdinalIgnoreCase))
    tests = [("120-draw ship reward creates a hero instance and heals legacy bag pollution", BuildShipHundredRewardIntegrationTest)];
if (args.Contains("--tactic-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("tactic SetHerosTactic persists formation", TacticIntegrationTest)];
if (args.Contains("--story-unlock", StringComparer.OrdinalIgnoreCase))
    tests = [
        ("story unlock config includes event, side and personal stories", StoryUnlockConfigTest),
        ("illustrate payload encodes unlocked personal stories", HeroMemoryCodecTest)
    ];
if (args.Contains("--illustrate-behaviour", StringComparer.OrdinalIgnoreCase))
    tests = [("illustrate entries unlock every configured behaviour", IllustrateBehaviourUnlockTest)];
if (args.Contains("--remould-integration", StringComparer.OrdinalIgnoreCase))
    tests = [
        ("remould config and hero protobuf fields match the client", RemouldConfigAndCodecTest),
        ("hero remould consumes costs and persists its node", HeroRemouldIntegrationTest)
    ];
if (args.Contains("--construction-integration", StringComparer.OrdinalIgnoreCase))
    tests = [
        ("traditional construction config, protocol and queue match the client", ConstructionConfigAndCodecTest),
        ("traditional construction consumes resources and persists its queue", ConstructionIntegrationTest)
    ];
if (args.Contains("--building-integration", StringComparer.OrdinalIgnoreCase))
    tests = [
        ("building config, lifecycle and assignment codecs match the client", BuildingCodecTest),
        ("building construction and hero assignment persist and refresh the client", BuildingAssignmentIntegrationTest)
    ];
if (args.Contains("--fashion-preview-mod", StringComparer.OrdinalIgnoreCase))
    tests = [("fashion shop previews tolerate an unlocked skin without its hero", FashionPreviewModTest)];
if (args.Contains("--buildship-new-state-native", StringComparer.OrdinalIgnoreCase))
    tests = [("native draw results only prompt to lock a genuinely new ship", BuildShipNewStateNativePatchTest)];
if (args.Contains("--login-integration", StringComparer.OrdinalIgnoreCase))
    tests = [("protobuf login server creates a local profile", GameLoginIntegrationTest)];
if (args.Contains("--mubar-battle-codec", StringComparer.OrdinalIgnoreCase))
    tests = [("Mubar battle start preserves CopyType 33", MubarBattleStartCodecTest)];
if (args.Contains("--sea-safe-codec", StringComparer.OrdinalIgnoreCase))
    tests = [("sea-copy entries include non-nil safe-area state", SeaCopySafeAreaCodecTest)];
if (args.Contains("--dailycopy", StringComparer.OrdinalIgnoreCase))
    tests = [("daily-copy gameplay unlocks and resets destroyer challenge progress", DailyCopyGameplayTest)];
if (args.Contains("--task-completion", StringComparer.OrdinalIgnoreCase))
    tests = [("tasks remain incomplete until persisted progress reaches the goal", TaskCompletionRequiresProgressTest)];
if (args.Contains("--account-profile", StringComparer.OrdinalIgnoreCase))
    tests = [
        ("selected launcher profile flows through bootstrap login responses", AccountProfileBootstrapTest),
        ("launcher profile names initialize and migrate character names", AccountProfileNameMigrationTest)
    ];
var failed = 0;
foreach (var (name, run) in tests)
{
    try { await run(); Console.WriteLine($"PASS {name}"); }
    catch (Exception e) { failed++; Console.Error.WriteLine($"FAIL {name}: {e.Message}"); }
}
return failed;

// 客户端 IllustrateData:IsFirstGetHero() 判定的是 oldCurrId —— 应用某次 illustrate.IllustrateInfo
// 之前的 currId 快照。ShowGirlPage 的 bNew（首次获得动画、上锁询问、NEW 角标）全部取自它。
// 因此两件事必须成立，否则重复获得的舰船会被当成首次获得：
//   1. 登录全量图鉴推送之后要补一条 illustrate.OldIllustrateInfo，把 oldCurrId 从空表同步成
//      currId；登录时 currId 尚为空，SetIllustrateData 快照出来的 oldCurrId 必然是空的。
//   2. 商店发放舰娘时要推 illustrate.IllustrateInfo，否则该 ship_info_id 永远进不了 currId。
static async Task ShipAcquisitionIllustrateSyncTest()
{
    string root = FindRepositoryRoot();
    string dataRoot = Path.Combine(Path.GetTempPath(), "blueoath-illustrate-sync-" + Guid.NewGuid().ToString("N"));
    const string profileId = "illustrate-sync";
    const int shipTemplateId = 40110311;
    try
    {
        var repo = new SqliteGameRepository(dataRoot);
        await repo.SaveAccountAsync(PlayerAccountFactory.CreateDefault(profileId, 1) with
        {
            Dock = new HeroDock([new Hero(10, 10210511, 5)]),
        });

        ServerOptions options = ServerOptions.Parse(
            ["--data=" + dataRoot,
             "--client-path=" + Path.Combine(root, "blueoath", "blueoath"),
             "--profile-id=" + profileId]);
        using Microsoft.Extensions.Logging.ILoggerFactory loggerFactory =
            Microsoft.Extensions.Logging.LoggerFactory.Create(_ => { });
        var services = new GameServices(repo, options, loggerFactory);

        List<string> loginMethods = (await services.BuildSyncPushesAsync(profileId, 1, CancellationToken.None))
            .Select(push => TMessageCodec.DecodeResponse(push).Method ?? "").ToList();
        int infoIndex = loginMethods.IndexOf("illustrate.IllustrateInfo");
        int oldIndex = loginMethods.IndexOf("illustrate.OldIllustrateInfo");
        Assert(infoIndex >= 0 && oldIndex >= 0,
            "login snapshot did not seed the client illustrate baseline");
        Assert(oldIndex > infoIndex,
            "illustrate.OldIllustrateInfo must follow the full illustrate snapshot it takes a copy of");

        List<string> plainMethods =
            (await services.BuildBuyPushesAsync(profileId, 1, CancellationToken.None))
            .Select(push => TMessageCodec.DecodeResponse(push).Method ?? "").ToList();
        Assert(!plainMethods.Contains("illustrate.IllustrateInfo"),
            "a purchase without ships should not push illustrate data");

        IReadOnlyList<byte[]> shipPushes = await services.BuildBuyPushesAsync(
            profileId, 1, CancellationToken.None, newShipTemplateIds: [shipTemplateId]);
        List<TResponse> shipResponses = shipPushes.Select(push => TMessageCodec.DecodeResponse(push)).ToList();
        Assert(shipResponses.Any(push => push.Method == "hero.UpdateHeroBagData"),
            "buying a ship did not refresh the dock");
        TResponse illustratePush = shipResponses.SingleOrDefault(p => p.Method == "illustrate.IllustrateInfo")
            ?? throw new InvalidDataException("buying a ship did not push illustrate data");
        // IllustrateId = ship_info_id = (templateId - 1) / 10，客户端据此把该船并入 currId。
        byte[] expected = new ProtocolPackage().Write(0x08, (ulong)((shipTemplateId - 1) / 10)).ToArray();
        Assert(illustratePush.Ret is { Length: > 0 } && ContainsSequence(illustratePush.Ret, expected),
            "illustrate push did not carry the purchased ship's illustrate id");
    }
    finally
    {
        if (Directory.Exists(dataRoot)) Directory.Delete(dataRoot, true);
    }
}

static async Task HeroAdvanceStateTest()
{
    string root = FindRepositoryRoot();
    string dataRoot = Path.Combine(Path.GetTempPath(), "blueoath-hero-advance-" + Guid.NewGuid().ToString("N"));
    const string profileId = "hero-advance-state";
    try
    {
        var repo = new SqliteGameRepository(dataRoot);
        PlayerAccount account = PlayerAccountFactory.CreateDefault(profileId, 1) with
        {
            Character = PlayerAccountFactory.CreateDefault(profileId, 1).Character with
            {
                SecretaryId = 70,
                Gold = 1_600_000,
            },
            Dock = new HeroDock(
            [
                new Hero(10, 10210511, 5, EquipSlots: [101, 0, 0, 0, 0, 0]),
                new Hero(20, 10210512, 15, EquipSlots: [102, 0, 0, 0, 0, 0]),
                new Hero(30, 10330111, 5, EquipSlots: [103, 0, 0, 0, 0, 0]),
                new Hero(40, 10210513, 25),
                new Hero(50, 10210514, 40),
                new Hero(60, 10210515, 60),
                new Hero(70, 10210511, 5),
                new Hero(80, 10210511, 5, Lock: true),
                new Hero(90, 12550112, 15),
                new Hero(100, 10240316, 80),
                new Hero(110, 10540111, 1),
                new Hero(120, 10210511, 5),
                new Hero(130, 10240326, 80),
                new Hero(140, 12850111, 1),
            ]),
            Bag = new PlayerBag([new BagItem(120004, 15), new BagItem(17512, 15)]),
            Equip = new PlayerEquip(
            [
                new EquipItem(101, 30151, HeroId: 10),
                new EquipItem(102, 30141, HeroId: 20),
                new EquipItem(103, 30421, HeroId: 30),
            ], 2000),
            Building = new PlayerBuilding(
                [new PlayerBuildingEntry(1, 2, 2, [40])],
                [new PlayerBuildingLand(1, 1)]),
            Fleet = new PlayerFleet([new FleetEntry(1, HeroInfo: [50])]),
            Bath = new PlayerBath([new BathHero(60)]),
        };
        await repo.SaveAccountAsync(account);

        ServerOptions options = ServerOptions.Parse(
            ["--data=" + dataRoot,
             "--client-path=" + Path.Combine(root, "blueoath", "blueoath"),
             "--profile-id=" + profileId]);
        using Microsoft.Extensions.Logging.ILoggerFactory loggerFactory =
            Microsoft.Extensions.Logging.LoggerFactory.Create(_ => { });
        var services = new GameServices(repo, options, loggerFactory);
        var heroService = new HeroService(services);

        byte[] emptyArgs = new ProtocolPackage().Write(0x08, 20UL).ToArray();
        HeroService.AdvanceResult emptyRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", emptyArgs), profileId, CancellationToken.None);
        Assert(!emptyRejected.Changed, "hero advance ignored its configured material requirement");

        byte[] nonexistentArgs = new ProtocolPackage()
            .Write(0x08, 20UL)
            .Write(0x10, 999UL)
            .ToArray();
        HeroService.AdvanceResult nonexistentRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", nonexistentArgs), profileId, CancellationToken.None);
        Assert(!nonexistentRejected.Changed, "hero advance accepted a nonexistent material hero");

        byte[] assignedArgs = new ProtocolPackage()
            .Write(0x08, 20UL)
            .Write(0x10, 40UL)
            .ToArray();
        HeroService.AdvanceResult assignedRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", assignedArgs), profileId, CancellationToken.None);
        Assert(!assignedRejected.Changed, "hero advance consumed a hero assigned to a building");

        foreach (var (materialId, reason) in new[]
                 {
                     (50UL, "fleet"),
                     (60UL, "bath"),
                     (70UL, "secretary"),
                     (80UL, "lock"),
                 })
        {
            byte[] protectedArgs = new ProtocolPackage()
                .Write(0x08, 20UL)
                .Write(0x10, materialId)
                .ToArray();
            HeroService.AdvanceResult protectedRejected = await heroService.BuildAdvanceRetAsync(
                new TRequest("hero.HeroAdvance", protectedArgs), profileId, CancellationToken.None);
            Assert(!protectedRejected.Changed, $"hero advance consumed a material protected by {reason}");
        }

        PlayerAccount loaded = await services.GetOrCreateAccountAsync(profileId, CancellationToken.None);
        PlayerAccount poor = loaded with { Character = loaded.Character with { Gold = 19_999 } };
        await services.SaveAccountAsync(poor, CancellationToken.None);
        byte[] args = new ProtocolPackage()
            .Write(0x08, 20UL)
            .Write(0x10, 10UL)
            .ToArray();
        HeroService.AdvanceResult poorRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", args), profileId, CancellationToken.None);
        Assert(!poorRejected.Changed, "hero advance allowed a negative currency balance");
        await services.SaveAccountAsync(
            poor with { Character = poor.Character with { Gold = 1_600_000 } }, CancellationToken.None);

        HeroService.AdvanceResult result = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", args), profileId, CancellationToken.None);
        Assert(result.Changed && result.ConsumedHeroIds.SequenceEqual([10U]),
            "valid hero advance did not consume its material hero");

        PlayerAccount saved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("advanced account disappeared");
        Assert(saved.Dock.Heroes.Select(h => h.HeroId).SequenceEqual(
                   [20U, 30U, 40U, 50U, 60U, 70U, 80U, 90U, 100U, 110U, 120U, 130U, 140U]) &&
               saved.Dock.Heroes.Select(h => h.HeroId).Distinct().Count() == saved.Dock.Heroes.Count,
            "hero advance duplicated its target or overwrote the neighboring hero");
        Hero advanced = saved.Dock.Heroes.Single(h => h.HeroId == 20);
        Assert(advanced.TemplateId == 10210513 && advanced.Advance == 1,
            "hero advance did not persist the upgraded target");
        Assert(saved.Character.Gold == 1_580_000,
            "hero advance did not deduct the configured currency cost");
        Assert(saved.Equip!.Items.Single(e => e.EquipId == 101).HeroId == 0 &&
               saved.Equip.Items.Single(e => e.EquipId == 102).HeroId == 20 &&
               saved.Equip.Items.Single(e => e.EquipId == 103).HeroId == 30,
            "hero advance left orphan equipment or changed a surviving hero's equipment");

        var insufficientItemArgs = new ProtocolPackage().Write(0x08, 90UL);
        for (int i = 0; i < 15; i++) insufficientItemArgs.Write(0x18, 120004UL);
        for (int i = 0; i < 14; i++) insufficientItemArgs.Write(0x18, 17512UL);
        HeroService.AdvanceResult itemRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", insufficientItemArgs.ToArray()), profileId, CancellationToken.None);
        Assert(!itemRejected.Changed, "hero advance ignored its configured item quantity");

        var itemArgs = new ProtocolPackage().Write(0x08, 90UL);
        for (int i = 0; i < 15; i++) itemArgs.Write(0x18, 120004UL);
        for (int i = 0; i < 15; i++) itemArgs.Write(0x18, 17512UL);
        HeroService.AdvanceResult itemResult = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", itemArgs.ToArray()), profileId, CancellationToken.None);
        Assert(itemResult.Changed && itemResult.UpdatedHero?.TemplateId == 12550113,
            "configured item-based hero advance was rejected");
        PlayerAccount itemSaved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("item-advanced account disappeared");
        Assert(itemSaved.Bag!.Items.Single(i => i.TemplateId == 120004).Num == 0 &&
               itemSaved.Bag.Items.Single(i => i.TemplateId == 17512).Num == 0 &&
               itemSaved.Character.Gold == 1_500_000,
            "item-based hero advance deducted the wrong inventory or currency amount");

        byte[] invalidQualityArgs = new ProtocolPackage()
            .Write(0x08, 100UL)
            .Write(0x10, 120UL)
            .ToArray();
        HeroService.AdvanceResult invalidQualityRejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", invalidQualityArgs), profileId, CancellationToken.None);
        Assert(!invalidQualityRejected.Changed,
            "optional hero advance accepted a material below configured quality 4");

        byte[] optionalArgs = new ProtocolPackage()
            .Write(0x08, 100UL)
            .Write(0x10, 110UL)
            .ToArray();
        HeroService.AdvanceResult optionalResult = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", optionalArgs), profileId, CancellationToken.None);
        Assert(optionalResult.Changed && optionalResult.ConsumedHeroIds.SequenceEqual([110U]) &&
               optionalResult.UpdatedHero?.TemplateId == 10240317,
            "configured quality-4 optional hero advance was rejected");
        PlayerAccount optionalSaved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("optional-advanced account disappeared");
        Assert(optionalSaved.Dock.Heroes.All(hero => hero.HeroId != 110) &&
               optionalSaved.Character.Gold == 1_000_000,
            "optional hero advance consumed the wrong hero or currency amount");

        byte[] ssrOptionalArgs = new ProtocolPackage()
            .Write(0x08, 130UL)
            .Write(0x10, 140UL)
            .ToArray();
        HeroService.AdvanceResult ssrOptionalResult = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", ssrOptionalArgs), profileId, CancellationToken.None);
        Assert(ssrOptionalResult.Changed && ssrOptionalResult.ConsumedHeroIds.SequenceEqual([140U]) &&
               ssrOptionalResult.UpdatedHero?.TemplateId == 10240327,
            "configured quality-5 optional hero advance was rejected");
        PlayerAccount ssrOptionalSaved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("SSR optional-advanced account disappeared");
        Assert(ssrOptionalSaved.Dock.Heroes.All(hero => hero.HeroId != 140) &&
               ssrOptionalSaved.Character.Gold == 500_000,
            "SSR optional hero advance consumed the wrong hero or currency amount");

        byte[] selfConsumeArgs = new ProtocolPackage()
            .Write(0x08, 20UL)
            .Write(0x10, 20UL)
            .ToArray();
        HeroService.AdvanceResult rejected = await heroService.BuildAdvanceRetAsync(
            new TRequest("hero.HeroAdvance", selfConsumeArgs), profileId, CancellationToken.None);
        Assert(!rejected.Changed,
            "hero advance allowed the target hero to consume itself");
    }
    finally
    {
        if (Directory.Exists(dataRoot)) Directory.Delete(dataRoot, true);
    }
}

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

static Task RemouldConfigAndCodecTest()
{
    RemouldConfigLoader.Load(FindClientConfigDir());
    Assert(RemouldConfigLoader.AllEffects.Count >= 800,
        "ship remould effect config was not loaded");
    ConfigShipRemouldTemplate stage = RemouldConfigLoader.GetTemplate(525)
        ?? throw new InvalidDataException("Oakland remould stage 525 was not loaded");
    IReadOnlyList<long> stageEffects = stage.RemouldItemGroup is { Count: > 0 } configuredEffects
        ? configuredEffects
        : throw new InvalidDataException("Oakland remould stage has no effects");
    Assert(stageEffects.All(id => RemouldConfigLoader.GetEffect(checked((int)id)) is not null),
        "a stage references a missing remould effect");
    Assert(RemouldConfigLoader.AllEffects.Values
        .SelectMany(effect => effect.Cost ?? [])
        .All(cost => cost.Count >= 3 && cost[0] is not (2 or 3)),
        "remould config contains an unsupported instance-asset cost");

    var args = new ProtocolPackage();
    args.Write(0x08, 7UL);
    args.Write(0x10, 388UL);
    HeroRemouldArg decoded = ProtocolDecoder.DecodeHeroRemouldArg(args.ToArray());
    Assert(decoded == new HeroRemouldArg(7, 388), "TRemouldArg field layout did not decode");

    byte[] hero = PlayerDataCodec.Encode(new HeroGrid(
        HeroId: 7,
        TemplateId: PlayerAccountFactory.DefaultHeroTemplateId,
        Lvl: 80,
        AdvLv: 3,
        ArrRemouldEffect: [388, 400],
        RemouldLV: 2));
    Assert(ContainsSequence(hero, new byte[] { 0xB8, 0x01, 0x84, 0x03 }) &&
        ContainsSequence(hero, new byte[] { 0xB8, 0x01, 0x90, 0x03 }),
        "THeroGrid did not encode repeated ArrRemouldEffect field 23");
    Assert(ContainsSequence(hero, new byte[] { 0xC0, 0x01, 0x02 }) &&
        ContainsSequence(hero, new byte[] { 0xC8, 0x01, 0x03 }),
        "THeroGrid did not encode RemouldLV/AdvLv fields 24/25");
    return Task.CompletedTask;
}

static Task ConstructionConfigAndCodecTest()
{
    string configDir = FindClientConfigDir();
    ConstructionConfigLoader.Load(configDir);
    Assert(ConstructionConfigLoader.Formulas.Count == 4,
        "traditional construction formulas were not loaded");
    Assert(ConstructionConfigLoader.Qualities.Count == 2020,
        "traditional construction quality curve was not loaded");
    Assert(ConstructionConfigLoader.Ships.Count == 30,
        "traditional construction ship packages were not loaded");
    Assert(ConstructionService.FormatFormulaMessage(999, 999, 999) ==
           "固定建造配方\n金999 钢999 铝999",
        "traditional construction discussion text does not fit all three resources");

    ShipMainLoader.Load(configDir);
    ShipHandbookLoader.Load(configDir);
    var (_, _, _, shipInfos) = BuildShipExtractLoader.Load(configDir);
    BuildFormulaCatalog.Load(shipInfos);
    var remouldHandbooks = ShipHandbookLoader.All
        .Where(entry => entry.Value.ShowState == 1 && entry.Value.ShowTag == 1)
        .ToList();
    Assert(remouldHandbooks.Count > 0,
        "client config did not contain an open remould handbook entry for construction alias coverage");
    foreach (var (remouldShipInfoId, _) in remouldHandbooks)
    {
        Assert(shipInfos.TryGetValue(remouldShipInfoId, out ConfigShipInfo? remouldInfo) &&
               remouldInfo.SfId > 0,
            $"remould handbook {remouldShipInfoId} did not identify its base ship");
        int baseTemplateId = BuildFormulaCatalog.TryGetTemplateByHtid(checked((int)remouldInfo!.SfId));
        Assert(baseTemplateId > 0 &&
               BuildFormulaCatalog.TryGetTemplateByHtid(remouldShipInfoId) == baseTemplateId,
            $"remould handbook {remouldShipInfoId} did not resolve to its base construction formula");
        Assert(BuildFormulaCatalog.GetFormula(remouldShipInfoId * 10 + 1) is null,
            $"remould handbook {remouldShipInfoId} became an independent construction target");
    }

    var steel = new ProtocolPackage().Write(0x08, 10029UL).Write(0x10, 30UL);
    var aluminium = new ProtocolPackage().Write(0x08, 10030UL).Write(0x10, 40UL);
    var project = new ProtocolPackage()
        .Write(0x0A, steel.ToArray())
        .Write(0x0A, aluminium.ToArray())
        .Write(0x10, 50UL);
    var request = new ProtocolPackage().Write(0x0A, project.ToArray());
    ConstructionProjectsArg decoded = ProtocolDecoder.DecodeConstructionProjectsArg(request.ToArray());
    Assert(decoded.Projects.Count == 1 && decoded.Projects[0].Gold == 50 &&
        decoded.Projects[0].Items.SequenceEqual([
            new ConstructionItemArg(10029, 30), new ConstructionItemArg(10030, 40)]),
        "traditional construction project protobuf mismatch");
    Assert(ProtocolDecoder.DecodeConstructionIndexArg(new byte[] { 0x08, 0x01, 0x08, 0x02 })
        .Indexes.SequenceEqual([1, 2]), "unpacked construction indexes did not decode");
    Assert(ProtocolDecoder.DecodeConstructionIndexArg(new byte[] { 0x0A, 0x02, 0x01, 0x02 })
        .Indexes.SequenceEqual([1, 2]), "packed construction indexes did not decode");

    ConstructionProject persistedProject = new(
        [new ConstructionItem(10029, 30), new ConstructionItem(10030, 40)], 50);
    PlayerAccount account = PlayerAccountFactory.CreateDefault("queue-test", 1) with
    {
        Construction = new PlayerConstruction([
            new ConstructionJob(1, 40110211, 100, 100, false, persistedProject),
            new ConstructionJob(2, 40110211, 200, 200, false, persistedProject),
            new ConstructionJob(3, 40110211, 50, 0, false, persistedProject)], persistedProject, 4),
    };
    PlayerAccount refreshed = ConstructionService.RefreshQueue(account, 500);
    Assert(refreshed.Construction?.Jobs.All(job => job.Completed) == true,
        "offline construction queue did not cascade through waiting work");
    byte[] info = ConstructionService.EncodeInfo(refreshed.Construction);
    Assert(info.Count(value => value == 0x0A) >= 3,
        "completed traditional construction jobs were not encoded");
    return Task.CompletedTask;
}

static Task BuildingCodecTest()
{
    BuildingConfigLoader.Load(FindClientConfigDir());
    Assert(BuildingConfigLoader.Infos.Count == 35 && BuildingConfigLoader.Lands.Count == 10,
        "building or land configs were not loaded");
    Assert(BuildingConfigLoader.GetInfo(11) is { Type: 2, Level: 1 } &&
        BuildingConfigLoader.GetLand(2)?.BuildinggroupId?.Contains(2) == true,
        "electric building/land config mismatch");
    Assert(BuildingConfigLoader.GetLevelUp(11)?.Leveluptime == 0,
        "JP level-1 building should complete immediately");
    Assert(BuildingConfigLoader.MaterialTemplateIds.SequenceEqual(
            new[] { 14001, 14002, 14003, 14004, 14011 }),
        "building material ids were not collected from level-up configs");

    PlayerBuilding state = PlayerAccountFactory.DefaultBuilding(1234);
    Assert(state.Buildings.Count == 2 && state.Buildings.Any(x => x.Tid == 2) &&
        state.Buildings.Any(x => x.Tid == 41), "default office/dormitory state mismatch");
    Assert(state.Lands.Any(x => x.Index == 1 && x.BuildingId == 1) &&
        state.Lands.Any(x => x.Index == 6 && x.BuildingId == 2), "default building land mapping mismatch");

    byte[] snapshot = PlayerDataCodec.Encode(BuildingService.ToProtocol(state, 1234));
    Assert(ContainsSequence(snapshot, new byte[] { 0x08, 0x01, 0x10, 0x02, 0x18, 0x02, 0x28, 0x00 }),
        "building snapshot omitted the level-2 office");
    Assert(ContainsSequence(snapshot, new byte[] { 0x08, 0x02, 0x10, 0x29, 0x18, 0x01, 0x28, 0x00 }),
        "building snapshot omitted the level-1 dormitory");

    var setHero = new ProtocolPackage().Write(0x08, 2UL).Write(0x10, 1UL);
    SetBuildingHeroArg decoded = PlayerDataCodec.DecodeSetBuildingHeroArg(setHero.ToArray());
    Assert(decoded.BuildingId == 2 && decoded.HeroIds.SequenceEqual(new uint[] { 1 }),
        "building.SetHero request did not decode");

    var setList = new ProtocolPackage()
        .Write(0x08, 1UL)
        .Write(0x08, 2UL)
        .Write(0x10, unchecked((ulong)(long)-1))
        .Write(0x10, 1UL)
        .Write(0x10, unchecked((ulong)(long)-1));
    SetBuildingListHeroArg listDecoded = PlayerDataCodec.DecodeSetBuildingListHeroArg(setList.ToArray());
    Assert(listDecoded.BuildingIds.SequenceEqual(new[] { 1, 2 }) &&
        listDecoded.HeroIds.SequenceEqual(new[] { -1, 1, -1 }),
        "building.SetBuildingListHero request did not preserve -1 separators");

    var add = new ProtocolPackage().Write(0x08, 11UL).Write(0x10, 2UL);
    AddBuildingArg addDecoded = PlayerDataCodec.DecodeAddBuildingArg(add.ToArray());
    Assert(addDecoded == new AddBuildingArg(11, 2), "building.AddBuilding request did not decode");
    var buildingId = new ProtocolPackage().Write(0x08, 3UL);
    Assert(PlayerDataCodec.DecodeBuildingIdArg(buildingId.ToArray()) == 3,
        "building lifecycle building id did not decode");
    Assert(PlayerDataCodec.EncodeAddBuildingRet(3).SequenceEqual(new byte[] { 0x08, 0x03 }),
        "building.AddBuilding response did not contain the new building id");
    return Task.CompletedTask;
}

static Task StoryUnlockConfigTest()
{
    string configDir = FindClientConfigDir();
    ChapterCopyLoader.Load(configDir);
    CharacterStoryLoader.Load(configDir);

    Assert(ChapterCopyLoader.GetCopyIds(1).Count > 0, "main story chapter was not loaded");
    Assert(ChapterCopyLoader.GetCopyIds(14005).Contains(953001), "event story chapter was not loaded");
    Assert(ChapterCopyLoader.GetCopyIds(14006).Contains(955001), "side story chapter was not loaded");
    Assert(ChapterCopyLoader.GetCopyIds(10001).Contains(40001), "archived activity story was not loaded");
    Assert(ChapterCopyLoader.GetCopyType(953001) == 1, "event story was not exposed as PlotCopy");
    Assert(ChapterCopyLoader.AllChapterMemories.Contains(new ChapterMemory(10001, 15)),
        "archived activity story was not marked fully unlocked");
    Assert(CharacterStoryLoader.AllMemories.Count > 0, "personal stories were not loaded");
    Assert(CharacterStoryLoader.AllMemories.Contains(new HeroMemory(2064011, 1001)),
        "known personal story was not exposed through HeroMemoryList");
    return Task.CompletedTask;
}

static Task IllustrateBehaviourUnlockTest()
{
    HandbookBehaviourLoader.Load(FindClientConfigDir());
    IReadOnlyList<int> expected = HandbookBehaviourLoader.AllBehaviourIds;
    Assert(expected.Count >= 60, "handbook behaviour index was not fully loaded");
    Assert(expected.SequenceEqual(expected.OrderBy(id => id)) && expected.Distinct().Count() == expected.Count,
        "handbook behaviour ids must be unique and deterministic");

    IllustrateInfo info = GameServices.BuildUnlockedIllustrateInfo(102105, 123456);
    Assert(info.IllustrateId == 102105 && info.GetTime == 123456,
        "unlocked illustrate entry lost its identity or timestamp");
    Assert(info.BehaviourList is not null && info.BehaviourList.SequenceEqual(expected),
        "unlocked illustrate entry did not include every configured behaviour");
    return Task.CompletedTask;
}

static Task HeroMemoryCodecTest()
{
    var memory = new HeroMemory(2064011, 1001);
    var nested = PlayerDataCodec.Encode(memory);
    var payload = PlayerDataCodec.Encode(new IllustrateInfoRet(
        IllustrateEquipList: [new IllustrateEquipInfo()],
        HeroMemoryList: [memory]));

    Assert(payload.Length >= nested.Length + 4, "personal story payload is incomplete");
    Assert(payload[0] == 0x42, "HeroMemoryList must use illustrate field 8");
    Assert(payload[1] == nested.Length, "HeroMemory message length mismatch");
    Assert(payload.AsSpan(2, nested.Length).SequenceEqual(nested), "HeroMemory message body mismatch");
    Assert(payload[2 + nested.Length] == 0x4A, "IllustrateEquipList must remain field 9");

    var chapter = new ChapterMemory(10001, 15);
    var chapterNested = PlayerDataCodec.Encode(chapter);
    var chapterPayload = PlayerDataCodec.Encode(new StoryMemoryList([chapter]));
    Assert(chapterPayload[0] == 0x0A, "MemoryList must use field 1");
    Assert(chapterPayload[1] == chapterNested.Length, "MemoryInfo message length mismatch");
    Assert(chapterPayload.AsSpan(2).SequenceEqual(chapterNested), "MemoryInfo message body mismatch");
    return Task.CompletedTask;
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

static Task BagDeletionMarkerCodecTest()
{
    var payload = PlayerDataCodec.Encode(new BagGridInfo(10180, 0));
    Assert(payload.AsSpan().SequenceEqual(new byte[] { 0x08, 0xC4, 0x4F, 0x10, 0x00 }),
        "zero-count bag entry omitted the explicit Num=0 deletion marker");
    return Task.CompletedTask;
}

static Task TreasureCodecTest()
{
    var arg = PlayerDataCodec.DecodeBagNormalTreasureInfoArg(
        new byte[] { 0x08, 0xBC, 0x50, 0x10, 0x01 });
    Assert(arg == new BagNormalTreasureInfoArg(10300, 1),
        "normal treasure request protobuf mismatch");

    var payload = PlayerDataCodec.Encode(new BagTreasureInfoRet(
        [new CommonReward(Type: 2, ConfigId: 30164, Num: 1, Id: 7)], TreasureId: 10300));
    Assert(payload.Length > 5 && payload[0] == 0x0A && payload[^3..].SequenceEqual(new byte[] { 0x10, 0xBC, 0x50 }),
        "normal treasure response protobuf mismatch");
    return Task.CompletedTask;
}

static Task BuildShipRewardCodecTest()
{
    var payload = ProtocolEncoder.EncodeBuildShipRet(
        [new CommonReward(Type: 1, ConfigId: 2, Num: 1, Id: 3)]);
    Assert(payload.AsSpan().SequenceEqual(
        new byte[] { 0x0A, 0x08, 0x08, 0x01, 0x10, 0x02, 0x18, 0x01, 0x20, 0x03, 0x1A, 0x00 }),
        "build ship response must omit empty SpReward while retaining aligned TransReward");
    return Task.CompletedTask;
}

static async Task BuildShipHundredRewardIntegrationTest()
{
    string repositoryRoot = FindRepositoryRoot();
    string dataRoot = Path.Combine(Path.GetTempPath(), "blueoath-buildship-reward-" + Guid.NewGuid().ToString("N"));
    const string profileId = "hundred-reward-player";
    const string legacyProfileId = "legacy-polluted-bag-player";
    try
    {
        var repo = new SqliteGameRepository(dataRoot);
        ServerOptions options = ServerOptions.Parse([
            "--data=" + dataRoot,
            "--client-path=" + Path.Combine(repositoryRoot, "blueoath", "blueoath"),
            "--profile-id=" + profileId
        ]);
        using Microsoft.Extensions.Logging.ILoggerFactory loggerFactory =
            Microsoft.Extensions.Logging.LoggerFactory.Create(_ => { });
        var services = new GameServices(repo, options, loggerFactory);
        var buildShip = new BuildShipService(services);

        int poolId = 0, limitCount = 0, shipTemplateId = 0, rewardCount = 0;
        foreach (var (id, config) in services.ExtractShips)
        {
            foreach (var entry in config.HundredReward ?? [])
            {
                if (entry.Count >= 4 && entry[0] == 120 && entry[1] == GameServices.GoodsTypeShip &&
                    ShipHandbookLoader.GetShipName(checked((int)entry[2])) == "朝日")
                {
                    poolId = id;
                    limitCount = checked((int)entry[0]);
                    shipTemplateId = checked((int)entry[2]);
                    rewardCount = checked((int)entry[3]);
                    break;
                }
            }
            if (poolId != 0) break;
        }
        Assert(poolId != 0 && shipTemplateId != 0,
            "real client config has no 120-draw Asahi ship reward to exercise");

        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, CancellationToken.None);
        var originalHeroIds = account.Dock.Heroes.Select(hero => hero.HeroId).ToHashSet();
        var buildState = account.BuildState ?? new PlayerBuildState(
            new Dictionary<int, int>(),
            new Dictionary<int, IReadOnlyList<int>>(),
            new Dictionary<int, IReadOnlyList<int>>());
        var drawCount = buildState.DrawCount.ToDictionary(pair => pair.Key, pair => pair.Value);
        drawCount[poolId] = limitCount;
        account = account with { BuildState = buildState with { DrawCount = drawCount } };
        await services.SaveAccountAsync(account, CancellationToken.None);

        var requestArgs = new List<byte>();
        AppendTestVarint(requestArgs, 1 << 3);
        AppendTestVarint(requestArgs, checked((ulong)poolId));
        AppendTestVarint(requestArgs, 2 << 3);
        AppendTestVarint(requestArgs, checked((ulong)limitCount));
        byte[] response = await buildShip.BuildBuildShipRewardRetAsync(
            new TRequest("buildship.BuildShipReward", requestArgs.ToArray()), profileId, CancellationToken.None);

        PlayerAccount claimed = await services.GetOrCreateAccountAsync(profileId, CancellationToken.None);
        Hero granted = claimed.Dock.Heroes.Single(hero => !originalHeroIds.Contains(hero.HeroId));
        Assert(granted.TemplateId == shipTemplateId,
            "120-draw reward created the wrong ship template");
        Assert(claimed.Bag?.Items.Any(item => item.TemplateId == shipTemplateId) != true,
            "ship reward polluted the item bag");
        byte[] expectedReward = PlayerDataCodec.Encode(new CommonReward(
            GameServices.GoodsTypeShip, shipTemplateId, rewardCount, checked((int)granted.HeroId)));
        Assert(ContainsSequence(response, expectedReward),
            "ship reward response omitted the created hero instance id");
        Assert(claimed.BuildState?.UsedRewardInfo.GetValueOrDefault(poolId)?.Contains(limitCount) == true,
            "120-draw reward claim state was not persisted");

        byte[] repeated = await buildShip.BuildBuildShipRewardRetAsync(
            new TRequest("buildship.BuildShipReward", requestArgs.ToArray()), profileId, CancellationToken.None);
        Assert(repeated.Length == 0 &&
               (await services.GetOrCreateAccountAsync(profileId, CancellationToken.None)).Dock.Heroes.Count == claimed.Dock.Heroes.Count,
            "repeated reward claim was not idempotent");

        PlayerAccount legacy = PlayerAccountFactory.CreateDefault(
            legacyProfileId, checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()), legacyProfileId);
        int legacyHeroCount = legacy.Dock.Heroes.Count;
        legacy = GameServices.AddBagItem(legacy, shipTemplateId, 1);
        await repo.SaveAccountAsync(legacy, CancellationToken.None);
        var migrationServices = new GameServices(repo, options, loggerFactory);
        PlayerAccount healed = await migrationServices.GetOrCreateAccountAsync(legacyProfileId, CancellationToken.None);
        Assert(healed.Bag?.Items.Any(item => item.TemplateId == shipTemplateId) != true,
            "GetOrCreateAccountAsync did not remove a ship template from the legacy item bag");
        Assert(healed.Dock.Heroes.Count == legacyHeroCount + 1 &&
               healed.Dock.Heroes.Count(hero => hero.TemplateId == shipTemplateId) == 1,
            "legacy bag cleanup did not restore the claimed ship as a real hero instance");
        PlayerAccount persisted = await repo.LoadAccountAsync(legacyProfileId, CancellationToken.None)
            ?? throw new InvalidDataException("legacy profile disappeared after bag migration");
        Assert(persisted.Bag?.Items.Any(item => item.TemplateId == shipTemplateId) != true,
            "legacy bag cleanup was not persisted");
        Assert(persisted.Dock.Heroes.Count(hero => hero.TemplateId == shipTemplateId) == 1,
            "restored legacy ship instance was not persisted");
    }
    finally
    {
        if (Directory.Exists(dataRoot)) Directory.Delete(dataRoot, true);
    }
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
    Assert(account!.Character.Uid == 1 && account.Character.Name == "Hero", "character defaults mismatch");
    Assert(account.Character.SecretaryId == 1, "secretary id mismatch");
    Assert(account.Dock.Heroes.Count == 1, "dock should contain one hero");
    Assert(account.Dock.Heroes[0].HeroId == account.Character.SecretaryId, "secretary hero not in dock");
    Hero initialHero = account.Dock.Heroes[0];
    Assert(initialHero.Lock, "initial secretary hero was not locked");
    Assert(initialHero.EquipSlots?.SequenceEqual(new uint[] { 1, 0, 2, 0, 0, 0 }) == true,
        "initial secretary hero equipment slots mismatch");
    Assert(account.Equip?.Items is { Count: 2 } initialEquips &&
           initialEquips.Select(x => x.TemplateId).SequenceEqual(new[]
           {
               PlayerAccountFactory.DefaultHeroMainGunTemplateId,
               PlayerAccountFactory.DefaultHeroSecondaryGunTemplateId,
           }) &&
           initialEquips.All(x => x.HeroId == initialHero.HeroId),
        "initial secretary equipment instances were not created and bound");

    // 修改并保存账号，验证往返持久化。
    var updated = account with
    {
        Character = account.Character with { Level = 10 },
        Dock = new HeroDock(
            [new Hero(1, PlayerAccountFactory.DefaultHeroTemplateId, 5), new Hero(2, 10210512, 3)],
            BagSize: 200),
        Building = account.Building! with
        {
            Buildings = account.Building!.Buildings
                .Select(building => building.Id == 2
                    ? building with { HeroIds = new uint[] { 1 } }
                    : building)
                .ToArray(),
        },
    };
    await repo.SaveAccountAsync(updated);
    var reloaded = await repo.LoadAccountAsync("hero");
    Assert(reloaded is not null, "account was not reloaded");
    Assert(reloaded!.Character.Level == 10, "character update not persisted");
    Assert(reloaded.Dock.Heroes.Count == 2 && reloaded.Dock.BagSize == 200, "dock update not persisted");
    Assert(reloaded.Building?.Buildings.Single(x => x.Id == 2).HeroIds.SequenceEqual(new uint[] { 1 }) == true,
        "building assignment not persisted");
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

static Task AccountProfileBootstrapTest()
{
    const string profileId = "player-test_01";
    const string profileName = "测试账号";
    ServerOptions options = ServerOptions.Parse([
        "--profile-id=" + profileId,
        "--profile-name=" + profileName
    ]);
    Assert(options.ProfileId == profileId && options.ProfileName == profileName,
        "server profile identity options mismatch");

    var endpoints = new ServerEndpoints { GameLoginPort = 8123 };
    var responder = new BootstrapHttpResponder(endpoints, new AnnouncementConfig(), options);

    using JsonDocument plData = JsonDocument.Parse(
        responder.BuildResponse("GET /phone/getPlData/getPlData HTTP/1.1").Body);
    // 事件 1007 的信封是 errornu/errordesc/data，平台字段（含 pid）都在 data 之下，
    // 见 BootstrapHttpResponder 的 getPlData 分支；摊到根对象会让 SDK 走 111111
    // 未知错误分支，因此响应体是对的，断言需跟随该结构。
    Assert(plData.RootElement.GetProperty("data").GetProperty("pid").GetString() == profileId,
        "getPlData did not expose selected profile");

    using JsonDocument login = JsonDocument.Parse(
        responder.BuildResponse("GET /login?test=1 HTTP/1.1").Body);
    Assert(login.RootElement.GetProperty("Pid").GetString() == profileId &&
        login.RootElement.GetProperty("openid").GetString() == profileId,
        "SDK login did not expose selected profile");

    using JsonDocument hash = JsonDocument.Parse(
        responder.BuildResponse("GET /gethash HTTP/1.1").Body);
    Assert(hash.RootElement.GetProperty("pid").GetString() == profileId,
        "gethash did not expose selected profile");
    return Task.CompletedTask;
}

static Task DuplicateHeroMigrationTest()
{
    PlayerAccount account = PlayerAccountFactory.CreateDefault("duplicate-hero", 1);
    Hero original = account.Dock.Heroes[0] with
    {
        HeroId = 11,
        TemplateId = 20640214,
        Advance = 3,
        Level = 49,
    };
    Hero upgraded = original with { TemplateId = 20640215, Advance = 4 };
    Hero neighbor = original with { HeroId = 14, TemplateId = 20620111, Advance = 0 };
    account = account with
    {
        Dock = account.Dock with { Heroes = [original, upgraded, neighbor] },
    };

    PlayerAccount repaired = GameServices.RepairDuplicateHeroIds(account);
    Assert(repaired.Dock.Heroes.Select(hero => hero.HeroId).SequenceEqual([11U, 14U]) &&
           repaired.Dock.Heroes[0].TemplateId == 20640215 &&
           repaired.Dock.Heroes[0].Advance == 4,
        "duplicate hero migration did not preserve the upgraded record");
    Assert(ReferenceEquals(GameServices.RepairDuplicateHeroIds(repaired), repaired),
        "duplicate hero migration was not idempotent");
    return Task.CompletedTask;
}

static Task AccountProfileNameMigrationTest()
{
    const string profileId = "player-legacy01";
    PlayerAccount legacy = PlayerAccountFactory.CreateDefault(profileId, 1) with
    {
        ProfileDisplayName = null
    };

    PlayerAccount migrated = GameServices.SynchronizeProfileDisplayName(legacy, "Asa");
    Assert(migrated.Character.Name == "Asa" && migrated.ProfileDisplayName == "Asa",
        "legacy profile id name was not migrated to the launcher account name");

    PlayerAccount renamedInLauncher = GameServices.SynchronizeProfileDisplayName(migrated, "Bob");
    Assert(renamedInLauncher.Character.Name == "Bob" && renamedInLauncher.ProfileDisplayName == "Bob",
        "launcher-managed character name did not follow account rename");

    PlayerAccount custom = renamedInLauncher with
    {
        Character = renamedInLauncher.Character with { Name = "游戏内昵称" }
    };
    PlayerAccount preserved = GameServices.SynchronizeProfileDisplayName(custom, "Carol");
    Assert(preserved.Character.Name == "游戏内昵称" && preserved.ProfileDisplayName == "Carol",
        "custom in-game character name was overwritten");

    byte[] userList = GameServices.EncodeGetUsers(preserved);
    ProtocolDecoder.ProtoReader listReader = new(userList);
    Assert(listReader.TryReadField(out int field, out int wire) && field == 1 && wire == 2,
        "saved character was omitted from player.GetUserList");
    byte[] userInfo = listReader.ReadBytes().ToArray();
    Assert(ProtocolDecoder.DecodeStringField(userInfo, 2) == "游戏内昵称" &&
           ProtocolDecoder.DecodeVarintField(userInfo, 3) == 80,
        "player.GetUserList did not preserve the saved character name and level");
    return Task.CompletedTask;
}

static Task EquipmentModTest()
{
    string modsRoot = Path.Combine(FindRepositoryRoot(), "Mods");
    EquipmentModCatalog catalog = EquipmentModLoader.Load(modsRoot, "jp-1.4.0");
    EquipmentModDefinition definition = catalog.Equipment.Single(x => x.Id == 900001);
    Assert(definition.SourceTemplateId == 30023,
        "custom equipment does not clone the expected built-in template");
    Assert(catalog.Goods.Single(x => x.GoodId == 990001) is
        { ShopId: 5, Type: GameServices.GoodsTypeEquip, ItemId: 900001, Num: 1 },
        "custom equipment GM shop good is invalid");

    var source = new ConfigEquip
    {
        EId = 30023,
        Name = "source",
        Quality = 3,
        EnhanceLevelMax = 30,
        StarMax = 5,
        EquipProp = [[8, 67], [3200, 225]],
        EnhanceProp = [[8, 4], [3200, 15]],
    };
    ConfigEquip custom = EquipmentModLoader.BuildConfig(source, definition);
    Assert(custom.EId == 900001 && custom.Name == "未来試作砲" && custom.NoResolve == 1,
        "custom equipment overrides were not applied");
    Assert(custom.EquipProp is [[8, 90], [3200, 300]] &&
           custom.EnhanceProp is [[8, 6], [3200, 20]],
        "custom equipment attributes were not applied");
    Assert(source.EId == 30023 && source.Name == "source",
        "building custom equipment mutated its source template");

    var merged = EquipmentModLoader.MergeGoods(
        new GmGoodsConfig([], new Dictionary<int, int>()), catalog);
    Assert(merged.Goods.Any(x => x.GoodId == 990001),
        "custom equipment was not merged into the GM shop catalog");
    Assert(EquipmentModLoader.Load(modsRoot, "cn-1.5.20").Equipment.Count == 0,
        "JP custom equipment loaded for the CN client");
    return Task.CompletedTask;
}

static Task EquipmentModConfigIntegrationTest()
{
    string root = FindRepositoryRoot();
    string clientPath = Environment.GetEnvironmentVariable("BLUEOATH_TEST_CLIENT_PATH")
        ?? Path.Combine(root, "blueoath", "blueoath");
    string configDir = ConfigDbLoader.BuildConfigDir(clientPath);
    Assert(File.Exists(Path.Combine(configDir, "config_equip.db")),
        "real config_equip.db is missing");
    EquipmentModCatalog catalog = EquipmentModLoader.Load(Path.Combine(root, "Mods"), "jp-1.4.0");
    EquipLoader.Load(configDir, catalog.Equipment);
    ConfigEquip? custom = EquipLoader.Get(900001);
    Assert(custom is { EId: 900001, Name: "未来試作砲", NoResolve: 1 },
        "custom equipment was not added to the real server catalog");
    Assert(custom!.EquipProp is [[8, 90], [3200, 300]],
        "real server catalog contains incorrect custom equipment attributes");
    Assert(EquipLoader.Get(30023) is { EId: 30023 },
        "source equipment disappeared after applying the mod overlay");
    return Task.CompletedTask;
}

static Task FashionPreviewModTest()
{
    string root = FindRepositoryRoot();
    string modsRoot = Path.Combine(root, "Mods");
    var manager = new ModManager(modsRoot, "jp-1.4.0");
    manager.LoadAll();
    Assert(manager.LoadedIds.Contains("fashion-preview-fix.mod"),
        "fashion preview fix was not discoverable by the JP mod loader");

    string entry = File.ReadAllText(Path.Combine(modsRoot, "fashion-preview-fix.mod", "main.lua"));
    Assert(entry.Contains("GetOwnFashionByHeroId", StringComparison.Ordinal) &&
           entry.Contains("hero_id == nil", StringComparison.Ordinal) &&
           entry.Contains("self:GetOwnFashion(sf_id)", StringComparison.Ordinal),
        "fashion preview hook does not guard nil heroes through ship-level ownership");
    Assert(!entry.Contains("key ~= \"heroId\"", StringComparison.Ordinal),
        "fashion preview hook still strips heroId and can break remould ownership checks");
    string bootstrap = File.ReadAllText(Path.Combine(modsRoot, "bootstrap.lua"));
    Assert(bootstrap.Contains("fashion-preview-fix.mod/main.lua", StringComparison.Ordinal) &&
           bootstrap.Contains("global_watchers", StringComparison.Ordinal) &&
           bootstrap.Contains("watch_global = function", StringComparison.Ordinal),
        "fashion preview fix is missing its shared runtime global watcher");
    return Task.CompletedTask;
}

static Task BuildShipNewStateNativePatchTest()
{
    string root = FindRepositoryRoot();
    string source = File.ReadAllText(Path.Combine(root, "native", "Payload", "lua_mod_loader.cpp"));
    Assert(source.Contains("BuildShipCheckShowMeetPatched", StringComparison.Ordinal) &&
           source.Contains("pendingBuildShipIsNew", StringComparison.Ordinal) &&
           source.Contains("ShowGirlUpdatePagePatched", StringComparison.Ordinal) &&
           source.Contains("showGirlSetField(state, paramIndex, \"bNew\")", StringComparison.Ordinal),
        "native xLua bridge does not carry CheckShowMeet into ShowGirlPage");
    Assert(source.Contains("hasBuildNum && !hasGetWay", StringComparison.Ordinal) &&
           source.Contains("TryPatchBuildShipNewState(state)", StringComparison.Ordinal),
        "native build-ship patch is not scoped and invoked for live Lua states");

    string bootstrap = File.ReadAllText(Path.Combine(root, "Mods", "bootstrap.lua"));
    Assert(!bootstrap.Contains("buildship-new-state-fix", StringComparison.Ordinal),
        "build-ship new-state fix still depends on a Lua mod entry");
    return Task.CompletedTask;
}

static async Task TcpIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    var data = Path.Combine(Path.GetTempPath(), "blueoath-tcp-" + Guid.NewGuid().ToString("N"));
    var startInfo = new ProcessStartInfo("dotnet") { RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false, CreateNoWindow = true };
    startInfo.ArgumentList.Add(serverDll); startInfo.ArgumentList.Add("--port=0"); startInfo.ArgumentList.Add("--region=jp"); startInfo.ArgumentList.Add("--data=" + data);
    startInfo.ArgumentList.Add("--client-path=" + Path.Combine(root, "blueoath", "blueoath"));
    startInfo.ArgumentList.Add("--profile-id=local-player");
    startInfo.ArgumentList.Add("--profile-name=默认账号");
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "server process did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("port").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        await using var client = new LocalGameClient(); await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        JsonElement login = await client.SendAsync<JsonElement>(MessageTypes.Login,
            new { profileId = "local_player", name = "local_player" }, timeout.Token);
        Assert(login.GetProperty("profileId").GetString() == "local-player",
            "legacy login did not return the launcher-selected profile");
        var state = await client.SendAsync<PlayerState>(MessageTypes.State, new { profileId = "local_player" }, timeout.Token); Assert(state.Fuel == 100, "initial state mismatch");
        await client.SendAsync<PlayerState>(MessageTypes.SetFormation, new { profileId = "local_player", shipIds = new[] { 1001, 1002 } }, timeout.Token);
        await client.SendAsync<Stage>(MessageTypes.EnterStage, new { profileId = "local_player", stageId = 1 }, timeout.Token);
        var outcome = await client.SendAsync<JsonElement>(MessageTypes.BattleResult, new { profileId = "local_player", stageId = 1, win = true }, timeout.Token); Assert(outcome.GetProperty("outcome").GetProperty("victory").GetBoolean(), "battle response mismatch");

        var repo = new SqliteGameRepository(data);
        Assert((await repo.ListProfilesAsync()).SequenceEqual(["local-player"]),
            "legacy login created a second profile from the client-supplied id");
        Assert(await repo.LoadAccountAsync("local-player") is not null &&
               await repo.LoadAccountAsync("local_player") is null,
            "legacy login created a second account from the client-supplied id");
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
    var clientPath = Environment.GetEnvironmentVariable("BLUEOATH_CLIENT_PATH")
        ?? Path.Combine(root, "blueoath", "blueoath");
    startInfo.ArgumentList.Add("--client-path=" + clientPath);
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
        var observedPushes = new List<TResponse>();

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
                observedPushes.Add(response);
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
        Assert(observedPushes.Any(p => p.Method == "copy.GetCopy" && p.Ret is { Length: > 20 } &&
            p.Ret[^2] == 0x18 && p.Ret[^1] == 33),
            "user login did not synchronize MubarCopy (CopyType=33), leaving アンブラ進軍 empty");

        var userInfo = await RoundTrip("user.GetUserInfo", null);
        Assert(userInfo.Method == "user.GetUserInfo", "get user info response method mismatch");
        Assert(userInfo.Ret is { Length: > 0 }, "get user info response was empty");

        byte[] mubarStartArgs = new ProtocolPackage()
            .Write(0x10, 932113UL) // CopyId(2)
            .Write(0x48, 1UL)      // BattleMode(9)=Normal
            .ToArray();
        var mubarStart = await RoundTrip("copy.StartBase", mubarStartArgs);
        Assert(mubarStart.Method == "copy.StartBase", "Mubar StartBase response method mismatch");
        Assert(mubarStart.Ret is { Length: > 0 } &&
               ProtocolDecoder.DecodeVarintField(mubarStart.Ret, 7) == 33,
            "Mubar StartBase response did not preserve CopyType 33");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task TreasureIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    var data = Path.Combine(root, "test-treasure-tmp");
    Directory.CreateDirectory(data);
    const string profileId = "treasure-player";
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
        Assert(process.Start(), "treasure test server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        var port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        var stream = client.GetStream();

        async Task<TResponse> RoundTrip(string method, byte[]? args, ICollection<TResponse>? prePushes = null)
        {
            byte[] request = TMessageCodec.EncodeRequest(new TRequest(method, args, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                TResponse response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                if (response.IsResponse == 1) return response;
                prePushes?.Add(response);
            }
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin(profileId, 1, "open", "hash")));
        await RoundTrip("player.GetUserList", null);
        await RoundTrip("player.CreateUser",
            new byte[] { 0x0A, 0x04, (byte)'b', (byte)'o', (byte)'x', (byte)'1', 0x10, 0x01 });
        await RoundTrip("user.UserLogin", new byte[] { 0x08, 0x01 });

        // GM 商品 10001（shop 18）发放一个 10300「激稀有武器箱」。
        TResponse bought = await RoundTrip("shop.BuyGoods",
            new byte[] { 0x08, 0x12, 0x10, 0x91, 0x4E, 0x18, 0x01 });
        Assert(bought.Err == 0, "equipment treasure could not be granted");
        var repo = new SqliteGameRepository(data);
        PlayerAccount before = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("treasure profile was not persisted");
        int equipCountBefore = before.Equip?.Items.Count ?? 0;
        Assert(before.Bag?.Items.Any(x => x.TemplateId == 10300 && x.Num == 1) == true,
            "granted equipment treasure was missing from the bag");

        var openPushes = new List<TResponse>();
        TResponse opened = await RoundTrip("bag.GetNormalTreasureInfo",
            new byte[] { 0x08, 0xBC, 0x50, 0x10, 0x01 }, openPushes);
        Assert(opened.Err == 0 && opened.Ret is { Length: > 0 }, "equipment treasure response was empty");
        Assert(opened.Ret![0] == 0x0A && opened.Ret[^3..].SequenceEqual(new byte[] { 0x10, 0xBC, 0x50 }),
            "equipment treasure response did not contain reward and treasure id");
        TResponse bagPush = openPushes.Single(x => x.Method == "bag.UpdateBagData");
        Assert(bagPush.Ret is { Length: > 0 } &&
            ContainsSequence(bagPush.Ret, new byte[] { 0x08, 0xBC, 0x50, 0x10, 0x00 }),
            "consumed equipment treasure did not send a Num=0 bag deletion marker");

        PlayerAccount after = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("opened treasure profile was not persisted");
        Assert(after.Bag?.Items.All(x => x.TemplateId != 10300) != false,
            "opened equipment treasure was not consumed");
        Assert((after.Equip?.Items.Count ?? 0) == equipCountBefore + 1,
            "opening the treasure did not create exactly one equipment instance");
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
    startInfo.ArgumentList.Add("--client-path=" + Path.Combine(root, "blueoath", "blueoath"));
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

static async Task BuildingAssignmentIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    // 配置加载器从数据目录向上定位客户端配置，因此集成数据放在仓库根目录内。
    var data = Path.Combine(root, "test-building-" + Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(data);
    const string profileId = "building-player";
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
        Assert(process.Start(), "building test server did not start");
        var readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(10));
        using var ready = JsonDocument.Parse(readyLine ?? throw new InvalidDataException("server did not report ready"));
        int port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        NetworkStream stream = client.GetStream();

        async Task<TResponse> RoundTrip(
            string method,
            byte[]? args,
            ICollection<TResponse>? prePushes = null)
        {
            byte[] request = TMessageCodec.EncodeRequest(new TRequest(method, args, 1));
            await NetSocketFrameCodec.WriteAsync(stream, request, NetSocketFrameCodec.TypeData, timeout.Token);
            while (true)
            {
                var frame = await NetSocketFrameCodec.ReadAsync(stream, timeout.Token);
                Assert(frame is not null, $"empty response for {method}");
                TResponse response = TMessageCodec.DecodeResponse(frame!.Value.Payload);
                if (response.IsResponse == 1) return response;
                prePushes?.Add(response);
            }
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin(profileId, 1, "open", "hash")));
        await RoundTrip("player.GetUserList", null);
        await RoundTrip("player.CreateUser",
            new byte[] { 0x0A, 0x04, (byte)'b', (byte)'a', (byte)'s', (byte)'e', 0x10, 0x01 });

        var assignedPushes = new List<TResponse>();
        var setHero = new ProtocolPackage().Write(0x08, 2UL).Write(0x10, 1UL);
        TResponse assigned = await RoundTrip("building.SetHero", setHero.ToArray(), assignedPushes);
        Assert(assigned.Err == 0, "building.SetHero returned an error");
        TResponse? push = assignedPushes.LastOrDefault(item => item.Method == "building.UpdateBuildingInfo");
        Assert(push is not null, "building.SetHero did not send a refresh push before its response");
        Assert(push!.IsResponse == 0 && push.Method == "building.UpdateBuildingInfo",
            "building.SetHero sent the wrong refresh push");
        Assert(push.Ret is { Length: > 0 } &&
            ContainsSequence(push.Ret, new byte[] { 0x08, 0x02, 0x10, 0x29, 0x18, 0x01, 0x20, 0x01 }),
            "dormitory refresh did not include the assigned hero");

        var initialRepo = new SqliteGameRepository(data);
        PlayerAccount beforeConstruction = await initialRepo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("building profile was not persisted before construction");
        int initialGold = beforeConstruction.Character.Gold;
        string initialBag = JsonSerializer.Serialize(beforeConstruction.Bag);
        Assert(BuildingConfigLoader.MaterialTemplateIds.All(templateId =>
                beforeConstruction.Bag?.Items.SingleOrDefault(item => item.TemplateId == templateId)?.Num >= 99_999),
            "new profile did not receive the building materials required by the client");

        var addPushes = new List<TResponse>();
        var add = new ProtocolPackage().Write(0x08, 11UL).Write(0x10, 2UL);
        TResponse added = await RoundTrip("building.AddBuilding", add.ToArray(), addPushes);
        Assert(added.Err == 0 && added.Ret?.SequenceEqual(new byte[] { 0x08, 0x03 }) == true,
            "building.AddBuilding did not return building id 3");
        TResponse? addPush = addPushes.LastOrDefault(item => item.Method == "building.UpdateBuildingInfo");
        Assert(addPush?.Ret is { Length: > 0 } &&
            ContainsSequence(addPush.Ret, new byte[] { 0x08, 0x03, 0x10, 0x0B, 0x18, 0x01 }),
            "building.AddBuilding did not pre-push the new electric building");

        var occupied = new ProtocolPackage().Write(0x08, 11UL).Write(0x10, 2UL);
        TResponse duplicate = await RoundTrip("building.AddBuilding", occupied.ToArray());
        Assert(duplicate.Err != 0, "building.AddBuilding accepted an occupied land");

        static byte[] BuildingId(int id) => new ProtocolPackage().Write(0x08, unchecked((ulong)id)).ToArray();

        var officeUpgradePushes = new List<TResponse>();
        TResponse officeUpgraded = await RoundTrip(
            "building.UpgradeBuilding", BuildingId(1), officeUpgradePushes);
        Assert(officeUpgraded.Err == 0 && officeUpgradePushes.Any(item =>
                item.Method == "building.UpdateBuildingInfo" && item.Ret is { Length: > 0 } &&
                ContainsSequence(item.Ret, new byte[] { 0x08, 0x01, 0x10, 0x03, 0x18, 0x03 })),
            "office upgrade to level 3 was not synchronized before the response");

        TResponse electricUpgraded = await RoundTrip("building.UpgradeBuilding", BuildingId(3));
        Assert(electricUpgraded.Err == 0, "electric building upgrade failed");
        TResponse electricDegraded = await RoundTrip("building.DegradeBuilding", BuildingId(3));
        Assert(electricDegraded.Err == 0, "electric building degradation failed");

        TResponse officeDegraded = await RoundTrip("building.DegradeBuilding", BuildingId(1));
        Assert(officeDegraded.Err == 0, "office degradation from level 3 to level 2 failed");
        TResponse invalidOfficeDegrade = await RoundTrip("building.DegradeBuilding", BuildingId(1));
        Assert(invalidOfficeDegrade.Err == 3409,
            "office degradation ignored an occupied land's office-level requirement");

        TResponse finished = await RoundTrip("building.FinishBuilding", BuildingId(3));
        Assert(finished.Err == 0, "building.FinishBuilding was not idempotent for an instant build");

        var repo = new SqliteGameRepository(data);
        PlayerAccount persisted = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("building profile was not persisted");
        Assert(persisted.Building?.Buildings.Single(x => x.Id == 2).HeroIds.SequenceEqual(new uint[] { 1 }) == true,
            "building assignment was not written to the profile database");
        Assert(persisted.Building?.Buildings.Single(x => x.Id == 1) is { Tid: 2, Level: 2 } &&
            persisted.Building.Buildings.Single(x => x.Id == 3) is { Tid: 11, Level: 1 } &&
            persisted.Building.Lands.Any(x => x.Index == 2 && x.BuildingId == 3),
            "building lifecycle result was not written to the profile database");
        Assert(persisted.Character.Gold == initialGold &&
            JsonSerializer.Serialize(persisted.Bag) == initialBag,
            "base construction unexpectedly consumed gold or items");
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
    string clientPath = Path.Combine(root, "blueoath", "blueoath");
    string configDir = ConfigDbLoader.BuildConfigDir(clientPath);
    FashionConfigLoader.Load(configDir);
    FashionShopCatalog catalog = FashionShopGoodsLoader.Load(configDir);
    Assert(catalog.Goods.Count(g => g.ShopId == 23) == 32 &&
           catalog.Goods.Count(g => g.ShopId == 29) == 51,
        "fashion catalog was not rebuilt from the 32 featured and 51 broken shelf entries");
    Assert(catalog.Goods.Single(g => g.ItemId == 4011014).ShopId == 29,
        "legacy Z1 broken fashion was not moved from its stale shop_id 23 to shelf shop 29");
    Assert(catalog.Goods.All(g => g.ItemId != 1062024),
        "archived Ranger broken fashion was reintroduced despite being absent from both shelves");

    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    // 游戏客户端配置目录由 --client-path 直接指定（不再依赖数据目录位置向上逐级查找）。
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
    startInfo.ArgumentList.Add("--client-path=" + clientPath);
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

        var shopsResponse = await RoundTrip("shop.GetShopsInfo", null);
        Dictionary<int, List<int>> shopGoods = DecodeShopGoods(shopsResponse.Ret ?? []);
        Assert(shopGoods.GetValueOrDefault(23) is { Count: 32 },
            $"featured fashion shop 23 did not contain its 32 shelf fashions " +
            $"(actual: {shopGoods.GetValueOrDefault(23)?.Count ?? 0})");
        Assert(shopGoods.GetValueOrDefault(29) is { Count: 51 },
            $"broken fashion shop 29 did not contain its 51 shelf fashions " +
            $"(actual: {shopGoods.GetValueOrDefault(29)?.Count ?? 0})");
        Assert(!shopGoods[23].Intersect(shopGoods[29]).Any(),
            "featured and broken fashion shops contained overlapping shelf goods");
        Assert(shopGoods.GetValueOrDefault(1)?.Contains(500) != true,
            "legacy unassigned fashion good 500 remained visible in shop 1");

        int fashionGoodId = shopGoods[23][0];
        var buyResponse = await RoundTrip("shop.BuyGoods", EncodeBuyGoodsRequest(23, fashionGoodId));
        Assert(buyResponse.Err == 0,
            $"fashion good {fashionGoodId} was listed in shop 23 but purchase validation rejected it");

        int brokenFashionGoodId = shopGoods[29][0];
        var brokenBuyResponse = await RoundTrip(
            "shop.BuyGoods", EncodeBuyGoodsRequest(29, brokenFashionGoodId));
        Assert(brokenBuyResponse.Err == 0,
            $"broken fashion good {brokenFashionGoodId} was listed in shop 29 but purchase validation rejected it");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static Dictionary<int, List<int>> DecodeShopGoods(byte[] payload)
{
    var shops = new Dictionary<int, List<int>>();
    int offset = 0;
    while (offset < payload.Length)
    {
        ulong key = ReadTestVarint(payload, ref offset);
        int field = checked((int)(key >> 3));
        int wire = (int)(key & 7);
        if (field != 1 || wire != 2)
        {
            SkipTestField(payload, ref offset, wire);
            continue;
        }

        byte[] shopPayload = ReadTestBytes(payload, ref offset);
        int shopOffset = 0;
        int shopId = 0;
        var goods = new List<int>();
        while (shopOffset < shopPayload.Length)
        {
            ulong shopKey = ReadTestVarint(shopPayload, ref shopOffset);
            int shopField = checked((int)(shopKey >> 3));
            int shopWire = (int)(shopKey & 7);
            if (shopField == 1 && shopWire == 0)
            {
                shopId = checked((int)ReadTestVarint(shopPayload, ref shopOffset));
            }
            else if (shopField == 3 && shopWire == 2)
            {
                byte[] goodsPayload = ReadTestBytes(shopPayload, ref shopOffset);
                int goodsOffset = 0;
                while (goodsOffset < goodsPayload.Length)
                {
                    ulong goodsKey = ReadTestVarint(goodsPayload, ref goodsOffset);
                    int goodsField = checked((int)(goodsKey >> 3));
                    int goodsWire = (int)(goodsKey & 7);
                    if (goodsField == 1 && goodsWire == 0)
                        goods.Add(checked((int)ReadTestVarint(goodsPayload, ref goodsOffset)));
                    else
                        SkipTestField(goodsPayload, ref goodsOffset, goodsWire);
                }
            }
            else
            {
                SkipTestField(shopPayload, ref shopOffset, shopWire);
            }
        }
        if (shopId != 0) shops[shopId] = goods;
    }
    return shops;
}

static byte[] EncodeBuyGoodsRequest(int shopId, int goodId)
{
    var bytes = new List<byte>();
    AppendTestVarint(bytes, 1 << 3);
    AppendTestVarint(bytes, checked((ulong)shopId));
    AppendTestVarint(bytes, 2 << 3);
    AppendTestVarint(bytes, checked((ulong)goodId));
    AppendTestVarint(bytes, 3 << 3);
    AppendTestVarint(bytes, 1);
    return bytes.ToArray();
}

static void AppendTestVarint(List<byte> bytes, ulong value)
{
    while (value >= 0x80)
    {
        bytes.Add((byte)(value | 0x80));
        value >>= 7;
    }
    bytes.Add((byte)value);
}

static ulong ReadTestVarint(byte[] payload, ref int offset)
{
    ulong value = 0;
    for (int shift = 0; shift < 64; shift += 7)
    {
        if (offset >= payload.Length) throw new EndOfStreamException("truncated test protobuf varint");
        byte current = payload[offset++];
        value |= (ulong)(current & 0x7f) << shift;
        if ((current & 0x80) == 0) return value;
    }
    throw new InvalidDataException("test protobuf varint is too long");
}

static byte[] ReadTestBytes(byte[] payload, ref int offset)
{
    int length = checked((int)ReadTestVarint(payload, ref offset));
    if (length < 0 || offset + length > payload.Length)
        throw new EndOfStreamException("truncated test protobuf bytes");
    byte[] value = payload.AsSpan(offset, length).ToArray();
    offset += length;
    return value;
}

static void SkipTestField(byte[] payload, ref int offset, int wire)
{
    switch (wire)
    {
        case 0:
            ReadTestVarint(payload, ref offset);
            return;
        case 1:
            offset = checked(offset + 8);
            break;
        case 2:
            offset = checked(offset + checked((int)ReadTestVarint(payload, ref offset)));
            break;
        case 5:
            offset = checked(offset + 4);
            break;
        default:
            throw new InvalidDataException($"unsupported test protobuf wire type {wire}");
    }
    if (offset > payload.Length) throw new EndOfStreamException("truncated test protobuf field");
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

static async Task EquipEnhanceIntegrationTest()
{
    var root = FindRepositoryRoot();
    var serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0", "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the solution first");
    var data = Path.Combine(root, "test-equip-enhance-" + Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(data);
    const string profileId = "equip-enhance-player";
    const uint normalEquipId = 77;
    const uint heroPageEquipId = 78;
    const uint boundEquipId = 79;
    const uint goldEquipId = 80;
    const uint legacyGoldEquipId = 81;
    const uint riseStarEquipId = 82;
    const uint riseStarConsumedEquipId = 83;
    const uint universalRiseStarEquipId = 84;
    const uint universalCoreEquipId = 85;
    const uint wrongQualityCoreEquipId = 86;
    const int urEquipTemplateId = 100106;
    const int goldEquipTemplateId = 100101;
    const int goldUniversalCoreTemplateId = 30581;
    const int purpleUniversalCoreTemplateId = 30582;

    var repo = new SqliteGameRepository(data);
    await repo.CreateAsync(profileId, profileId);
    PlayerAccount seeded = await repo.LoadAccountAsync(profileId)
        ?? throw new InvalidDataException("failed to seed equipment enhancement account");
    Hero hero = seeded.Dock.Heroes[0];
    uint[] slots = [normalEquipId, heroPageEquipId, boundEquipId, 0, 0, 0];
    seeded = seeded with
    {
        Character = seeded.Character with { Gold = 100_000, UrEquipCoin = 100 },
        Dock = seeded.Dock with
        {
            Heroes = [hero with { EquipSlots = slots }],
        },
        Equip = new PlayerEquip(
        [
            new EquipItem(normalEquipId, urEquipTemplateId, EnhanceLv: 1, HeroId: hero.HeroId),
            new EquipItem(heroPageEquipId, urEquipTemplateId, EnhanceLv: 1, HeroId: hero.HeroId),
            new EquipItem(boundEquipId, urEquipTemplateId, EnhanceLv: 35, HeroId: hero.HeroId),
            new EquipItem(goldEquipId, goldEquipTemplateId),
            // Older builds stored only the remainder instead of cumulative EnhanceExp.
            new EquipItem(legacyGoldEquipId, goldEquipTemplateId, EnhanceLv: 3, EnhanceExp: 0),
            new EquipItem(riseStarEquipId, goldEquipTemplateId, EnhanceLv: 15, Star: 2),
            new EquipItem(riseStarConsumedEquipId, goldEquipTemplateId),
            new EquipItem(universalRiseStarEquipId, goldEquipTemplateId, EnhanceLv: 15, Star: 2),
            new EquipItem(universalCoreEquipId, goldUniversalCoreTemplateId),
            new EquipItem(wrongQualityCoreEquipId, purpleUniversalCoreTemplateId),
        ], 2000),
        Bag = new PlayerBag(
        [
            new BagItem(60000, 30),
            new BagItem(10029, 200),
            new BagItem(10030, 200),
            new BagItem(60003, 15),
            new BagItem(10000, 53),
        ], 100),
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
    startInfo.ArgumentList.Add("--profile-id=" + profileId);
    startInfo.ArgumentList.Add("--client-path=" + Path.Combine(root, "blueoath", "blueoath"));
    using var process = new Process { StartInfo = startInfo };
    try
    {
        Assert(process.Start(), "equipment enhancement test server did not start");
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

        static byte[] EnhanceArgs(uint equipId, params (uint TemplateId, uint Num)[] items)
        {
            var args = new ProtocolPackage().Write(0x08, equipId);
            foreach (var item in items)
            {
                var body = new ProtocolPackage()
                    .Write(0x08, item.TemplateId)
                    .Write(0x10, item.Num);
                args.Write(0x12, body.ToArray());
            }
            return args.ToArray();
        }

        static byte[] RiseStarArgs(uint equipId, params uint[] consumeIds)
        {
            var args = new ProtocolPackage().Write(0x08, equipId);
            foreach (uint consumeId in consumeIds)
                args.Write(0x10, consumeId);
            return args.ToArray();
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin(profileId, 1, "open", "hash")));
        await RoundTrip("hero.GetHeroInfo", null); // drain login synchronization pushes

        var (normalResponse, normalPushes) = await RoundTrip("equip.Enhance", EnhanceArgs(normalEquipId,
            (60000, 5), (10029, 100), (10030, 100)));
        Assert(normalResponse.Err == 0 && normalResponse.Ret is { Length: > 0 },
            $"equipped UR normal enhancement was rejected: {normalResponse.ErrMsg}");
        Assert(normalPushes.Any(p => p.Method == "bag.UpdateBagData") &&
            normalPushes.Any(p => p.Method == "equip.UpdateEquipBagData"),
            "equipped UR normal enhancement did not refresh bag and equipment data");
        PlayerAccount normallyEnhanced = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("normal enhancement account disappeared");
        Assert(normallyEnhanced.Equip!.Items.Single(e => e.EquipId == normalEquipId).EnhanceLv == 2,
            "equipped UR normal enhancement did not persist level 2");
        Assert(normallyEnhanced.Bag!.Items.Single(i => i.TemplateId == 60000).Num == 25 &&
            normallyEnhanced.Bag.Items.Single(i => i.TemplateId == 10029).Num == 100 &&
            normallyEnhanced.Bag.Items.Single(i => i.TemplateId == 10030).Num == 100,
            "equipped UR normal enhancement consumed the wrong material amount");

        var (heroPageResponse, heroPagePushes) =
            await RoundTrip("equip.EnhanceBind", EnhanceArgs(heroPageEquipId));
        Assert(heroPageResponse.Err == 0 && heroPageResponse.Ret is { Length: > 0 },
            "hero-page UR enhancement without ItemArr was rejected");
        Assert(heroPagePushes.Any(p => p.Method == "bag.UpdateBagData") &&
            heroPagePushes.Any(p => p.Method == "equip.UpdateEquipBagData"),
            "hero-page UR enhancement did not refresh bag and equipment data");
        PlayerAccount heroPageEnhanced = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("hero-page enhancement account disappeared");
        Assert(heroPageEnhanced.Equip!.Items.Single(e => e.EquipId == heroPageEquipId).EnhanceLv == 2,
            "hero-page UR enhancement did not persist level 2");
        Assert(heroPageEnhanced.Bag!.Items.Single(i => i.TemplateId == 60000).Num == 20 &&
               !heroPageEnhanced.Bag.Items.Any(i => i.TemplateId is 10029 or 10030),
            "hero-page UR enhancement did not consume its configured materials");

        for (int expectedLevel = 1; expectedLevel <= 4; expectedLevel++)
        {
            var (goldResponse, _) = await RoundTrip("equip.Enhance", EnhanceArgs(goldEquipId, (60000, 2)));
            Assert(goldResponse.Err == 0 && goldResponse.Ret is { Length: > 0 },
                $"gold equipment enhancement {expectedLevel} was rejected");
            PlayerAccount goldEnhanced = await repo.LoadAccountAsync(profileId)
                ?? throw new InvalidDataException("gold enhancement account disappeared");
            EquipItem gold = goldEnhanced.Equip!.Items.Single(e => e.EquipId == goldEquipId);
            Assert(gold.EnhanceLv == expectedLevel && gold.EnhanceExp == expectedLevel * 200,
                $"gold equipment enhancement {expectedLevel} did not persist cumulative experience");
        }

        var (legacyGoldResponse, _) =
            await RoundTrip("equip.Enhance", EnhanceArgs(legacyGoldEquipId, (60000, 2)));
        Assert(legacyGoldResponse.Err == 0 && legacyGoldResponse.Ret is { Length: > 0 },
            "legacy gold equipment enhancement was rejected after level 3");
        PlayerAccount legacyGoldEnhanced = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("legacy gold enhancement account disappeared");
        EquipItem legacyGold = legacyGoldEnhanced.Equip!.Items.Single(e => e.EquipId == legacyGoldEquipId);
        Assert(legacyGold.EnhanceLv == 4 && legacyGold.EnhanceExp == 800,
            "legacy remainder experience was not normalized to cumulative experience");

        var (boundResponse, boundPushes) = await RoundTrip("equip.EnhanceBind", EnhanceArgs(boundEquipId));
        Assert(boundResponse.Err == 0 && boundResponse.Ret is { Length: > 0 },
            "equipped UR bound enhancement was rejected");
        Assert(boundPushes.Any(p => p.Method == "user.UpdateUserInfo") &&
            boundPushes.Any(p => p.Method == "bag.UpdateBagData") &&
            boundPushes.Any(p => p.Method == "equip.UpdateEquipBagData"),
            "bound enhancement did not refresh currency, bag, and equipment data");
        PlayerAccount boundEnhanced = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("bound enhancement account disappeared");
        Assert(boundEnhanced.Equip!.Items.Single(e => e.EquipId == boundEquipId).EnhanceLv == 36,
            "equipped UR bound enhancement did not persist level 36");
        Assert(boundEnhanced.Character.UrEquipCoin == 90 && boundEnhanced.Character.Gold == 65_000,
            "equipped UR bound enhancement did not consume configured currencies");
        Assert(!boundEnhanced.Bag!.Items.Any(i => i.TemplateId == 60003) &&
               boundEnhanced.Bag.Items.Single(i => i.TemplateId == 10000).Num == 41,
            "equipped UR bound enhancement did not consume configured bag materials");

        var (riseStarResponse, riseStarPushes) = await RoundTrip(
            "equip.RiseStar", RiseStarArgs(riseStarEquipId, riseStarConsumedEquipId));
        Assert(riseStarResponse.Err == 0 && riseStarResponse.Ret is { Length: > 0 },
            "gold equipment rise-star was rejected");
        Assert(riseStarPushes.Any(p => p.Method == "user.UpdateUserInfo") &&
               riseStarPushes.Any(p => p.Method == "bag.UpdateBagData"),
            "rise-star did not refresh currency and bag data before its response");
        TResponse riseStarEquipPush = riseStarPushes.Single(p => p.Method == "equip.UpdateEquipBagData");
        byte[] consumedDeletion = PlayerDataCodec.Encode(
            new EquipInfo(riseStarConsumedEquipId, TemplateId: 0));
        Assert(riseStarEquipPush.Ret is { Length: > 0 } &&
               ContainsSequence(riseStarEquipPush.Ret, consumedDeletion),
            "rise-star equipment push omitted the consumed equipment deletion marker");

        PlayerAccount risenStar = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("rise-star account disappeared");
        Assert(risenStar.Equip!.Items.Single(e => e.EquipId == riseStarEquipId).Star == 3 &&
               risenStar.Equip.Items.All(e => e.EquipId != riseStarConsumedEquipId),
            "rise-star did not persist the target update and consumed equipment removal");
        Assert(risenStar.Character.Gold == 45_000 &&
               risenStar.Bag!.Items.Single(i => i.TemplateId == 10000).Num == 21,
            "rise-star did not consume its configured currency and item costs");

        var (wrongCoreResponse, wrongCorePushes) = await RoundTrip(
            "equip.RiseStar", RiseStarArgs(universalRiseStarEquipId, wrongQualityCoreEquipId));
        Assert(wrongCoreResponse.Err != 0 && wrongCorePushes.Count == 0,
            "rise-star accepted a universal core with the wrong quality");
        PlayerAccount wrongCoreRejected = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("wrong-quality core rejection account disappeared");
        Assert(wrongCoreRejected.Equip!.Items.Single(e => e.EquipId == universalRiseStarEquipId).Star == 2 &&
               wrongCoreRejected.Equip.Items.Any(e => e.EquipId == wrongQualityCoreEquipId) &&
               wrongCoreRejected.Character.Gold == 45_000 &&
               wrongCoreRejected.Bag!.Items.Single(i => i.TemplateId == 10000).Num == 21,
            "wrong-quality universal core rejection mutated the account");

        var (universalResponse, universalPushes) = await RoundTrip(
            "equip.RiseStar", RiseStarArgs(universalRiseStarEquipId, universalCoreEquipId));
        Assert(universalResponse.Err == 0 && universalResponse.Ret is { Length: > 0 },
            "gold equipment rise-star rejected its same-quality universal core");
        byte[] universalDeletion = PlayerDataCodec.Encode(
            new EquipInfo(universalCoreEquipId, TemplateId: 0));
        TResponse universalEquipPush = universalPushes.Single(p => p.Method == "equip.UpdateEquipBagData");
        Assert(universalEquipPush.Ret is { Length: > 0 } &&
               ContainsSequence(universalEquipPush.Ret, universalDeletion),
            "rise-star equipment push omitted the consumed universal core deletion marker");
        PlayerAccount universalRisenStar = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("universal rise-star account disappeared");
        Assert(universalRisenStar.Equip!.Items.Single(e => e.EquipId == universalRiseStarEquipId).Star == 3 &&
               universalRisenStar.Equip.Items.All(e => e.EquipId != universalCoreEquipId) &&
               universalRisenStar.Equip.Items.Any(e => e.EquipId == wrongQualityCoreEquipId),
            "rise-star did not consume only the selected same-quality universal core");
        Assert(universalRisenStar.Character.Gold == 25_000 &&
               universalRisenStar.Bag!.Items.Single(i => i.TemplateId == 10000).Num == 1,
            "universal-core rise-star did not consume its configured currency and item costs");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task ConstructionIntegrationTest()
{
    string root = FindRepositoryRoot();
    string serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0",
        "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the server first");
    string data = Path.Combine(root, ".test-data", "blueoath-construction-" + Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(data);
    const string profileId = "construction-test";
    var repo = new SqliteGameRepository(data);
    await repo.CreateAsync(profileId, profileId);

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
        Assert(process.Start(), "construction test server did not start");
        string readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(20))
            ?? throw new InvalidDataException("server did not report ready");
        using var ready = JsonDocument.Parse(readyLine);
        int port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        NetworkStream stream = client.GetStream();

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

        static byte[] Project(int gold, int steelCount, int aluminiumCount)
        {
            var steel = new ProtocolPackage().Write(0x08, 10029UL)
                .Write(0x10, checked((ulong)steelCount));
            var aluminium = new ProtocolPackage().Write(0x08, 10030UL)
                .Write(0x10, checked((ulong)aluminiumCount));
            return new ProtocolPackage()
                .Write(0x0A, steel.ToArray())
                .Write(0x0A, aluminium.ToArray())
                .Write(0x10, checked((ulong)gold))
                .ToArray();
        }

        await RoundTrip("player.Login", GameLoginCodec.Encode(new TArgLogin(profileId, 1, "open", "hash")));
        await RoundTrip("hero.GetHeroInfo", null); // drain login synchronization pushes
        PlayerAccount baseline = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("construction account was not initialized");
        int steelBefore = baseline.Bag?.Items.Single(item => item.TemplateId == 10029).Num ?? 0;
        int aluminiumBefore = baseline.Bag?.Items.Single(item => item.TemplateId == 10030).Num ?? 0;
        int quickBefore = baseline.Bag?.Items.Single(item => item.TemplateId == 10031).Num ?? 0;

        var invalidArgs = new ProtocolPackage().Write(0x0A, Project(29, 30, 30));
        var (invalid, invalidPushes) = await RoundTrip("build.BuildingByFormula", invalidArgs.ToArray());
        Assert(invalid.Err != 0 && invalidPushes.Count == 0,
            "an out-of-range construction project was not rejected atomically");

        var projects = new ProtocolPackage();
        for (int i = 0; i < 3; i++) projects.Write(0x0A, Project(30, 30, 30));
        var (started, startPushes) = await RoundTrip("build.BuildingByFormula", projects.ToArray());
        Assert(started.Err == 0, $"valid construction request was rejected: {started.ErrMsg}");
        Assert(startPushes.Any(push => push.Method == "build.BuildsInfo") &&
            startPushes.Any(push => push.Method == "bag.UpdateBagData") &&
            startPushes.Any(push => push.Method == "user.UpdateUserInfo"),
            "construction start did not synchronize queue, materials, and currency");

        PlayerAccount queued = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("construction queue was not persisted");
        IReadOnlyList<ConstructionJob> queuedJobs = queued.Construction?.Jobs ?? [];
        Assert(queuedJobs.Count == 3 && queuedJobs.Count(job => job.EndTime > 0) == 2 &&
            queuedJobs.Count(job => job.EndTime == 0) == 1,
            "construction did not use two active slots and one waiting slot");
        Assert(queued.Character.Gold == baseline.Character.Gold - 90 &&
            queued.Bag!.Items.Single(item => item.TemplateId == 10029).Num == steelBefore - 90 &&
            queued.Bag.Items.Single(item => item.TemplateId == 10030).Num == aluminiumBefore - 90,
            "construction resources were not deducted exactly once");
        Assert(queued.Construction?.LastProject?.Gold == 30,
            "last construction formula was not persisted for client reuse");

        byte[] firstIndex = new ProtocolPackage().Write(0x08, 1UL).ToArray();
        var (finished, finishPushes) = await RoundTrip("build.BuildQuicklyFinish", firstIndex);
        Assert(finished.Err == 0 && finishPushes.Any(push => push.Method == "build.BuildsInfo") &&
            finishPushes.Any(push => push.Method == "bag.UpdateBagData"),
            "quick construction did not synchronize its queue and item cost");
        PlayerAccount quickFinished = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("quick-finished construction was not persisted");
        Assert(quickFinished.Construction?.Jobs.Count(job => job.Completed) == 1 &&
            quickFinished.Construction.Jobs.Count(job => !job.Completed && job.EndTime > 0) == 2 &&
            quickFinished.Construction.Jobs.All(job => job.Completed || job.EndTime > 0),
            "quick construction did not promote the waiting job into the free slot");
        Assert(quickFinished.Bag!.Items.Single(item => item.TemplateId == 10031).Num == quickBefore - 1,
            "quick construction item was not consumed");

        var (received, receivePushes) = await RoundTrip("build.BuildReceive", firstIndex);
        Assert(received.Err == 0 && received.Ret is { Length: > 0 } && received.Ret[0] == 0x0A,
            "construction receive did not return a ship reward");
        Assert(receivePushes.Any(push => push.Method == "build.BuildsInfo") &&
            receivePushes.Any(push => push.Method == "hero.UpdateHeroBagData") &&
            receivePushes.Any(push => push.Method == "illustrate.IllustrateInfo"),
            "construction receive did not synchronize queue, dock, and illustration data");
        PlayerAccount receivedAccount = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("received construction was not persisted");
        Assert(receivedAccount.Construction?.Jobs.Count == 2 &&
            receivedAccount.Dock.Heroes.Count == baseline.Dock.Heroes.Count + 1,
            "receiving a construction result did not remove one job and add one ship");
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
}

static async Task HeroRemouldIntegrationTest()
{
    string root = FindRepositoryRoot();
    string serverDll = Path.Combine(root, "src", "BlueOath.Server", "bin", "Debug", "net8.0",
        "BlueOath.Server.dll");
    Assert(File.Exists(serverDll), "server assembly is missing; build the server first");

    RemouldConfigLoader.Load(FindClientConfigDir());
    ConfigShipRemouldTemplate stage = RemouldConfigLoader.GetTemplate(525)
        ?? throw new InvalidDataException("Oakland remould stage was not loaded");
    ConfigShipRemouldTemplate nextStage = RemouldConfigLoader.GetTemplate(526)
        ?? throw new InvalidDataException("Oakland second remould stage was not loaded");
    List<int> stageEffectIds = (stage.RemouldItemGroup ?? []).Select(id => checked((int)id)).ToList();
    List<int> nextStageEffectIds = (nextStage.RemouldItemGroup ?? [])
        .Select(id => checked((int)id)).ToList();
    List<int> allEffectIds = [.. stageEffectIds, .. nextStageEffectIds];
    int effectId = stageEffectIds
        .First(id => RemouldConfigLoader.GetEffect(checked((int)id))?.RemouldPrev is not { Count: > 0 });
    ConfigShipRemouldEffect effect = RemouldConfigLoader.GetEffect(effectId)
        ?? throw new InvalidDataException("initial Oakland remould effect was not loaded");
    Dictionary<(int Type, int Id), int> selectedCosts = (effect.Cost ?? [])
        .GroupBy(cost => (Type: checked((int)cost[0]), Id: checked((int)cost[1])))
        .ToDictionary(group => group.Key, group => checked((int)group.Sum(cost => cost[2])));
    Dictionary<(int Type, int Id), int> stageCosts = allEffectIds
        .SelectMany(id => RemouldConfigLoader.GetEffect(id)?.Cost ?? [])
        .GroupBy(cost => (Type: checked((int)cost[0]), Id: checked((int)cost[1])))
        .ToDictionary(group => group.Key, group => checked((int)group.Sum(cost => cost[2])));

    string data = Path.Combine(root, ".test-data", "blueoath-remould-" + Guid.NewGuid().ToString("N"));
    Directory.CreateDirectory(data);
    const string profileId = "remould-test";
    var repo = new SqliteGameRepository(data);
    await repo.CreateAsync(profileId, profileId);
    PlayerAccount seeded = await repo.LoadAccountAsync(profileId)
        ?? throw new InvalidDataException("failed to seed remould account");
    Hero hero = seeded.Dock.Heroes.Single() with
    {
        Level = Math.Max(100, checked((int)effect.LimitLevel)),
        Advance = Math.Max(10, checked((int)effect.LimitStar)),
    };
    seeded = seeded with { Dock = seeded.Dock with { Heroes = [hero] } };
    foreach (var (key, amount) in stageCosts)
    {
        if (key.Type == GameServices.GoodsTypeCurrency)
        {
            Assert(GameServices.TryGetCurrency(seeded, key.Id, out int current),
                $"unsupported remould currency {key.Id}");
            if (current < amount + 10)
                seeded = GameServices.AddCurrency(seeded, key.Id, amount + 10 - current);
        }
        else
        {
            int current = seeded.Bag?.Items.FirstOrDefault(i => i.TemplateId == key.Id)?.Num ?? 0;
            if (current < amount + 10)
                seeded = GameServices.AddBagItem(seeded, key.Id, amount + 10 - current);
        }
    }
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
        Assert(process.Start(), "remould test server did not start");
        string readyLine = await process.StandardOutput.ReadLineAsync().WaitAsync(TimeSpan.FromSeconds(20))
            ?? throw new InvalidDataException("server did not report ready");
        using var ready = JsonDocument.Parse(readyLine);
        int port = ready.RootElement.GetProperty("gameLoginPort").GetInt32();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
        using var client = new TcpClient();
        await client.ConnectAsync("127.0.0.1", port, timeout.Token);
        NetworkStream stream = client.GetStream();

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
        await RoundTrip("hero.GetHeroInfo", null); // drain login synchronization pushes

        byte[] EncodeRemouldArg(int id)
        {
            var value = new ProtocolPackage();
            value.Write(0x08, 1UL);
            value.Write(0x10, checked((ulong)id));
            return value.ToArray();
        }

        byte[] remouldArg = EncodeRemouldArg(effectId);
        var (response, pushes) = await RoundTrip("hero.HeroRemould", remouldArg);
        Assert(response.Err == 0, $"valid remould request was rejected: {response.ErrMsg}");
        Assert(pushes.Any(push => push.Method == "hero.UpdateHeroBagData"),
            "remould did not refresh hero data before its response");
        Assert(pushes.Any(push => push.Method == "bag.UpdateBagData"),
            "remould did not refresh item costs before its response");
        Assert(pushes.Any(push => push.Method == "user.UpdateUserInfo"),
            "remould did not refresh currency costs before its response");

        PlayerAccount saved = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("remould account disappeared");
        Hero savedHero = saved.Dock.Heroes.Single();
        Assert(savedHero.RemouldEffects?.Contains(effectId) == true,
            "completed remould effect was not persisted");
        Assert(savedHero.RemouldLevel == 0,
            "a partially completed first stage advanced RemouldLevel");
        foreach (var (key, amount) in selectedCosts)
        {
            if (key.Type == GameServices.GoodsTypeCurrency)
            {
                Assert(GameServices.TryGetCurrency(seeded, key.Id, out int before) &&
                    GameServices.TryGetCurrency(saved, key.Id, out int after) && after == before - amount,
                    $"remould currency {key.Id} was not deducted exactly once");
            }
            else
            {
                int before = seeded.Bag?.Items.FirstOrDefault(i => i.TemplateId == key.Id)?.Num ?? 0;
                int after = saved.Bag?.Items.FirstOrDefault(i => i.TemplateId == key.Id)?.Num ?? 0;
                Assert(after == before - amount, $"remould item {key.Id} was not deducted exactly once");
            }
        }

        var (duplicate, duplicatePushes) = await RoundTrip("hero.HeroRemould", remouldArg);
        Assert(duplicate.Err != 0 && duplicatePushes.Count == 0,
            "duplicate remould request was not rejected atomically");
        PlayerAccount unchanged = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("remould account disappeared after duplicate request");
        Assert(unchanged.Dock.Heroes.Single().RemouldEffects?.Count(id => id == effectId) == 1,
            "duplicate remould request changed persisted state");

        int nextEffectId = checked((int)(nextStage.RemouldItemGroup ?? [])
            .First(id => RemouldConfigLoader.GetEffect(checked((int)id))?.RemouldPrev is not { Count: > 0 }));
        var (earlyStage, earlyPushes) = await RoundTrip("hero.HeroRemould", EncodeRemouldArg(nextEffectId));
        Assert(earlyStage.Err != 0 && earlyPushes.Count == 0,
            "a second-stage remould effect was accepted before the first stage completed");

        var completed = new HashSet<int> { effectId };
        while (completed.Count < stageEffectIds.Count)
        {
            int candidate = stageEffectIds.First(id => !completed.Contains(id) &&
                (RemouldConfigLoader.GetEffect(id)?.RemouldPrev is not { Count: > 0 } prerequisites ||
                 prerequisites.Any(prev => completed.Contains(checked((int)prev)))));
            var (nodeResponse, _) = await RoundTrip("hero.HeroRemould", EncodeRemouldArg(candidate));
            Assert(nodeResponse.Err == 0,
                $"valid first-stage remould effect {candidate} was rejected: {nodeResponse.ErrMsg}");
            completed.Add(candidate);
        }

        PlayerAccount stageCompleted = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("remould account disappeared after stage completion");
        Hero completedHero = stageCompleted.Dock.Heroes.Single();
        Assert(completedHero.RemouldLevel == 1 &&
            stageEffectIds.All(id => completedHero.RemouldEffects?.Contains(id) == true),
            "completing every first-stage node did not advance RemouldLevel to 1");
        while (completed.Count < allEffectIds.Count)
        {
            int candidate = nextStageEffectIds.First(id => !completed.Contains(id) &&
                (RemouldConfigLoader.GetEffect(id)?.RemouldPrev is not { Count: > 0 } prerequisites ||
                 prerequisites.Any(prev => completed.Contains(checked((int)prev)))));
            var (nodeResponse, _) = await RoundTrip("hero.HeroRemould", EncodeRemouldArg(candidate));
            Assert(nodeResponse.Err == 0,
                $"valid second-stage remould effect {candidate} was rejected: {nodeResponse.ErrMsg}");
            completed.Add(candidate);
        }

        PlayerAccount fullyRemoulded = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("remould account disappeared after completion");
        Hero fullyRemouldedHero = fullyRemoulded.Dock.Heroes.Single();
        Assert(fullyRemouldedHero.RemouldLevel == 3 &&
            allEffectIds.All(id => fullyRemouldedHero.RemouldEffects?.Contains(id) == true),
            "completing both node stages did not include the terminal empty stage in RemouldLevel");
        foreach (List<long> skillEffect in allEffectIds
                     .SelectMany(id => RemouldConfigLoader.GetEffect(id)?.RemouldEffectType ?? [])
                     .Where(value => value.Count >= 2 && value[0] is 4 or 5))
        {
            uint oldSkillId = checked((uint)skillEffect[1]);
            PSkillEntry? skill = fullyRemouldedHero.PSkills?.FirstOrDefault(value => value.PSkillId == oldSkillId);
            Assert(skill is not null, $"remould skill {oldSkillId} was not added to PSkill");
            if (skillEffect[0] == 5)
                Assert(skill!.Replace == checked((int)skillEffect[2]),
                    $"remould skill {oldSkillId} was not replaced");
        }
    }
    finally
    {
        if (!process.HasExited) { process.Kill(true); process.WaitForExit(3000); }
        if (Directory.Exists(data)) Directory.Delete(data, true);
    }
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
    Assert(seeded.Dock.Heroes[0].Affection == PlayerAccountFactory.DefaultAffection,
        "new profiles did not initialize affection at 50");
    Hero second = seeded.Dock.Heroes[0] with
    {
        HeroId = 2,
        TemplateId = 40320111,
        Fashioning = 4032011,
        Affection = 990_000,
        EquipSlots = new uint[] { 77, 0, 0, 0, 0, 0 },
    };
    Hero third = seeded.Dock.Heroes[0] with
    {
        HeroId = 3,
        Affection = 1_000_000,
    };
    Hero legacyLowAffection = seeded.Dock.Heroes[0] with
    {
        HeroId = 4,
        Affection = 10_000,
    };
    seeded = seeded with
    {
        Dock = seeded.Dock with { Heroes = [seeded.Dock.Heroes[0], second, third, legacyLowAffection] },
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
    startInfo.ArgumentList.Add("--client-path=" + Path.Combine(root, "blueoath", "blueoath"));
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
        // Login synchronization is emitted immediately after the login response, so the next
        // request observes those queued pushes before its own response.
        var (initialHeroResponse, _) = await RoundTrip("hero.GetHeroInfo", null);
        Assert(initialHeroResponse.Ret is { Length: > 0 } &&
            ContainsSequence(initialHeroResponse.Ret, new byte[] { 0x80, 0x01, 0x00 }),
            "hero data did not explicitly initialize ChangeNameTime=0");
        Assert(ContainsSequence(initialHeroResponse.Ret!, new byte[] { 0x98, 0x01, 0x00 }) &&
            ContainsSequence(initialHeroResponse.Ret!, new byte[] { 0xA8, 0x01, 0x00 }),
            "unmarried hero data did not explicitly initialize MarryTime/MarryType=0");
        PlayerAccount migrated = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("migrated account disappeared");
        Assert(migrated.Dock.Heroes.Single(h => h.HeroId == 4).Affection ==
                PlayerAccountFactory.DefaultAffection,
            "legacy affection migration was not persisted during account load");

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
        Assert(giftedAffection == PlayerAccountFactory.UnmarriedMaxAffection &&
            giftedAffection > initialAffection,
            "gift did not cap persisted unmarried affection at 100");
        Assert(gifted.Bag?.Items.Single(i => i.TemplateId == 280002).Num == 998,
            "gift count was not limited to the quantity actually needed");
        Assert(gifted.Bag?.Items.Count(i => i.Num == 999) == 7,
            "not all configured affection gift types were provisioned for the existing profile");

        var (cappedGiftResponse, cappedGiftPushes) =
            await RoundTrip("hero.AddAffection", giftArgs.ToArray());
        Assert(cappedGiftResponse.Err != 0 && cappedGiftPushes.Count == 0,
            "gift at the unmarried affection limit was accepted");
        PlayerAccount cappedGiftRejected = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("capped gift account disappeared");
        Assert(cappedGiftRejected.Dock.Heroes.Single(h => h.HeroId == 2).Affection ==
                PlayerAccountFactory.UnmarriedMaxAffection &&
            cappedGiftRejected.Bag?.Items.Single(i => i.TemplateId == 280002).Num == 998,
            "gift at the affection limit changed affection or inventory");

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
            giftRejected.Bag?.Items.Single(i => i.TemplateId == 280002).Num == 998,
            "failed gift request changed persisted data");

        const string customName = "马克西姆";
        var renameArgs = new ProtocolPackage();
        renameArgs.Write(0x08, 2UL);
        renameArgs.Write(0x12, customName);
        var (renameResponse, renamePushes) = await RoundTrip("hero.ChangeName", renameArgs.ToArray());
        Assert(renameResponse.Err == 0, "Unicode hero rename was rejected");
        TResponse renameHeroPush = renamePushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("rename did not refresh hero data before its response");
        Assert(renameHeroPush.Ret is { Length: > 0 } &&
            ContainsSequence(renameHeroPush.Ret, Encoding.UTF8.GetBytes(customName)),
            "rename update did not contain the UTF-8 custom name");
        PlayerAccount renamed = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("rename account disappeared");
        Hero renamedHero = renamed.Dock.Heroes.Single(h => h.HeroId == 2);
        Assert(renamedHero.Name == customName && renamedHero.ChangeNameTime > 0,
            "Unicode custom name or rename time was not persisted");

        var resetNameArgs = new ProtocolPackage();
        resetNameArgs.Write(0x08, 2UL);
        resetNameArgs.Write(0x12, "");
        var (resetNameResponse, resetNamePushes) =
            await RoundTrip("hero.ChangeName", resetNameArgs.ToArray());
        Assert(resetNameResponse.Err == 0, "resetting a custom hero name was rejected");
        TResponse resetNamePush = resetNamePushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("name reset did not refresh hero data before its response");
        Assert(resetNamePush.Ret is { Length: > 0 } &&
            ContainsSequence(resetNamePush.Ret, new byte[] { 0x7A, 0x00 }),
            "name reset did not explicitly clear the cached custom name");
        PlayerAccount resetNameAccount = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("name reset account disappeared");
        Assert(resetNameAccount.Dock.Heroes.Single(h => h.HeroId == 2).Name == "",
            "custom name reset was not persisted");

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

        // The ring shop uses a retired event token in the JP config. Existing profiles must receive
        // that client-side currency, and the purchased ring must be pushed before the Lua callback.
        var buyRingArgs = new ProtocolPackage();
        buyRingArgs.Write(0x08, 1072UL);
        buyRingArgs.Write(0x10, 102021UL);
        buyRingArgs.Write(0x18, 1UL);
        var (buyRingResponse, buyRingPushes) =
            await RoundTrip("shop.BuyGoods", buyRingArgs.ToArray());
        Assert(buyRingResponse.Err == 0 && buyRingResponse.Ret is { Length: > 0 },
            "oath ring purchase did not return a reward");
        Assert(buyRingPushes.Any(p => p.Method == "bag.UpdateBagData"),
            "oath ring purchase did not refresh inventory before its response");
        PlayerAccount ringPurchased = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("ring purchase account disappeared");
        Assert(ringPurchased.Bag?.Items.Single(i => i.TemplateId == 10180).Num == 1,
            "purchased oath ring was not persisted");
        Assert(ringPurchased.Bag?.Items.Single(i => i.TemplateId == 17553).Num == 99_999_999,
            "retired-event currency required by the ring shop was not provisioned");

        // A hero mutation refreshes the client cache before success. HeroGrid.Name is a custom
        // nickname, not the handbook's Chinese display name, so JP/CN clients stay localized.
        var marryArgs = new ProtocolPackage();
        marryArgs.Write(0x08, 2UL);
        marryArgs.Write(0x10, 1UL);
        var (marryResponse, marryPushes) = await RoundTrip("hero.Marry", marryArgs.ToArray());
        Assert(marryResponse.Err == 0, "Blucher marriage was rejected");
        TResponse marryHeroPush = marryPushes.FirstOrDefault(p => p.Method == "hero.UpdateHeroBagData")
            ?? throw new InvalidDataException("marriage did not refresh hero data");
        Assert(marryHeroPush.Ret is { Length: > 0 } &&
            !ContainsSequence(marryHeroPush.Ret, Encoding.UTF8.GetBytes("奥克兰")),
            "hero update incorrectly sent the Chinese handbook name as a custom nickname");
        TResponse marryBagPush = marryPushes.FirstOrDefault(p => p.Method == "bag.UpdateBagData")
            ?? throw new InvalidDataException("marriage did not refresh ring inventory");
        Assert(marryBagPush.Ret is { Length: > 0 } &&
            ContainsSequence(marryBagPush.Ret, new byte[] { 0x08, 0xC4, 0x4F, 0x10, 0x00 }),
            "marriage did not send an explicit zero-count ring deletion marker");
        Assert(marryPushes.Any(p => p.Method == "user.UpdateUserInfo"),
            "marriage did not refresh ring inventory and MarriedNum before its response");
        PlayerAccount married = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("marriage account disappeared");
        Assert(married.Dock.Heroes.Single(h => h.HeroId == 2).MarryTime > 0 &&
            married.Bag?.Items.Single(i => i.TemplateId == 10180).Num == 0,
            "marriage and ring deduction were not persisted atomically");

        var noRingArgs = new ProtocolPackage();
        noRingArgs.Write(0x08, 3UL);
        noRingArgs.Write(0x10, 1UL);
        var (noRingResponse, noRingPushes) = await RoundTrip("hero.Marry", noRingArgs.ToArray());
        Assert(noRingResponse.Err != 0 && noRingPushes.Count == 0,
            "marriage without an oath ring was reported as success");
        PlayerAccount rejectedMarriage = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("rejected marriage account disappeared");
        Assert(rejectedMarriage.Dock.Heroes.Single(h => h.HeroId == 3).MarryTime == 0 &&
            rejectedMarriage.Character.MarriedNum == married.Character.MarriedNum,
            "failed marriage changed persistent data");

        var (secondRingResponse, _) = await RoundTrip("shop.BuyGoods", buyRingArgs.ToArray());
        Assert(secondRingResponse.Err == 0, "second oath ring purchase was rejected");
        var (secondMarryResponse, secondMarryPushes) =
            await RoundTrip("hero.Marry", noRingArgs.ToArray());
        Assert(secondMarryResponse.Err == 0 &&
            secondMarryPushes.Any(p => p.Method == "hero.UpdateHeroBagData"),
            "a second eligible ship could not be married after purchasing another ring");
        PlayerAccount twiceMarried = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("second marriage account disappeared");
        Assert(twiceMarried.Dock.Heroes.Single(h => h.HeroId == 3).MarryTime > 0 &&
            twiceMarried.Character.MarriedNum == married.Character.MarriedNum + 1 &&
            twiceMarried.Bag?.Items.Single(i => i.TemplateId == 10180).Num == 0,
            "consecutive marriage state was not persisted correctly");

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

static Task MubarBattleStartCodecTest()
{
    string configDir = FindClientConfigDir();
    ChapterCopyLoader.Load(configDir);
    CopyBattleLoader.Load(configDir);

    const int copyId = 932113; // 实际客户端日志中的アンブラ進軍关卡
    Assert(ChapterCopyLoader.GetCopyType(copyId) == 33,
        "Mubar activity copy was not classified as CopyType 33");

    PlayerAccount account = PlayerAccountFactory.CreateDefault("mubar-codec", 1);
    byte[] payload = ProtocolEncoder.EncodeStartBaseRet(
        copyId, account.Dock.Heroes.ToList(), account.Character);
    Assert(ProtocolDecoder.DecodeVarintField(payload, 7) == 33,
        "copy.StartBase downgraded MubarCopy to PlotCopy");
    Assert(CopyBattleLoader.IsSearch3d(copyId),
        "Mubar activity copy was not classified as search_3d");

    bool hasCopyResource = false;
    bool hasConfigData = false;
    bool skipsEnemyVcr = false;
    ProtocolDecoder.ProtoReader reader = new(payload);
    while (reader.TryReadField(out int field, out int wire))
    {
        if (field == 4) hasCopyResource = true;
        if (field == 25) hasConfigData = true;
        if (field == 17 && wire == 2)
        {
            ProtocolDecoder.ProtoReader skip = new(reader.ReadBytes());
            while (skip.TryReadField(out int skipField, out int skipWire))
            {
                if ((skipField == 2 || skipField == 3) && skipWire == 0)
                {
                    if (skip.ReadVarint() == 1)
                        skipsEnemyVcr = true;
                }
                else
                    skip.Skip(skipWire);
            }
            continue;
        }
        reader.Skip(wire);
    }
    Assert(!hasCopyResource,
        "search_3d Mubar battle included arrRes and can stall on missing battlefield_resource");
    Assert(hasConfigData, "search_3d Mubar battle omitted search initialization ConfigData");
    Assert(skipsEnemyVcr, "search_3d Mubar battle did not skip blocking fleet VCR sequences");
    Assert(CopyBattleLoader.GetFleetIdList(copyId).Count > 0,
        "Mubar activity copy has no enemy fleet data");
    return Task.CompletedTask;
}

static Task SeaCopySafeAreaCodecTest()
{
    ChapterCopyLoader.Load(FindClientConfigDir());
    byte[] payload = ProtocolEncoder.EncodeSeaCopyInfo();
    bool foundSafeAreaCopy = false;

    ProtocolDecoder.ProtoReader response = new(payload);
    while (response.TryReadField(out int field, out int wire))
    {
        if (field != 1 || wire != 2)
        {
            response.Skip(wire);
            continue;
        }

        int baseId = 0;
        int safeLevel = 0;
        int selectedSafeLevel = 0;
        bool hasSafePoint = false;
        uint safePointBits = uint.MaxValue;
        ProtocolDecoder.ProtoReader baseInfo = new(response.ReadBytes());
        while (baseInfo.TryReadField(out int baseField, out int baseWire))
        {
            switch (baseField)
            {
                case 1 when baseWire == 0:
                    baseId = checked((int)baseInfo.ReadVarint());
                    break;
                case 8 when baseWire == 0:
                    safeLevel = checked((int)baseInfo.ReadVarint());
                    break;
                case 9 when baseWire == 5:
                    hasSafePoint = true;
                    safePointBits = baseInfo.ReadFixed32();
                    break;
                case 12 when baseWire == 0:
                    selectedSafeLevel = checked((int)baseInfo.ReadVarint());
                    break;
                default:
                    baseInfo.Skip(baseWire);
                    break;
            }
        }

        if (baseId != 5011) continue;
        foundSafeAreaCopy = true;
        Assert(safeLevel == 1,
            "sea-copy TBaseInfo omitted SfLv, causing config_safearea strId:nil");
        Assert(hasSafePoint && safePointBits == 0,
            "sea-copy TBaseInfo omitted the initial SfPoint float");
        Assert(selectedSafeLevel == 1,
            "sea-copy TBaseInfo omitted SfLvChoose used by SafeInfoPage");
        break;
    }

    Assert(foundSafeAreaCopy, "sea-copy synchronization did not include safe-area copy 5011");
    return Task.CompletedTask;
}

static async Task DailyCopyGameplayTest()
{
    string root = FindRepositoryRoot();
    string configDir = FindClientConfigDir();
    ChapterCopyLoader.Load(configDir);
    CopyBattleLoader.Load(configDir);

    Assert(ChapterCopyLoader.GetCopyType(20101) == 9,
        "destroyer challenge 20101 was not classified as DailyCopy");
    Assert(ChapterCopyLoader.GetDailyChapterId(20101) == 20001 &&
           ChapterCopyLoader.GetDailyGroupId(20001) == 2,
        "destroyer challenge chapter/group mapping does not match client config");
    Assert(ChapterCopyLoader.GetDailyCopyIds(20001).SequenceEqual(Enumerable.Range(20101, 10)),
        "destroyer challenge did not load all ten configured difficulties");
    Assert(ChapterCopyLoader.GetDailyTreatyCopyIds(20001).SequenceEqual([20518]) &&
           ChapterCopyLoader.IsDailyTreatyCopy(20518),
        "destroyer challenge did not load its configured treaty stage");

    PlayerAccount codecAccount = PlayerAccountFactory.CreateDefault("daily-copy-codec", 1);
    byte[] startPayload = ProtocolEncoder.EncodeStartBaseRet(
        20101, codecAccount.Dock.Heroes.ToList(), codecAccount.Character);
    Assert(ProtocolDecoder.DecodeVarintField(startPayload, 7) == 9,
        "copy.StartBase did not preserve DailyCopy type 9");

    var (baseInfoCount, foundFirstDestroyerLevel, foundDestroyerTreaty) =
        ScanDailyCopyInfo(ProtocolEncoder.EncodeDailyCopyInfo());
    Assert(baseInfoCount == 44 && foundFirstDestroyerLevel && foundDestroyerTreaty,
        "DailyCopy synchronization omitted configured normal or treaty levels");

    string dataRoot = Path.Combine(Path.GetTempPath(), "blueoath-daily-copy-" + Guid.NewGuid().ToString("N"));
    const string profileId = "daily-copy-player";
    try
    {
        var repo = new SqliteGameRepository(dataRoot);
        ServerOptions options = ServerOptions.Parse([
            "--data=" + dataRoot,
            "--client-path=" + Path.Combine(root, "blueoath", "blueoath"),
            "--profile-id=" + profileId,
        ]);
        using Microsoft.Extensions.Logging.ILoggerFactory loggerFactory =
            Microsoft.Extensions.Logging.LoggerFactory.Create(_ => { });
        var services = new GameServices(repo, options, loggerFactory);
        var dailyCopy = new DailyCopyService(services);
        const int today = 1_800_000_000;

        PlayerAccount account = await dailyCopy.GetRefreshedAccountAsync(
            profileId, today, CancellationToken.None);
        Assert(account.DailyCopy?.Chapters?.Count == 4 && account.DailyCopy.Groups?.Count == 4,
            "dailycopy.GetData did not initialize all client chapter/group rows");

        DailyCopyPassMutation mutation = dailyCopy.RecordPass(account, 20101, 3, today);
        account = mutation.Account;
        Assert(mutation.FirstPass, "first destroyer challenge clear was not marked as first pass");
        Assert(mutation.Rewards.Count >= 3 && mutation.Rewards.All(x => x.Num > 0),
            "destroyer clear omitted its configured first-pass/basic drops");
        await services.SaveAccountAsync(account, CancellationToken.None);
        DailyCopyChapterProgress destroyer = account.DailyCopy!.Chapters!
            .Single(x => x.ChapterId == 20001);
        Assert(destroyer.ChallengeTimes == 1 && destroyer.PassCopy?.SequenceEqual([20101]) == true,
            "destroyer clear did not persist challenge count and unlock progress");
        Assert(account.DailyCopy.Groups!.Single(x => x.DailyGroupId == 2).SuccessTimes == 1,
            "destroyer clear did not increment daily group success count");

        DailyCopyPassMutation treatyMutation = dailyCopy.RecordPass(account, 20518, 3, today);
        account = treatyMutation.Account;
        DailyCopyChapterProgress treatyDestroyer = account.DailyCopy!.Chapters!
            .Single(x => x.ChapterId == 20001);
        Assert(treatyMutation.FirstPass &&
               treatyMutation.Rewards.Where(x => x.ConfigId == 13001).Sum(x => x.Num) >= 5_560,
            "destroyer treaty clear omitted its configured pass/star rewards");
        Assert(treatyDestroyer.ChallengeTimes == 2 &&
               treatyDestroyer.PassCopy?.Contains(20518) == true &&
               treatyDestroyer.SelectEx && treatyDestroyer.ExStar == 3,
            "destroyer treaty clear did not persist its pass and EX-star state");
        Assert(account.DailyCopy.Groups!.Single(x => x.DailyGroupId == 2).SuccessTimes == 2,
            "destroyer treaty clear did not increment daily group success count");
        await services.SaveAccountAsync(account, CancellationToken.None);

        var (chapterRows, groupRows, extraRows) =
            CountDailyCopySnapshotRows(DailyCopyService.EncodeSnapshot(account.DailyCopy, today));
        Assert(chapterRows == 4 && groupRows == 4 && extraRows == 4,
            "dailycopy.UpdateDailyCopyData omitted a repeated array required by the client");

        PlayerAccount tomorrow = await dailyCopy.GetRefreshedAccountAsync(
            profileId, today + 86_400, CancellationToken.None);
        DailyCopyChapterProgress resetDestroyer = tomorrow.DailyCopy!.Chapters!
            .Single(x => x.ChapterId == 20001);
        Assert(resetDestroyer.ChallengeTimes == 0 &&
               resetDestroyer.PassCopy?.Contains(20101) == true &&
               resetDestroyer.PassCopy?.Contains(20518) == true &&
               resetDestroyer.ExStar == 3 &&
               tomorrow.DailyCopy.Groups!.Single(x => x.DailyGroupId == 2).SuccessTimes == 0,
            "cross-day refresh did not reset counts while preserving normal/treaty progress");
          }
    finally
    {
        if (Directory.Exists(dataRoot)) Directory.Delete(dataRoot, true);
    }
}

// 自选箱（config_item_selected，物品类型 8）此前完全没有服务端实现：bag.GetSelectTreasureInfo
// 落到 ShopModule 的 default 分支返回空 Ret 且 Err=0，客户端 SelectRandTreasurePage 解出空的
// treasuresInfo，表现为「选好点确认后什么都没有」。
// item_id 是 [GoodsType, ConfigId, Num] 三元组列表；position 是其中的序号，<b>从 1 开始</b>：
// 客户端 SelectRandTreasurePage 把它当 Lua 表下标直接用（item_id[self.pos]），初值即为 1。
// 按 0 基解析会整体偏移一位——选第 1 项拿到第 2 项，选末项则越界被拒。
// 本次只实现 type==3 的道具箱；type 1/2（舰船箱、装备箱）另有实现，必须保持空响应不变。
static async Task SelectTreasureTest()
{
    string root = FindRepositoryRoot();
    string dataRoot = Path.Combine(Path.GetTempPath(), "blueoath-select-box-" + Guid.NewGuid().ToString("N"));
    const string profileId = "select-box";
    const int itemBoxId = 80134;     // 祈願特注石選択箱（精選版）：[[11,110037,18],[11,110050,18]]
    const int fashionBoxId = 80240;  // 大破着せ替え+α選択箱：首项 [18,4044015,1]
    const int shipBoxId = 80324;     // 指定戦姫チケット（限定版）：下标 0 是舰船
    const int heroBoxId = 80001;     // 舰船箱（type=1），必须保持空响应
    try
    {
        var repo = new SqliteGameRepository(dataRoot);
        await repo.SaveAccountAsync(PlayerAccountFactory.CreateDefault(profileId, 1) with
        {
            Bag = new PlayerBag(
            [
                new BagItem(itemBoxId, 5),
                new BagItem(fashionBoxId, 1),
                new BagItem(shipBoxId, 1),
                new BagItem(heroBoxId, 1),
            ], 200),
        });

        ServerOptions options = ServerOptions.Parse(
            ["--data=" + dataRoot,
             "--client-path=" + Path.Combine(root, "blueoath", "blueoath"),
             "--profile-id=" + profileId]);
        using Microsoft.Extensions.Logging.ILoggerFactory loggerFactory =
            Microsoft.Extensions.Logging.LoggerFactory.Create(_ => { });
        var services = new GameServices(repo, options, loggerFactory);
        var shop = new ShopService(services);

        static byte[] Args(int treasureId, int position, int num) => new ProtocolPackage()
            .Write(0x08, (ulong)treasureId)
            .Write(0x10, (ulong)position)
            .Write(0x18, (ulong)num)
            .ToArray();

        // 80134 的选项是 [[11,110037,18],[11,110050,18]]。position=1 必须给第 1 项。
        ShopService.TreasureOpenResult first = await shop.BuildOpenSelectTreasureRetAsync(
            new TRequest("bag.GetSelectTreasureInfo", Args(itemBoxId, 1, 1)), profileId, CancellationToken.None);
        Assert(first.Changed, $"item selection box was rejected at position 1: {first.Error}");
        PlayerAccount afterFirst = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("select-box account disappeared");
        Assert(afterFirst.Bag!.Items.Single(i => i.TemplateId == 110037).Num == 18,
            "position 1 did not grant the first option (off-by-one in the option index?)");
        Assert(afterFirst.Bag.Items.All(i => i.TemplateId != 110050),
            "position 1 granted the second option instead of the first");
        Assert(afterFirst.Bag.Items.Single(i => i.TemplateId == itemBoxId).Num == 4,
            "item selection box consumed the wrong number of boxes");

        // position=2 是该箱的末项，必须同样可选——按 0 基解析时这里会越界被拒。
        ShopService.TreasureOpenResult last = await shop.BuildOpenSelectTreasureRetAsync(
            new TRequest("bag.GetSelectTreasureInfo", Args(itemBoxId, 2, 1)), profileId, CancellationToken.None);
        Assert(last.Changed, $"the last option was rejected: {last.Error}");
        PlayerAccount afterLast = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("select-box account disappeared");
        Assert(afterLast.Bag!.Items.Single(i => i.TemplateId == 110050).Num == 18,
            "the last option did not grant its reward");

        // 两侧越界都必须被拒绝，且不能扣除箱子。
        foreach (int badPosition in new[] { 0, 3 })
        {
            ShopService.TreasureOpenResult outOfRange = await shop.BuildOpenSelectTreasureRetAsync(
                new TRequest("bag.GetSelectTreasureInfo", Args(itemBoxId, badPosition, 1)),
                profileId, CancellationToken.None);
            Assert(!outOfRange.Changed,
                $"item selection box accepted an out-of-range position {badPosition}");
            PlayerAccount afterBad = await repo.LoadAccountAsync(profileId)
                ?? throw new InvalidDataException("select-box account disappeared");
            Assert(afterBad.Bag!.Items.Single(i => i.TemplateId == itemBoxId).Num == 3,
                $"a rejected selection at position {badPosition} still consumed a box");
        }

        // 时装奖励必须进时装表，不能按道具入包。
        ShopService.TreasureOpenResult fashion = await shop.BuildOpenSelectTreasureRetAsync(
            new TRequest("bag.GetSelectTreasureInfo", Args(fashionBoxId, 1, 1)), profileId, CancellationToken.None);
        Assert(fashion.Changed, $"fashion option was rejected: {fashion.Error}");
        PlayerAccount afterFashion = await repo.LoadAccountAsync(profileId)
            ?? throw new InvalidDataException("select-box account disappeared");
        Assert(afterFashion.Fashion?.Entries.Any(e => e.FashionTids.Contains(4044015)) == true,
            "fashion option did not unlock the skin");
        Assert(afterFashion.Bag!.Items.All(i => i.TemplateId != 4044015),
            "fashion option polluted the item bag");

        // 舰船选项本次不实现，必须明确拒绝而不是静默发放。
        ShopService.TreasureOpenResult ship = await shop.BuildOpenSelectTreasureRetAsync(
            new TRequest("bag.GetSelectTreasureInfo", Args(shipBoxId, 1, 1)), profileId, CancellationToken.None);
        Assert(!ship.Changed && ship.Error.Length > 0,
            "ship option inside an item box should be rejected with an error");

        // 舰船箱（type=1）必须维持改动前的空响应：Changed=false 且 Error 为空。
        ShopService.TreasureOpenResult heroBox = await shop.BuildOpenSelectTreasureRetAsync(
            new TRequest("bag.GetSelectTreasureInfo", Args(heroBoxId, 1, 1)), profileId, CancellationToken.None);
        Assert(!heroBox.Changed && heroBox.Error.Length == 0,
            "hero selection box must keep its previous empty response");
    }
    finally
    {
        if (Directory.Exists(dataRoot)) Directory.Delete(dataRoot, true);
    }
}

static Task TaskCompletionRequiresProgressTest()
{
    TaskDefinition definition = new(
        TaskConfigCatalog.TypeDaily, 10, EventType: 2, Goal: 3, CountType: 1, RewardId: 40008);

    byte[] emptyTask = TaskProtocolCodec.EncodeTask(definition, null);
    Assert(ProtocolDecoder.DecodeVarintField(emptyTask, 3) == 0 &&
           ProtocolDecoder.DecodeVarintField(emptyTask, 4) == 0,
        "a task without progress encoded a finish time or completed count");

    Assert(!TaskService.IsCompleted(null, definition),
        "a task without persisted progress was treated as complete");
    Assert(!TaskService.IsCompleted(
            new PlayerTaskRecord(definition.TaskType, definition.Id, 0, Count: 2), definition),
        "task progress below the configured goal was treated as complete");
    Assert(TaskService.IsCompleted(
            new PlayerTaskRecord(definition.TaskType, definition.Id, 0, Count: 3), definition),
        "task progress at the configured goal was not treated as complete");
    Assert(TaskService.IsCompleted(
            new PlayerTaskRecord(definition.TaskType, definition.Id, FinishTime: 1, Count: 0), definition),
        "an explicitly finished task was not treated as complete");

    Dictionary<(int Type, int Id), PlayerTaskRecord> noProgress = [];
    Assert(TaskProtocolCodec.GetEventProgress([definition], noProgress) == 0,
        "an event without persisted progress encoded its goal as current progress");
    Dictionary<(int Type, int Id), PlayerTaskRecord> partialProgress = new()
    {
        [(definition.TaskType, definition.Id)] =
            new PlayerTaskRecord(definition.TaskType, definition.Id, 0, Count: 2)
    };
    Assert(TaskProtocolCodec.GetEventProgress([definition], partialProgress) == 2,
        "partial task event progress was not preserved");
    return Task.CompletedTask;
}

// ProtocolDecoder.ProtoReader 是 ref struct，C# 12 不允许它出现在 async 方法体内
// （CS8652）。DailyCopyGameplayTest 是 async，两处解析必须提到独立的同步方法里。
static (int BaseInfoCount, bool FirstDestroyerLevel, bool DestroyerTreaty) ScanDailyCopyInfo(byte[] copyPayload)
{
    int baseInfoCount = 0;
    bool foundFirstDestroyerLevel = false, foundDestroyerTreaty = false;
    ProtocolDecoder.ProtoReader copyReader = new(copyPayload);
    while (copyReader.TryReadField(out int field, out int wire))
    {
        if (field != 1 || wire != 2)
        {
            copyReader.Skip(wire);
            continue;
        }
        baseInfoCount++;
        int baseId = 0;
        ProtocolDecoder.ProtoReader baseInfo = new(copyReader.ReadBytes());
        while (baseInfo.TryReadField(out int baseField, out int baseWire))
        {
            if (baseField == 1 && baseWire == 0) baseId = checked((int)baseInfo.ReadVarint());
            else baseInfo.Skip(baseWire);
        }
        if (baseId == 20101) foundFirstDestroyerLevel = true;
        if (baseId == 20518) foundDestroyerTreaty = true;
    }
    return (baseInfoCount, foundFirstDestroyerLevel, foundDestroyerTreaty);
}

static (int ChapterRows, int GroupRows, int ExtraRows) CountDailyCopySnapshotRows(byte[] statePayload)
{
    int chapterRows = 0, groupRows = 0, extraRows = 0;
    ProtocolDecoder.ProtoReader stateReader = new(statePayload);
    while (stateReader.TryReadField(out int stateField, out int stateWire))
    {
        if (stateWire == 2 && stateField is >= 1 and <= 3)
        {
            _ = stateReader.ReadBytes();
            if (stateField == 1) chapterRows++;
            else if (stateField == 2) groupRows++;
            else extraRows++;
        }
        else stateReader.Skip(stateWire);
    }
    return (chapterRows, groupRows, extraRows);
}

static string FindClientConfigDir()
{
    string root = FindRepositoryRoot();
    string clientPath = Environment.GetEnvironmentVariable("BLUEOATH_CLIENT_PATH")
        ?? Path.Combine(root, "blueoath", "blueoath");
    return ConfigDbLoader.BuildConfigDir(clientPath);
}

static void Assert(bool condition, string message) { if (!condition) throw new InvalidOperationException(message); }

sealed class FragmentedStream(byte[] data, int chunk) : MemoryStream
{
    private readonly byte[] _data = data; private int _offset;
    public override int Read(Span<byte> buffer) { if (_offset >= _data.Length) return 0; var count = Math.Min(Math.Min(chunk, buffer.Length), _data.Length - _offset); _data.AsSpan(_offset, count).CopyTo(buffer); _offset += count; return count; }
    public override ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default) => new(Read(buffer.Span));
}
