# 海域索敌→战斗（决斗）过渡：PlayerAutoKit / Autopilot / 移动速度清理逻辑调查

> 状态：**资料收集完成（2026-08-27）**。纯逆向研究+记录，未改动任何代码。
> 目标：查清海域（copyType=2，日服简化）索敌出生 → 自动寻敌（<1s）→ 遇敌 → 进入决斗后，
> **玩家舰队持续向固定方向移动、不自动攻击、手动操作无效** 的机制：移动/巡航/PlayerAutoKit
> 索敌状态在过渡时"被清（还是没被清）"、清在哪一环、谁有条件才清。
>
> 方法：il2cppdump（RVA = VA-0x10000000）+ capstone（GameAssembly.dll）。所有 RVA 均为 dump 地址。

---

## 0. 结论一句话

**"索敌→战斗"过渡（`StateBattleReady.__EnterBattleFromSearch` 0x510670）本身完全不清理自动巡航（Autopilot）与 PlayerAutoKit 索敌状态，也不停止舰队的既有航速/航向**；速度侧只做"换挡"（SetSpeed2Battle / ResetAllFleetRealSpeed），不停止运动。
真正的清理只有两条外部链路，都依赖"战斗状态机/网络消息"先正确推进：
1. **`PlayerAutoSearch.Leave`（0x62DDF0）** 停 `StopAutopilotPath` —— 只在 PlayerAutoSystem 收到 `BATTLE(4)` 标记并 `ChangeState(Battle)` 时才触发；
2. **`PlayerAutoSwitch(fleet,false)`（0x56ACE0）** 停 `StopAutopilotOrder`+`StopAutopilotPath` —— 只在 `D2LStartLogicAction.Excute`（0x317750）随"战斗开始逻辑"消息调用时才触发（日志 `auto 1 False` 即此）。

海域若任一环没到达（见 §5/§7），PlayerAutoSystem 一直以 `PlayerAutoSearch` 态运行，每帧 `__Autopilot` 会**重新注册巡航 order** 朝敌方目标直行 → 观感"固定方向移动"；手动 op 被搜索态巡航覆盖 → "操作无效"。**协议（服务端）无法直接控制该清理，只能通过 master 舰队锚点/SkipVcr/数据正确性间接影响**。

---

## 1. 关键机制背景：Logger '+' 系统标记（SystemWorkFlag）如何驱动"索敌/战斗"行为

所有"索敌/战斗"行为由 **LogicFSMUnit（状态机）+ LogicSystem（系统调度）** 按 `SysWorkFlag` 控制。

| 常量 | 值 | 说明 |
|---|---|---|
| `SysWorkFlag.SEARCH` | 2 | 索敌阶段（大地图/巡航/寻敌） |
| `SysWorkFlag.BATTLE` | 4 | 战斗阶段 |
| `SysWorkFlag.BATTLE_READY` | 32 | 索敌→战斗过渡（Ready） |
| `SysWorkFlag.LOADING` | 8 | 读盘 |
| `SysWorkFlag.RESULT` | 16 | 结算 |

调度链（全部为逻辑层，显示层另有驱动）：
- `LogicFSMUnit.Goto(state,enterParam,allowSame)`（0x4FD990）→ 取新状态的 `get_systemWorkFlag()` → `LogicSystem.ChangeWorkFlag(flag,allowSame)`（0x626640，调用点 0x4FDA62）。
- `LogicSystem.ChangeWorkFlag`（0x626640）→ 遍历 `__systemList` → `SystemBase.PrepareBegin(flag)`（0x591EC0）。
- `SystemBase.PrepareBegin`（0x591EC0）：`if (this.WorkFlag & flag) != 0` 才调 `vtable.Begin(flag)`。Tick 同理（0x591EF0，`(WorkFlag&flag)!=0` 才 `vtable.Tick`）。

各相关系统的 WorkFlag：
- `PlayerAutoSystem._WorkFlag` = **6**（SEARCH|BATTLE，0x167A00 `mov eax,6`）→ 索敌和战斗都会驱动；
- `FleetAutopilotSystem._WorkFlag` = **2**（仅 SEARCH，0x16DFA0 `mov eax,2`）→ 战斗态**不**驱动巡航系统本身；
- `StateSearch.get_systemWorkFlag`=2（0x16DFA0）、`StateBattleReady`=32（0x5116F0）、`StateBattle`=4（0x16E4B0）。

> 推论：只要 FSM 真正进入 `StateBattle`（flag=4），`PlayerAutoSystem.Begin(4)` 就必然被调用；若被"卡"在 Ready(32)/UIWait 等中间态（flag 不含 4），则 kit 仍保持 Search 态运行（或冻结），运动状态另由移动系统残留速度维持（见 §4）。

---

## 2. 索敌→战斗过渡的完整调用链（RVA 级）

### 2.1 `LogicFSMUnit.EnterBattleReady(weather)`（0x4FD6F0）→ `StateBattleReady._CEnter`（0x5101F0）

遇敌进入 Ready 的方式：
- D2L action（0x315E60，opcode `0x15F98`）：`[msg+0x10]==0 ? FSM.EnterResult : FSM.EnterBattleReady(weather)`——即"开战消息"携带判别位；
- 显示层 `BattleLogic.Run()`（0x3C0A50/0x3C00F0 等）按演出/时间线推进时也会调。

`StateBattleReady._CEnter`（0x5101F0，Slot 8）：
| RVA | 调用 | 作用 |
|---|---|---|
| 0x510230 | `LogicAPI.EnterBattle()`（0x10156630） | 置 `InBattle` 标记（逻辑层进入战斗） |
| 0x51026C–0x5102AD | `0x10986CA0(enterParam)` 转天气枚举 → switch{1:__EnterNight 0x5110D0, 2:__EnterLongNight 0x510BE0, 3:__EnterNextDay 0x510DA0, 其余:__EnterDay 0x510990} | 按昼夜分支 |
| 0x5102BE | `__EventSkill(4, weather)`（0x511280） | 技能/事件 |
| 0x51031D–0x51036A | `0x106711E0(battleAPI)` 取舰队列表 → 循环 `fleetMoveAPI.SetSpeed2Battle(fleet)`（0x10571560） | ★ 全体舰队速度切"战斗挡" |
| 0x5103BE+ | 事件（EventFire 等） | — |

### 2.2 `__EnterDay`（0x510990）—— 白天进战斗

| RVA | 调用 | 作用 |
|---|---|---|
| 0x51099B | **`__EnterBattleFromSearch`（0x510670）** | 索敌→战斗主流程（下一节） |
| 0x5109C3 | `objAPI.CleanAllValidObjExAttr(6)`（0x10528BA0） | 清对象"有效扩展属性"型=6 |
| 0x5109E5 | api vtable slot 79（0x13C）`Invoke(api, 1)` | 核心层某个 Init（候选：SetBattleTimeOfWeather 等，见 §8 局限） |
| 0x510A16 | `battleTimeAPI.?`（0x1065EC80，flag=1） | 战斗时间接口 |
| 0x510A41 | `battleAPI.?`（0x10673230，flag=1） | 战斗数据接口 |
| 0x510A6A | `exportStatisticAPI.?`（0x10560080） | 统计 |
| 0x510A93 | `buffAPI.?`（0x1065FE80） | Buffer |
| 0x510ABC | `flagAPI.?`（0x10564280） | Flag |
| 0x510AD4–0x510AF5 | 读 `LogicData.data_battle.nvnMode`（= [LogicData+0x54]+**0x24**） | ★ 分支 |
| nvnMode==0 | **`__SendEnterBattle()`（0x5114F0）** → `LogicNetAPI.SendEnterBattle(masterUid, prank)`（0x10159BB0） | 普通战斗网络发送 |
| nvnMode!=0 | `battleAPI.GetMasterFleetUID`（0x10671730）+`0x10411830`+`LogicNetAPI.SendEnterNvNBattle`（0x10159C60） | NvN 战斗发送 |

`LogicData_Battle`（TypeDefIndex 6594）：`nvnMode@0x24`、`isSearch@0x25`、`autoBattle@0x26`。
海域/剧情均 nvnMode=0（NvN 由战斗类型本地派生，服务端无直接字段）。

### 2.3 `__EnterBattleFromSearch`（0x510670）—— 核心主流程

逐条（括号内为接口对象偏移，基于 LogicAPI 字段布局）：

| RVA | 调用（用途） | 移动/巡航/PlayerAutoKit 相关性 |
|---|---|---|
| 0x51069B | `0x104FDE80(this,0)` 取 LogicAPI | — |
| 0x5106B9 | exportStatisticAPI(0xDC).?（0x1055FFA0） | 无关 |
| 0x5106E1 | objAPI(0x1C).`CleanAllValidObjExAttr(3)`（0x10528BA0） | 无关（清属性） |
| 0x51070B | joinBattleAPI(0xB0).**`GetJoinBattleFleetUidList()`**（0x1052B650）→ uids | **若返回空 → 后续全部落空**（海域"SetStageTime 未调用"根因之一，见 §7） |
| 0x510736 | bfTimeAPI(0xA8).?（0x1065F5E0） | 索敌时间接口 |
| 0x51075D | objAPI(0x1C).**`EnterBattle(uids)`**（0x10528C80） | IObj 进入战斗 |
| 0x510787 | api **vtable slot 73(0x124)** `Invoke(api,uids)` | 核心层战斗初始化（多态分发） |
| 0x5107A0 | **`LogicAPI.InitBattleFleetData(uids)`**（0x10156A00） | ★ 落位+速度（§3） |
| 0x5107C9 | battleAPI(0xB4).?（0x106705D0） | 战斗数据 |
| 0x5107D2 | `__UpdateShipEnterBattleHpState(uids)`（0x511550） | 血量状态 |
| 0x5107EE | `LogicAPI.FullShipTorpedoNum(uids)`（0x101567B0） | 鱼雷回满 |
| 0x510818 | api **vtable slot 77(0x134)** `Invoke(api,uids)` | 核心层后续 |
| 0x510830 | `LogicAPI.DestroySearchPlaneData()`（0x10156360） | 清索敌侦察机数据 |
| **0x510859** | **fleetMoveAPI(0x8C).`ResetAllFleetRealSpeed()`（0x10571080）** | ★★ 唯一"速度"动作：按 speedFac 重算 currSpeed，**不停止方向/不停止航行** |
| 0x510882 | pskillAPI(0xC4).?（0x11682A70） | 技能 |
| 0x5108A8 / 0x5108CF / 0x5108F5 | countAPI(0x54).?（0x1066D860 / 0x1066CFF0(uids) / 0x1066EB70） | 统计 |
| 0x510916 | threatAPI(0xFC).?（0x1040FC20） | 威胁值 |
| 0x51091F | `__CopyAirCtrlState(uids)`（0x510410） | 空优制 |
| 0x510945 | triggerAPI(0xD4).?（0x10410AF0, 2,0,0） | 触发器 |
| 0x51096B | 收尾事件（0x10132230, 4 …） | — |

> **关键观察 A：整段 0x510670 没有出现 `autopilotAPI(+0x38)`、`PlayerAutoSystem`、`PlayerAutoKit`、`PlayerAutoSearch`、`FleetAutopilot*`、`0x62F*`、`0x65E*` 的任何调用。** 索敌→战斗过渡本身不清理 PlayerAutoKit / Autopilot。

---

## 3. 落位 + 速度链：`LogicAPI.InitBattleFleetData`（0x156A00）与 `EBPKit.InitFleetPos`（0x153140）

| RVA | 调用 | 作用 |
|---|---|---|
| 0x156A3A | `fleetAPI.GetFleetsByFleetUid(uids)`（0x105671E0）→ fleetList | |
| 0x156A62 | `data_battle.battlePlayerList = fleetList` | 记录参战玩家舰队 |
| 0x156AB4 | 每舰队 `fleetMoveAPI.UnlockTurning(fleet)`（0x10572000） | 解锁转向锁定 |
| 0x156AD0 | 每舰队 `fleetMoveAPI.SetInitiativeTurning(fleet,0,0)`（0x10571520×3参） | 置主动转向=0 |
| 0x156AEA / 0x156B04 | `fleetAPI.?`（0x10565A20 / 0x10564A10） | 舰队接口 |
| 0x156B33 | `battleAPI.GetMasterFleetUID()`（0x10671730） | ★ master=被决斗敌舰队 |
| 0x156B48 | `0x10525BA0`（grade→ master uid 相关） | |
| 0x156B62 | **`joinBattleAPI.GetEBPKit(fleetList)`（0x1052B3C0）** | ★★ 按 master 的 `NPCBattlefieldData.battlefieldInfoId(→DictFleet.battlefield_info@0xD8)` 分支 |
| 0x156B84 | `kit->Execute(fleetList)`（vtable 0xE4/0xE8） | **落位执行** |
| 0x156B9B | `battleAPI.?`（0x10672950） | 敌我关系 |
| 0x156BD9 | 循环 `fleetMoveAPI.ResetFormPos(fleet)`（0x105712A0） | 阵型归位 |
| **0x156BF1** | 循环 **`fleetMoveAPI.SetSpeed2Battle(fleet)`（0x10571560）** | ★ 战斗速度挡 |
| 0x156C0B / 0x156C21 | `countAPI.?`（0x1066D620）/ `cutinAPI.?`（0x1066F550） | 统计/演出 |

`GetEBPKit`（0x52B3C0，已由《battlefield_info机制.md》确认）：
- `masterData.battlefield_info != -1` → **SceneConfigPos**（0x15E750，硬挪到别图坐标）；
- `== -1` → TeamAttackPos（0x163F90）/ GuardAttackPos（0x153710）/ **NormalPos（0x15DB90，默认）**。

`NormalPos.Execute`/`SceneConfigPos.Execute` 内部最终都走 `EBPKit.InitFleetPos(fleet,dir,pos)`（0x153140）：
- `fleetMoveAPI.UnlockTurning`（0x10572000）
- `fleetMoveAPI.SetInitiativeTurning(fleet,0,0)`（0x10571520）
- 写 `FleetMoveData.pos/dir`（`MapInfoInterface.GetBattleCenterPos` 相关，0x103F4960/0x103F49B0）

> **关键观察 B：落位只写 pos/dir、解锁转向、置主动转向=0，不把 currSpeed 清零，不停止"正在航行"状态。** `SetSpeed2Battle`（0x571560）逐船把目标速度因子切到战斗值；`ResetAllFleetRealSpeed`（0x571080）把 currSpeed 重算到 speedFac 对应值——两者都"换速"不"刹车"。

---

## 4. PlayerAutoSystem / PlayerAutoKit / PlayerAutoSearch / 巡航：谁在跑、谁该停

### 4.1 `PlayerAutoSystem.Begin`（0x62F250，Slot 8）—— working 与状态决定点

1. 循环全部 autoKits：`working(+0x24)=0`（复位）；
2. 对每支玩家舰队：找/建 `PlayerAutoKit`（ctor 0x62DB70，末尾 `working=0`）；
3. **无条件 `mov byte ptr [eax+0x24],1`（working=1）** @0x62F464；
4. `workFlag.IsType(SEARCH=2)` → `kit.ChangeState(Search=2)`；否则 `workFlag.IsType(BATTLE=4)` → `kit.ChangeState(Battle=1)`；两者都不是 → **不发 ChangeState（working 仍=1）**。

要素速查：
- `PlayerAutoKit.ChangeState`（0x62DB10）→ 虚调 FSM（触发旧态 Leave/新态 Enter）。
- `PlayerAutoKit.Tick`（0x62DB50）：`working!=0` 才 `jmp 0x105755b0`（FSM tick）。
- `PlayerAutoKit.Stop`（0x62DB40）：`working=0`；`Wort`（0x1DA2B0）：`working=1`（全镜像无直接调用点，疑似历史遗留）。

### 4.2 `PlayerAutoSearch`（索敌态，海域出生即激活）

- `Enter`（0x62DC00）：`__RefreshAIData`(0x62E900) → **`__StopAutopilot`(0x62F070)** → autoCyrcle=0 → 关/开寻敌标记。
- `Tick`（0x62DE80）：`__CheckValidEnemyFleet`(0x62E7E0) → `__CheckStopAutopilot`(0x62E780，内含 __StopAutopilot@0x62E7BD) → **`__Autopilot`(0x62E4D0)** → `__SkillTick`(0x62E970)。
- `__Autopilot`（0x62E4D0）：查 `HadAutopilotOrder`（0x1065E7D0），累计 autoCyrcle，取舰队中心（0x1056F160），遍历 `__validEnemyFleet` 找目标。
- `_BeginAutopilot(target,delta)`（0x62E280）：取 center → **navmesh 寻路 `0x11680B80`** → 存 `__enemyTarget(+0x68)` → **`autopilotAPI.RegistAutopilotOrder(fleet,target,path)`**（0x1065E8B0 系）。
- `Leave`（0x62DDF0）：base Leave（0x10132920）→ **`0x11681000`(navAPI，丢弃寻路)** → **`autopilotAPI.StopAutopilotPath(fleet)`（0x1065E940）** ← 离开索敌态的巡航清理。

> 巡航数据实体：`LogicData.data_autopilot(+0x8C)` → `FleetAutopilot(+0x8)`：`searchOrders@0x10 / searchPaths@0x18`。`FleetAutopilotSystem._WorkFlag=2`（仅索敌 tick，0x6DE970 消费 orders）。

### 4.3 `PlayerAutoBattle`（战斗态）

- `Enter`（0x62D460）：`__RefreshAllAIData`(0x62D7A0) + `AutoMoveKit` 初始化（0x1061E520…）+ `AutoSkillKit` CD 复位 + `AutoChangeTargetKit` 复位。**无速度停止**。
- `Tick`（0x62D5C0）：`__RefreshAIData`(0x62D710) → `MoveTick`→`AutoMoveKit.Tick`(0x61E110) → `SkillTick`→`AutoSkillKit.Tick`(0x61F2B0)。

### 4.4 谁真正调用了 Autopilot 停止接口（全调用点）

| 目标 | 调用点（函数≈） | 触发条件 |
|---|---|---|
| `StopAutopilotOrder`（0x65E900） | 0x56AE3A（≈0x56ACE0） | `PlayerAutoSwitch(uid,false)` 分支 |
| `StopAutopilotPath`（0x65E940） | 0x56AE62（≈0x56ACE0）；0x62DE63（≈PlayerAutoSearch.Leave 0x62DDF0） | 同上 / kit 离开 Search 态 |
| `__StopAutopilot`（0x62F070） | 0x62DC33（≈PlayerAutoSearch.Enter）、0x62E02B（≈PlayerAutoSearch.Tick）、0x62E7BD（≈__CheckStopAutopilot） | 索敌态自己管理（不是清理而是途中停） |
| `ResetAllFleetRealSpeed`（0x571080） | 0x510859（≈0x510670 ★）、0x500162（≈0x4FFF70）、0x4FED72、0x514579 | `__EnterBattleFromSearch`（StateBattleReady / PveCreator 两条） / 其它 |
| `SetSpeed2Battle`（0x571560） | 0x51036A（≈_CEnter）、0x156BF1（≈InitBattleFleetData）、0x4FF479、0x4FE176、0x4111D7 | 进战斗换战斗档 |
| `ResetAllPlayerFleet2SearchPatrol`（0x5711D0） | 0x514550（≈StateSearch.__EnterFromBattle 0x514420） | 离开战斗回索敌时才用 |

> **核心事实：`__EnterBattleFromSearch`（0x510670）里"移动清理"只有 `ResetAllFleetRealSpeed`（0x510859，换速不刹车），没有任何 Autopilot/PlayerAutoKit 停止调用。**

---

## 5. "固定方向移动"残留的确切机制

### 5.1 机制链（海域独有）

1. 海域出生（copyType=2，索敌 3D）→ `PlayerAutoSystem.Begin(SEARCH=2)` → 玩家 kit `working=1`、`ChangeState(Search)`；
2. `PlayerAutoSearch` 自动寻敌 <1s → `__Autopilot`/`_BeginAutopilot` 用 navmesh **注册 FOLLOW_TARGET_* 巡航 order**（`FleetAutopilot.searchOrders`），舰队按 order 直行；
3. 遇敌 → `StateBattleReady._CEnter`（0x5101F0）→ `__EnterDay`（0x510990）→ `__EnterBattleFromSearch`（0x510670）：
   - **不**调 StopAutopilotOrder/StopAutopilotPath，**不**调 PlayerAutoKit.*；
   - 只做 position/阵型/speedFac 切换（§2.3、§3）——`FleetMoveData.currSpeed(+0x58)` 与航向未被清零；
   - 之后再由 D2LStartLogicAction（0x317750）发 `auto 1 False`（`PlayerAutoSwitch(false)`，0x56AD8F 打印点），清掉 order/path 记账——**但同样不清 FleetMoveData 速度/方向**；
4. 若 FSM 未真正进入 `StateBattle`（flag=4，例如 Battle_Ready=32 卡住/战斗时间 0 立即 end/演出未跳完），`PlayerAutoSystem.Begin(4)` 不会发生 → kit **停留在 Search 态且 working=1** → 只要 Search 相关系统还在被调度，`PlayerAutoSearch.Tick → __Autopilot` 每帧**重新注册 order** 朝目标直行 ⇒ 观感"固定方向移动、不攻击、操作无效"。

### 5.2 为什么"操作无效"

- 手动移 op 走 `D2LChangePlayerAction.Excute`（0x3149D0，内部也调 `PlayerAutoSwitch(fleet,false)`→0x56ACE0，0x56AE60 分支 StopAutopilotOrder/Path + SetInitiativeTurning(0,0)），但由于 kit 仍在 Search 态且 working=1，`PlayerAutoSearch.Tick→__Autopilot` 下一帧又注册新 order → 玩家指令被搜索态自动导航覆盖；
- 战斗态未真正建立 ⇒ 战斗操作 UI/StageBegin/BattleTime 未就绪（并与《海域战斗.md》的 SetStageTime 未调用同源）。

### 5.3 源头定位汇总

| 源头 | 位置 |
|---|---|
| 索敌巡航注册 | PlayerAutoSearch._BeginAutopilot 0x62E280（navmesh 0x11680B80 + RegistAutopilotOrder 0x1065E8B0） |
| 过渡"该清却没清" | StateBattleReady.__EnterBattleFromSearch 0x510670（无 autopilot/kit 清理） |
| 过渡已做（不够） | ResetAllFleetRealSpeed 0x510859；SetSpeed2Battle 0x156BF1 / 0x51036A；落位 EBPKit.InitFleetPos 0x153140（只写 pos/dir） |
| 真正能停巡航的条件链 | ① PlayerAutoSystem.Begin(BATTLE)→ChangeState(Battle)：需 FSM 到 Battle 态（flag=4）；② PlayerAutoSwitch(false)：需 D2LStartLogic 消息 |

---

## 6. 剧情关 vs 海域关：清理路径差异

| 维度 | 剧情（copyType=1） | 海域（copyType=2） |
|---|---|---|
| 进入方式 | 每次"重新 StartBase → 新战斗帧" | 索敌→战斗过渡（EnterBattleFromSearch，不重新 StartBase） |
| 索敌阶段 | 无 3D 索敌/无自动寻敌（PlayerAutoSearch 不激活） | 出生即索敌，PlayerAutoSearch 激活、巡航已注册 |
| 战斗初始化 | 干净状态（新 kit/新数据）；`InitBattleFleetData` 正常 | 继承 Search 残留；`__EnterBattleFromSearch` 无巡航/kit 清理 |
| 巡航残留 | **无**（从未启动） | **有**（order 已注册，过渡不清） |
| 战斗时间 | SetStageTime 正常（NPCBattlefieldData 齐全） | SetStageTime 未调用（GetJoinBattleFleetUidList 或 InitBattleTimeData 链路空）→ 限时立即归零 |
| 结果 | 正常（可 AI/手动切换） | moving 残留 + 无法操作 |

> 差异根因：**剧情没有"索敌自动巡航"的既有状态，所以不需要清理；海域有，而过渡函数没有承担清理职责，只能依赖 PlayerAutoSwitch(false)/PlayerAutoSearch.Leave 两条"战斗已正常启动"后才执行的链路。**

---

## 7. 服务端协议字段相关性（EncodeStartBaseRet）

清理本身 100% 在客户端本地 FSM/系统/网络消息链内，**没有一个服务端字段直接触发"停巡航/清 PlayerAutoKit"**。可影响的范围如下：

| 字段（wire） | 现值 | 是否/如何影响移动清理 |
|---|---|---|
| EnemiesFleets(24).FleetId = **160010000（锚点）** | 已实施 | → master DictFleet.battlefield_info=-1 → GetEBPKit=NormalPos → 舰队留原地 + InitFleetPos 写 pos/dir；仍发真实 fid（160090000/161010000/162010000）→ SceneConfigPos 硬挪 → 战场漂移（已另档）。**间接影响运动状态，但不等同于清理** |
| SkipVcr(17) StartVcr/EndVcr=true | 已实施 | 跳进场/沉没演出 → 显示层时间线更易推进到 EnterBattle（flag=4）→ 间接保证 PlayerAutoSearch.Leave/PlayerAutoSwitch 被触发。若 couldSkip* 因 si_id 缺失为 false（见 §8-3），演出等待可能卡住过渡 |
| IsRunningFight(10)/BattleMode(18)/MatchType(26)/AnimMode(20)/IsFinal(19)/WeatherGroupId(22) | 回环/0 | 仅按分支进入不同流程；不直接控制清理 |
| copyType(7)=2 | 已实施 | 决定"索敌玩法"分支（Pve/Sea） |
| ConfigData(25) (50000,1),(0,1) | 已实施 | `_InitWithStartDataCore` 配置项；50000/0 走 safeLv；**勿发 52002**（会覆盖索敌限时→立即结束→连锁卡战斗） |
| EnemyFleet(5)/EnemyFleets 内容 | 已实施 | 决定敌舰队满足度/自动目标，间接影响搜索目标合法性 |

> **结论（服务端口径）**：服务端**无法**直接"绕过/触发移动清理"。能做的只是让客户端走 NormalPos（锚点）并尽量让显示层时间线完整推进（SkipVcr 正确、数据不缺失），从而让系统标记切到 `BATTLE(4)`、让 D2LStartLogic 正常到达。海域"固定方向移动"如需根治，应在客户端侧处理（§9）。

---

## 8. 补充：SkipVcr / couldSkip 链路（背景条目核对）

- `SkipVcr`（乙级：TCopySkipVcr/TSkipVcr，proto field 17/2/3）：TStartBaseRet.skipVcr → `LogicData_Search? ``couldSkipAnim`（0x5C, 行 326560）→ 显示层 `ShipDataComponent.SetData`（0x258600）逐船用 `si_id` → `couldSkipEnterBattleAnim(+0xD0)/couldSkipComboDeadAnim(+0xD1)`（0x317214 附近）。
- 服务端已把**敌舰的 `config_ship_enemy.ship_info_id`** 下发（仅玩家船 si_id 对敌舰落空），并置 `StartVcr/EndVcr=true`——这是正确方向（进入`__EnterBattleFromSearch` 的演出等待会拖住显示层 timeline）。
- 背景所述"`shipInfoModelData = GetShipInfo(ship.dictId=TemplateId)` 为 null → couldSkip* = false"属于显示层模型元数据缺失的次生风险：若命中，进入战斗 VCR 不跳过 → 演出等待 → 与 §5 的"显示层不推进→系统标记不切 BATTLE"叠加。

---

## 9. 修复候选（仅供决策，未实施）

1. 客户端在 `__EnterBattleFromSearch`（0x510670，或 `PveCoreCreator.__EnterBattleFromSearch` 0x4FFF70）增加：遍历 uids → `autopilotAPI.StopAutopilotOrder/StopAutopilotPath` + `fleetMoveAPI.SetSpeedReal(fleet, 0)`（或 `ResetFormPos` + 清 FleetMoveData 速度）。
2. 确保海域战斗 FSM 必达 `StateBattle`：检查 `InitBattleTimeData`（vtable slot 14，间接调用）为何未达（`GetJoinBattleFleetUidList` 空 / `NPCBattlefieldData` 缺失）——这同时修复"限时立即耗尽"。
3. 兜底：`PveCoreCreator.InitBattleFleetData`（0x4FF280）或 `PlayerAutoSystem.Begin`（0x62F250）在 `data_battle.autoBattle==0` 时若 kit 仍为 Search 态则强制 `ChangeState(Battle)` 或 `Stop()`。

---

## 10. 关键 RVA 表

| 函数/接口 | RVA |
|---|---|
| LogicFSMUnit.Goto / EnterSearch / EnterBattleReady / EnterBattle / EnterBattleUIWait / EnterResult | 0x4FD990 / 0x4FD960 / 0x4FD6F0 / 0x4FD8B0 / 0x4FD850 / 0x4FD910 |
| LogicSystem.ChangeWorkFlag | 0x626640 |
| SystemBase.PrepareBegin / Tick（`(WorkFlag&flag)!=0` 才派发） | 0x591EC0 / 0x591EF0 |
| SysWorkFlag 枚举（SEARCH=2/BATTLE=4/READY=32） | dump TypeDefIndex 7591 |
| **StateBattleReady._CEnter** | **0x5101F0** |
| **StateBattleReady.__EnterDay** | **0x510990** |
| **StateBattleReady.__EnterBattleFromSearch** | **0x510670** |
| StateBattleReady.__SendEnterBattle / __ResetBattleFleetSpeed / __UpdateShipEnterBattleHpState / __EventSkill | 0x5114F0 / 0x511430（无调用点）/ 0x511550 / 0x511280 |
| StateBattleReady.__CopyAirCtrlState | 0x510410 |
| StateBattleReady.__EnterNight / __EnterLongNight / __EnterNextDay | 0x5110D0 / 0x510BE0 / 0x510DA0 |
| **LogicAPI.InitBattleFleetData**（落位+速度） | **0x156A00** |
| LogicAPI.DestroySearchPlaneData / FullShipTorpedoNum / EnterBattle | 0x10156360 / 0x101567B0 / 0x10156630 |
| LogicNetAPI.SendEnterBattle / SendEnterNvNBattle / SendPlayerAutoSwitch | 0x10159BB0 / 0x10159C60 / 0x1015B500 |
| joinBattleAPI.GetEBPKit / GetJoinBattleFleetUidList | 0x52B3C0 / 0x52B650 |
| NormalPos.Execute / SceneConfigPos.Execute / EBPKit.InitFleetPos | 0x15DB90 / 0x15E750 / 0x153140 |
| fleetMoveAPI.SetSpeed2Battle / ResetAllFleetRealSpeed / ResetAllPlayerFleet2SearchPatrol / ResetFormPos / UnlockTurning / SetInitiativeTurning | 0x571560 / 0x571080 / 0x5711D0 / 0x5712A0 / 0x572000 / 0x571520 |
| StateSearch.__EnterFromBattle（回索敌换挡） | 0x514420 |
| AutopilotInterface.StopAutopilotOrder / StopAutopilotPath / RegistAutopilotOrder | 0x65E900 / 0x65E940 / 0x65E860/0x65E810/0x65E8B0 |
| FleetAutopilotSystem（_WorkFlag=2 / Tick） | 0x16DFA0 / 0x6DE970 |
| FleetAutopilot.StopOrder / StopPath | 0x5E3960 / 0x5E3A50 |
| **PlayerAutoSystem（_WorkFlag=6 / Init / Begin / Tick）** | 0x167A00 / 0x62F4D0 / **0x62F250** / 0x62F650 |
| PlayerAutoKit ctor / ChangeState / Stop / Wort / Tick | 0x62DB70 / 0x62DB10 / 0x62DB40 / 0x1DA2B0 / 0x62DB50 |
| PlayerAutoSearch Enter / Tick / __Autopilot / _BeginAutopilot / __StopAutopilot / __CheckStopAutopilot / __EndAutopilotByNavMesh / Leave / __SkillTick | 0x62DC00 / 0x62DE80 / 0x62E4D0 / 0x62E280 / 0x62F070 / 0x62E780 / 0x62E8B0 / 0x62DDF0 / 0x62E970 |
| PlayerAutoBattle Enter / Tick / MoveTick / SkillTick / __RefreshAllAIData | 0x62D460 / 0x62D5C0 / 0x62D550 / 0x62D580 / 0x62D7A0 |
| AutoMoveKit.Tick / AutoSkillKit.Tick | 0x61E110 / 0x61F2B0 |
| **PlayerInterface.PlayerAutoSwitch（`auto {0} {1}` 打印点 0x56AD8F）** | **0x56ACE0** |
| D2LStartLogicAction.Excute / D2LPlayerAutoSwitchAction.Excute / D2LChangePlayerAction.Excute | 0x317750 / 0x316050 / 0x3149D0 |
| PveCoreCreator / MultiPveClinetCoreCreator（__EnterBattleFromSearch / InitBattleFleetData / InitBattleState / _PlayAuto） | 0x4FFF70 / 0x4FF280 / 0x4FF4C0 / 0x4FEB40；0x4FEB80 / 0x4FDF80 / 0x4FE1B0 |
| LogicData.data_battle(+0x54) / LogicData_Battle{nvnMode 0x24,autoBattle 0x26} | dump TypeDefIndex 6603 / 6594 |
| LogicData.data_autopilot(+0x8C) / FleetAutopilot{searchOrders 0x10, searchPaths 0x18} | dump TypeDefIndex 6835 / 6831 |

---

## 11. 遗留确认项（信息不全处）

1. api **vtable slot 73/77/79（偏移 0x124/0x134/0x13C）**的实际方法未 100% 落定（候选 `InitBattleArea`/`InitBattleTimeData`/`SetBattleTimeOfWeather` 等，slot 号与 dump 中该类内 Slot 编号需运行时 vtable 对齐）。不影响结论：均非移动/巡航清理。
2. `__ResetBattleFleetSpeed`（0x511430）无直接调用点，可能仅供间接/历史使用。
3. `PlayerAutoKit.Wort`（0x1DA2B0）全镜像无直接调用点，working=1 的实际写入已确认来自 `PlayerAutoSystem.Begin`（0x62F464）。
4. 海域实际是"卡在 Battle_Ready(32)"还是"进入了 Battle 但时间 0 立即退"需运行期 hook 区分（`LogicFSMUnit.Goto` 0x4FD990 或 `LogicSystem.ChangeWorkFlag` 0x626640 打点）。

> 结论可靠度：过渡不含任何 Autopilot/PlayerAutoKit 清理 = **确证**（完整反汇编无 0x38/0x62F*/0x65E* 调用）；"固定方向移动"的更精确运行时成因（search 态残留 vs 速度残留）需按 §11-4 运行时钩子二次确认。