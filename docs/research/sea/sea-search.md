# 海域索敌（SeaCopy）机制调查记录

> 状态：**资料收集完成（2026-08-24）**。本文档由 3 个 sub-agent 深度逆向调查汇总，作为海域索敌大地图"无迷雾 + 敌舰队全部出现在玩家面前 + 决斗距离异常"问题的完整资料库，避免后续重复读汇编。
>
> 海域索敌玩法：进入后是 3D 大地图，敌舰队以 Search3DModel 形式分布，战争迷雾覆盖，我方舰队移动，接触敌舰队触发决斗。海域关卡 `copyType=2`（SeaCopy）。

---

## 1. 敌舰队位置决定逻辑（关键）

### 1.1 调用链

```
服务端 copy.StartBase → TStartBaseRet.field5 EnemyFleet=[...舰队dictID]
  → PlayerInterface.InitNpc(BattleStartData)  RVA 0x168ADB0
      （海域实际用这条；InitNpc(int[]) 0x168ABF0 仅 Multi-Pve 用）
  → FleetInterface.GenerateNPCFleetFromChapter   RVA 0x567AF0
      ├─ _InitNPCBattlefieldData  0x56CAC0  (battle_center_pos → 仅供进战斗用)
      ├─ __InitPlayerBaseInfo     0x56E620
      ├─ _InitShipList            0x56D170
      ├─ _InitFleetMoveData(fleet, birthPosId) ★位置★ 0x56C710
      └─ _InitNPCRoteData(fleet)  ★巡逻★    0x56CCE0
  → FleetInterface.AddFleet        0x564750
  → InitNpcAttacheds(master, copy_attacheds, formation)  0x168A8C0
  → __CreateNPCThreatData          0x168CB90
```

### 1.2 ★ 位置核心 `FleetInterface._InitFleetMoveData(Fleet, string birthPosId)` RVA 0x56C710
- `birthPosId = DictFleet.birth_sp_id`（FleetInitData(DictFleet) 0x1B7860 从 DictFleet+0x14 取）。
- `Fleet.pos = ConfigInterface.DictPos(birthPosId)`（0x66C1C0）：`ConfigAPI.GetConfig(BL_PVEWorldScale=128)=2.75` → `ScenePositionBlo.GetLogicPos`（0x5EB190）→ `config_scene_position` 表 `DictScenePosition`（sp_id/position_id/position_x/position_z/eluer_y），坐标 ×2.75。
- **无随机、无散布、无服务端覆盖。位置 = config_scene_position 出生点。**

### 1.3 ★ 巡逻 `FleetInterface._InitNPCRoteData(NPCFleet)` RVA 0x56CCE0
- `routePosList = FleetPatrolPosBlo.GetPatrolPosList(battlefieldData.dictId)`（0x5E4740，内部 DictFleetPatrolPosBlo 0xE07AB0）→ 遍历 sp_id → DictPos → routePosList。
- 表：`config_fleet_patrol_pos.db`（f_id→sp_id[]，1312 行）、`config_fleet_patrol_route.db`（fpr_id/f_id/sp_id/order，3245 行）。
- **海域（f_id 16x）舰队在 patrol_pos/route 均无记录** → routePosList 空 → 敌舰静止在出生点（不巡逻移动）。

### 1.4 海域敌舰出生点实测（config_scene_position）
| 海域 | 玩家出生 (x,z) | 敌舰队 f_id | Enemy_Birth* (x,z) | 距离(逻辑) | ×2.75 |
|---|---|---|---|---|---|
| 1-A 1600100 | `Player_Birth1600100` (113,85) | 160010000 | `Enemy_Birth1600100` (63,85) | **50** | 137 |
| 2-A 1600600 | ( -727,-1181) | 160060000 | (126,75) | 1610 | 4427 |
| 3-A 1610300 | (97,65) | 161030002 | (126,70) | **≈30** | 83 |
| 对照组 1000100 区 | (13,114) | — | 散布 (159,222)(182,36)(310,189)(345,70)(446,186) | 100–450+ | — |

> 注意：海域 1-A/3-A 的 Enemy_Birth* 被配在玩家出生点旁（30–50 逻辑单位），对照组 1000100 区散布 100–450 单位。这是 **config_scene_position 表数据**。

### 1.5 Search3DModel（大地图敌怪外观）
- 类：`Search3DModel`(5814)/`Search3DModelImp`(5815)/`Search3DConfigData`(5813)，挂在 ViewFleet 上（`ViewLogicObject.search3DModel@0xA0`），位置随舰队。
- 创建：`ViewFleet.InitFleetData` 0x266AC0 → `Search3DModel.GetComponent` 0x255020；`ViewFleet.InitSearch3DModel` 0x266E90 → `config_fleet.search3d_item_id` → `Search3DConfigData.SetFromDict` 0x253EF0。
- 显示：`Search3DModelImp.TickHideShow` 0x254CA0：距离 < `config_search3d_item.display_distence`(2000) 显示，受迷雾 isOutFog 影响。
- 海域 BOSS 外观：`config_search3d_item[7].item_ui_root='item_search3d_enemyboss'`。

---

## 2. 战争迷雾（Fog）机制

### 2.1 逻辑侧初始化
```
PveCoreCreator._InitWithStartDataCore(0x500530) @0x500929
  → FogInterface.InitFogData(DictCopy)  0x5254B0
      length = DictCopy.copy_scene_length(0x30), width = copy_scene_width(0x34)
      → __InitFogData(length, width)     0x525770
          mapFogOpen = ConfigBase.GetConfig(BL_MapFogSwitch=205)>0   → config=1 → 开启
          logicViewDelta = BattlefieldInfo.MapFogView() (208=140/209=120)
          fogScale = 0.5
          FogBaseData(w=round(length*0.5*WorldScale), h=...)   → 初始全部不透明(有雾)
```
- 运行期：`FogSystem.Init/Tick`（0x625410/0x625500）以玩家舰队为中心 `FogSetTransparent`（0x525040/0x525180）挖雾，半径：`BL_SearchFleetViewRadius=126(80)`、`Delta=127(10)`、AttackPlaneViewRadius=19、SearchPlaneViewRadius=18。
- 逻辑→显示：`FogInterface.Convert`（0x524DA0）→ `L2DLogicResumOver.fogInfo@0x48` → `BattleDisplay.InitCopyData`（0x17AA70）**无条件**写 `logicFogW@0x20/logicFogH@0x24/logicFogData@0x1c`。

### 2.2 ★ 显示侧开关（根因）
```
SearchOpeGroup.InitKitCtrl  0x1A84B0
  isFogHide = (DictCopy.map_fog_hide(0x68) > 0)    ← config_copy.map_fog_hide
  → MapFogCtrl4.Init(root, isFogHide)              0x3989A0
      → FogBaseData(w,h,isFogHide) 0x392FB0：isFogHide==true → SetArrayTransparent(全透明)
      → FogRtKit.Init(w,h,isFogHide) 0x37F670：isFogHide→清屏无雾色
      → _ResumeFog(isFogHide) 0x399450：isFogHide!=0 → 直接 return（跳过迷雾恢复）
```
- **`config_copy.map_fog_hide` 海域关卡全部=1**（1401 副本中 418 个=1，海域是其中一片）→ `isFogHide=true` → 迷雾被显示侧主动关闭 → **无迷雾**。
- 若 map_fog_hide=0：`BL_MapFogSwitch=1` + logicFogData 已就位 → 直接出雾。
- 每帧：`SearchOpeGroup.TickFog`(0x1AA3D0) → `MapFogCtrl4.ApplyFog`(0x398560) → `FogRtKit.ExecuteGraphics`(0x37F440, Blit 画 `_FogMask`) → 全屏雾效（`share/shader/fogofwar`，bundle 存在加载正常）。

### 2.3 场景资源
- 所有场景 bundle（sd_seascout_*、sd_newscene、sd_lighttower*、sd_001 等）**都没有迷雾网格/迷雾对象**——战争迷雾 100% 由代码运行时生成（FogRtKit + shader + RenderTexture + `SearchRightMap.__FogRT`）。场景里的 "Fog" 字符串是 uSky/TOD 天气雾效，与战争迷雾无关。

---

## 3. 海域索敌完整初始化链路（PveCoreCreator._InitWithStartDataCore 0x500530）

| 偏移 | 调用 | API | 说明 |
|---|---|---|---|
| 0x5005F9 | 0x11697F90 | rootAPI+0x14 | 根接口初始化 |
| 0x500610 | 0x1052BBF0 | logicResume+0x64 | 逻辑恢复 |
| 0x50062F | 0x116952E0 | randomFactor+0xEC | 随机因子 allFactors=[61] |
| 0x50063A | 0x10156FB0 | LogicAPI | SetCopyType(=2) |
| 0x500656 | 0x1040F7E0 | support+0xC0 | 支援舰队 |
| 0x500774 | 0x103640A0 | obj+0x1C | 随机种子 |
| 0x500780 | 0x105DEC50 | — | **查 config_copy（copyDictId=startData+0xC）→ DictCopy** |
| 0x50078E | 0x1095B750 | — | 查 config_copy_display → DictCopyDisplay |
| 0x5007D4 | 0x1168A870 | player+0x84 | InitGod |
| 0x5007F9 | vtable[0xE4] | player+0x84 | **InitPlayer(startData, DictCopy, Display)** |
| 0x500815 | 0x1168ADB0 | player+0x84 | **InitNpc(BattleStartData)** ← startData.enemys(=字段24) |
| 0x500855 | **0x10675B20** | search+0xA4 | **DataSearchInterface.Init(DictCopy)** |
| 0x5008FB | 0x10675BD0 | search+0xA4 | SetSafeLevel(startData.safeLv) |
| 0x500912 | 0x1167E200 | map+0x68 | 地图接口 |
| 0x500929 | 0x105254B0 | fog+0x74 | **Fog.InitFogData(DictCopy)** |
| 0x500941 | 0x11696B50 | resPoint+0x70 | InitResPoint（海域 arrRes 空→跳过） |
| 0x500958 | 0x1052A170 | island+0x6C | IslandInterface.InitIslandData |
| 0x500972 | 0x11680F50 | nav+0xF4 | 导航网格 |
| 0x5009C6 | 0x104122C0 | weather+0x7C | 天气（dictCopy.weather_group 为空） |
| 0x5009E7 | 0x1167EB30 | mission+0x80 | 任务 + weatherGroupId |
| 0x5009FF | 0x10410810 | threat+0xFC | 威胁值 |

**DataSearchInterface.Init（0x675B20）**：存 `data_search.copyId=dictCopy.r_id、copyDisplayId=copy_id、teamAttackNum=dictCopy.team_attack_num`。`EnterSearch`=0x675A50、`SetSafeLevel`=0x675BD0、`isSupportTeamAttack`(teamAttackNum>1)=0x675C00。**服务端无需额外字段**（Rid/SafeLv 已正确）。

**注意**：`PVEStartData.ctor`(0x58E780) **不填充 enemyFleetId(+0x94)**；海域敌舰队来自 `startData.enemys`（字段24 EnemyFleets），非 InitNpc(int[])。LoadingTick 钩子读到的 `sd_enemyFleetId0=0` 是正常（不消费）。

---

## 4. 网络协议（海域索敌）

- **海域索敌只有 1 个协议**：`copy.StartBase`（TStartBaseArg → TStartBaseRet）。从响应到大地图显示全本地初始化，无后续网络请求。
- 入场前海域页面：`copyinfo.GetCopyInfo`、`copy.GetRandomFactors`（服务端均已实现）。
- cacheId 本地生成（`config_battle_config[285]=1`），不走 `cachedata.CacheData`。

### 4.1 服务端已知 bug
| # | 位置 | 问题 | 影响 |
|---|---|---|---|
| S1 | `GameLoginSession.cs:248-263` | `copy.StartBase` 收到后在正常响应外**再发一个 IsResponse:0 的重复 StartBase 推送**（EncodeStartBaseRetDirect，英雄顺序与请求不同） | 客户端收到两次 StartBase；第二次因事件已注销被静默丢弃。**冗余无害，建议删除** |
| S2 | `EncodeStartBaseRet` Game.cs:1134-1137 | `WeatherGroupId` 写字段 **21**(0xA8)，客户端 pb 期望字段 **22**(0xB0) | 客户端 WeatherGroupId 恒=0。**潜伏 bug，海域配天气组时需改** |

### 4.2 `no method:` 警告（良性）
- lua `socket_net.lua:132` `OnReceived`：收到响应方法名无 handler 时告警。
- 实际方法名为**空串**：C# 网络层把 TCP 残留/截断的 **5 字节碎片包**（HEAD_LEN=5）也分派给 Lua，方法名解析失败为空 → 告警。**与海域索敌 bug 无关，全程无害**。

---

## 5. 根因汇总（海域索敌无迷雾 + 敌舰在面前）

| # | 根因 | 证据 | 层面 |
|---|---|---|---|
| 1 | **`config_copy.map_fog_hide=1`** → 显示侧 `isFogHide=true` → `_ResumeFog` 直接 return，迷雾被主动关闭 | 反汇编 0x1A84B0/0x392FB0/0x399450；海域全=1 | 客户端配置数据 |
| 2 | **`config_scene_position` 海域 `Enemy_Birth*` 出生点在玩家旁**（30–50 逻辑单位，×2.75≈83–137 世界单位），对照组散布 100–450 单位 | 表实测 | 客户端配置数据 |
| 3 | **海域舰队无 `config_fleet_patrol_pos/route` 记录** → `_InitNPCRoteData` 空 → 敌舰不巡逻不移动 | 表扫描 16x 全空；日志 GetJsonDataGroup config_fleet_patrol_pos 返回空 | 客户端配置数据 |
| 4 | `config_scene.island_ids=[]` → 岛屿不生成 → `NavMesh Vertices NUM==6`（仅默认平面） | 日志；config_scene 表 | 客户端配置数据 |
| 5 | `config_copy.weather_group=[]` + S2(WeatherGroupId 字段号错) | config 表 + 服务端代码 | 客户端数据+服务端 bug |
| 6 | `config_battlefield_resource` 无海域行 | config 表 | 客户端配置数据 |

> **核心洞察**：迷雾管线完整且正常（`BL_MapFogSwitch=1`、logicFogData 已就位），唯独显示侧被 `map_fog_hide=1` 按关卡关闭。若海域索敌应有雾，需使 `isFogHide=false`（map_fog_hide 判断覆盖），雾立即可见；而敌舰即使出生点近，也会被战争迷雾遮蔽（1-A 敌舰 137 世界单位 > 视野 80），接近才显现——**迷雾修复是核心**。

---

## 6. 关键 RVA 地址表

| 函数 | RVA |
|---|---|
| PlayerInterface.InitNpc(BattleStartData) | 0x168ADB0 |
| PlayerInterface.InitNpc(int[]) | 0x168ABF0 |
| PlayerInterface.InitPlayer | 0x168BB60 |
| FleetInterface.GenerateNPCFleetFromChapter | 0x567AF0 |
| **FleetInterface._InitFleetMoveData（位置）** | **0x56C710** |
| **FleetInterface._InitNPCRoteData（巡逻）** | **0x56CCE0** |
| FleetInterface._InitNPCBattlefieldData | 0x56CAC0 |
| FleetInterface.AddFleet | 0x564750 |
| **ConfigInterface.DictPos（出生点→坐标）** | **0x66C1C0** |
| **ScenePositionBlo.GetLogicPos** | **0x5EB190** |
| FleetPatrolPosBlo.GetPatrolPosList | 0x5E4740 |
| DictFleetPatrolPosBlo.GetPatrolPosList | 0xE07AB0 |
| FleetBlo.GetFleet | 0x5E3C70 |
| PveCoreCreator.InitWithStartData | 0x5004C0 |
| **PveCoreCreator._InitWithStartDataCore** | **0x500530** |
| DataSearchInterface.Init / EnterSearch / SetSafeLevel | 0x675B20 / 0x675A50 / 0x675BD0 |
| **FogInterface.InitFogData / __InitFogData** | **0x5254B0 / 0x525770** |
| FogInterface.Convert / FogSetTransparent | 0x524DA0 / 0x525040 |
| FogSystem.Init / Tick | 0x625410 / 0x625500 |
| BattleDisplay.InitCopyData | 0x17AA70 |
| **SearchOpeGroup.InitKitCtrl（isFogHide=map_fog_hide>0）** | **0x1A84B0** |
| **MapFogCtrl4.Init / _ResumeFog / ApplyFog** | **0x3989A0 / 0x399450 / 0x398560** |
| FogBaseData..ctor(w,h,isFogHide) / SetArrayTransparent | 0x392FB0 / 0x3921D0 |
| FogRtKit.Init / ExecuteGraphics | 0x37F670 / 0x37F440 |
| ViewFleet.InitFleetData / InitSearch3DModel | 0x266AC0 / 0x266E90 |
| Search3DModelImp.TickHideShow | 0x254CA0 |
| IslandInterface.InitIslandData | 0x52A170 |
| InitResPoint | 0x1696B50 |
| PVEStartData.ctor(TStartBaseRet) | 0x58E780 |
| ConfigAPI.GetConfig | 0x3F12D0 |

**关键配置表**：`config_scene_position`（出生点，关键）、`config_copy`（map_fog_hide@0x68/copy_scene_length@0x30/copy_scene_width@0x34/weather_group）、`config_fleet`（birth_sp_id/search3d_item_id）、`config_fleet_patrol_pos` / `config_fleet_patrol_route`（海域空）、`config_battle_config`（205=BL_MapFogSwitch/126=BL_SearchFleetViewRadius=80/128=BL_PVEWorldScale=2.75）、`config_search3d_item`（7=BOSS 外观）、`config_scene`（island_ids）、`config_battlefield_info`（enemy_position/player_position，决斗战斗位置）。

---

## 7. 待决策方案（见对话后续）
- 迷雾：海域索敌强制 `isFogHide=false`（客户端 patch 0x1A84B0/0x399450 之一，或 map_fog_hide 判断覆盖）。
- 敌舰分散：给海域舰队补 patrol（客户端 patch 或数据），或依赖迷雾遮蔽（出生点虽近但被雾遮）。
- 服务端：删 S1 重复推送、修 S2 WeatherGroupId 字段 21→22。
- 岛屿/NavMesh：确认海域大地图是否需要岛屿（海域或为纯海面，island_ids=[] 可能正常）。
