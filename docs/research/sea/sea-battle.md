# 海域战斗（侦察/索敌3D）卡加载 调查记录

> 状态：**主要问题已解决（2026-08-23）**——海域侦察任务（copyId=1600100，"1A-侦察任务"）已能进入战斗（StageBegin + BattlePage 加载）。剩余小问题：**战斗限时立即耗尽**（见文末）。
>
> 海域关卡在 `config_copy_display` 中 `search_3d=1`（索敌3D），`copy_demo_id=1601`，`random_factor_sets=[61]`。海域索敌（SeaCopy，copyType=2）是**正常玩法**，不能绕开（绕开会失去索敌意义）。

---

## 1. 海域战斗流程（客户端完整链）

```
海域关卡点击 → copy.StartBase 请求（ChapterId=1001, CopyId=1600100）
  → 服务端响应 TStartBaseRet（CopyType=2, RandomFactors, ConfigData 等）
  → PrepareBattleMgr._CopyEnter → CreateDefaultBattleParam
  → StageMgr.Goto(eStageSimpleBattle) → StageEnterImpl
  → initBattle → getStartData（PVEStartData..ctor）
  → createBattleFrame → ChangeScene(scenes/sd_seascout_1_1)  ← 海域索敌场景
  → initBattleFrame → BattleFrame.Init
  → CoreLogic.ctor（0x354C30）→ _InitCoreAPI/_InitCoreSystem/_InitCoreLogic
  → CoreLogic.InitWithStartData（槽位73 = 0x300690, MutiTickLockStep）
  → ILogicAPI.InitWithStartData（0x4FBA20）
  → ILogicCoreCreator.InitWithStartData（槽位4）→ PveCoreCreator（0x5004C0）
  → _InitWithStartDataCore（0x500530）
       ├─ Fog.InitFogData（0x5254B0）
       ├─ InitResPoint（0x1696B50，资源点，遍历 copyRess）
       └─ IslandInterface.InitIslandData（0x52A170，岛屿）
  → BattleManager.InitBattle → Run → StageBegin → BattlePage 加载
```

### 关键数据链（索敌场景）

```
config_copy[1600100].scene_id="1600100"
  → DictSceneBlo.GetScene("1600100") → config_scene[1600100] {scene_res_name:"sd_seascout_1_1", island_ids:[]}
  → IslandGroupBlo.GetSceneAllIslandGroup(sceneId) → island_ids → config_island_group → config_island
```

- 海域索敌场景 `sd_seascout_1_1` 的 `island_ids=[]`（空，正常——海域索敌场景没有配置岛屿组）。
- 海域 `battlefield_resource` 无 copy_id=1600100 记录（资源点数据为空，官方同样）。

---

## 2. 服务端协议修复（`src/BlueOath.Server/Protocols/GameLoginMessageHandler.cs`）

### 2.1 新增 `copy.GetRandomFactors` 协议
- 海域关卡详情页请求随机因子（`copyservice.lua:SendGetRandomFactors` → `copy.GetRandomFactors`），服务端原无响应。
- `RandomFactorLoader`：`config_copy_display.random_factor_sets` → `config_random_factor_set.factor_groups` → `config_random_factor_group.factor`。
- 海域 1600100 → sets=[61] → factors=[61]。

### 2.2 StartBase 响应字段（EncodeStartBaseRet）
- **CopyType(7)**：海域=2（SeaCopy），剧情=1。
- **RandomFactors(12)**：海域下发 `{Factors:[1], GroupId:61, SetId:61}`。
- **IsRunningFight(10)/BattleMode(18)/MatchType(26)**：回环请求同名字段。
- **IsFinal(19)/AnimMode(20)/WeatherGroupId(21)**：海域补齐。
- **ConfigData(25)**：海域下发 `{Type:50000(ProData), Value:1}, {Type:52002, Value:1}, {Type:0(safeLv), Value:1}`。

### 2.3 ConfigData 的 protobuf-net 编码（关键坑）
- 客户端用 **protobuf-net** 反序列化（非标准 protobuf）。
- protobuf-net 输出：`CA 01 04 08 D0 86 03`（field25 len-delimited，内容**直接是字段**，**无子消息 tag 0x0A 包装**），Value=默认(0) 不序列化。
- 之前错误编码（0x0A 子消息包装 + Value=0）触发 `ProtoBuf.ProtoException`（getStartData 失败，mStartData=0）。

### 2.4 海域 arrRes 发空（关键修复）
- 海域 `arrRes(4)` 改为**空**（仅剧情发 `[{id:copyId}]`）。
- 原因：`InitResPoint` 遍历 `battleStartData.copyRess`（=arrRes），用元素 type 查 `battlefield_resource`。海域 `battlefield_resource[1600100]` 缺失 → GetDict null → 遍历卡死。arrRes 空 → copyRess 空 → InitResPoint 跳过。

---

## 3. 关键 RVA / 钩子信息

| 函数 | RVA | 说明 |
|---|---|---|
| CoreLogic.ctor | 0x354C30 | 战斗核心逻辑构造 |
| MutiTickLockStep.InitWithStartData | 0x300690 | 战斗核心初始化（CoreLogic 子类） |
| CoreLogic.InitWithStartData | 0x2FBE40 | 基类（调 ILogicAPI.InitWithStartData） |
| ILogicAPI.InitWithStartData | 0x4FBA20 | 调 ILogicCoreCreator slot4 |
| PveCoreCreator.InitWithStartData | 0x5004C0 | PVE 索敌核心入口 |
| PveCoreCreator._InitWithStartDataCore | 0x500530 | 索敌核心初始化（读 ConfigDatas[52002]/[safeLv]） |
| DataSearchInterface.Init | 0x675B20 | 索敌搜索接口初始化 |
| Fog.InitFogData | 0x5254B0 | 索敌迷雾 |
| InitResPoint | 0x1696B50 | 索敌资源点（遍历 copyRess → battlefield_resource） |
| IslandInterface.InitIslandData | 0x52A170 | 岛屿初始化（scene_id → island_ids → island_group → island） |
| BfTimeInterface.Init | 0x65F200 | 索敌时间初始化 |
| BfTimeInterface.__InitDayNightData | 0x65F770 | 索敌时间（battlefieldTime）初始化 |
| BattleTimeInterface.SetStageTime | 0x65ED60 | 战斗限时设置（battleMs/nightMs/longNightMs） |
| LogicAPI.InitBattleTimeData | 0x156C40 | 遍历舰队 UID → SetStageTime |
| StateBattleReady.__EnterBattleFromSearch | 0x510670 | 索敌→战斗转换 |
| MultiPveCoreCreator.__EnterBattleFromSearch | 0x4FFF70 | 海域 PVE 索敌→战斗 |
| GetJoinBattleFleetUidList | 0x52B650 | 加入战斗舰队 UID 列表 |
| 岛屿接口 IslandGroupBlo.GetSceneAllIslandGroup | 0x5E7DD0 | scene_id → config_island_group |

### 钩子安装经验（重要）
- **InstallReturnHook（hookFn 调 original）容易崩溃**：StageEnterImpl(0x1EA8C0)、BattleManager.InitBattle(0x299640)、0x2FBE40、BfTime.LastTime(0x65F370) 都崩过。改用 InstallStrArgHook（trampoline 记录进入）更安全。
- **InstallStrArgHook 的 stolenLen 必须覆盖完整指令**：IslandInterface.InitIslandData(0x52A170) prologue 是 `55 8B EC 83 EC 08 80 3D ...`（13 字节），stolenLen=9 会**截断 7 字节 cmp**（只复制前 4 字节），stub 执行 `cmp byte ptr [野地址],imm` → 0xC0000005。**必须 stolenLen=13**。
- 高频函数 hook（GetJoinBattleFleetUidList、StartLoad、config 查询 0x10956450）会导致崩溃/性能问题，避免 hook。

---

## 4. 索敌时间 / 战斗限时（剩余问题）

### 4.1 索敌限时体系（BfTime）
```
DictCopy.battle_time (config_copy, 180秒)
  → BfTimeInterface.Init → __InitDayNightData
  → LogicData_BfTime.battlefieldTime (LAttrInt, 毫秒) ← 索敌限时真实来源
  → ShareMemorySystem._TickInSearch → SetSearchTimeData
  → LogicShareMemory.searchLastTime → BattleTimeGroup.m_fSearchTime
```

### 4.2 战斗限时体系（BattleTime，剧情战斗正常）
```
[索敌遇敌] LogicFSMUnit.EnterBattleReady
  → StateBattleReady.__EnterBattleFromSearch (0x510670)
  → joinBattleAPI.GetJoinBattleFleetUidList() (0x52B650)
  → api.InitBattleTimeData(uids) (0x156C40)
  → FleetInterface.Fleet(uid) → Convert2NPC → NPCBattlefieldData
  → BattleTimeInterface.SetStageTime(battleMs, nightMs, longNightMs) (0x65ED60)
  → LogicData_BattleTime.battleTimeMax (0x8)
```

### 4.3 海域战斗限时立即耗尽的根因
- **海域 SetStageTime(0x65ED60) 未调用**（hook 确认 0 次）。
- explore 分析：SetStageTime 未调用 → `LogicData_BattleTime.battleTimeMax` 保持 0 → `battleTime(LAttrCDMS)` max=0 → `IsTimeOver()` 恒真 → 战斗限时立即归零。
- 根因候选（按 explore 推断）：
  1. **GetJoinBattleFleetUidList() 返回空列表 / null** → InitBattleTimeData 在循环前早退 → SetStageTime 永不执行。
  2. Fleet/Convert2NPC 查不到对象（循环内每项 null）。
  3. 海域 FSM 未走到 StateBattleReady 战斗转换（战斗未走到 __EnterBattleFromSearch 路径）。
- **待验证**：`EnterBattleFromSearch.StateBattleReady`（0x510670）海域是否调用（单个安全 hook 已准备，因多 hook 崩溃未完成验证）。

### 4.4 排查建议
1. hook `EnterBattleFromSearch.StateBattleReady`（0x510670，InstallStrArgHook，stolenLen=10）确认海域索敌→战斗转换是否触发。
2. 若触发但 SetStageTime 未调用 → hook `GetJoinBattleFleetUidList`（0x52B650）确认舰队 UID 列表是否为空。
3. 若 joinBattleUidList 空 → 海域索敌遇敌的舰队加入逻辑（客户端 joinBattleAPI）未正确执行，可能需服务端 StartBase 提供舰队 UID / 索敌遇敌数据。
4. 也可检查 `config_fleet[160010000]`（海域敌舰队）的 `battle_time`（NPCBattlefieldData 来源）。

---

## 5. 诊断钩子清单（当前 hooks_debug.cpp 状态）

### 保留（安全 InstallStrArgHook）
- LoadingTick（0x1EF290，含 startData 字段 dump：copyType/copyDictId/battleMode/animMode/weather/enemyFleetId/allFactors/configDatas/enemys/copyRess）
- BattleFrameBase.Init（0x308EF0）、BFInner（CoreLogic.ctor 0x354C30 内部）、CLInit（_InitCore*）
- PveCore（0x5004C0/0x500530）、IslandInterface（0x52A170，stolen=13）
- Fog（0x5254B0）、InitResPoint（0x1696B50）、BfTime（0x65F200/0x65F770）
- BattleTime.SetStageTime（0x65ED60）
- BattleManager.Ctor/InitBattle/Run
- VEH：0xE06D7363/0xC0000005/0x4001000A 打印 CXXSTACK

### 已回退（导致崩溃）
- StageEnterImpl（0x1EA8C0，InstallReturnHook）
- InitWithStartData/LogicCore/2FBE40 系列（InstallReturnHook 或干扰）
- SearchToBattle（0x510670/0x4FFF70/0x52B650，多 hook 崩）
- BfTime.LastTime（0x65F370，InstallReturnHook 高频）
- GetQucikConditions/config 查询（0x10956450，高频）

---

## 6. 遗留临时改动
- `config_island_group.db` 插入了 `2000122`（`ig_id:2000122, island_array:[200012200], points:["Island_Side200012200"], name:"2000122"`），备份在 `config_island_group.db.bak-2000122`。**海域 island_ids 空，此补丁实际未生效**（岛屿初始化未读它），可考虑回滚。
- 海域索敌场景 `island_ids=[]`、`battlefield_resource` 空、`config_island[200012200]` 缺失——均为官方同样状态，非卡点。
