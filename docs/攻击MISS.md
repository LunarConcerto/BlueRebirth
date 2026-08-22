# 攻击 MISS 调查记录（已解决）

> 状态：**已解决（2026-08-22）**。根因是实战斗伤害公式里的"主动技能伤害系数"
> `Ship.actSkillInfo.damageFac` 在离线服务端下为 0，被逐级相乘后把最终伤害清零 →
> `DamageInfo.isMiss=true` → 显示 MISS。已在 payload 里 NOP 掉所有 EPU 伤害路径上的
> damageFac 乘法（等价于按 1.0 处理）。实测玩家主炮伤害 100~139，敌舰 HP 从 9999999 下降。

## 现象
- 战斗可正常进入（详见 `docs/战斗系统.md` 的[进入战斗]复盘）。
- 玩家攻击：炮弹**视觉命中**敌人，但**不计算伤害**，直接显示 `MISS`（MISS 是游戏机制）。
- 无报错、无崩溃（崩溃是诊断钩子引起，已确认与游戏无关）。

## 已确认事实（运行时钩子数据）

### 1. 命中判定 `__IsHit` 通过
- 函数：`Battle.Logic.API.Sub.Kits.ExportAPI.IEPUBase.__IsHit(double hit, double dodge)`，GameAssembly RVA `0x5281B0`。
- 运行时钩子实测：`hit=100, dodge=0, result=true` —— **命中判定通过**（不是命中问题）。
- 公式（反汇编）：`hit = Max(5.0, hit - dodge)`，然后 `0x364210(...)` 计算概率，最后 `comisd hit/100.0 vs result; seta al`。
- 常量：0x1A25AD0=5.0、0x1A25AD8=100.0、0x1A27400=10000.0。

### 2. MISS 由 `DamageInfo.isMiss` 控制
- `DamageInfo`（Battle.Communication，TypeDefIndex 6364）：`targetUid(0x8) / sourceTargetUID(0x10) / propId(0x18) / value(0x1C) / positiveValue(0x20) / realValue(0x24) / isCrit(0x28) / isMiss(0x29)`。
- 显示层读 isMiss 决定显示 MISS 还是伤害数字。

### 3. `_EventDamageAfter` 显示 damage=0
- 函数：`IEPUBase._EventDamageAfter`，RVA `0x527380`。
- 钩子读到 `damage=0`（int，偏移可信），hit/crit 参数读成了指针（arg 布局未完全对齐，函数实际参数数 > dump 显示的 7 个）。
- 结论倾向：**本地伤害计算为 0** → isMiss=true → 显示 MISS。

### 4. 用户发现的预览系统函数（重要参考）
- `AttackerTargetAnalyser__GenerateDamage`（IDA 伪代码）：
  ```c
  v5->fields.value = BattlePreviewFleet__ChangeHp(targetFleet, target, targetState, 0);
  v5->fields.isMiss = (targetState == 1);   // DamageResult.Miss
  ```
- `DamageResult` 枚举：`Normal=0, Miss=1, BadlyDamage=2, Sink=3`。
- 这是**战斗预览**系统（`PreViewBattleManager` / `TestLocalNet` / `BattlePreviewFleet`），非实战斗。
- 但 `isMiss = (targetState == Miss)` 的模式很可能同样适用于实战斗 → **实战斗的 isMiss 也由某个"结果"决定**。

### 5. 伤害公式链（实战斗）
- `EPU_MainGun.__ExecuteAtom`（RVA `0x521E40`）：读 `exportShip.GetAttribute(api, 8=Attack)`、`targetShip.GetAttribute(api, 9=Defense)`。
- `__ExecuteAtom` → `0x5266D0`（建导出）→ `0x52A509`（伤害导出）→ 构建 `DamageInfo`。
- `_GetShipDamageCoe`（0x527F70）：伤害系数，经 `this->field8(LogicAPI)[+0xA0]` → `0x53A3F0`。

## 已尝试方案（均未修复）

| 方案 | 结果 |
|---|---|
| 服务端 `copy.AttackBase` 返回回环 + 伤害字段（field5=1e9） | 无效果（客户端 AttackBase 是 fire-and-forget，无注册 handler，不读响应） |
| 玩家/敌舰补发 `Hit(19)/Dodge(20)` 属性 | 仍 MISS（命中判定本来就通过） |
| hook `GetAttr_Attack`（0x50AD40） | **从未触发** → 伤害计算不走这个 getter |
| hook `Ship.GetAttribute`（0x50B1F0） | **从未触发** → 伤害计算不走这个虚方法 |
| hook `EPU_MainGun.AfterExecute`（0x520D60） | **从未触发** → 主炮攻击不走 AfterExecute |
| hook `EPU_MainGun.Execute`（0x520EC0） | 首次 stolenLen=10 切坏 `8B 75 08` 崩溃；**已修正为 stolenLen=12，尚未复测** |
| hook `SetAttackDmgInfo0`（0x41E860） | 参数偏移未对齐（raw 栈值不像该函数签名），疑似挂错函数 |
| hook `_EventDamageAfter`（0x527380） | 读到 damage=0，但该钩子会崩（堆地址执行），可能是 arg 布局或函数签名问题 |

## 当前关键矛盾
- `__IsHit` 返回 true（命中），但游戏显示 MISS（isMiss=true）。
- 说明实战斗的 isMiss 不由 `__IsHit` 决定，而是由**伤害/结果机制**决定（类似预览的 targetState）。
- 若本地伤害确实=0，则 isMiss 被迫 true（"0 伤害=miss"规则）。

## 待验证方向

### A. 确认实战斗 `Execute`（0x520EC0，stolenLen=12）的 L2DAttackInfo 伤害数据
- `L2DAttackInfo`（Battle.Communication，6490）：`attackInfo(List<AttackInfo> at 0x38)`。
- `AttackInfo`（6351）：`attackerShipUid(0x8) / attackerUID(0x10) / damageInfos(List at 0x18)`。
- `DamageInfo`：`value(0x1C) / realValue(0x24) / isCrit(0x28) / isMiss(0x29)`。
- payload 已有 `DumpAttackInfos(container, attackInfoOffset)` 辅助函数（0x38 用 Execute，0x14 用 AfterExecute）。
- **下一步**：复测 Execute 钩子，读实战斗 DamageInfo 的 value/isMiss。

### B. 找实战斗设置 `isMiss` 的代码
- 实战斗 DamageInfo.isMiss 在哪个导出函数设置？可能直接写 `dmg+0x29`。
- 反汇编 `0x52A509`（伤害导出）的完整函数体，找写 0x29 的地方。

### C. 玩家战斗船的攻击力来源
- `Ship.PBConvert`（RVA `0x307F20`，stolenLen 需 17）构建战斗船。
- 战斗船属性存 `battleAttribute`（Ship+0x48），其中 Attack 不是直接字段（在 `LAttrCodeInt` 复杂结构里）。
- 需确认玩家攻击力到底是不是 100（服务端 Attr 发的）。

### D. 服务端"直接扣血"思路（用户原方案）
- 若本地伤害确实=0 且难以从公式修，考虑服务端在 `copy.AttackBase` 响应里携带伤害，让客户端应用。
- 前提：需确认客户端是否读 AttackBase 响应（目前看是不读，fire-and-forget）。

## 相关文件/地址速查
- 服务端：`src/BlueOath.Server/Protocols/GameLoginMessageHandler.cs`（EncodeStartBaseRet / BuildAttackBaseRet / BuildQuitBaseRet）。
- Payload：`native/Payload/hooks.cpp`（__IsHit/GetAttrAttack/Ship.GetAttribute/Execute/AfterExecute 钩子，部分被注释禁用）。
- dump：`il2cppdump/dump.cs`（DamageInfo 323928、L2DAttackInfo 325791、EPU_MainGun 339787、IEPUBase 340476、Ship 355882、ShipBattleAttribute 356632、EnumProp 403905、DamageResult 533188、AttackerTargetAnalyser 532990）。
- Lua 协议定义：`lua_tools/BlueoathLua/copy_pb.lua`（字段号）。
- GameAssembly RVA：`__IsHit=0x5281B0`、`Ship.GetAttribute=0x50B1F0`、`GetAttr_Attack=0x50AD40`、`EPU_MainGun.Execute=0x520EC0`、`AfterExecute=0x520D60`、`_EventDamageAfter=0x527380`、`__ExecuteAtom=0x521E40`、`_GetShipDamageCoe=0x527F70`、`SetAttackDmgInfo0=0x41E860`。

## 环境备注
- 启动：`tools/debug-game.ps1 -SkipBuild`（= run-game.bat）。游戏常因后台 wrapper 被 kill 而不启动，需分步：先清理进程，再单独 `Start-Process powershell -File debug-game.ps1 -SkipBuild`。
- payload 构建后 bin-x86 常不更新（被游戏锁定），需杀进程后手动 `Copy-Item` 临时构建目录的 DLL。
- 诊断钩子 `capture_bugly` 仍开启（bootstrap.ini），curl 重定向到 9887 捕获服务器（可能已停）。

---

# 2026-08-22 解决复盘（本问题全部根因）

## 根因：`Ship.actSkillInfo.damageFac` = 0
- `ShipActSkillInfo.damageFac`（dump 355854，offset 0x28，"主动技能伤害系数"）在离线服务端下没有被初始化成 1.0，
  而是保持 0（ctor 不写它，零内存默认）。
- 实战斗所有 EPU 伤害路径在**最后一步**都把总伤害 `* damageFac`：
  - `EPU_MainGun.__ExecuteAtom`（0x521E40）：0x5222F1 `mulsd xmm0,[ebp-0x60]`
  - `EPU_MainGun_Torpedo.__ExecuteAtom`（0x521530）：0x521910 `mulsd xmm1,[ebp-0x24]`
  - `EPU_BuffAttack.__Execute`（0x520370）：0x52044A
  - `EPU_PSkill.__EcecuteMain`（0x523030）：0x52314B
  - `EPU_PSkill.__Execute`（0x523250）：0x5232F0
  - `EPU_AirAttack.__ExecuteAtom`（0x523870）：0x523C03
- 0 * 总伤害 = 0 → `DamageInfo.value=0` → `isMiss=true` → 显示 MISS。`__IsHit` 一直返回 true，
  但伤害计算在乘 damageFac 前就……不，是乘到 0 为止。
- 关键区分：**`GetASkillAttr`（0x65BA80）返回的 ASkillAttrUnit.damageFac（0x10）是 1.0**（运行时钩子实测），
  真正为 0 的是 `Ship.actSkillInfo.damageFac`。前者在 0x5222EC 乘法（可保留，本来就是 1.0）。

## 修复：payload NOP 掉 6 处 damageFac 乘法
- `native/Payload/hooks.cpp` 的 `TryApplyMainGunDamageFacPatch()` 把 6 个 `mulsd xmm?,[ebp-X]`（各 5 字节）
  写成 NOP（等价于 damageFac 按 1.0 处理）。校验字节后打补丁，全部成功。
- 影响：主动技能的伤害系数不再生效（离线服务端本来也没配 A-skill，可接受）。

## 实测验证
- `EventDamageAfter ... damage=100/105/111/116/120/132/139`（此前为 0）。
- 敌舰（Boss，ship 71）`GetAttribute prop=1`：9999999 → 9999899 → 持续下降，伤害真实生效。
- 主炮（skillType=1）正常；AerialSearch（skillType=5，索敌）仍 0 伤害（侦察机制，正常）。
- 战斗中崩溃钩子仍会打印 `0x4001000A`（C++ 异常/调试异常），非致命，游戏稳定运行。

## 顺带修复/新增的钩子
1. `_EventDamageAfter`（0x527380）钩子原本是坏的：trampoline 把同一个 `[esp+0x40]` push 8 次（所有参数读成同一个值），
   且 `stolenLen=10` 切断了 `cmp byte[disp],imm8` 指令 → 崩溃。已改为 `stolenLen=13` + 正确参数偏移，
   现在能读到真实 damage/hit/crit（damage 在 arg6）。
2. `__ExecuteAtom`（0x521E40，stolenLen=13）钩子：记录 exportShip/targetShip/qteNum/mainGunDamageAdd/actSkillDamFac。
3. 系数钩子：`GetDamageOdd_BCS`(0x521A20)、`GetAmmounitionEffect`(0x66A190)、`GetShipDamageCoe`(0x66A3F0)、
   `GetBattleQteDamageCoe`(0x66A260)、`AttackCoeOfRelation`(0x66BEE0)、`GetASkillAttr`(0x65BA80)。
4. **登录自动兜底**：SDK event 29（公告 WebView open）不一定触发 → 无头登录卡死。在 payload 定时循环里，
   若 30s 后仍未连上服务端则每 5s 派发一次伪造登录结果（event 2），直到 `netlogic currState==2`。

## 遗留：伤害量级 / 通关可行性
- 服务端 `EncodeStartBaseRet` 给玩家船发 Attack=100（硬编码），实测主炮每发 ~100~139。
- Boss HP=9999999 → 需约 8 万发才能击沉，**不实际**。若要能通关：
  - 服务端提高玩家 Attack（或按 config_ship_main 的 attack 发），或
  - 降低 config_ship_enemy 的 HP，或
  - payload 里把主炮/鱼雷伤害再乘一个系数。
- `copy.AttackBase` 确认是 fire-and-forget（客户端不读响应），服务端"直接扣血"方案无效，已排除。

## 地址速查（补充）
- damageFac 乘法待 NOP 地址：0x52044A / 0x521910 / 0x5222F1 / 0x52314B / 0x5232F0 / 0x523C03。
- `ShipActSkillInfo.damageFac` = Ship+0x64 → +0x28。
- `GetASkillAttr`（0x65BA80）返回 ASkillAttrUnit.damageFac（0x10）。
- 伤害最终公式（EPU_MainGun.__ExecuteAtom）：
  `damage = ceil( (Max(Attack*0.9 - Defense, 0) + Attack*0.1) * base1 * GetASkillAttrFac * actSkillDamFac )`。
- `0x57F960` = `Mathf.CeilToInt`（最终取整）；`0x5806B0` = `Max(a, 0)`。
