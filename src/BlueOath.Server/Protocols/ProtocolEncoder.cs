using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 服务端 protobuf 编码器：把实体/数据编码为客户端可解析的 protobuf 字节。
/// 统一基于 <see cref="ProtocolPackage"/>（fluent 写入），输出与旧手写
/// <c>WriteVarint(ms, key); WriteVarint(ms, value);</c> 字节完全一致。
/// </summary>
internal static class ProtocolEncoder
{
    /// <summary>编码 TBuildShipRet: BuildShipResult(1, repeated TCommonReward)。</summary>
    internal static byte[] EncodeBuildShipRet(IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        foreach (CommonReward r in rewards)
        {
            ProtocolPackage item = new();
            if (r.Type != 0)
                item.Write(0x08, unchecked((ulong)r.Type));
            if (r.ConfigId != 0)
                item.Write(0x10, unchecked((ulong)r.ConfigId));
            if (r.Num != 0)
                item.Write(0x18, unchecked((ulong)r.Num));
            item.Write(0x20, unchecked((ulong)r.Id));
            byte[] body = item.ToArray();
            output.Write(0x0A, body);
        }

        // TransReward(3) 需要与抽取结果按下标对齐，否则 _LoadTenCard 会访问 nil。
        // SpReward(2) 不能填充空元素：客户端用 next(SpReward) 判断是否需要打开
        // 额外奖励页，空壳会被误判为真实奖励并显示一个没有内容的报酬页面。
        for (int i = 0; i < rewards.Count; i++)
        {
            output.WriteRaw(0x1A); // TransReward
            output.WriteRaw(0x00);
        }

        return output.ToArray();
    }

    /// <summary>构建头像解锁列表推送（TNewHeadUnlockedList），包含船坞中所有舰娘的 sf_id。</summary>
    internal static byte[] BuildHeadUnlockedListPush(PlayerAccount account)
    {
        // 收集船坞中所有舰娘的 sf_id（ship_info_id = (TemplateId - 1) / 10）
        List<int> sfIds = account.Dock.Heroes
            .Select(h => (h.TemplateId - 1) / 10)
            .Distinct()
            .ToList();
        ProtocolPackage output = new();
        foreach (int sfId in sfIds)
        {
            // TNewHeadNode: ShipFleetId(1, int32), ProfileID(2, repeated int32)
            ProtocolPackage node = new();
            node.Write(0x08, unchecked((ulong)sfId)); // ShipFleetId
            node.Write(0x10, unchecked((ulong)sfId)); // ProfileID = sfId
            byte[] body = node.ToArray();
            output.Write(0x0A, body); // UnlockedList field 1, wire 2
        }

        return output.ToArray();
    }

    /// <summary>编码 TEquipDismantleRet: ItemInfo(1, repeated TCommonReward)。</summary>
    internal static byte[] EncodeEquipDismantleRet(IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        foreach (CommonReward r in rewards)
        {
            ProtocolPackage item = new();
            if (r.Type != 0)
                item.Write(0x08, unchecked((ulong)r.Type));
            if (r.ConfigId != 0)
                item.Write(0x10, unchecked((ulong)r.ConfigId));
            if (r.Num != 0)
                item.Write(0x18, unchecked((ulong)r.Num));
            if (r.Id != 0)
                item.Write(0x20, unchecked((ulong)r.Id));
            byte[] body = item.ToArray();
            output.Write(0x0A, body);
        }

        return output.ToArray();
    }

    /// <summary>编码 build.BuildReceive 的 TBuildReceiveRet.reward。</summary>
    internal static byte[] EncodeBuildReceiveRet(IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        foreach (CommonReward reward in rewards)
            output.Write(0x0A, PlayerDataCodec.Encode(reward));
        return output.ToArray();
    }

    /// <summary>编码 TRetireHeroRet: Reward(1, repeated TCommonReward)。</summary>
    internal static byte[] EncodeRetireHeroRet(IReadOnlyList<CommonReward> rewards)
    {
        ProtocolPackage output = new();
        foreach (CommonReward reward in rewards)
            output.Write(0x0A, PlayerDataCodec.Encode(reward));
        return output.ToArray();
    }

    /// <summary>编码 TLockHeroRet: Ret(1, uint32)，返回被更新的舰娘实例 ID。</summary>
    internal static byte[] EncodeLockHeroRet(uint heroId)
    {
        ProtocolPackage output = new();
        output.Write(0x08, heroId);
        return output.ToArray();
    }

    /// <summary>编码 THeroAddAffectionRet: Ret(1), HeroId(2), Affection(3)。</summary>
    internal static byte[] EncodeHeroAddAffectionRet(uint heroId, int affection)
    {
        ProtocolPackage output = new();
        output.Write(0x08, 0UL);
        output.Write(0x10, heroId);
        output.Write(0x18, unchecked((ulong)affection));
        return output.ToArray();
    }

    internal static byte[] EncodeHeroAddExpRet(uint heroId, List<ItemCount> items)
    {
        ProtocolPackage output = new();
        if (heroId != 0)
            output.Write(0x08, heroId);
        foreach (ItemCount item in items)
        {
            ProtocolPackage itemMsg = new();
            if (item.Id != 0)
                itemMsg.Write(0x10, unchecked((ulong)item.Id));
            if (item.Num != 0)
                itemMsg.Write(0x18, unchecked((ulong)item.Num));
            byte[] body = itemMsg.ToArray();
            output.Write(0x12, body);
        }

        return output.ToArray();
    }

    internal static byte[] EncodeStartBaseRet(int copyId, List<Hero> heroes, PlayerCharacter character,
        IReadOnlyList<int>? deployHeroIds = null,
        bool isRunningFight = false, int battleMode = 1, int matchType = 0,
        IReadOnlyList<RandomFactorEntry>? randomFactors = null,
        PlayerEquip? playerEquip = null)
    {
        // 本关全部敌舰队 id（config_copy → fleet_id 数组）。客户端
        // BattleStartData.enemyFleetId 是 int[]，PlayerInterface.InitNpc 遍历它逐个生成
        // 敌舰队（每舰队含自身 copy_attacheds 附属舰队）。只发单个会导致关卡多舰队时
        // 只生成 1 个敌怪。查不到时回退单值。
        List<int> fleetIdList = CopyBattleLoader.GetFleetIdList(copyId);

        // 出战船只按客户端请求顺序（剧情关可能带临时/支援舰船，其 HeroId 不在玩家船坞，
        // 需从 config_assist_ship_info 加载回环，否则临时舰船丢失）。编队为空时回退到全部船。
        List<Hero> deploy;
        if (deployHeroIds is { Count: > 0 })
        {
            Dictionary<int, Hero> byId = heroes.ToDictionary(h => (int)h.HeroId);
            deploy = new List<Hero>();
            foreach (int id in deployHeroIds)
            {
                if (byId.TryGetValue(id, out Hero? hero))
                {
                    deploy.Add(hero);
                }
                else if (AssistShipLoader.Get(id) is { } assist)
                {
                    int templateId = checked((int)assist.ShipMainId);
                    deploy.Add(new Hero((uint)id, templateId, checked((int)assist.ShipLevel),
                        (templateId - 1) / 10));
                }

                if (deploy.Count >= 6) break;
            }
        }
        else
        {
            deploy = heroes.Take(6).ToList();
        }

        ProtocolPackage ms = new();
        // BattlePlayer (1) — TBattlePlayerList with full fleet data
        ProtocolPackage bpList = new();
        ProtocolPackage bp = new();
        bp.Write(0x08, character.Uid); // Pid
        bp.Write(0x10, character.Uid); // Uid
        bp.Write(0x1A, character.Name); // Uname
        bp.Write(0x20, unchecked((ulong)character.Level)); // Level
        bp.Write(0x28, 1UL); // PlayerCamp=1
        bp.Write(0x30, 1UL); // Index=1
        // FleetInfo (7) — TBattleFleet with full ship data
        ProtocolPackage fleet = new();
        fleet.Write(0x08, 1UL); // FleetId=1
        fleet.Write(0x10, 2UL); // FormationId=2
        fleet.Write(0x18, 1UL); // Index=1
        // Ships (4)
        for (int i = 0; i < deploy.Count; i++)
        {
            Hero h = deploy[i];
            ProtocolPackage ship = new();
            ship.Write(0x08, (ulong)h.HeroId);
            ship.Write(0x10, unchecked((ulong)h.TemplateId));
            ship.Write(0x18, unchecked((ulong)h.Level));
            ship.Write(0x20, unchecked((ulong)i));
            // Attr (5) — 按船 TemplateId 查 config_ship_main 发真实属性（考虑等级成长），
            // 临时/支援舰船（HeroId 在 config_assist_ship_info）直接用其属性表。
            // 命中判定 __IsHit(hit, dodge) 依赖 Hit/Dodge。
            ConfigAssistShipInfo? assist = AssistShipLoader.Get(checked((int)h.HeroId));
            ConfigShipMain? cfg = ShipMainLoader.Get(h.TemplateId);
            long shipHp, attack, defense, hit, dodge, crit, antiCrit, torpedoAttack, torpedoDefense;
            long planeBomb = 0, planeTorpedo = 0, scoutNum = 1;
            if (assist is not null)
            {
                shipHp = assist.Hp;
                attack = assist.Attack;
                defense = assist.Defense;
                hit = assist.Hit;
                dodge = assist.Dodge;
                crit = assist.Crit;
                antiCrit = assist.AntiCrit;
                torpedoAttack = assist.TorpedoAttack;
                torpedoDefense = assist.TorpedoDefense;
                // 空袭伤害基础 ShipPlaneAttack(14)=舰载机轰炸攻击(ship_bomb_attack)。
                // plane_bomb 是飞机炸弹属性（经飞机装备传递），不是舰载机攻击。
                if (ShipMainLoader.Get(checked((int)assist.ShipMainId)) is { } acfg)
                {
                    planeBomb = acfg.ShipBombAttack;
                    planeTorpedo = acfg.ShipTorpedoAttack;
                    if (acfg.CarryPlaneCount > 0) scoutNum = acfg.CarryPlaneCount;
                }
            }
            else if (cfg is null)
            {
                shipHp = 1000;
                attack = 100;
                defense = 50;
                hit = 100;
                dodge = 35;
                crit = 0;
                antiCrit = 0;
                torpedoAttack = 0;
                torpedoDefense = 0;
            }
            else
            {
                shipHp = ShipMainLoader.Leveled(cfg.Hp, cfg.HpLevelup, h.Level);
                attack = ShipMainLoader.Leveled(cfg.Attack, cfg.AttackLevelup, h.Level);
                defense = ShipMainLoader.Leveled(cfg.Defense, cfg.DefenseLevelup, h.Level);
                hit = cfg.Hit;
                dodge = cfg.Dodge;
                crit = cfg.Crit;
                antiCrit = cfg.AntiCrit;
                torpedoAttack = ShipMainLoader.Leveled(cfg.TorpedoAttack, cfg.TorpedoAttackLevelup, h.Level);
                torpedoDefense = ShipMainLoader.Leveled(cfg.TorpedoDefense, cfg.TorpedoDefenseLevelup, h.Level);
                planeBomb = cfg.ShipBombAttack;
                planeTorpedo = cfg.ShipTorpedoAttack;
                if (cfg.CarryPlaneCount > 0) scoutNum = cfg.CarryPlaneCount;
            }

            foreach ((int attrId, long val) in new[]
                     {
                         (1, shipHp), (5, scoutNum), (8, attack), (9, defense),
                         (10, torpedoAttack), (11, torpedoDefense),
                         (14, planeBomb), (15, planeTorpedo),
                         (17, crit), (18, antiCrit), (19, hit), (20, dodge)
                     })
            {
                ProtocolPackage attr = new();
                attr.Write(0x08, unchecked((ulong)attrId));
                attr.Write(0x10, unchecked((ulong)val));
                byte[] ab = attr.ToArray();
                ship.Write(0x2A, ab);
            }

            ship.Write(0x30, PlayerAccountFactory.HpCoefficient); // CurHp(6)
            ship.Write(0x58, 3UL); // EquipGridNum(11)
            ship.Write(0x60, unchecked((ulong)h.Fashioning)); // Fashioning(12)
            // PSkill (8) — TFiledPSkillLv[]，编码实际技能数据。
            if (h.PSkills is { Count: > 0 })
            {
                foreach (PSkillEntry sk in h.PSkills)
                {
                    ProtocolPackage pskill = new();
                    pskill.Write(0x08, (ulong)sk.PSkillId);
                    pskill.Write(0x10, unchecked((ulong)sk.Level));
                    byte[] pskillBytes = pskill.ToArray();
                    ship.Write(0x42, pskillBytes);
                }
            }
            else
            {
                // 无技能数据时编码一个 dummy PSkill，PSkillId=41210 是有效 config ID
                ProtocolPackage pskill = new();
                pskill.Write(0x08, 41210UL);
                pskill.Write(0x10, 1UL);
                byte[] pskillBytes = pskill.ToArray();
                ship.Write(0x42, pskillBytes);
            }
            // Equips (7) — TBattleEquip[]。临时/支援舰船用 config_assist_ship_info.equip。
            // 航母的空袭依赖飞机装备（PlaneNum），否则空袭技能不出现。
            // 玩家自有舰船从 EquipSlots → EquipItem.TemplateId → ConfigEquip 读取装备。
            var equipById = playerEquip?.Items.ToDictionary(e => e.EquipId) ?? new Dictionary<uint, EquipItem>();
            List<ConfigEquip> shipEquips = [];
            if (assist?.Equip is { Count: > 0 })
            {
                for (int ei = 0; ei < assist.Equip.Count; ei++)
                {
                    int eid = checked((int)assist.Equip[ei]);
                    if (eid == 0) continue;
                    ConfigEquip? ecfg = EquipLoader.Get(eid);
                    if (ecfg is not null) shipEquips.Add(ecfg);
                }
            }
            else if (h.EquipSlots is { Count: > 0 })
            {
                foreach (uint slotId in h.EquipSlots)
                {
                    if (slotId == 0) continue;
                    if (!equipById.TryGetValue(slotId, out EquipItem? eqItem)) continue;
                    ConfigEquip? ecfg = EquipLoader.Get(eqItem.TemplateId);
                    if (ecfg is not null) shipEquips.Add(ecfg);
                }
            }

            for (int ei = 0; ei < shipEquips.Count; ei++)
            {
                ConfigEquip ecfg = shipEquips[ei];
                ProtocolPackage eq = new();
                eq.Write(0x08, unchecked((ulong)ecfg.EId)); // EquipTid(1)
                eq.Write(0x10, unchecked((ulong)ei)); // EquipIndex(2)
                eq.Write(0x18, 100UL); // PlaneNum(3)
                if (ecfg.EquipProp is { Count: > 0 })
                    foreach (List<long> ap in ecfg.EquipProp)
                        if (ap is { Count: >= 2 })
                        {
                            ProtocolPackage av = new();
                            av.Write(0x08, unchecked((ulong)ap[0])); // propId
                            av.Write(0x10, unchecked((ulong)ap[1])); // value
                            byte[] avb = av.ToArray();
                            eq.Write(0x22, avb);
                        }

                byte[] eqb = eq.ToArray();
                ship.Write(0x3A, eqb);
            }

            byte[] sb = ship.ToArray();
            fleet.Write(0x22, sb);
            // HeroList (8) — one per ship
            fleet.Write(0x40, (ulong)h.HeroId);
        }

        fleet.Write(0x28, 0UL); // StrategyId=0
        fleet.Write(0x38, 0UL); // KillTimes=0
        fleet.Write(0x48, 1UL); // TacticType=1
        byte[] fb = fleet.ToArray();
        bp.Write(0x3A, fb);
        byte[] bpb = bp.ToArray();
        bpList.Write(0x0A, bpb);
        byte[] bplb = bpList.ToArray();
        ms.Write(0x0A, bplb);
        // RandomSeed (2) — 当前时间戳（秒），避免每次战斗相同随机序列
        ms.Write(0x10, unchecked((ulong)(int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()));
        // Rid (3) = config_copy 的 r_id（客户端用它作 copyDictId 查 config_copy -> scene_id）
        int copyRid = CopyBattleLoader.GetConfigId(copyId);
        ms.Write(0x18, unchecked((ulong)copyRid));
        // CopyId (6) — 客户端用它在 config_copy_display 里查配置（键=显示 id，来自请求）
        ms.Write(0x30, unchecked((ulong)copyId));
        // CopyType (7)：剧情=1(PlotCopy)，海域=2(SeaCopy)。海域关卡战斗初始化按 CopyType 分支。
        // 海域侦察任务按 SeaCopy(2) 走索敌 3D 玩法，是正常逻辑，不能绕开（绕开会失去索敌玩法意义）。
        bool isSeaCopy = ChapterCopyLoader.GetSeaLevels().Contains(copyId);
        ms.Write(0x38, isSeaCopy ? 2UL : 1UL);
        // RandomFactors (12) — 海域索敌/侦察场景初始化依赖。按 copyId 查表：
        // config_copy_display.random_factor_sets → config_random_factor_set.factor_groups
        // → config_random_factor_group.factor（RandomFactorLoader）。海域 1600100 → [61]。
        // 剧情关 random_factor_sets=[] 无条目，自然不编码。
        if (randomFactors is { Count: > 0 })
        {
            foreach (RandomFactorEntry entry in randomFactors)
            {
                ProtocolPackage rf = new();
                foreach (int f in entry.Factors)
                    rf.Write(0x08, unchecked((ulong)f)); // Factors(1)
                if (entry.GroupId != 0)
                    rf.Write(0x10, unchecked((ulong)entry.GroupId)); // GroupId(2)
                if (entry.SetId != 0)
                    rf.Write(0x18, unchecked((ulong)entry.SetId)); // SetId(3)
                byte[] rfb = rf.ToArray();
                ms.Write(0x62, rfb);
            }
        }

        // CopyPass (8) = false
        // BossProgress (9) = 0
        // IsRunningFight (10) — 回环客户端请求的 IsRunningFight（请求/响应同名字段）
        if (isRunningFight)
        {
            ms.Write(0x50, 1UL);
        }

        // SafeLv (13) = 0
        ms.Write(0x68, 0UL);
        // BattleMode (18) = Normal=1(普通)/Exercises=2(练习)/Memory=3(记忆)/Sweep=4(扫荡)
        // 回环客户端请求的 BattleMode（请求 field 9）
        ms.Write(0x90, unchecked((ulong)(battleMode == 0 ? 1 : battleMode)));
        // MatchType (26) = 0 — 回环客户端请求的 MatchType（请求 field 15）
        if (matchType != 0)
        {
            ms.Write(0xD0, unchecked((ulong)matchType));
        }

        // 海域索敌：补齐未编码字段（IsFinal/AnimMode/WeatherGroupId），索敌核心初始化可能检查。
        if (isSeaCopy)
        {
            // IsFinal (19) = false
            ms.Write(0x98, 0UL);
            // AnimMode (20) = 0
            ms.Write(0xA0, 0UL);
            // WeatherGroupId (22) = 0 — 客户端 pb TStartBaseRet.WeatherGroupId=22（copy_pb.lua）。
            // 之前误写字段 21(0xA8)，客户端永远读到 0；改 22(0xB0)。
            ms.Write(0xB0, 0UL);
        }

        // Token (16) = ""
        ms.Write(0x82, "1111111111111111111111111111111111111");
        // arrRes (4) — TCopyRes[]。海域索敌 InitResPoint 遍历 copyRess（=arrRes）用元素查
        // battlefield_resource，海域 battlefield_resource[copyId] 缺失导致 GetDict null 卡死。
        // 海域 arrRes 发空（copyRess 空 → InitResPoint 跳过资源点生成）。
        if (!isSeaCopy)
        {
            ProtocolPackage cr = new();
            cr.Write(0x08, unchecked((ulong)copyId)); // id
            byte[] crb = cr.ToArray();
            ms.Write(0x22, crb);
        }

        // CopyMission (23) — repeated int32。注意：字段23 是 varint 元素（wire type 0），
        // 之前的 `0xB8 0x00` 编码出来的不是空数组而是 [0]——客户端按 0 去查 config_mission
        // 找不到 DictMission，MissionNode 拿 null 直接空引用崩溃。必须发客户端 config_mission
        // 里真实存在的任务 ID。按 copyId 查 config_copy.mission_id（官方多空），空则回退
        // config_mission 第一条完整任务链（101→102→103，ECA action 均已配置）。
        foreach (int mid in CopyBattleLoader.GetMissionIdList(copyId))
        {
            ms.Write(0xB8, unchecked((ulong)mid));
        }

        // EnemyFleet (5) — repeated int32：本关全部敌舰队 id → BattleStartData.enemyFleetId。
        // 客户端战斗帧用它在 config_fleet 查 ship_exp / is_last_fleet，必须非空且有效。
        // 多舰队关卡（fleet_id 数组>1）必须逐个下发，InitNpc 才会生成全部敌舰队。
        foreach (int fid in fleetIdList)
        {
            ms.Write(0x28, unchecked((ulong)fid));
        }

        // SkipVcr (17) — TCopySkipVcr[]，补发使 ctor 的 skipVcrs(+0x88) 段有数据
        {
            ProtocolPackage sv = new();
            sv.Write(0x08, 1021051UL); // ShipInfoId=1（玩家一号舰的 ship_info_id）
            // StartVcr(2)=false, EndVcr(3)=false 默认不编码（bool 默认 false）
            byte[] svb = sv.ToArray();
            ms.Write(0x8A, svb);
        }

        // EnemyFleets (24) — TBattleEnemyFleet[]，客户端 ctor 与战斗帧都需要。
        // 每个敌舰队（fleet_id 数组元素）各发一条，含该舰队 config_fleet.copy_enemys 的敌舰属性。
        foreach (int fid in fleetIdList)
        {
            List<int> enemyIds = CopyBattleLoader.GetEnemyIds(fid);
            if (enemyIds.Count == 0) continue;
            ProtocolPackage ef = new();
            ef.Write(0x08, unchecked((ulong)fid)); // FleetId
            ef.Write(0x10, 0UL); // State=0
            foreach (int enemyId in enemyIds)
            {
                CopyBattleLoader.EnemyStat? stat = CopyBattleLoader.GetEnemyStat(enemyId);
                if (stat == null) continue;
                ProtocolPackage es = new();
                es.Write(0x08, unchecked((ulong)enemyId)); // ShipId
                // Attr (2): ShipHp=1, Attack=8, Defense=9, Torpedo=10, TorpedoDefense=11,
                //          Hit=19, Dodge=20
                foreach ((int attrId, int val) in new[]
                         {
                             (1, stat.Hp), (8, stat.Attack), (9, stat.Defense),
                             (10, stat.TorpedoAttack), (11, stat.TorpedoDefense),
                             (19, stat.Hit), (20, stat.Dodge)
                         })
                {
                    ProtocolPackage attr = new();
                    attr.Write(0x08, unchecked((ulong)attrId));
                    attr.Write(0x10, unchecked((ulong)val));
                    byte[] ab = attr.ToArray();
                    es.Write(0x12, ab);
                }

                // PSkill (3) — List<int>，至少一个元素使列表非空
                es.Write(0x18, 1UL);
                byte[] esb = es.ToArray();
                ef.Write(0x1A, esb);
            }

            byte[] efb = ef.ToArray();
            ms.Write(0xC2, efb);
        }

        // ConfigData (25) — repeated TPassEvaluate。protobuf-net 编码：每个 TPassEvaluate 是
        // 独立 field25(len-delimited)，内容直接是字段（无子消息 tag），Value=默认(0)不序列化。
        // PveCoreCreator._InitWithStartDataCore 用 ConfigDatas[52002(0xCB22)] 作为索敌限时（秒）
        // 覆盖 battlefieldTime：ConfigDatas[52002]=v → 索敌限时=v*1000 ms。之前发 (52002,1) 导致
        // 索敌限时 1 秒立即耗尽。删除 52002 → TryGetValue 失败回退 dictCopy.battle_time=180。
        if (isSeaCopy)
            foreach ((int t, int v) in new[] { (50000, 1), (0, 1) })
            {
                ProtocolPackage ce = new();
                if (t != 0)
                    ce.Write(0x08, unchecked((ulong)t)); // Type(1)
                if (v != 0)
                    ce.Write(0x10, unchecked((ulong)v)); // Value(2)
                byte[] ceb = ce.ToArray();
                ms.Write(0xCA, ceb);
            }

        return ms.ToArray();
    }

    internal static byte[] EncodePassBaseRet(int copyId = 0, int grade = 3, int firstPass = 1, int passTime = 60)
    {
        ProtocolPackage ms = new();
        if (copyId != 0)
            ms.Write(0x60, unchecked((ulong)copyId));
        if (grade != 0)
            ms.Write(0x20, unchecked((ulong)grade));
        int starLevel = grade > 0 ? 7 : 0;
        ms.Write(0x30, unchecked((ulong)starLevel));
        if (firstPass != 0)
            ms.Write(0x50, unchecked((ulong)firstPass));
        if (passTime != 0)
            ms.Write(0x40, unchecked((ulong)passTime));
        ms.Write(0x18, 0UL);
        return ms.ToArray();
    }

    /// <summary>copyinfo.GetCopyInfo 响应（TGetCopyInfoRet）。</summary>
    internal static byte[] BuildCopyInfoRet(byte[] args) => EncodeCopyInfoRet();

    internal static byte[] EncodeCopyInfoRet()
    {
        ProtocolPackage ms = new();
        ms.Write(0x20, 0UL);
        return ms.ToArray();
    }

    /// <summary>编码 TBattlePlayer 子消息（玩家 + 编队 + 舰船数据）。</summary>
    internal static byte[] EncodeBattlePlayer(List<Hero> heroes, PlayerCharacter character)
    {
        ProtocolPackage bp = new();
        bp.Write(0x08, character.Uid); // Pid
        bp.Write(0x10, character.Uid); // Uid
        bp.Write(0x1A, character.Name); // Uname
        bp.Write(0x20, unchecked((ulong)character.Level)); // Level
        bp.Write(0x28, 1UL); // PlayerCamp=1
        bp.Write(0x30, 1UL); // Index=1
        ProtocolPackage fleet = new();
        fleet.Write(0x08, 1UL); // FleetId=1
        fleet.Write(0x10, 2UL); // FormationId=2
        fleet.Write(0x18, 1UL); // Index=1
        for (int i = 0; i < Math.Min(heroes.Count, 6); i++)
        {
            Hero h = heroes[i];
            ProtocolPackage ship = new();
            ship.Write(0x08, (ulong)h.HeroId);
            ship.Write(0x10, unchecked((ulong)h.TemplateId));
            ship.Write(0x18, unchecked((ulong)h.Level));
            ship.Write(0x20, unchecked((ulong)i));
            foreach ((int attrId, int val) in new[] { (1, 1000), (2, 100), (3, 50) })
            {
                ProtocolPackage attr = new();
                attr.Write(0x08, unchecked((ulong)attrId));
                attr.Write(0x10, unchecked((ulong)val));
                byte[] ab = attr.ToArray();
                ship.Write(0x2A, ab);
            }

            ship.Write(0x30, PlayerAccountFactory.HpCoefficient);
            ship.Write(0x58, 3UL);
            ship.Write(0x60, unchecked((ulong)h.Fashioning));
            byte[] sb = ship.ToArray();
            fleet.Write(0x22, sb);
            fleet.Write(0x40, (ulong)h.HeroId); // HeroList(8) per ship
        }

        fleet.Write(0x28, 0UL);
        fleet.Write(0x38, 0UL);
        fleet.Write(0x48, 1UL);
        byte[] fb = fleet.ToArray();
        bp.Write(0x3A, fb);
        return bp.ToArray();
    }

    /// <summary>编码玩家编队数据为 TSelfTactis protobuf。</summary>
    public static byte[] EncodeFleet(PlayerFleet fleet)
    {
        ProtocolPackage ms = new();
        foreach (FleetEntry t in fleet.Tactics)
        {
            ProtocolPackage entry = new();
            // tacticName (1)
            // Empty means "use the localized default fleet name". The Lua protobuf runtime
            // represents an omitted optional string as nil, while FleetLogic only applies its
            // localized fallback when tacticName == "", so the zero-length field is required.
            entry.Write(0x0A, t.TacticName ?? "");
            // heroInfo (2, repeated int32)
            if (t.HeroInfo is { Count: > 0 })
                foreach (int h in t.HeroInfo)
                    entry.Write(0x10, unchecked((ulong)h));
            // modeId (3)
            entry.Write(0x18, unchecked((ulong)t.ModeId));
            // strategyId (4)
            entry.Write(0x20, unchecked((ulong)t.StrategyId));
            // formationId (5)
            entry.Write(0x28, unchecked((ulong)t.FormationId));
            // type (6)
            entry.Write(0x30, unchecked((ulong)t.Type));
            // exHeroInfo (7, repeated int32)
            if (t.ExHeroInfo is { Count: > 0 })
                foreach (int h in t.ExHeroInfo)
                    entry.Write(0x38, unchecked((ulong)h));
            byte[] body = entry.ToArray();
            ms.Write(0x0A, body); // tactics field 1
        }

        if (fleet.MaxPower != 0)
            ms.Write(0x10, unchecked((ulong)fleet.MaxPower));
        if (fleet.MinPower != 0)
            ms.Write(0x18, unchecked((ulong)fleet.MinPower));
        return ms.ToArray();
    }

    /// <summary>cachedata.CacheData 响应（TCacheDataRet{Ret=string}）。</summary>
    internal static byte[] EncodeCacheDataRet()
    {
        ProtocolPackage ms = new();
        ms.Write(0x0A, "local");
        return ms.ToArray();
    }

    /// <summary>编码全部剧情回顾章节为 TUserCopyInfo protobuf（CopyType=1 PlotCopy）。
    /// 包含主线、活动、番外和日常等全部剧情章节，并标记为已通关。</summary>
    public static byte[] EncodePlotCopyInfo(int chapterId = 1, PlayerCopyProgress? progress = null)
    {
        Dictionary<int, CopyRecord> recordMap = progress?.Records
            .ToDictionary(r => r.CopyId, r => r) ?? new Dictionary<int, CopyRecord>();

        // 使用章节加载器获取所有章节的关卡
        List<int> chapterIds = ChapterCopyLoader.GetAllChapterIds();
        // 收集 chapterId 及之前所有章节的关卡
        List<int> allCopyIds = new();
        foreach (int chId in chapterIds)
        {
            if (chId > chapterId) break;
            allCopyIds.AddRange(ChapterCopyLoader.GetCopyIds(chId));
        }

        #region 兜底

        // 兜底：如果加载器没有数据，使用硬编码的关卡列表
        if (allCopyIds.Count == 0)
        {
            allCopyIds.AddRange(new[]
            {
                1, 2, 3, 4, 6, 7, 9, 10, 11, 12, 13,
                101, 102, 103, 104, 105, 106, 107, 108
            });
        }

        #endregion

        ProtocolPackage ms = new();
        int maxCopyId = 0;
        foreach (int cid in allCopyIds)
        {
            ProtocolPackage baseInfo = new();
            baseInfo.Write(0x08, unchecked((ulong)cid)); // BaseId(1)
            baseInfo.Write(0x10, 0UL); // Rid(2)=0
            int starLevel = 7;
            int firstPassTime = 1;
            if (recordMap.TryGetValue(cid, out CopyRecord? rec))
            {
                starLevel = rec.StarLevel;
                firstPassTime = rec.FirstPassTime > 0 ? 1 : 1;
            }

            baseInfo.Write(0x18, unchecked((ulong)starLevel)); // StarLevel(3)
            baseInfo.Write(0x20, 0UL); // IsRunningFight(4)=0
            baseInfo.Write(0x28, 0UL); // LBPoint(5)=0
            baseInfo.Write(0x30, unchecked((ulong)firstPassTime)); // FirstPassTime(6)
            byte[] body = baseInfo.ToArray();
            ms.Write(0x0A, body);
            if (cid > maxCopyId) maxCopyId = cid;
        }

        ms.Write(0x10, unchecked((ulong)maxCopyId)); // MaxCopyId(2)
        ms.Write(0x18, 1UL); // CopyType(3)=PlotCopy
        return ms.ToArray();
    }

    /// <summary>编码海域（SeaCopy, CopyType=2）数据为 TUserCopyInfo protobuf。
    /// 海域页面（SeaCopyPage）依赖 Data.copyData:GetCopyInfo() 里有海域关卡，
    /// 否则 CheckChapterIsOpen/GetBattleModeChapter 返回 false，节点不显示。
    /// MaxCopyId = 最后一章第一关，使 _getFarestId(SeaCopy) 落在最后一章，
    /// 从而 nChapterNewIndex = 最后一章，所有章节可自由切换。</summary>
    public static byte[] EncodeSeaCopyInfo(PlayerSeaCopyProgress? progress = null)
    {
        Dictionary<int, CopyRecord> recordMap = progress?.Records
            .ToDictionary(r => r.CopyId, r => r) ?? new Dictionary<int, CopyRecord>();
        List<int> seaLevels = ChapterCopyLoader.GetSeaLevels();
        int maxCopyId = ChapterCopyLoader.GetSeaLastCopyId();
        ProtocolPackage ms = new();
        foreach (int cid in seaLevels)
        {
            ProtocolPackage baseInfo = new();
            baseInfo.Write(0x08, unchecked((ulong)cid)); // BaseId(1)
            baseInfo.Write(0x10, 0UL); // Rid(2)=0
            int starLevel = 7;
            int firstPassTime = 1;
            if (recordMap.TryGetValue(cid, out CopyRecord? rec))
            {
                starLevel = rec.StarLevel;
                firstPassTime = rec.FirstPassTime > 0 ? 1 : 1;
            }

            baseInfo.Write(0x18, unchecked((ulong)starLevel)); // StarLevel(3)
            baseInfo.Write(0x20, 0UL); // IsRunningFight(4)=0
            baseInfo.Write(0x28, 0UL); // LBPoint(5)=0
            baseInfo.Write(0x30, unchecked((ulong)firstPassTime)); // FirstPassTime(6)
            byte[] body = baseInfo.ToArray();
            ms.Write(0x0A, body);
        }

        ms.Write(0x10, unchecked((ulong)maxCopyId)); // MaxCopyId(2)
        ms.Write(0x18, 2UL); // CopyType(3)=SeaCopy
        return ms.ToArray();
    }

    /// <summary>
    /// 回环 copy.AttackBase 请求（TAttackBaseArg: AttackType(1)/CopyId(2)/HeroIds(3)/EnemyId(4)）
    /// 并附带一个伤害值（字段5，按最大生命值比例的扣血，HpCoefficient 比例尺=1e10 下 10%=1e9）。
    /// 客户端在没有回报时认定攻击失效，因此这里必须回包。
    /// </summary>
    internal static byte[] BuildAttackBaseRet(byte[]? args)
    {
        int attackType = 0, copyId = 0, enemyId = 0;
        List<int> heroIds = new();
        if (args is { Length: > 0 })
        {
            ProtocolDecoder.ProtoReader reader = new(args);
            while (reader.TryReadField(out int field, out int wire))
                switch (field)
                {
                    case 1 when wire == 0: attackType = checked((int)reader.ReadVarint()); break;
                    case 2 when wire == 0: copyId = checked((int)reader.ReadVarint()); break;
                    case 3 when wire == 0: heroIds.Add(checked((int)reader.ReadVarint())); break;
                    case 4 when wire == 0: enemyId = checked((int)reader.ReadVarint()); break;
                    default: reader.Skip(wire); break;
                }
        }

        ProtocolPackage ms = new();
        if (attackType != 0)
            ms.Write(0x08, unchecked((ulong)attackType));
        if (copyId != 0)
            ms.Write(0x10, unchecked((ulong)copyId));
        foreach (int hid in heroIds)
            ms.Write(0x18, unchecked((ulong)hid));
        if (enemyId != 0)
            ms.Write(0x20, unchecked((ulong)enemyId));
        // 伤害：扣除 10% 最大生命值（比例尺下 1e9）
        ms.Write(0x28, 1_000_000_000UL);
        return ms.ToArray();
    }

    /// <summary>回环 copy.QuitBase 请求（TQuitBaseArg），让客户端确认退出请求被受理。</summary>
    internal static byte[] BuildQuitBaseRet(byte[]? args)
    {
        ProtocolPackage ms = new();
        if (args is { Length: > 0 })
            // 直接回环原始请求字节（客户端数据回环，避免服务端造数据）
            ms.WriteRaw(args);
        return ms.ToArray();
    }
}
