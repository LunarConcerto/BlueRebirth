# 苍蓝誓约 `battlefield_info`（战场配置）完整逻辑调查报告

> 状态：**资料收集完成（2026-08-25）**。本文档逆向自 il2cpp Windows 版（JP 1.4.0），覆盖 `config_fleet.battlefield_info` 从配置到战斗中敌/玩家舰队落位的**完整数据流**，作为海域"非 1-A 决斗后敌舰队离很远、玩家无法操作"问题的资料库，避免后续重复读汇编。
>
> 相关文档：`docs/research/sea/sea-search.md`（索敌阶段出生点/迷雾/巡逻）、`docs/research/sea/sea-battle.md`（索敌→战斗 FSM / 战斗限时）。
>
> 结论一句话：**`battlefield_info` 只在索敌→决斗转换时决定用哪套"进场位置工具（EBPKit）"：`-1` 走 `NormalPos`（按当前舰队几何中心落位，正常）；非 `-1` 走 `SceneConfigPos`（按 `config_battlefield_info` 里另一张地图的场景出生点坐标落位）。海域非 1-A 舰队配的 `battlefield_info` 指向的是 1600900/1610300/1620100 等**别的地图**的坐标，落入当前海域场景（1600100）后全部偏移到错误位置 → 敌舰远、操作失效。**

---

## 1. 完整数据流（配置 → 战斗落位）

### 1.1 阶段 A：生成敌舰队时写入 `NPCBattlefieldData`

```
服务端 copy.StartBase → PlayerInterface.InitNpc(BattleStartData) 0x168ADB0
  → FleetInterface.GenerateNPCFleetFromChapter 0x567AF0
  → GenerateNPCFleetFromEnemyData 0x567DF0（海域/索敌路径）
  → FleetInterface._InitNPCBattlefieldData(NPCFleetBase fleet, DictFleet fleetData)  0x56CAC0
```

`_InitNPCBattlefieldData`（0x56CAC0）把 `DictFleet`（config_fleet）字段**逐字段复制**到 `NPCFleetBase.battlefieldData`（NPCBattlefieldData，offset 0xB0）：

| DictFleet 偏移 | 字段 | → NPCBattlefieldData 偏移 | 字段 |
|---|---|---|---|
| 0x8 | f_id | 0x8 | dictId |
| 0xC | copy_type | 0xC | copyType |
| 0x10 | is_last_fleet(==1) | 0x10 | isFinalFleet |
| 0x18 | **battle_center_pos**(string) | 0x28 | **battleCenterPosId** |
| 0x2C | copy_attacheds_formation | 0x14 | partnerFormation |
| 0x30 | battle_time ×1000 | 0x1C | battleMilliseconds |
| 0x34 | night_battle_time ×1000 | 0x20 | nightBattleMilliseconds |
| 0x38 | longNight_battle_time ×1000 | 0x24 | longNightMilliseconds |
| 0x3C | battle_radiu | 0x2C | battleRadiu |
| **0xD8** | **battlefield_info** | **0x30** | **battlefieldInfoId** |

> 注意：**无条件复制**，`battlefield_info = -1` 也被原样写入 `battlefieldInfoId`（不会在此处分流）。
> `_InitNPCBattlefieldData` 由 `GenerateNPCFleetFromChapter`(0x567BAF) 与 `GenerateNPCFleetFromEnemyData`(0x567EB0) 两处调用。

### 1.2 阶段 B：索敌→决斗转换 `StateBattleReady.__EnterBattleFromSearch`

```
LogicFSMUnit 进入 StateBattleReady._CEnter  0x5101F0
  → __EnterDay  0x510990
  → __EnterBattleFromSearch  0x510670   （索敌→战斗，关键入口）
      ├─ JoinBattleInterface.GetJoinBattleFleetUidList()  0x52B650  → uid 列表
      ├─ LogicAPI.InitBattleArea(uids)     0x156980（vtable Slot 12）
      ├─ LogicAPI.InitBattleFleetData(uids) 0x156A00
      └─ ShipInterface.EnterBattle(uids)   0x528C80 等
```

### 1.3 阶段 C：`InitBattleArea` → `MapInfoInterface.SetBattleData`（写战场中心/半径/战场ID）

`LogicAPI.InitBattleArea`（0x156980）：

```
masterUid = battleAPI.GetMasterFleetUID()                0x10671730
master    = fleetAPI.Fleet(masterUid)                    0x10567360
npc       = fleetAPI.Convert2NPC(master)                 0x10565B70
bd        = npc->battlefieldData                         [npc + 0xB0]（NPCBattlefieldData）
mapAPI.SetBattleData(bd->battleCenterPosId,              0x1167E570
                     bd->battleRadiu,
                     bd->battlefieldInfoId)
```

> **master = 正在被决斗的敌舰队**（海域索敌里它就是战斗发起方，其 `DictFleet` 决定整个分支）。所以海域 1-A（`battlefield_info=-1`）与其他海域（非 -1）行为不同，正因每个**敌舰队自己的** config_fleet 配置不同。

`MapInfoInterface.SetBattleData(centerPos, battleRadiu, battlefieldInfoId)`（0x167E570）写入 `LogicData.data_map`（LogicData_Map）：

| LogicData_Map 偏移 | 字段 | 来源 |
|---|---|---|
| 0x38/0x40 | battleCenterPos (x,y) | `ConfigInterface.DictPos(centerPos)`（0x66C1C0，内部 `ScenePositionBlo.GetLogicPos` 0x5EB190 → config_scene_position） |
| 0x48 | battleCircleRadiu | 参数 battleRadiu |
| 0x4C | **battlefieldInfoId** | 参数 battlefieldInfoId（= NPCBattlefieldData.battlefieldInfoId） |
| 0x50 | **dictBattlefieldInfo** | **仅当 battlefieldInfoId != -1**：`ConfigInterface.DictBattlefieldInfo(id)`（0x66C1A0 → 0x5DABA0 → DictBattlefieldInfoBlo） |

即：`-1` 时 `LogicData_Map.dictBattlefieldInfo` **保持 null**；非 -1 时加载 `config_battlefield_info[id]` 对象。

### 1.4 阶段 D：选 EBPKit 并落位（核心分支）

`LogicAPI.InitBattleFleetData`（0x156A00）尾部：

```
kit = joinBattleAPI.GetEBPKit(fleetList)    0x52B3C0
kit->Execute(fleetList)                     （vtable，多态派发）
```

`JoinBattleInterface.GetEBPKit`（0x52B3C0）→ **根据 master 敌舰队的 `DictFleet.battlefield_info` 选择工具**：

```
master = fleetAPI.Fleet(battleAPI.GetMasterFleetUID())
masterData = FleetBlo.GetFleet(ToString(master->dictID))    0x105E3C70   // master.dictID 在 0x84
if masterData->battlefield_info != -1  → new SceneConfigPos    // 0x11D38830，海域非 1-A
else:
    if 遭遇了特殊队形条件                   → new TeamAttackPos     // 0x11D3885C
    elif searchAPI.isSupportTeamAttack()   → new GuardAttackPos    // 0x11D38878
    else                                   → new NormalPos         // 0x11D38894，海域 1-A
```

`EnterBattlePos` 工具族（`Battle.Logic.API.Root.Kits.EnterBattlePos`）：

| 工具 | 说明 | Execute RVA |
|---|---|---|
| NormalPos（默认/-1） | 以**当前所有舰队几何中心**为基准落位，保持索敌时相对距离 | 0x15DB90 |
| SceneConfigPos（battlefield_info≥0） | 按 `config_battlefield_info` 的 position 数组逐舰队落位 | 0x15E750 |
| GuardAttackPos | 护卫舰队，围绕 map center | 0x153710 |
| TeamAttackPos | 队攻 | 0x163F90 |
| BuffChangePos | Buff 改位 | 0x151DD0 |

---

## 2. `SceneConfigPos`：enemy/player/assist 位置如何落舰队（关键）

### 2.1 Execute（0x15E750）→ InitFleetsWithBattleFieldInfo（0x15E8D0）

```
master    = fleetAPI.Fleet(battleAPI.GetMasterFleetUID())
masterData= FleetBlo.GetFleet(ToString(master->dictID))      // 敌舰队的 config_fleet
bfi       = DictBattlefieldInfoBlo.GetBattlefieldInfo(       // 0xED1D30
              ToString(masterData->battlefield_info))        // [masterData+0xD8]
InitFleetsWithBattleFieldInfo(master, masterData, fleetList)
```

### 2.2 InitFleetsWithBattleFieldInfo（0x15E8D0）逐舰队落位

- 跳过 master（f_id/copy_type 与 masterData 相同的舰队不处理——它是主角，走 `player_position`）。
- 其余舰队按类型取数组（JArray indexer `0x107D0BF0`）：
  - `FleetInterface.CanManual(fleet)`（0x5657E0，玩家手动舰队）→ **player_fleet_position[]**（`DictBattlefieldInfo.get_player_fleet_position` 0x440D80）
  - 其余 → **assist_fleet_position[]**（0x440CE0）
  - 敌舰队 → **enemy_position[]**（0x440D30）
- 每个位置 id → `SceneConfigPos.InitFleetBattlePos(fleet, birthPosId)`（0x15E7D0）：
  1. `ConfigInterface.DictPos(birthPosId)`（0x66C1C0）→ CVector2
     - 内部：`ScenePositionBlo.GetScenePosition(sp_id)`（0x11AAD30，config_scene_position 表）→ `position_x(0x14)/position_z(0x1C)` → `×WorldScale`（`GetLogicPos` 0x5EB190，scale 来自 `ConfigAPI.GetConfig(BL_PVEWorldScale=128)=2.75`）
  2. `ScenePositionBlo` 取 `eluer_y(0x20)` 作为朝向
  3. `EBPKit.InitFleetPos(fleet, dir, pos)`（0x153140）→ `FleetMoveInterface.UnlockTurning`(0x10572000) / `SetInitiativeTurning`(0x10571520) → `FleetMoveData` 写 pos/dir（0x103F4960/0x103F49B0）→ 逐船按阵型排开。

> **位置字符串（如 `Enemy_Battle16103000200`）是 config_scene_position 的 `sp_id` 键**，客户端**不按场景 GameObject.Find**，而是按坐标从全局配置表解析。任务背景中"场景内 GameObject 对象名"的理解需要修正：这些 sp_id 在设计上对应场景里的出生点物件名（config 的 `name` 列存场景 id，如 `1610300`），但**运行时逻辑侧只消费 config 坐标**。

### 2.3 master 敌舰队自己的位置

master 用 `DictBattlefieldInfo.player_position`（0x14，字符串）落位。实测 `config_battlefield_info` 各行的 `player_fleet_position[0] == player_position`，即敌 master 与被手动控制的玩家首舰队落在同一坐标附近（面向作战）。

---

## 3. `battlefield_info = -1`（默认）与 非-1 的代码分支差异

| 环节 | `-1`（如海域 1-A 160010000） | 非 `-1`（如 160090000/161010000/162010000） |
|---|---|---|
| `_InitNPCBattlefieldData` 0x56CAC0 | 照常写入 `battlefieldInfoId=-1` | 照常写入 1609/1613/1621 |
| `InitBattleArea`→`SetBattleData` 0x167E570 | 写 `LogicData_Map.battlefieldInfoId=-1`，**不加载** `dictBattlefieldInfo`（0x50=null） | 加载 `DictBattlefieldInfo` 到 0x50 |
| `GetEBPKit` 0x52B3C0 | `masterData.battlefield_info==-1` → **NormalPos**（或队攻/护卫） | → **SceneConfigPos** |
| 落位方式 | `NormalPos.Execute` 0x15DB90：`GetFleetsCenter(fleetList)` 求当前舰队平均中心，各舰队按 `EnterBattleRange`/`BattleRangeLength` 保持原相对距离排开 → **不依赖 battlefield_info，位置=索敌时当前位置** | `SceneConfigPos.Execute` 0x15E750：**直接覆盖**舰队坐标为 `config_scene_position`（另一张地图）坐标 |
| `FleetBattleProvingPosSystem.InitBattlefieldShape` 0x6E1990 | `mBattlefieldInfoId==-1` → **直接 return**，不设任何战场形状 | 读 `battlefield_shape(0xC)` + `shape_param(0x10)`，按 1圆/2矩/3梯/4扇/5弧 填 mCircleRadius/mRectWidth/...，Tick 把舰队限制在 battleCenterPos 周边形状内 |
| `DataBattleInterface.SetMasterFleetUpAsEnemy` 0x673560 | 走 `LogicData.data_guardFleet`（LogicData_SquireFleet，索敌遭遇的 master/meetFleet 关系） | 走 fleetList 逐队按当前位置设敌我关系 |
| 显示侧 `L2DEnterBattleLogicExe` 0x1672FC0 / `BattleWarningModule` 0x183AF0 | 边界形状 null → 不画（或正常边界） | 按 logic battleCenterPos + radius 画战场边界警告 |

**根因差异**：`-1` 时舰队"留在原地、保持遭遇时的相对位置"；非 `-1` 时舰队被**硬挪到 `config_battlefield_info` 指定的坐标**。

---

## 4. 海域实测数据（为何"敌舰队远、无法操作"）

| 敌舰队 f_id | battlefield_info | battle_center_pos（config_fleet） | 目标场景(name) | 玩家/敌落位坐标(x,z) |
|---|---|---|---|---|
| 160010000（1-A） | **-1** | `Battle_Center1600100` | **1600100**（=海域场景） | 玩家出生 `Player_Birth16001000000`(0,-60) |
| 160090000 | 1609 | `Enemy_Battle16009000000` | **1600900** | enemy(-652,-967) / player `Player_Birth16009000000`(-729,-1093) |
| 161010000 | 1613 | `Enemy_Battle16103000200` | **1610300** | enemy(-658,-937)(-795,-993)(-769,-891) / player `Player_Birth16103000100`(-729,-1091) |
| 162010000 | 1621 | `Enemy_Battle16201000000` | **1620100** | enemy `Enemy_Birth16201000000`(-823,-1031) / player(-729,-1093) |

- `config_battlefield_info[1609/1613/1621]`：`battlefield_shape=1`（圆）、`shape_param="2000"`（半径 2000 逻辑单位，×2.75≈5500 世界单位）。
- 海域索敌决斗**不切场景**，战斗仍在 `sd_seascout_1_1`（copy 1600100）。非 1-A 的战场中心/舰队坐标全部取自 **1600900/1610300/1620100 地图**的 config_scene_position → 坐标直接落到当前海域场景的错误位置。
- 落位后 `battleCenterPos`（如 1613 的 `Enemy_Battle16103000200`=(-658,-937)）用于：AI 战斗（`AI.Battle.Ctrl.battleCenterPos` 0x620920/0x61EA41）、`FleetBattleProvingPosSystem` 形状约束、显示侧 `BattleWarningModule`。三者全部跟着错误中心走 → 战场整体漂移到海域场景角落 → 敌舰可见但离玩家出生/视野极远，且玩家操作镜头/移动以战场中心为锚，表现为"无法操作"。

---

## 5. 位置对象缺失时的行为（fallback / 异常）

分三层：

1. **数组缺失/为空**（`enemy_position[]/player_fleet_position[]/assist_fleet_position[]` 为空或取不到）：
   `SceneConfigPos.InitFleetsWithBattleFieldInfo` 走错误分支，打游戏日志后**跳过该舰队（不落位，保持当前位置）**，不崩溃。日志串（stringliteral 索引 8752-8755）：
   - `DictBattlefieldInfoBlo Invalid ID {0}, 找策划解决`（0x1D24E6C，`battlefield_info` 配置不存在时）
   - `DictBattlefieldInfoBlo Invalid enemy_position {0}, 找策划解决`（0x1D24E78）
   - `DictBattlefieldInfoBlo Invalid player_fleet_position {0}, 找策划解决`（0x1D24EA4）
   - `DictBattlefieldInfoBlo Invalid assist_fleet_position {0}, 找策划解决`（0x1D24EC8）
   （日志调用点均在 0x15EBA2–0x15ED61，格式串 `{0}` = 当前数组下标。）

2. **单个 sp_id 在 config_scene_position 中不存在**：
   `ConfigInterface.DictPos`（0x66C1C0）→ `GetScenePosition` 返回 null → 走 0x1066C237 → `0x11633DF0`（il2cpp NullReferenceException 抛出点）→ **抛空引用异常（崩溃/卡战斗）**。海域非 1-A 的场景位置行在全局表里都存在，因此不触发此路径，只是坐标错。

3. **显示侧**：`L2DEnterBattleLogicExe`（0x1672FC0 起）→ `BattleWarningModule.Create(fleetUid, battleRadius, battleCenterPoint)`（0x183870），边界直接用 logic `battleCenterPos`，**不查场景物件**；`battlefieldInfoId=-1` 时 `BattleWarningModule.Load`（0x183AF0）`battleFieldInfo` 为 null，按形状字段默认处理。舰队模型位置随逻辑同步，不依赖场景对象名。

> 结论：**不存在"对象缺失→fallback 到某坐标"的降级**；非 -1 路径的"坐标错位"来自**配置表本身把另一张地图的坐标塞进了当前场景**，属于数据/场景匹配问题。

---

## 6. 关键 RVA 地址表

### 数据类
| 类 | 关键字段（偏移） | TypeDefIndex |
|---|---|---|
| `Battle.Logic.Data.NPCBattlefieldData` | dictId 0x8 / copyType 0xC / isFinalFleet 0x10 / partnerFormation 0x14 / partnerShips 0x18 / battleMilliseconds 0x1C / nightBattleMilliseconds 0x20 / longNightMilliseconds 0x24 / **battleCenterPosId 0x28** / **battleRadiu 0x2C** / **battlefieldInfoId 0x30** | 7054 |
| `Battle.Logic.Data.NPCFleetBase` | **battlefieldData 0xB0** | 7053 |
| `Battle.Logic.Data.Fleet` | birthPos 0x48 / **dictID 0x84** / sceneConfigPos 0xA4 | 7037 |
| `Battle.Logic.Data.LogicData_Map` | sceneDictId 0x8 / baseLength 0xC / baseWidth 0x10 / battlefieldMinPos 0x18 / battlefieldMaxPos 0x28 / **battleCenterPos 0x38** / **battleCircleRadiu 0x48** / **battlefieldInfoId 0x4C** / **dictBattlefieldInfo 0x50** | 7205 |
| `Dict.DataModel.DictFleet` | f_id 0x8 / copy_type 0xC / is_last_fleet 0x10 / birth_sp_id 0x14 / **battle_center_pos 0x18** / copy_attacheds_formation 0x2C / battle_time 0x30 / night_battle_time 0x34 / longNight_battle_time 0x38 / battle_radiu 0x3C / **battlefield_info 0xD8** | 8332 |
| `Dict.DataModel.DictBattlefieldInfo` | id 0x8 / **battlefield_shape 0xC** / **shape_param 0x10** / **player_position 0x14** / arr_player_fleet_position 0x18 / arr_enemy_position 0x1C / arr_assist_fleet_position 0x20 | 8282 |
| `Dict.DataModel.DictScenePosition` | sp_id 0x8 / position_id 0xC / name 0x10 / position_x 0x14 / position_y 0x18 / position_z 0x1C / eluer_y 0x20 | 8377 |

### 函数（RVA）
| 函数 | RVA | 说明 |
|---|---|---|
| `FleetInterface._InitNPCBattlefieldData` | 0x56CAC0 | DictFleet→NPCBattlefieldData 全字段复制（含 battlefield_info→0x30） |
| `FleetInterface.GenerateNPCFleetFromChapter` | 0x567AF0 | 调 _InitNPCBattlefieldData（0x567BAF） |
| `FleetInterface.GenerateNPCFleetFromEnemyData` | 0x567DF0 | 调 _InitNPCBattlefieldData（0x567EB0） |
| `FleetInterface.Fleet(long)` / `Convert2NPC` | 0x567360 / 0x565B70 | 取舰队 / 转 NPC |
| `FleetInterface.CanManual(long)` | 0x5657E0 | player_fleet_position 分支判定 |
| `FleetInterface.CenterPos` | 0x56F160 | NormalPos 用舰队中心 |
| `LogicAPI.InitBattleArea` | 0x156980（vtable Slot 12） | 读 master NPCBattlefieldData → SetBattleData |
| `LogicAPI.InitBattleFleetData` | 0x156A00 | GetEBPKit + Execute |
| `MapInfoInterface.SetBattleData` | 0x167E570 | 写 LogicData_Map（中心/半径/战场ID/加载 DictBattlefieldInfo） |
| `MapInfoInterface.GetBattleCenterPos` | 0x167E0B0 | 读 battleCenterPos（AI/边界系统大量调用） |
| `MapInfoInterface.GetBattlefieldInfoId` / `GetBattlefieldInfo` | 0x167E110 / 0x167E140 | 读 battlefieldInfoId / dictBattlefieldInfo |
| `ConfigInterface.DictPos` | 0x66C1C0 | sp_id→CVector2（config_scene_position） |
| `ConfigInterface.DictBattlefieldInfo` | 0x66C1A0 | id→DictBattlefieldInfo（jmp 0x5DABA0） |
| `ScenePositionBlo.GetScenePosition` | 0x11AAD30 | config_scene_position 查询 |
| `ScenePositionBlo.GetLogicPos` | 0x5EB190 | (position_x,position_z)×scale→CVector2；取 eluer_y 0x5EB160 |
| `FleetBlo.GetFleet(string)` | 0x5E3C70 | DictFleet 查询 |
| `DictBattlefieldInfoBlo.GetBattlefieldInfo` | 0xED1D30 | 战场配置查询 |
| `JoinBattleInterface.GetEBPKit` | 0x52B3C0 | **核心分支：battlefield_info→SceneConfigPos/NormalPos/GuardAttackPos/TeamAttackPos** |
| `JoinBattleInterface.GetJoinBattleFleetUidList` | 0x52B650 | 索敌遇敌舰队 UID |
| `NormalPos.Execute` | 0x15DB90 | -1 默认：按当前舰队中心落位 |
| `SceneConfigPos.Execute` | 0x15E750 | 非-1：读 masterData→DictBattlefieldInfo |
| `SceneConfigPos.InitFleetsWithBattleFieldInfo` | 0x15E8D0 | 逐舰队按 enemy/player/assist 数组落位 |
| `SceneConfigPos.InitFleetBattlePos(Fleet,string)` | 0x15E7D0 | sp_id→DictPos+eluer_y→InitFleetPos |
| `EBPKit.InitFleetPos` | 0x153140 | 写 FleetMoveData（pos/dir）+ 逐船阵型 |
| `StateBattleReady._CEnter / __EnterDay / __EnterBattleFromSearch` | 0x5101F0 / 0x510990 / 0x510670 | 索敌→战斗 FSM |
| `DataBattleInterface.GetMasterFleetUID` | 0x671730 | master（被决斗敌舰队）UID |
| `DataBattleInterface.SetMasterFleetUpAsEnemy` | 0x673560 | 按 battlefieldInfoId 分流敌我关系 |
| `FleetBattleProvingPosSystem.Begin / InitBattlefieldShape` | 0x6E1000 / 0x6E1990 | 战场形状（圆/矩/梯/扇/弧） |
| `FleetBattleProvingPosSystem.BattleCircleRangeTick` 等 | 0x6E06E0 等 | Tick 内把舰队限制在形状内 |
| `L2DEnterBattleLogicExe.OnStart/ClearSearchData` | 0x1672FC0 / 0x16723D0 | 显示侧进入战斗 + 建 BattleWarningModule |
| `BattleWarningModule.Load/Create/OutSidePos` | 0x183AF0 / 0x183870 / 0x183CB0 | 显示战场边界警告 |

### 配置表
- `config_fleet`：`battle_center_pos`(0x18) / `battle_radiu`(0x3C) / `battlefield_info`(0xD8)
- `config_battlefield_info`：id / battlefield_shape(1圆2矩3梯4扇5弧) / shape_param("2000"=圆半径) / player_position / player_fleet_position[] / enemy_position[] / assist_fleet_position[]
- `config_scene_position`：sp_id / position_id / name(场景id) / position_x / position_y / position_z / eluer_y

---

## 7. 根因与修复建议（供决策）

- **根因**：海域非 1-A 的 `config_fleet.battlefield_info`（1609/1613/1621）把**另一张地图（1600900/1610300/1620100）**的 `config_scene_position` 坐标引入当前海域场景（1600100），`SceneConfigPos` 把敌/玩家舰队硬挪到这些坐标 → 战场整体错位。
- **可能修复方向**（均未实施，仅列出）：
  1. 数据层：把海域舰队 `config_fleet.battlefield_info` 改为 `-1`（与 1-A 一致），或为海域场景补一份指向 `1600100` 场景的 `config_battlefield_info`（enemy/player_position 用海域场景的出生点，如 `Player_Birth16001000000`）。
  2. 客户端 patch：`JoinBattleInterface.GetEBPKit`（0x52B3C0）在 `copyType==SeaCopy` 时强制返回 `NormalPos`，绕过 SceneConfigPos。
  3. 若确需保留 `SceneConfigPos`，需让 `SetBattleData` 的 centerPos/positions 相对当前场景做坐标转换（当前代码无此逻辑）。
