# 自律/自动战斗（AutoBattle）完整机制调查记录

> 调查对象：blueoath（苍蓝誓约，il2cpp v24 / Unity 2019 系，Windows x86）
> GameAssembly RVA = 地址 - 0x10000000；dump `il2cppdump/dump.cs` TypeDefIndex 索引
> 状态：资料收集完成（2026-08-26）。海域索敌决斗 `auto  1 False` 日志已被正确定位与解释。

---

## 1. AutoBattle 相关类/接口/函数清单（dump.cs 定位）

### 1.1 逻辑层（`Battle.Logic.*`，AI 实际接管舰队的部分）

| 类 | TypeDefIndex | 关键字段(偏移) | 关键方法 RVA | 作用 |
|---|---|---|---|---|
| `Battle.Logic.System.ALL::PlayerAutoSystem` | 6810 | kidDict@0x20, autoKits@0x24 | ctor 0x62F6E0 / **Init 0x62F4D0** / **Tick 0x62F650** | 自动战斗总调度：Init 时为每支舰队建 PlayerAutoKit；Tick 每帧驱动所有 kit |
| `Battle.Logic.System.Kits.PlayerAuto::PlayerAutoKit` | 6807 | api@0x18, net@0x1C, fleet@0x20, **working@0x24** | ctor 0x62DB70 / Wort 0x1DA2B0 / Stop 0x62DB40 / ChangeState 0x62DB10 / Tick 0x62DB50 | 单舰队自动 FSM 机；`working=1` 才驱动（状态机 Battle/Search 二态） |
| `Battle.Logic.System.Kits.PlayerAuto::PlayerAutoState` | 6809 | ctrl@0x18 | ctor 0x62F200 | 基类 |
| `...::PlayerAutoSearch` | 6808 | stopAutopilot@0x1C, waitFatigue@0x1D, searchSpeed@0x20, autoCyrcle@0x60, skillOpen@0x64, enemyTarget@0x68 | Enter 0x62DC00 / **Tick 0x62DE80** / __Autopilot 0x62E4D0 / _BeginAutopilot 0x62E280 / __StopAutopilot 0x62F070 / __CheckStopAutopilot 0x62E780 / __EndAutopilotByNavMesh 0x62E8B0 / __SkillTick 0x62E970 | 索敌（海域大地图）自动：寻敌/索敌、自动接敌、自动索敌技能、导航网格刹车 |
| `...::PlayerAutoBattle` | 6805 | battleSkillBeginCD@0x20, **autoMoveKit@0x40, autoSkillKit@0x44, autoChangeTargetKit@0x48**, torpedoDazeCD@0x50 | Enter 0x62D460 / Tick 0x62D5C0 / MoveTick 0x62D550 / SkillTick 0x62D580 / __RefreshAIData 0x62D710 / __RefreshAllAIData 0x62D7A0 / __TorpedoDazeCD 0x62D810 | 战斗自动：回合走位 + 技能自动释放 |
| `AutoMoveKit` | 6801 | moveRange@0xC, battleSpeedFac@0x10, rangeRandom@0x20, 距离分级 _sqrMoveRangeDis* | ctor 0x61ECC0 / **Tick 0x61E110** / RefreshMoveRange 0x61DA60 / TickAvoidTorpedo 0x61DF00 | 自动**移动/走位**（按 config_fleet_auto 权重选交战距离，含鱼雷规避） |
| `AutoSkillKit` | 6803 | mainVice/torpedo/air/additional/dive 权重 | ctor 0x61F7F0 / **Tick 0x61F2B0** / __RefreshSkillRandomKit 0x61F5E0 | 自动**技能释放**（权重随机选 ActionSkillType，受 CD、天气、装备限制） |
| `AutoChangeTargetKit` | 6800 | enemy@0x14, __TargetCD@0x18 | Tick 0x61CD80 / __TickEnemy 0x61CDC0 | 自动换目标 |
| `AutoAvoidTorpedoKit` | 6799 | totalAvoidTime@0x8 … | Tick 0x61C460 / __GetTurnType 0x61C7F0 | 自动鱼雷规避 |
| `Battle.Logic.API.Sub::AutopilotInterface` | 6830 | | 见 dump | 巡航指令（点击式自动导航）RegistAutopilotOrder / StopAutopilotOrder / HadAutopilotOrder |
| `FleetAutopilot / FleetAutopilotOrder` | 6831/6832 | | | 索敌自动巡航订单队列 |
| `Battle.Logic.API.Sub::PlayerInterface` | | **PlayerAutoSwitch(long,bool) 0x56ACE0** | | **核心开关 API（见 §2）** |
| `Battle.Communication::Fleet` | 6339 | **autoBattle@0x78** | | 通信层舰队 auto 标志 |
| `Battle.Logic.Data::LogicData_Battle` | 6594 | **autoBattle@0x26** | | 战斗逻辑级总开关（PlayerAutoSwitch 写它） |
| `Battle.Logic.Data::BattleFleetData` | 7036 | **autoBattle@0x88** | | 逻辑层单舰队 auto 标志 |
| `Battle.Logic.System.Kits::_PlayAuto` | | 0x4FEB40 | | 自动播放工具 |
| `EnumPlayerAutoState` | 6806 | Battle=1, Search=2 | | 状态枚举 |
| `Battle.Logic.Net.Actions::D2LPlayerAutoSwitchAction` | 7516 | | **Excute 0x316050** | D2L 网络操作→PlayerAutoSwitch |
| `Battle.Logic.Net.Actions::D2LStartLogicAction` | 7528 | | **Excute 0x317750** | 战斗开始消息→按 autoBattle 调 PlayerAutoSwitch |
| `Battle.Logic.Net.Actions::D2LChangePlayerAction` | 7501 | | Excute 0x3149D0 | 换玩家→PlayerAutoSwitch |
| `Battle.Communication::D2LStartLogic` | 6376 | **autoBattle@0x8** | | display→logic 开始消息携带 auto 标志 |

### 1.2 表现层 / UI（`Battle.Display` / `BabelTime.GD.UI`）

| 类 | TypeDefIndex | 方法 RVA | 作用 |
|---|---|---|---|
| `Battle.Display::BattleDisplay` | 5752 | **isAutoBattle 0x17EE20 / SetAutoBattle 0x17C6D0** | 表现层 auto 开关（内部调 BattleUITool） |
| `BabelTime.GD.UI::ViewFleet` | 6237 | SetAutoBattle 0x269820 | 舰队视觉 auto 状态（hadOpenedAutoBattleByCopy/Fleet @0x139/0x13A） |
| `BabelTime.GD::BattleUITool` | 11494 | GetAutoBattle 0x341210 / SetAutoBattle 0x342530 | 全局（静态）auto 状态变量 |
| `BattleUISub::AutoBattleGroup` | 10756 | CFirstOpen 0x1D4930 / CReOpen 0x1D4B60 / **CheckShowAutoFun 0x1D4C90** / OnNotification 0x1D4E00 / OnClickAutoBattleMask 0x1D4D40 / Tick 0x1D5020 | 战斗中自律按钮组；决定显隐、转发点击、处理 SwitchAutoBattle 事件 |
| `BattleUISub::AutoBattleCtrl` | 10665 | Init 0x2AC250 / **EnableAuto 0x2AC180** / SetAutoUI 0x2AC680 / SetOtherOpeAutoUI 0x2AC6F0 / Show 0x276BE0 / Hide 0x2AC220 / OnNotification 0x2AC360 / **OnPointerClick 0x2AC3B0** | 自律按钮控件（点击→表示层） |
| `AutoBattleHelper` | 5985 | ctor 0x1777D0 | 挂载标注 |
| `BattleAutoPlay : GuideBehaviourInstrumentBase` | 10254 | | 引导用的自动播放（跳过动画） |
| `AutoQABattle / AutoQAUtil / AutoRotationHelper / AutoPressBtnHelper` | 5987/5988/5990/5986 | | QA/桌面自动点击、镜头自动旋转等（与玩家自律无关） |

### 1.3 xlua 绑定
- `_m_SetAutoBattle_xlua_st_` RVA 0xEF1460、`_m_GetAutoBattle_xlua_st_` RVA 0xEEEC00（lua 可调），对应 `BattleUITool.SetAutoBattle/GetAutoBattle`。
- Lua 侧 `DisplayLuaUtil`（`lua_tools/BlueoathLuaJP/game/battle/display/displayluautil.lua`）是与 C# 同名桥：`OnAutoBattleClick / CheckAutoBattle / IsAutoBattleEnabled / CheckDoubleSpeed / CheckTripleSpeed`。

---

## 2. `auto  1 False` 日志：来源与含义（已铁证定位）

### 2.1 格式串
- 字符串字面量 **`"auto  {0} {1}"`**，存在于 global-metadata.dat，literal **索引 6743**，数据偏移 0x43892。
- 字面量 cache 槽地址 = **VA 0x11D25168**（BASE 0x11D1E80C + 6743*4，slot RVA 0x1D25168，位于 .data）。
- 全镜像只有 1 个真实引用点（`push dword ptr [0x11d25168]` at **RVA 0x56AD8F**）。

### 2.2 打印函数
`Battle.Logic.API.Sub::PlayerInterface.PlayerAutoSwitch(long fleetUID, bool auto)` — **RVA 0x56ACE0**（函数范围 0x56ACE0–0x56B024）。

反汇编关键段（0x56AD4A–0x56ADAB）：
```
56AD35  lea eax,[ebp-0x10]; push eax
56AD39  push [0x11d13144]            ; (MethodInfo of Long/Int64 box?)
56AD45  call 0x11642b50              ; box → [ebp-8]  = 装箱 fleetUID
56AD50  mov al,[ebp+0x14]            ; auto 参数(boolean)
56AD53  lea eax,[ebp-1]; push eax
56AD57  push [0x11d12ad0]
56AD5D  call 0x11642b50              ; box → eax     = 装箱 auto
56AD8F  push [0x11d25168]            ; "auto  {0} {1}"
56AD97  call 0x10EB16E0              ; String::Format(string, object, object)
56AD9F  test esi,esi; je +done       ; esi = 0x10378bf0() 结果（Battle.Config.EnvConfig 相关开关）
56ADAB  call 0x1036c7c0              ; 日志（最终落到 Debug.LogError(object) 0xE515F0，
                                      ;   被 payload 捕获打印 Unity.LogError: ...）
```
格式化结果即 `"auto  {fleetUID}  {auto}"`，日志行为 `Logger/EnvConfig` 条件化（`esi` 守卫，0x10378bf0 = Battle.Config.Manager.EnvConfig 某开关）。

### 2.3 观测值解读
`auto  1 False` = **`PlayerAutoSwitch(fleetUID=1, auto=false)`**。
- `{0} = 1`：装箱的 fleetUID（玩家舰队 UID = 1，本地服首个舰队）。
- `{1} = False`：要切换到的 auto 状态 = 关。
- 海域决斗（3-A 1620100）日志紧随其后出现 `StateBattleReady`，因为 `D2LStartLogicAction.Excute`(0x317750)/`D2LPlayerAutoSwitchAction.Excute`(0x316050) 在战斗开始/切换时调用 `PlayerAutoSwitch`，随后进入战斗 Ready 状态。

**结论：`auto  1 False` 是每次海域决斗进场时"关闭/维持关闭玩家 auto"的正常调试日志，不是报错。**

### 2.4 同函数后续动作（auto 应用链）
`PlayerAutoSwitch` 内：
- 0x56ADD7 `mov [obj+0x26], cl` → 写 `LogicData_Battle.autoBattle`（@0x26）。
- auto==false 分支（0x56AE60）：关爱舰队 `BattleFleetData.autoBattle=0`（0x56AE82 `mov [eax+0x88],0`）等。
- auto==true 分支（0x56AF70）：置 1、调 `0x1015b500`（开自动）/`0x1066d510`。

---

## 3. autobattle 配置字段消费链（字段→函数→效果）

### 3.1 `config_copy_display` 字段在 `DictCopyDisplay`（TypeDefIndex 8313）中的偏移
- `auto_continuation` @ 0xC4
- `autobattle_time` @ 0xC8
- `autobattle_isshow` @ 0xF8
- `autobattle_gamelimit`（ArrayData）@ 0xFC（JArray arr_autobattle_gamelimit）
- `autobattle_opendesc` @ 0x100
- `ban_autobattle` @ 0x16C
- （`autobattle_open`：JSON 里有该键，但 **DictCopyDisplay 无对应 C# 字段**，客户端反序列化时被丢弃——海域值为 0，无关）

### 3.2 消费链

**① 按钮显隐（战斗页）**
`AutoBattleGroup.CFirstOpen`(0x1D4930)
  → 取 `BattleDisplay` 的 displayCopyId（0x1017e7f0→[+0xc]）
  → `DisplayLuaUtil.IsAutoBattleEnabled(copyDisplayId)`（C# RVA **0x135680** / lua `return copyDisplay.autobattle_isshow == 1`）
  → `enableShowAuto = 结果`（存 AutoBattleGroup@0x5C）
  → `AutoBattleCtrl.Show`(0x276BE0) / `Hide`(0x2AC220)
  → ReOpen(0x1D4B60)/`OnNotification` 时以 @0x5C 维持。

**② 点击（开/关自律）**
`AutoBattleCtrl.OnPointerClick`(0x2AC3B0)
  → `EnableAuto(bool)`(0x2AC180)
  → `SetAutoUI`(0x2AC680) 切图标 + `SetOtherOpeAutoUI`(0x2AC6F0)
  → `BattleDisplay.SetAutoBattle`(0x17C6D0)
  → 全局 `BattleUITool.SetAutoBattle`(0x10342530) + `ViewFleet.SetAutoBattle`(0x10269820)（改舰队视觉）
  → 发 UIEvent `SwitchAutoBattle = 200065(0x30D81)`（0x1027a7e0 带 0x30d81）。
※ `BattleDisplay.isAutoBattle()`(0x17EE20) 只是读回 `BattleUITool.GetAutoBattle`(0x341210)。

**③ 逻辑侧真正落开关**
display 层把状态经操作 op 送到逻辑层：
`D2LPlayerAutoSwitchAction.Excute`(0x316050) ／ `D2LStartLogicAction.Excute`(0x317750)
  → `PlayerInterface.PlayerAutoSwitch(fleetUID, auto)`(0x56ACE0)
  → 打印 `auto  {fleetUID} {auto}`、写 `LogicData_Battle.autoBattle`、逐舰队 `BattleFleetData.autoBattle`，
    并驱动 `PlayerAutoKit`（Wort 开启 working=1 / Stop 关闭 working=0），由 `PlayerAutoSystem.Tick`(0x62F650) 每帧驱动。

**④ 点击前置校验（lua `displayluautil.lua`，决定能否开）**
`OnAutoBattleClick(copyId)`
  → `config_copy → config_copy_display`（copy.copy_id）
  → `CheckFuncOpen(FunctionID.AutoFIght)`（模块是否开放）
  → `CheckAutoBattle`：`moduleManager:CheckFunc(FunctionID.AutoFIght,false)` + 遍历 `autobattle_gamelimit` 检查 `gameLimitLogic.CheckConditionById(limitId, copyDisplay.id)`
  → 不满足：弹 `autobattle_opendesc` 文案。

**⑤ `ban_autobattle` 的消费**
- 按钮显隐路径**不读** `ban_autobattle`（已被 0x1D4930 反汇编证实：只读 autobattle_isshow）。
- 海域副本全部 `ban_autobattle=1`；最可能用于**战斗进入时的强制"禁自律"**——与 `auto  1 False`（进场强制关 auto）行为吻合（详见 §5/§6，尚待单点 hook 证实读取点）。

### 3.3 AI 行为参数：`config_fleet_auto` / `DictFleetAuto`
- 表 `config_fleet_auto`（fa_id 1–5，共 5 行）：
  `weight_main_gun=900, weight_additionalSkill=900, weight_torpedo=5000, cd_skill=0.5, cd_skill_begin=0.5, battle_speed=3, search_speed=3, avoid_torpedo_duration=3, search_explore_switch, search_airattack_switch, weight_range_middle(50/300/1000 按敌情), weight_range_far, weight_range_near, search_auto_air_attack_a1/a2/a3·b1/b2/b3...`
- `DictFleetAuto`（TypeDefIndex 8333）字段：fa_id@0x8 / search_speed@0xC / battle_speed@0x18 / weight_main_gun@0x1C … cd_range_switch@0x40 / cd_skill_begin@0x48 / cd_skill@0x50 / avoid_torpedo_duration@0x58 / search_auto_* 。
- 消费：`AutoMoveKit.RefreshMoveRange`(0x61DA60) 读 range weight、`AutoSkillKit.__RefreshSkillRandomKit`(0x61F5E0) 读技能 weight、`AutoMoveKit.HadTorpedoAutoSpeed` 等 → 决定自动走位距离区间与技能优先。
- 舰队通过 `config_fleet.fa_id` 绑定（sea 舰队同表）。

---

## 4. 海域 1-A vs 非 1-A 的 autobattle 配置（实测数据）

扫描全 81 个海域副本（16xxxxx，config_copy_display）：**全部 `ban_autobattle=1 / autobattle_isshow=1 / autobattle_open=0 / autobattle_time=360 / autobattle_gamelimit=[] / auto_continuation=0`**——与"1-A vs 非 1-A"无关，**无任何配置差异**。

| 副本 | id | name | ban | isshow | open | time | 备注 |
|---|---|---|---|---|---|---|---|
| 1-A | 1600100 | 1A-偵察任務 | 1 | 1 | 0 | 360 | copy_demo_id=1601, random_factor_sets=[61], battle_time=180 |
| 2-A | 1610100 | 2A-安全航路 | 1 | 1 | 0 | 360 | random_factor_sets=[43] |
| 2-C | 1610300 | 2C-安全航路 | 1 | 1 | 0 | 360 | （此前文档误写 3-A=1620100 的对照） |
| 3-A | 1620100 | 3A-安全航路 | 1 | 1 | 0 | 360 | copy_demo_id=**11621（5 位）**, random_factor_sets=[43] |
| 训练 | 16000001 | 訓練イベント | **0** | 1 | 0 | 360 | 唯一 ban=0 |
| 对照 | 1000100 | イベント1-1 | 0 | 1 | 0 | 360 | copy_display_type=1 |

推论：
- "非 1-A 没有自律按钮 / 1-A 正常" 不能用 `autobattle_isshow`/`ban_autobattle` 区分（海域全相等）。
- 候选解释：a) 玩家实际进的是"训练イベント"(16000001, ban=0) 对照出正常；b) 非 1-A 海域战斗**进入帧初始化不完整**（本地服 `battlefield_resource`/`config_fleet` 等数据缺失），`AutoBattleGroup.CFirstOpen` 取不到合法 displayCopyId → `IsAutoBattleEnabled` 查表失败返回 false → 按钮被 `Hide`。这与"决斗后无法操作"同源（见 §6）。

---

## 5. 状态机与"谁接管了舰队的操作权"

- **索敌/海域阶段**：`PlayerAutoKit` 当前状态 `PlayerAutoSearch`（自动巡航开时 working=1）。手动操作由玩家发"操作 op"，逻辑侧 `D2L*Action.Excute` 消费；autopilot 指令走 `AutopilotInterface.RegistAutopilotOrder`（点击导航）与玩家移动不冲突。
- **自动接管（移动/技能）**：`PlayerAutoBattle.MoveTick`(0x62D550)→`AutoMoveKit.Tick`(0x61E110) 直接改舰队位置/CVector2 走位；`SkillTick`(0x62D580)→`AutoSkillKit.Tick`(0x61F2B0) 直接调 `FleetSkillInterface.AutoExecute` 释放技能。
- **入口判定**：`PlayerAutoKit.Tick`(0x62DB50) 仅当 `working(+0x24)!=0` 才 `jmp 0x105755b0`（FSM tick）。`Wort` 置 1、`Stop` 置 0。
- **auto 开关**（谁设置）：`BattleUITool.SetAutoBattle`/`PlayerInterface.PlayerAutoSwitch`，二者都来源于 UI 点击发 op 与战斗开始消息 D2LStartLogic（`autoBattle@0x8`），战斗帧按副本把初始 auto 写成 false（对应"1 False"）。

---

## 6. "海域决斗后无法操作"与自动战斗的关联分析

**证据支持（相关）**
1. 每次海域决斗进场，逻辑都会执行 `PlayerAutoSwitch(1, false)`（日志 `auto  1 False`），即把 auto 置为 **关**。这是一个确定性事件，与"无法操作"出现在同一时刻。
2. `PlayerAutoKit` 是"索敌↔战斗"双态共享的一个 kit：若海域阶段自动巡航(Autopilot/PlayerAutoSearch) 是开着的（working=1），进入战斗后 kit 状态虽切到 Battle，但 `working` 仍可能为 1（`PlayerAutoSwitch(false)` 的关停分支是否真把 working 归 0、是否走 `Stop()` 尚未在 disasm 中逐条确认）——若未真正停，AI 将每帧调用 `AutoMoveKit.Tick`/`AutoSkillKit.Tick`，**舰只自动动、玩家的移动/攻击 op 自然被覆盖/无感**。
3. `ban_autobattle=1` 是个"禁自律"信号；如果服务端/战斗初始化用它**强制关闭** auto，但 UI 侧（`autobattle_isshow=1`）仍显示"自律"按钮，则 UI 状态与逻辑状态不一致——点按无响应，看似"无法操作"。

**证据反对（关系不强）**
1. `auto  1 False` 打印的正是"auto=false"，方向是**从自动切回手动**，理论上不会让 AI 接管，反而应恢复手动；"无法操作"更像输入被吞/过渡态卡住。
2. 日志后面紧跟 `EnterBattleFromSearch.StateBattleReady`——战斗端正处在"索敌→战斗"过渡，此时 UI 尚未切到战斗操作态；输入失效可能是**过渡/初始化未完成的次生现象**（与文档《海域战斗.md》中"限时立即耗尽 / SetStageTime 未调用"同栈：非 1-A 海域战斗帧初始化数据不齐）。
3. 3-A 的非正常性更多反映在 `battlefield_resource` 缺失、`config_fleet_patrol` 空、`map_fog_hide` 等（已另档），均与 auto 状态无强关联。

**结论（当前置信度）**
- `auto  1 False` = "进场把玩家 auto 置关"，**属正常流程输出，非错误**。
- "无法操作"与"auto 状态被错误设置"的因果**证据不足**；若追查，重点验证两点：
  ① `PlayerAutoSwitch(false)` 的关停分支是否同步 `PlayerAutoKit.Stop()`（working 清零）；如果只清了 `BattleFleetData.autoBattle` 而 `working` 保持 1，战斗态 AI 仍会空转接管（支持"AI 接管导致无法操作"）。
  ② 非 1-A 海域战斗帧 `BattleFrame/SearchToBattle` 初始化是否缺数据导致 `AutoBattleGroup` 取不到 displayCopyId → 自律按钮被隐藏 + 操作区未就绪（支持"输入被吞/操作 UI 未就绪"）。

---

## 7. 关键 RVA 总表

| 函数/数据 | RVA |
|---|---|
| `auto  {0} {1}` 字面量 slot（VA 0x11D25168） | 0x1D25168 |
| **PlayerInterface.PlayerAutoSwitch(long,bool)**（日志打印点 0x56AD8F） | **0x56ACE0** |
| String::Format(string,object,object) | 0xEB16E0 |
| Debug.LogError(object)（payload 挂钩点） | 0xE515F0 |
| D2LPlayerAutoSwitchAction.Excute | 0x316050 |
| D2LStartLogicAction.Excute | 0x317750 |
| D2LChangePlayerAction.Excute | 0x3149D0 |
| PlayerAutoSystem.Init / Tick | 0x62F4D0 / 0x62F650 |
| PlayerAutoKit ctor / Wort / Stop / ChangeState / Tick | 0x62DB70 / 0x1DA2B0 / 0x62DB40 / 0x62DB10 / 0x62DB50 |
| PlayerAutoBattle.Enter / Tick / MoveTick / SkillTick | 0x62D460 / 0x62D5C0 / 0x62D550 / 0x62D580 |
| PlayerAutoSearch.Enter / Tick / __Autopilot / __StopAutopilot | 0x62DC00 / 0x62DE80 / 0x62E4D0 / 0x62F070 |
| AutoMoveKit.Tick / RefreshMoveRange | 0x61E110 / 0x61DA60 |
| AutoSkillKit.Tick / __RefreshSkillRandomKit | 0x61F2B0 / 0x61F5E0 |
| AutoChangeTargetKit.Tick | 0x61CD80 |
| AutoAvoidTorpedoKit.Tick | 0x61C460 |
| BattleDisplay.isAutoBattle / SetAutoBattle | 0x17EE20 / 0x17C6D0 |
| BattleUITool.GetAutoBattle / SetAutoBattle | 0x341210 / 0x342530 |
| ViewFleet.SetAutoBattle | 0x269820 |
| AutoBattleGroup.CFirstOpen / CReOpen / CheckShowAutoFun / OnNotification | 0x1D4930 / 0x1D4B60 / 0x1D4C90 / 0x1D4E00 |
| AutoBattleCtrl.Init / EnableAuto / SetAutoUI / OnPointerClick | 0x2AC250 / 0x2AC180 / 0x2AC680 / 0x2AC3B0 |
| DisplayLuaUtil（C# 桥）OnAutoBattleClick/CheckAutoBattle/IsAutoBattleEnabled | 0x135800 / 0x135230 / 0x135680 |
| xlua _m_SetAutoBattle_st_ / _m_GetAutoBattle_st_ | 0xEF1460 / 0xEEEC00 |
| LogicData_Battle.autoBattle 字段 | +0x26 |
| BattleFleetData.autoBattle 字段 | +0x88 |
| Fleet(Communication).autoBattle 字段 | +0x78 |
| DictCopyDisplay: autobattle_isshow / autobattle_time / autobattle_opendesc / ban_autobattle | +0xF8 / +0xC8 / +0x100 / +0x16C |
| DictFleetAuto 权重字段（weight_*） | +0x1C..0x98 |

## 8. 附：config_fleet_auto / 观察清单
- 海域副本全部 `ban_autobattle=1`；玩家舰队 UID 在本地服为 1。
- 建议后续验证：hook `PlayerAutoSwitch`(0x56ACE0) 实参（确认 fleetUID/auto），以及 hook `PlayerAutoKit.Stop`(0x62DB40) 确认关 auto 时是否归零 working。