# 苍蓝誓约本地复原 Roadmap

后续工作以可重复生成的静态证据为先，只有静态分析无法确认的边界才进行一次有明确观测目标的客户端运行。

## M1 配置数据目录化

- [x] 批量读取日服和国服 `config_*.db`。
- [x] 对 `DBObject.jsonbytes` 逐字节执行 `XOR 0x55`，验证 JSON 完整率。
- [x] 生成逐表行数、字段集合、样本和哈希。
- [x] 固定序章 `0-4` 为跨服首个战斗基准，并提取场景、舰队、敌舰和首通奖励链。
- [x] 自动生成逐字段和逐记录的 JP/CN 差异摘要。
- [x] 解析奖励三元组及关卡所需剧情辅助舰队、阵型和首通持久化船只奖励。

完成标准：关卡闭环所需配置可以由工具稳定提取，不需要手工查看数据库。当前 M1 已完成。

只读查询单条配置：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-config --config-query=jp:config_copy_display:1
```

## M2 IL2CPP 消息类型完善

- [x] 从 x86 PE 中自动定位并校验唯一的 `Il2CppMetadataRegistration` 强候选。
- [x] 将字段类型索引解析为基础类型、类、值类型、数组、引用和泛型列表。
- [x] 为登录及关卡关键消息输出字段名、实际类型、原始 typeIndex 和证据等级。
- [x] 提取属性表与 custom attribute 类型，确认协议属性同时具有 `ProtoMemberAttribute` 和 `DefaultValueAttribute`。
- [x] 依据字段/属性严格同序关系生成推断 field tag，并保留 `inferred-property-order` 证据等级。
- [x] 输出 JP/CN 独立的版本化 `.proto` 草案。
- 继续定位 `ProtoMemberAttribute` 构造参数或 protobuf-net serializer model，以把 tag 从强推断提升为直接确认。

当前确认：日服 registration RVA `0x01b1b878`，国服 RVA `0x01ad6368`；两服类型表均通过 257/257 抽样验证。目标消息字段边界、类型与属性映射已完整解析，JP/CN 语义一致。此前目录曾把 `methodCount` 当成 `fieldCount`，现已按该客户端 v24 变体的真实布局修正，因此 `TArgLogin` 的实际字段为 `Pid/Timestamp/OpenDateTime/Hash/SampleInfo`，设备信息属于嵌套 `TSampleInfo`。

完成标准：登录和关卡闭环消息的字段名称、类型及嵌套关系完整。

## M3 协议 ID 与事件映射

- [x] 确认 `SocketService.Login` 最终调用 `LogicSocketClient.Send`，内部操作码为 `2`，JP/CN 调用形态一致。
- [x] 建立 `CodeRegistration.methodPointers` 自动定位与关键 IL2CPP 方法 RVA 目录。
- [x] 实现 `TArgLogin`、`TSampleInfo`、`TRetLogin` 的最小真实 protobuf codec。
- [x] 本地服务以 `Pid` 创建/加载 SQLite 档案并返回 `TRetLogin { Ret = "0" }`，进程级测试通过。
- [x] 交叉引用 `NetProtocol`、`C2SProtocol`、`S2CProtocol` 的注册和分发调用点。
- [x] 确认登录 C2S 固定 11 字节头、S2C handler `5`、`TAckPack/TNetOperation` 信封及 `opCode=2` 路由。
- 建立数字消息 ID、请求/响应、推送事件和处理函数映射。
- 定位 SDK 事件 `1007` 的订阅方和 `data` 对象结构。

当前基本登录服务端逻辑与真实客户端 wire codec 已可运行，字节级和进程级集成测试均通过。剩余工作是一次定向客户端冒烟测试，确认底层 socket/KCP 消息边界以及客户端接受本地 `TRetLogin` 后的下一条请求。

完成标准：登录闭环涉及的消息 ID 不再依赖猜测。

## M4 Wire Format

- [x] 确认登录消息的应用层头、字段端序和响应 handler。
- [x] 确认传输选择：游戏逻辑 socket 走 **KCP over UDP**，不是 TCP。证据：
  - `LogicSocketClient` 存在 `KcpSend` 方法（JP RVA `3898672` / CN `1993280`），
    与 `Send`（JP `3899200` / CN `1993808`）并列；`Send` 通过传输对象
    `[+0xfc]` 函数指针转发。
  - Unity 网络层含 `ConnectionConfigInternal::InitUdpSocketReceiveBufferMaxSize`，
    底层为 UDP 收发。payload 已补上 UDP IAT hook（`sendto/WSASendTo/recvfrom`，
    带节流日志），运行时观测确认客户端在 SDK 登录后**未产生任何 UDP 流量**，
    即尚未发起 KCP 连接。
  - 应用层消息格式（11 字节头 + protobuf）位于 KCP 流内部，M3 的确认只覆盖了
    应用层，未覆盖 KCP 包层（`conv/cmd/frg/wnd/ts/sn/una/len`）。
- [ ] 捕获并解码 KCP 包，确认 `conv` 协商、序号、分片与粘包边界（待服务器列表打通后做真实抓包）。
- [ ] 确认 protobuf 之外的压缩、加密、校验和握手步骤。
- [x] 生成可重放 fixture 骨架：`BlueOath.Protocol/KcpCodec.cs` 提供
  `KcpPacket`/`KcpCodec`（24 字节头，LE 端序，`conv/cmd/frg/wnd/ts/sn/una/len`）、
  `FragmentPushMessage`（按 `frg=剩余分片数` 分片）、`KcpReassembler`（按 `sn` 重组）、
  `KcpStreamReader`（拆包/粘包缓冲）、`KcpSession`（会话收发）；`BlueOath.Tests` 新增
  `kcp fragments reassemble across sticky and split buffers` 回环自测通过。
- [x] 本地服务 KCP 端点：`BlueOath.Server` 新增 `--kcp-game-login-port`（UDP 监听，
  `KcpSession` 收发 + `TArgLogin`→`TRetLogin`）；`BlueOath.Tests` 新增
  `kcp login server creates a local profile over UDP` 集成测试通过（假客户端分片
  UDP 发登录、收 KCP 响应、解回 `TRetLogin` 并落档）。
- [x] KCP 可靠性层：`BlueOath.Protocol/KcpConnection.cs` 实现 ARQ——
  累计 ACK（`una`）、ACK 解析（清发送缓冲）、超时重传（RTO 指数退避）、
  死链检测（重传 ≥20 次标记 dead）、重复包检测、按 `sn` 乱序缓冲；分片改为
  KCP 语义（每片唯一 `sn`、`frg=剩余片数`），`KcpReassembler` 改为流式按
  `sn` 序拼接。`BlueOath.Tests` 新增 `kcp connection acks and retransmits`
  单元测试（ACK una、RTO 前后不重传/重传、ACK 后清缓冲）通过。

完成标准：本地测试客户端能按真实 wire format（UDP + KCP + 应用层）编解码登录消息。

> ## M5 现状小结（登录→服务器列表链已打通到最后一环）
>
> 游戏登录是**两段式**：SDK 登录（`BabelTimeSDKManager.Login` `0x2D1870` →
> `0x102CFB80(0,2,0)` → `new_sdk.login`，已 bypass）之后，还需经服务器列表选择
> 才走到游戏 socket 登录（`SocketService.Login` `2281232` → `LogicSocketClient.Send`
> 操作码 2，KCP/UDP）。
>
> 服务器地址不在配置库里，来自 SDK `getServerList`。关键链路（均已运行时确认）：
>
> - `BabelTimeSDKManager.GetServiceList`（`0x2D0530`，经 xLua 由 Lua 调用，方法指针
>   在 IL2CPP methodPointers 表 `0x18B0A14`）→ `0x102CFB80(0,3,0)`（操作码 3 门槛）
>   → `Platform.getServerList` P/Invoke（`0x3C4AE0`，调用点 `0x2D06D9`）→ 原生
>   `getServerList`（`new_sdk.dll` `0x3AB60`）。
> - `getServerList` 发起 `POST /phone/serverlist/` 并返回**状态码 1**（非字符串），
>   服务器列表 JSON 写入 SDK 内部全局 std::string，游戏侧 Lua 读回解析、选服、连接。
> - payload 两处改动使链路打通：`HookInitSdk` 改调 `originalInitSdk`（装载 host 配置，
>   否则 host 为 null、`getServerList` URL 变成 `nullindex.php`）；登录 event=2 后
>   直接 `TryInvokeJpGetServiceList`（调 `0x2D0530`，走 stolen-bytes detour 回跳）。
>
> **服务器列表 entry 字段已确认**（国服反编译源码 `lua_tools/BlueoathLua/util/
> platformmanager.lua` + 日服字节码字符串常量交叉验证，见 `docs/lua-catalog/README.md`）：
> `name`/`serverIndex`/`new`/`groupid`/`openDateTime`/`status`/`hot`/`host`/`port`/
> `recommend_weight`（外层 `result.root.notice` + `result.root.item[]`）。
> 本地服务 `/phone/serverlist/` 已按此结构响应（`serverlist` 只是 URL 路径，非响应字段；
> SDK 不解析响应体，原样存进内部 string 交给 Lua 解析）。此前误列 `serverId`/`serverIp`/
> `flag`/`ready_open_weight`/`openTime` 均来自其它函数，非服务器列表字段。
> 下一步：冒烟验证游戏是否发起 KCP 连接，并驱动选服/连接这条 Lua 状态机。
>
> ## 关键 RVA / 地址参考
>
> `new_sdk.dll`（联云/lianyun，image base `0x10000000`）导出：
> `getServerList=0x3AB60`、`getHost=0x3C9F0`、`getLogHost=0x3C800`、
> `getLoginedServerInfo=0x3C650`、`login=0x3A850`、`tickLoop=0x3AA40`、
> `initSDK=0x3A780`。SDK 配置 `platform/config.json`/`game_config.json`（Android）
> 为 **DES 加密**（密钥常量 `BTPRIKEY`，`loadConfig` 内 `0x16B89` 做密钥展开），
> 字段含 `host_internet/ip_internet/host_web/host_share/host_debug/host_cdn1/host_cdn2/
> crashHost/track_host/ali_host`；DES 模式/IV 未确认（ECB/CBC 试失败）。
> `getServerList` HTTP 响应字段：`serverlist`、`data`、`shareUrl`、`pImagePath`、
> `pDes`，`serverlist` 数组 entry 字段待解析。

## M5 定向运行验证与本地登录

- 仅针对 M2-M4 中剩余的少量不确定项布置日志或 hook。
- 单次捕获登录请求，回填协议目录和版本适配器。
- 本地服务依次实现登录、主界面、编队、关卡、战斗和结算。

完成标准：日服完成可重复的离线闭环，客户端原始文件哈希不变。

## M6 泛化与国服适配

- 从 `catalog.json`、配置目录和协议目录生成 `ProtocolProfile`/`ClientAdapter`。
- 公共业务逻辑不包含服别判断，差异集中在版本配置和能力开关。
- 用同一套测试 fixture 验证国服对应流程。

完成标准：新增客户端版本主要通过生成适配器和补充证据完成，而非复制业务代码。

---

## 会话记录：2026-08-18 — JP 1.4.0 看板船娘加载攻关

### 核心成果

**3D 看板船娘（UIShipProxy）成功加载。** `UIShipProxy.ctor called` / `LoadModel called` 出现在日志中。

### 攻关方法论

**关键转折：安装 `lua_pcallk` 错误探针。** xLua 框架在页面 `DoOnOpen` 中抛出的 Lua 运行时错误（nil 索引等）会被静默吞掉，既不进 `Debug.LogError` 也不进 `Debug.LogException`。此前一直在"盲修"——猜一个缺失字段，补上，下一个 nil 再猜。装了探针（hook `xlua.dll` 的 `lua_pcallk`）后，每次运行时错误都会被完整打印到日志，包含 `homepage.lua:行号` 和具体字段名。

### 修复的阻塞点（共 8 个）

| # | 阻塞点 | 缺失数据 | 错误 |
|---|--------|---------|------|
| 1 | `RegisterAllEvent` → `shop_reddot` nil | JP prefab 缺 widget | `GetComponentsNeed` POST-CALL 注入 Lua dummy table |
| 2 | `_PlayerData` → `ServerId` nil | UserInfo 字段 56 | `ServerId=1` |
| 3 | `_PlayerData` → `Exp` nil | UserInfo 字段 11 | `Exp=0` |
| 4 | `DoOnOpen` → `TopShowPvePt` → `SetText(nil)` | UserInfo 字段 62 `PvePt` | `PvePt=100` |
| 5 | `homefunitem` → `GetSpecialPlots` → `pairs(nil)` | BuildingInfo 缺 `SpecialPlotDatas` | `building.UpdateBuildingInfo` 推送 dummy 数据 |
| 6 | `_PlayerData` → `GetLoveNum` → `startTime` nil | HeroGrid 字段 20 `UpdateTime` | `UpdateTime=now` |
| 7 | `_PlayerData` → `GetLoveInfo` → `loveInfo` nil | HeroGrid 字段 17 `Affection` | `Affection=1000` |
| 8 | `_PlayerData` → `GetHeroHp` → `CurHp` nil | HeroGrid 字段 9 `CurHp` | `CurHp=1000` |

### 预填的字段（主动分析，非崩溃驱动）

| # | 数据结构 | 字段 | 值 | 原因 |
|---|---------|------|-----|------|
| 9 | HeroGrid | `Equips` (3) | dummy 元素 | `_SetExtraInfo` 中 `ipairs(nil)` 崩溃 |
| 10 | HeroGrid | `PSkill` (13) | dummy 元素 (PSkillId=41210) | 同上 |
| 11 | HeroGrid | `Mood` (18) | 0 | `GetMoodNum` 算术运算 |
| 12 | HeroGrid | `MarryType` (21) | 0 | `GetLoveInfo` 分支判断 |
| 13 | UserInfo | `Medal` (39) | 0 | `_ShowMedal` → `GetCurrency(MEDAL)` |
| 14 | UserInfo | `HeadShow` (44) | 0 | `_ReverseMask` / `_SetSecretary` 检查 |
| 15 | HeroGrid | `CreateTime` (8) | now | `_SetExtraInfo` 使用 |

### 关键基础设施变更

1. **`lua_pcallk` 错误探针** (`hooks_debug.cpp`): POST-CALL hook 在 `xlua.dll` 的 `lua_pcallk` 上，捕获所有被 pcall 保护的 Lua 错误，打印完整 stack traceback 到日志。安装方式：
   - 使用 `InstallXluaExportHook` 对 `xlua.dll` 导出函数做 detour（不同于 `InstallStrArgHook` 的 GameAssembly SHA 门控）
   - 6 参数 cdecl POST-CALL 裸函数 trampoline，保存 `L` 状态指针，读取错误栈顶字符串

2. **Widget 表 dump**: `InjectShopRedDot` 中增加 `lua_next` 遍历，dump HomePage widget 表所有 key 到日志（`WidgetKeys: ...`），用于确认 JP prefab 缺失哪些 widget。

3. **`debug-game.ps1` 清理**: 启动前清理残留 server/game 进程。

### 服务器端 proto 补全

`src/BlueOath.Protocol/GameLoginProtocol.cs` — `EncodeRetGetUserInfo`:
- 字段 11 `Exp=0`, 39 `Medal=0`, 44 `HeadShow=0`, 56 `ServerId=1`, 62 `PvePt=100`

`src/BlueOath.Protocol/PlayerDataCodec.cs` — `HeroGrid`:
- 字段 8 `CreateTime`, 9 `CurHp`, 17 `Affection`, 18 `Mood`, 19 `MarryTime`, 20 `UpdateTime`, 21 `MarryType`
- 字段 3 `Equips`（dummy 元素）, 13 `PSkill`（dummy 元素 PSkillId=41210）

`src/BlueOath.Server/Protocols/GameLoginMessageHandler.cs`:
- `building.UpdateBuildingInfo` 推送（含 `SpecialPlotDatas`/`NormalPlotDatas` dummy 数据）

### 当前状态

- ✅ 登录 → 建号 → 用户信息 → 英雄数据 → 主场景 → HomePage 全链路
- ✅ 3D 看板船娘加载（`UIShipProxy.ctor` + `LoadModel`）
- ✅ 建造队列 (BuildsInfo) / 浴室 (BathroomInfo) / 后宅 (BuildingInfo) dummy 推送
- ⚠️ 红点系统仍有非致命 logError（`getStateByRedDot` 收到 nil redDot，被 logError 吞掉，不阻塞）
- ⚠️ HeroGrid 的 `Equips`/`PSkill` 使用 dummy 数据，可能影响属性计算精度
- ⚠️ 大量 `Expected the end but found invalid token` 错误（cjson 解析空/损坏数据），非致命

---

## M7 系统模块逐项打通

客户端共 64 个 UI 模块、125 个 logic 模块、139 个 pb 协议组。当前仅打通登录到主页链路，其余全部未实现。

**依赖关系：第二梯队（船娘养成/装备/背包）是第一梯队（编队/出击/战斗）的前置条件**——必须先有可管理的船娘、装备、物品，才能编队出击。

### 第二梯队：船娘养成与资源管理（出击前置）

| # | 模块 | 文件数 | 关键 proto 消息 | 依赖 |
|---|------|--------|----------------|------|
| 2.1 | **船坞 (Dock)** | 3 | `HeroGrid` 列表，退役/锁定 | HeroBag 已推送，可能可打开 |
| 2.2 | **船娘详情 (GirlInfo)** | 15 | `HeroInfo`，装备/强化/突破/属性 | 装备数据、属性计算 |
| 2.3 | **装备 (Equip)** | 5 | `EquipList`，`EquipInfo`，强化/突破 | 背包物品数据；**已打通**（仓库 + 商店购买 + 穿脱，见会话记录） |
| 2.4 | **背包 (Bag)** | 12 | `BagInfo`，`GridInfo`，物品使用/出售 | 无 |
| 2.5 | **学习 (Study)** | 9 | `StudyInfo`，技能学习/加速 | PSkill dummy 数据精度 |
| 2.6 | **结婚 (Marry)** | 5 | HeroGrid 的 Affection/Marry 字段 | 已预填，可能部分可打开 |
| 2.7 | **强化/突破 (Strengthen/Break)** | 跟 GirlInfo 绑定 | `intensify`，`remould`，`advance` | 消耗材料数据 |

### 第一梯队：核心战斗循环

| # | 模块 | 文件数 | 关键 proto 消息 | 依赖 |
|---|------|--------|----------------|------|
| 1.1 | **编队 (Fleet)** | 9 | `FleetInfo` 推送 | ✅ 已完成 |
| 1.2 | **关卡 (Copy)** | 29 | `CopyInfo`，`CopyRecord`，敌方数据 | 编队完成 |
| 1.3 | **战斗 (Battle)** | 4 (工具) | `BattleParams`，`InitActorInfo`，`InitSkillInfo` | 编队+关卡完成 |

### 第三梯队：经济 / 社交 / 经营

| 模块 | 文件数 | 说明 |
|------|--------|------|
| 建造 (BuildShip) | 10 | 抽卡，含建造队列/UP池/UR池；**已打通**（10 连 + 动画 + 船坞入库，见会话记录） |
| 商店 (Shop) | 6 | 含快速购买/物品详情 |
| 任务 (Task) | 4 | 含成就/日常/周常/教学任务 |
| 后宅 3D (Building) | 11 | 含 2D 列表/3D 场景/生产/配方 |
| 浴室 (Bathroom) | 7 | 含舰队修理/礼物/加速 |
| 公会 (Guild) | 22 | 最大模块，含捐献/任务/公会战/公会商店 |
| 好友 (Friend) | 1 | 好友列表/申请/搜索 |
| 聊天 (Chat) | 6 | 含公会频道/弹幕 |
| 邮件 (Mail) | 2 | 含附件领取；**已打通**（23 封货币邮件 + 3 封道具邮件 + 无限领取，`GmMailType` 标志位区分，见会话记录） |
| 排行 (Rank) | 4 | 含活动 Boss 排行/小游戏排行 |
| 竞技场 (Sport) | 6 | 含挑战/排行/积分奖励 |
| 教学 (Teaching) | 13 | 师徒系统 |

### 第四梯队：活动 / 特殊玩法（60+ 文件）

| 模块 | 文件数 | 说明 |
|------|--------|------|
| 活动大厅 (Activity) | 60+ | 含 20 个子模块（签到、累计消费、限时建造、抽奖、纸人、情人节...） |
| 爬塔 (Tower) | 17 | 含地图/装备/主题/奖励/重置 |
| Battle Pass | 10 | 含进阶/购买等级/奖励预览 |
| 远征 (Adventure) | 4 | 含敌人/角色/攻击结算 |
| 收藏/许愿 (Illustrate) | 14 | 含图鉴/许愿/加速；**图鉴部分已打通**（见会话记录） |
| 杂志 (Magazine) | 3 | 含派遣/解锁 |
| AR Kit | 5 | 含创建/加入/投影 |
| Mini Game | 7 | 含限时/无限/排行榜 |
| 炼金 (Alchemy) | 1 | 莱莎联动 |
| 其他活动 | 15+ | 圣诞节/万圣节/新年/情人节/校园/美食 等 |

---

## 会话记录：2026-08-18（第二轮）— 船坞 → 船娘详情链路打通

### 核心成果

**船坞（Dock）→ 船娘详情（GirlInfo）链路已基本打通，界面可正常显示。**

- 船坞按钮出现并可点击打开船坞页面
- 船坞页面打开无报错
- 船娘详情页（GirlShowPage）可显示（仍有少量非致命报错）

### 关键认知修正

**船坞按钮「未出现」的真相**：不是协议未满足，而是船上坞按钮位于右侧面板（`config_home_page` hp_id="3"，function_id ["5","7","8"]），由 Unity prefab 控制显隐。`_CreateRight()` 对三个按钮无差别创建图标+点击事件，无任何 Lua 过滤。曾尝试在 `GetComponentsNeed` hook 里用 Lua C API 调 `btn_right1.gameObject:SetActive(true)` 激活，但**无效果**（已回滚）。最终通过清理其他报错、修复登录链路后按钮自然可见。

### 修复的报错清单（共 8 个阻塞点）

| # | 报错位置 | 根因 | 修复 |
|---|---------|------|------|
| 1 | `userdata.lua:108` m_TypeNumMap nil | `LoginOk` 事件触发时 `SetCurrency` 尚未执行 | 在 `user.UserLogin` 应答**前**先推送 `user.UpdateUserInfo` |
| 2 | `activitylogic.lua:432` NewTaskStage nil | 字段 46 未编码 | 添加 `NewTaskStage=7`（先试 0 触发新手引导，改 7 跳过） |
| 3 | `equipdata.lua:279` EquipsId nil | 空 Equip 消息 `0x12 0x00` 解码成单个空元素 | 去掉空 Equip 消息，只留 `type=0` |
| 4 | `marrylogic.lua:206` mood nil | `Mood=0` 因 `if != 0` 守卫未编码 | Mood/MarryTime/MarryType 无条件编码 |
| 5 | `custom_time.lua:153` os.date 失败 | loginTime/loginTimePre 为 0 | 新增 `user.UpdateLoginTime` 推送 |
| 6 | 黑屏闪退（堆损坏 0xc0000374） | ForceMainStage 在后台线程调 StageMgr.Goto 与主线程竞争 | ForceMainStage 加 2 秒延迟 |
| 7 | `girlshowpage.lua:300` Exp nil | HeroGrid 字段 5 未编码 | 无条件编码 `Exp=0` |
| 8 | `shiplogic.lua:989` Replace nil | PSkill 的 Replace(字段4) 未编码，`nil ~= 0` 为真 | PSkill 编码 `Replace=0` |

### 剩余非致命报错（不影响界面，待后续处理）

| 报错 | 说明 |
|------|------|
| cjson `Expected ...` (top=1) | 服务端返回空/畸形 JSON，被 `pcall` 保护，属误报 |
| `functions.lua:1569` Equals nil | `IsNil()` 用 `pcall` 捕获的试探性调用，属误报 |
| `readonlymeta.lua:38` ipairs(nil) | 改造页 `RemouldLV`/`ArrRemouldEffect` 字段 nil |
| `homeremouldstate.lua:65` index nil | 改造页 `config_ship_remould_show[nil]` 查询（因 RemouldLV 未编码） |

### 方法论沉淀（重要）

1. **Lua nil 比较陷阱**：`nil ~= 0` 在 Lua 中为**真**。服务端字段为 0 时若不编码，客户端读到 nil，会导致 `if v.Replace ~= 0` 这类判断走错分支（返回 nil 而非跳过）。**凡客户端会读取做比较/拼接/算术的整型字段，必须无条件编码（即使值为 0）**。

2. **空消息编码陷阱**：protobuf 重复字段若编码 `length=0` 的空消息（如 `0x12 0x00`），会被解码成**单个空元素**而非空数组，导致 `element.field` 为 nil。要表示「无数据」应**不编码该字段**，而非编码空消息。

3. **堆损坏排查**：`0xc0000374` 是堆损坏（`ntdll.dll`），非 Lua 逻辑错误。查 Windows 事件日志（`Get-WinEvent Application`）拿到异常码，可快速定位是原生内存问题。本项目的 `ForceMainStage` 从 payload 后台线程调 `StageMgr.Goto` 是根因，延迟只是缓解。

4. **船娘详情的数据依赖**：GirlShowPage 需要 HeroGrid 的 `Exp`(5)、`Lvl`(4)、`CurHp`(9)、`TemplateId`(2)、PSkill 的 `PSkillId`(1)/`PSkillExp`(2)/`Level`(3)/`Replace`(4)。这些字段缺一则属性/技能/经验条显示崩溃。

### 服务器端字段现状（`PlayerDataCodec.cs` HeroGrid）

- 无条件编码：`Exp`(5)、`Mood`(18)、`MarryTime`(19)、`MarryType`(21)
- 条件编码（非 0）：`HeroId`(1)、`TemplateId`(2)、`Lvl`(4)、`CreateTime`(8)、`CurHp`(9)、`Affection`(17)、`UpdateTime`(20)、`Fashioning`(22)
- 硬编码字节：`Equips`(3) = type=0；`PSkill`(13) = PSkillId=41210/Exp=0/Level=0/Replace=0

### 下一步方向

- 剩余两个非致命报错集中在**改造（Remould）**模块，需补 `RemouldLV`(26)、`ArrRemouldEffect`(23) 字段
- 第二梯队继续推进：装备（Equip）、背包（Bag）、学习（Study）

---

## 会话记录：2026-08-19 — 图鉴系统（Illustrate）打通

### 核心成果

**图鉴（Illustrate）系统功能几乎完整，无报错。** 打开图鉴界面显示全部图鉴条目，玩家拥有的舰娘显示为已解锁，其余显示为未解锁剪影。

### 数据流

- `illustrate.IllustrateInfo` 是登录后的 S2C 推送（Ret = `TIllustrateInfoRet`）。
- 客户端 `IllustrateService._IllustrateInfo` → `PbToLua(TILLUSTRATEINFORET)` → `Data.illustrateData:SetIllustrateData` → `UpdateHero`。
- `UpdateHero` 遍历 `IllustrateList` 标记已解锁条目，再遍历 `config_ship_handbook` 配置生成其余 LOCK/CLOSE 状态条目（**兜底逻辑：图鉴内容不依赖推送是否完整，只依赖推送是否到达**）。

### 关键字段与推导

| 项 | 值 | 说明 |
|----|----|------|
| `IllustrateId` | `config_ship_handbook` 的 key = `ship_info_id` | 由 TemplateId 推导：`(TemplateId - 1) / 10`（规范 `ship_main_id = ship_info_id * 10 + 1`） |
| `IllustrateList`(1, repeated) | 玩家已解锁图鉴条目 | 必须非 nil（否则 `ipairs(nil)` 崩溃） |
| `IllustrateEquipList`(9, repeated) | 装备图鉴条目 | 必须非 nil（同上） |
| `LikeTime`(3) | 无条件编码 0 | `IsLike` 里 `LikeTime ~= 0`，`nil ~= 0` 为真会误判 |
| `MarryCount`(6) | 无条件编码 0 | `0 < MarryCount`，nil 会崩 |
| `BehaviourList`(5) | 至少编码一个 0 元素 | `pairs(nil)` 崩溃 |

### 服务器端实现

- `PlayerDataCodec.cs`：新增 `IllustrateInfo`/`IllustrateEquipInfo`/`IllustrateInfoRet` record + `Encode` 方法。
- `GameLoginMessageHandler.cs`：`BuildSyncPushesAsync` 新增 `illustrate.IllustrateInfo` 推送，`IllustrateList` 从存档舰娘列表推导（`ToIllustrateId`）。
- 秘书舰 TemplateId=10210511 → IllustrateId=1021051。

---

## 会话记录：2026-08-19 — 新手引导画面闪现修复

### 核心成果

**修复进入游戏时短暂闪现新手引导画面的问题。** 登录后不再触发引导系统第一个 stage。

### 根因

`guide.GuideInfo` 推送的**时序错误**。引导系统初始化发生在 `user.UserLogin` 响应阶段：

```
user.UserLogin 响应 → LuaEvent.LoginOk → LoginStage:_LoginOk
                                        → guideHub:onLoginOK()
                                          → guideManager:init()   ← 读取 GUIDE_DONE_STAGES（此时为空）
                                          → LOGIN_END 触发第一个 stage(id=10000) → GuidePage
```

原实现把 `guide.GuideInfo` 推送放在 `user.GetUserInfo` 之后（`BuildSyncPushesAsync`），比 `guideManager:init()` 晚，导致 `GUIDE_DONE_STAGES` 读不到，所有引导 stage 被误判未完成。

### 修复

把 `guide.GuideInfo` 推送**提前到 `user.UserLogin` 应答之前**（与 `user.UpdateUserInfo` 同位置），确保 `guideManager:init()` 执行时 `GUIDE_DONE_STAGES` 已完整。

### 关键知识点

| 项 | 说明 |
|----|------|
| 引导触发链路 | `LoginOk` → `LoginStage:_LoginOk` → `guideHub:onLoginOK()` → `guideManager:init()` + `LOGIN_END` |
| `GUIDE_DONE_STAGES` | 引导进度标记，value 是 `Serialize` 序列化的表（**字符串 key**），如 `{["10000"]=1,...}` |
| `GUIDE_DOING_STAGE` | 进行中 stage，空字符串表示无 |
| 引导 stage | `guideStageConfig.lua` 共 29 个顶层 stage，第一个 id=10000 的 `triggerType = LOGIN_END` |
| 推送时序原则 | **依赖客户端初始化时机的推送，必须在触发该初始化的请求应答前发送**（`user.UpdateUserInfo`/`guide.GuideInfo` 都是 `user.UserLogin` 前） |

### 改动文件

- `PlayerDataCodec.cs`：新增 `GuideSetting`/`GuideInfo` record + `Encode`（`FuncList`/`PlotList`/`Event` 占位避免 nil 崩溃，补 `using System.Text`）
- `GameLoginMessageHandler.cs`：新增 `BuildGuideInfoPush` 方法（`DoneGuideStages` 29 个 stage id 常量 + `BuildDoneGuideStages` 序列化）
- `GameLoginSession.cs`：`user.UserLogin` 分支里，`user.UpdateUserInfo` 之后再推 `guide.GuideInfo`

---

## 会话记录：2026-08-19 — 商店系统 + GM 功能打通

### 核心成果

**商店系统完全打通，GM 功能（免费购买）可用。** 商店各分页正常访问，GM 商品显示、单选/多选购买、资源发放（仓库/货币/时装）均已验证。

### 商店数据流

- `shop.UpdateShopInfo`（S2C 推送，Ret=`TRetShopsInfo`）设置 `Data.shopData.m_shopInfo`，登录时推送。
- `shop.BuyGoods`（C2S，单选）→ `TBuyGoodsArg{ShopId,GoodId,BuyNum,PriceIndex}` / `TBuyGoodsRet{Reward,GoodId,BuyNum}`。
- `shop.QualityBuyGoods`（C2S，多选）→ `TQualityBuyGoodsArg{ShopId,GoodIdList}` / `TQualityBuyGoodsRet{Reward,GoodIdList}`。

### 修复的报错清单（商店链路，共 8 个）

| # | 报错位置 | 根因 | 修复 |
|---|---------|------|------|
| 1 | `shopdata.lua:60` m_shopInfo nil | shop.UpdateShopInfo 未推送 | 登录时推送所有商店（104 个） |
| 2 | `shopdata.lua:34` table index nil | CondGoodList 空消息解码成空元素（Info.Type=nil） | CondGoodList/GoodList 不编码 |
| 3 | `periodmanager.lua:97` compare nil | UserInfo.CreateTime 未编码 | 补 CreateTime(22) 字段 |
| 4 | `custom_time.lua:153` os.date | SvrStartTime=0 | 推 `user.UpdateSvrTime` |
| 5 | `rechargelogic.lua:295` call nil | recharge.Info 未推送 | 推 `recharge.RechargeInfo`（空 Info） |
| 6 | `shopitemshow.lua:378` compare nil | UsedFRefreshNum/FRefreshNum/FRefreshTime 未编码 | 补字段并无条件编码 |
| 7 | `shopitemshow.lua:759` arithmetic nil | ShopGoodsData.Num 未编码 | Num/Status 无条件编码 |
| 8 | `custom_time.lua:207` arithmetic nil | BuyGoldTime/BuySupplyTime 未编码 | 补 BuyGoldNum(26)/BuyGoldTime(27)/BuySupplyNum(28)/BuySupplyTime(29) |

### 资源存储与发放（GM 免费购买）

| GoodsType | 存储位置 | 推送协议 |
|-----------|---------|---------|
| ITEM(1)/EQUIP_ENHANCE_ITEM(6) 道具 | 仓库 `PlayerBag` | `bag.UpdateBagData`（TBagInfoRet） |
| CURRENCY(5) 货币 | UserInfo（Gold/Diamond/Supply/Bath 等） | `user.UpdateUserInfo` |
| FASHION(18) 时装 | `PlayerFashion`（通用解锁，SfId→FashionTid） | `fashion.updateData`（TFashionList） |

- 货币字段持久化：`PlayerCharacter` 新增 `Gold`/`Diamond`/`Supply`/`Bath`；`AddCurrency` 按 CurrencyType 映射（1=金币,2=钻石,5=体力,13=温泉币）。
- 时装 SfId 映射：`FashionTid → SfId`（config_fashion 的 `belong_to_ship`），当前硬编码在配置里。
- 购买后（单选/多选）经 `BuildPostBuyPushesAsync` 推送 user + bag + fashion 更新。

### 数据驱动 GM 商品配置

- 配置文件 `runtime/jp/gm-goods.json`（数据驱动，无需改代码）。
- 每个商品：`goodId`（config_shop_goods 的 id，须 goods_visible=1）、`shopId`（分页）、`type`（GoodsType）、`itemId`、`num`。
- `GmGoodsConfigLoader` 加载；`BuildShopInfoPush` 按 `shopId` 分组推送。
- GM 商品按类型分页：常规商店(1)=货币+道具，装备商店(5)=装备强化道具，时装商店(23)=时装。

### 关键知识点

1. **商店分页 = config_shop 的 shopId**：客户端不校验商品的 shelf_id 与商店匹配，只校验 `goods_visible==1`，服务器可自由分页。
2. **购买发放的资源类型分流**：道具→仓库、货币→UserInfo、时装→时装解锁，三种存储+推送协议各不相同。
3. **客户端本地置灰**：商品因货币不足被客户端置灰（本地判断），服务器免费购买前需给足对应货币（或改商品 price）。
4. **数据驱动 > 硬编码**：GM 商品列表、时装 SfId 映射都走 `gm-goods.json`，后续扩充 GM 商品只需改配置。

---

## 会话记录：2026-08-19 — 邮件系统 + GM 货币发放打通

### 核心成果

**邮件系统完全打通，作为 GM 商店的前置，为玩家提供无限领取的 24 种货币。** 邮件页面显示 24 封货币邮件，单选/全选领取发放对应货币；领取后邮件不删除（`IsGotReawrd` 恒 0），可反复领取。

### 设计定位

- 单机版无法发邮件，邮件的作用是「无限领取货币」的入口（GM 商店前置）。
- 邮件数据驱动：`runtime/jp/gm-mails.json` 外置 24 封邮件（每种货币一封，各 10000）。
- 领取只发放资源，不删除邮件。

### 数据流

- 邮件列表是 **C2S 主动请求**（非登录推送）：打开邮件页面 → `mail.GetMailList` → `TMailListRet{list}`。
- 领取：`mail.FetchItem{Mid}`（单选）/ `mail.FetchAllItems`（全选）→ 发放货币 → `TMailListRet{list, Reward}`（`Reward`=`TCommonReward[]`，客户端 `fetchMailItem` 弹奖励）。
- 登录后推 `payback.newPayback` → `EmailService._TagUpdataMail` 置 `updataTog=true`，打开邮件页面才 `SendGetMailList`。

### 修复的报错

| 报错 | 根因 | 修复 |
|------|------|------|
| `emaillogic.lua:45` compare nil | `mail.TempLateId > 0` 比较，`TempLateId=0` 未编码 → nil | `TempLateId` 无条件编码 |

### 24 种持久货币全链路扩展

邮件需求推动货币从 4 种扩展到 UserInfo 全部 24 种持久货币字段：

- `PlayerCharacter` 新增 20 个货币字段（JSON 存档向后兼容）。
- `EncodeRetGetUserInfo` 重构为 `UserInfoFields` record 重载，完整编码 24 种货币。
- `AddCurrency` 覆盖 24 种 CurrencyType（1 金币/2 钻石/5 体力/8 主炮/9 鱼雷/10 飞机/11 其他/12 退役币/13 温泉币/14 战略点/15 勋章/18 塔币/22 演习币/23 时装点/24 公会贡献/25 幸运/26 教师勋章/27 教师声望/28 战令经验/29 战令金币/30 PVE点/31 公会币II/32 UR装备币/33 活动战令经验）。
- 排除非 UserInfo 字段的 CurrencyType（BULLET/GAS/ShipExp/UserExp/RMB/MERITS/ELECTRIC/FOOD/STRENGTH）。

### 改动文件

- `src/BlueOath.Core/PlayerEntities.cs`：`PlayerCharacter` 加 20 货币字段；`GmMailConfig`/`GmMailsConfig` record。
- `src/BlueOath.Protocol/GameLoginProtocol.cs`：`UserInfoFields` record + `EncodeRetGetUserInfo` 重载 + `DecodeMailMid`。
- `src/BlueOath.Protocol/PlayerDataCodec.cs`：`MailItem`/`MailList`/`MailListRet` record + `Encode`。
- `src/BlueOath.Server/Protocols/GameLoginMessageHandler.cs`：mail.* 方法分发、`BuildMailListRet`/`BuildFetchMailRetAsync`、`GmMailsConfigLoader`、`AddCurrency` 扩展。
- `src/BlueOath.Server/Sessions/GameLoginSession.cs`：邮件领取后推 `user.UpdateUserInfo`。
- `runtime/jp/gm-mails.json`：24 封货币邮件配置。

### 关键知识点

1. **邮件列表靠 C2S 拉取，不是推送**：邮件页面只在 `updataTog=true` 时才 `SendGetMailList`，`updataTog` 由 `payback.newPayback` 推送置位，缺这条推送 → 邮件页面永远空列表。
2. **无限领取 = `IsGotReawrd` 恒 0**：客户端 `CanFetchItem` 判 `IsGotReawrd == 0` 才显示领取按钮，服务器不置位即可反复领取。
3. **货币范围以 UserInfo 字段为准**：`userdata.lua GetCurrency` 映射的才是玩家持久货币，`user_pb.lua TGetUserInfoRet` 无字段的（GAS 等）是战斗/建筑临时值。

---

## 会话记录：2026-08-19 — 装备系统（仓库 + 商店购买 + 舰娘穿脱）打通

### 核心成果

**装备系统全链路打通**：装备仓库容量 2000，商店购买装备物品进入装备仓库，舰娘详情页可正常穿脱装备（到正确槽位）。

### 装备仓库

- 服务端 `PlayerEquip` 实体（`EquipBagSize=2000`，`EquipItem` 列表），登录时推送 `equip.UpdateEquipBagData`。
- `EquipItem`：`EquipId`（自增唯一实例 ID）、`TemplateId`（config_equip id）、`HeroId`（0=未装备）/ `SlotIndex` 等。
- 服务重启后 `_nextEquipId` 从存档最大 ID 恢复，避免 ID 冲突。

### 商店购买装备

- `ApplyGoods` 新增 `GoodsTypeEquip(2)` 分支，路由到 `AddEquipItem`（每次调用创建一件装备实例）。
- 购买后通过 `BuildPostBuyPushesAsync` 推送 `equip.UpdateEquipBagData`。

### 舰娘穿脱装备

- `hero.ChangeEquip`（`THeroChangeEquipArgs{HeroId, Index, EquipId, Type}`）：`EquipId>0` 装备 / `EquipId=0` 卸下。
- 更新 `Hero.EquipSlots`（6 槽位）和 `EquipItem.HeroId`。
- 应答后推送 `hero.UpdateHeroBagData` + `equip.UpdateEquipBagData`。
- HeroGrid Equips 编码对应 `FleetType.Normal=1`，6 个 `EquipsInfo{EquipsId, state}`，`EquipsId` 无条件编码。

### 修复的报错

| 报错 | 根因 | 修复 |
|------|------|------|
| `equipdata.lua:66` compare nil | `0 < v.HeroId` 比较，HeroId=0 未编码 → nil | HeroId 无条件编码 |
| `equiplogic.lua:444` table index nil | `tabSortTool[Tid][Star][EnhanceLv]` 索引，Star/EnhanceLv=0 未编码 → nil | Star/EnhanceLv/EnhanceExp 无条件编码 |
| 装备到错误槽位 | Lua 1-based 索引 vs C# 0-based 数组 | `index = luaIndex - 1` 转换 |

### 改动文件

- `src/BlueOath.Core/PlayerEntities.cs`：`EquipItem`/`PlayerEquip`/`Hero.EquipSlots`。
- `src/BlueOath.Protocol/PlayerDataCodec.cs`：`EquipInfo`/`EquipList`/`EquipsInfo`/`EquipsInfoByType` record + `Encode`。
- `src/BlueOath.Protocol/GameLoginProtocol.cs`：`DecodeHeroChangeEquipArgs`。
- `src/BlueOath.Server/Protocols/GameLoginMessageHandler.cs`：`AddEquipItem`/`BuildEquipPush`/`BuildChangeEquipRetAsync`/`BuildPostEquipPushesAsync`。
- `src/BlueOath.Server/Sessions/GameLoginSession.cs`：`hero.ChangeEquip` 后推送 hero + equip。

### 关键知识点

1. **装备字段必须无条件编码**：`EnhanceLv`/`Star`/`HeroId`/`EnhanceExp` 在 `EquipBagOverlay` 里做表索引和比较，值为 0 也必须编码（与 HeroGrid 的 `Exp`/`Mood` 同理）。
2. **Lua 1-based vs C# 0-based**：客户端 `nIndex` 从 1 开始，服务端数组从 0 开始，`hero.ChangeEquip` 的 Index 参数需要 `-1` 转换。
3. **装备仓库独立于道具仓库**：`EquipBagSize` 控制装备容量，`EquipInfo` 存储装备实例（含 `HeroId` 标记归属），`EquipNum` 按模板统计数量。

---

## 会话记录：2026-08-19 — 抽卡系统（建造）打通

### 核心成果

**抽卡（建造）系统完全打通**，10 连抽卡 + 动画展示 + 船坞入库全链路通。

### 设计定位

- 抽卡是纯服务端行为，客户端 `config_build_ship` 仅用于卡池展示（无实际池数据）。
- 卡池数据驱动：`runtime/jp/build-pools.json`（`poolId` + `ships[{templateId, weight}]`）。
- 池 ID 与客户端 `config_extract_ship.id` 对应（如池 1 对应新手池）。

### 数据流

- `buildship.BuildShip`（C2S）：`TBuildShipArg{Id, Num, CacheId}` → 服务端按权重随机抽 `Num` 艘船 → 创建 `Hero` 实例入船坞 → 返回 `TBuildShipRet{BuildShipResult=[TCommonReward]}`。
- 响应前推送 `hero.UpdateHeroBagData`（仅新 hero）+ `illustrate.IllustrateInfo`（仅新船图鉴），确保 `ShowGirlPage` 和 `CheckShowMeet` 数据就绪。

### 修复的报错（抽卡链路，共 8 个）

| 报错 | 根因 | 修复 |
|------|------|------|
| `emaillogic.lua:45` compare nil | `TempLateId=0` 未编码 | 无条件编码 |
| `equipdata.lua:66` compare nil | `HeroId=0` 未编码 | HeroId 无条件编码 |
| `equiplogic.lua:444` table index nil | `Star/EnhanceLv=0` 未编码 | 无条件编码 |
| `showgirlpage.lua:158` index nil | HeroId 无效 → hero 数据为空 | 设置 `Fashioning = (TemplateId-1)/10`（sf_id） |
| `buildshippage.lua:729` index nil | `SpReward/TransReward` 未编码 | 编码空元素 |
| `marrylogic.lua:246` loveInfo nil | `Affection=0` → `GetLoveInfo` 无匹配 | `Affection=1000` |
| `buildshiplogic.lua:77` index nil | 池中船不在 `config_ship_handbook` | 只放 handbook 中存在的船 |
| 船坞不显示角色 | `HeroBagSize=100` 低于下限 200 | `HeroBagSize=200` |

### 协议字段编码策略

| 字段 | 策略 |
|------|------|
| `TCommonReward.Id`(4) | 无条件编码（`_LoadTenCard` 读 HeroId，`IsLock` 需要） |
| `TCommonReward.Type/ConfigId/Num` | 条件编码（非 0） |
| `TBuildShipRet.SpReward`(2) | 每个 reward 编码一个空元素（`_LoadTenCard` 里 `self.transReward[n].Reward` 访问） |
| `TBuildShipRet.TransReward`(3) | 同上 |
| `HeroGrid.Fashioning`(22) | 必须非 0（`_SetExtraInfo` 调用 `GetShipShowByFashionId`） |

### 改动文件

- `PlayerEntities.cs`：`BuildShipEntry`/`BuildShipPool` record；`HeroDock.BagSize=200`。
- `PlayerDataCodec.cs`：`EncodeBuildShipRet` 完整编码（含 `SpReward`/`TransReward` 空元素）。
- `GameLoginMessageHandler.cs`：`GmBuildPoolLoader`（JSON 数据驱动）、`BuildBuildShipRetAsync`、`RollShip`/`WeightedPick`/`AddShip`、`DecodeBuildShipArg`、`_nextHeroId`/`_lastBuildHeroIds`/`GetAccountAsync`。
- `GameLoginSession.cs`：`buildship.BuildShip` 分支（先推 hero+illustrate，再应答）。
- `runtime/jp/build-pools.json`：卡池配置（池 ID 1，3 艘船）。

### 关键知识点

1. **抽卡是纯服务端行为**：客户端 `config_build_ship` 无实际池数据，服务器数据驱动。
2. **`Fashioning` 必须非 0**：`_SetExtraInfo` 调用 `GetShipShowByFashionId(Fashioning)`，为 0 时返回 nil → 提前 return → hero 数据为空。
3. **池中船必须在 `config_ship_handbook` 中**：`UpdateHero` 处理 handbook 时查不到会崩溃，导致图鉴数据不完整。
4. **`HeroBagSize` 下限 200**：`config_parameter[20].value=200`，低于此值会被 `GetBaseShipNum` 的 `Mathf.Clamp` 修正，但显示仍可能异常。

---

## 会话记录：2026-08-19 — 玩家个人资料（Profile）打通

### 核心成果

**玩家个人资料页无报错**，修改秘书舰、改名、改签名、改头像、改头像框全部可用。

### 修复的报错

| 报错 | 根因 | 修复 |
|------|------|------|
| `readonlymeta.lua:139` math.floor nil | `GetHeroCount`/`AttackCount` 未编码 | 编码 `GetHeroCount(41)`/`AttackCount(40)`/`MarriedNum(45)` |
| `playerheadframelogic.lua:53` index nil | `Head`(4) 未编码 → `config_profile[nil]` | 编码 `Head=1021051`（默认秘书舰） |
| `medallogic.lua:9` index nil | `MedalAcquiredTime` 编码了 MedalId=0 元素 | 不编码该字段（protobuf default_value={}） |
| `headdata.lua:71` table index nil | `user.GetHeadBuyCount` 未处理 | 返回 `ShipFleetId=0, Count=0` |
| 头像无法修改 | `user.NewHeadUnlockedList` 未推送 | 登录时推送船坞所有舰娘的 sf_id |

### 实现的协议

| 协议 | 参数 | 功能 |
|------|------|------|
| `user.SetUserSecretary` | `SecretaryId(1, uint32)` | 修改秘书舰 |
| `user.ChangeName` | `Name(1, string)` | 改名 |
| `user.SetMessage` | `Message(1, string)` | 修改个人签名 |
| `user.SetPlayerHeadFrame` | `headFrameId(1, int32)` | 修改头像框 |
| `user.SetHead` | `ProfileID(2, int32)` | 修改头像 |
| `user.GetHeadBuyCount` | `ShipFleetId(1)` | 查询头像购买计数（返回 0） |
| `user.BuyHead` | — | 购买头像（空响应） |
| `user.NewHeadUnlockedList` | (推送) | 动态推送船坞所有舰娘的 sf_id |

### 新增字段

- `PlayerCharacter` / `UserInfoFields`：`Head`(4)、`HeadFrame`(5)、`Message`(25)、`GetHeroCount`(41)、`AttackCount`(40)、`MarriedNum`(45)
- `BuildUserProfileUpdateAsync` 统一处理所有档案更新（解码 → 更新 → 落盘 → 推送）

### 改动文件

- `PlayerEntities.cs`：`PlayerCharacter` 新增 `Head`/`HeadFrame`/`Message`/`GetHeroCount`/`AttackCount`/`MarriedNum`
- `GameLoginProtocol.cs`：`UserInfoFields` 新增对应字段 + `EncodeRetGetUserInfo` 编码
- `GameLoginMessageHandler.cs`：`BuildUserProfileUpdateAsync` + `DecodeVarintField`/`DecodeStringField` + `BuildHeadUnlockedListPush` + `user.SetHead` 等分支
- `GameLoginSession.cs`：档案更新后推送 `user.UpdateUserInfo`

### 关键知识点

1. **统一档案更新模式**：`BuildUserProfileUpdateAsync(field)` 统一处理所有档案更新，`DecodeVarintField`/`DecodeStringField` 按字段号解码，灵活可扩展。
2. **`NewHeadUnlockedList` 动态生成**：从船坞 `Heroes` 推导 `sf_id = (TemplateId - 1) / 10`，去重后推送。
3. **`MedalAcquiredTime` 不编码**：protobuf `default_value={}`，不编码时客户端解出空表，`GetMedalIdTab` 返回空数组。

---

## 会话记录：2026-08-19 — 舰娘升级 + HP 修复

### 核心成果

**舰娘 HP 修复为满血，升级系统打通**。GM 商店获取强化素材 → 舰娘详情页使用素材升级 → 经验条/等级正确更新。

### HP 修复

- `HP_COEFFICIENT = 10000000000`（100亿），`CurHp` 需等于此值才满血。
- `Hero.CurHp` 类型从 `int` 改为 `long`（10亿超出 int 范围）。
- 默认秘书舰和抽卡新舰娘 `CurHp` 均设为 `HpCoefficient`。

### 升级系统

- `hero.AddExp`：`THeroAddExp{HeroId(1), ItemList(2, repeated TItem{Id=2, Num=3})}`
- 服务端从 `config_ship_exp_item.db` 加载每件素材 exp，从 `config_ship_levelup.db` 加载每级所需 exp
- 扣除仓库素材 → 计算总经验 → 循环升级 → 落盘 → 返回 `THeroAddExp` → 推送 hero + bag

### 改动文件

- `PlayerEntities.cs`：`Hero.CurHp` 改为 `long`，新增 `HpCoefficient` 常量
- `PlayerDataCodec.cs`：`HeroGrid.CurHp` 改为 `long`
- `GameLoginMessageHandler.cs`：`ShipLevelupLoader`（SQLite 读 config）、`BuildAddExpRetAsync`、`DecodeHeroAddExp`、`EncodeHeroAddExpRet`
- `GameLoginSession.cs`：`hero.AddExp` 后推送 hero + bag

### 关键知识点

1. **`CurHp` 满血值 = 100 亿**：`shiplogic.lua` 中 `HP_COEFFICIENT = 10000000000`，`GetHeroHp` 计算 `CurHp / HP_COEFFICIENT * maxHp`。`CurHp` 需用 `long` 类型（超出 int32 范围）。
2. **升级素材从 config_ship_exp_item.db 读取**：`ShipLevelupLoader` 启动时读取 SQLite 配置表，按 itemId 获取 exp 值。

---

## 会话记录：2026-08-19 — 编队系统打通

### 核心成果

**编队页面无报错打开**。修复 `tactic.GetHerosTactic` 协议未处理导致的 `exHeroInfo` nil 崩溃，支持编队数据读写。

### 根因

- `fleetlogic.lua:612`（`GetFleetHeroId`）：`if #fleetInfo[i].exHeroInfo then` — `exHeroInfo` 为 nil 时 `#nil` 崩溃
- 连锁：服务器未处理 `tactic.GetHerosTactic` → `FleetData:SetData` 从未被调用 → `FleetInfo[FleetType.Normal]` 为 nil → `GetFleetData()` 回退到 `GetGuildWarFleetData()` → 该回退创建的编队无 `exHeroInfo` 字段
- `FleetData:SetData` 本身有守卫 `if info.exHeroInfo == nil then info.exHeroInfo = {} end`，但守卫从未被执行

### 协议

- `TSelfTactis{tactics(repeated TTactic), MaxPower, MinPower, IsSkip}`
- `TTactic{tacticName(1), heroInfo(2,repeated), modeId(3), strategyId(4), formationId(5), type(6), exHeroInfo(7,repeated)}`
- 登录时推送 `tactic.GetHerosTactic` 初始化 5 个空编队（modeId 1-5, type=1=Normal）
- 客户端发送 `tactic.GetHerosTactic`（nil arg）请求编队数据
- 客户端发送 `tactic.SetHerosTactic`（TSelfTactis arg）保存编队修改

### 改动文件

- `PlayerEntities.cs`：新增 `FleetEntry`、`PlayerFleet` 实体；`PlayerAccount` 新增 `Fleet` 字段；`PlayerAccountFactory.DefaultFleet()` 创建 5 个空编队
- `GameLoginMessageHandler.cs`：
  - `EncodeFleet()` — 编码 TSelfTactis protobuf
  - `DecodeSetHerosTactic()` — 解码编队修改请求
  - `BuildGetHerosTacticAsync()` — 返回编队数据
  - `BuildSetHerosTacticAsync()` — 保存编队并落盘
  - `BuildSyncPushesAsync` — 登录时推送编队数据

### 关键知识点

1. **编队数据是推送驱动的**：客户端打开编队页面时不发送请求，从 `Data.fleetData:GetFleetData()` 读缓存，必须在登录时推送 `tactic.GetHerosTactic` 完成初始化。
2. **`exHeroInfo` 是潜艇位**：每个编队有 6 个主力位（heroInfo）和 3 个潜艇位（exHeroInfo），即使为空也必须初始化为 `{}`。

---

## 会话记录：2026-08-20 — WPF 图形化启动器

### 核心成果

**创建了 WPF 图形化启动器 `BlueOath.Launcher.Wpf`，替代 `run-game.bat` 和 `start-client.bat` 脚本。**

### 新增项目

`src/BlueOath.Launcher.Wpf/` — .NET 8.0 WPF 项目，`BlueOath.Local.sln` 第 10 个项目。

### 功能清单

| 功能 | 实现 |
|------|------|
| 启动页 | 左侧公告面板（数据驱动 `announcements.json`）+ 右侧大号启动按钮 + 小号调试启动按钮 |
| 正常启动 | 完整复制 `debug-game.ps1` 流程：WMI 清理残留进程 → TLS 证书生成 → 服务器启动 → 代理启动 → 注入游戏 |
| 调试启动 | 跳过服务器启动，仅启动代理 + 客户端，连接已运行服务器（默认端口 7080） |
| 进程守护 | 实时显示服务器/代理/游戏客户端进程状态（绿点/红点，PID） |
| 日志控制台 | 4 个子分页：服务器 / 代理 / 客户端 / 系统，实时输出各进程 stdout/stderr |
| 自动滚动 | 日志新增时自动 `ScrollIntoView` 到最新行 |
| 进程清理 | 使用 `System.Management` WMI 查询 `Win32_Process` 命令行，精确匹配 `BlueOath.Server.dll` 并强杀 |
| 嵌入图标 | 游戏原始图标 `uipic_ui_common_im_icon_100.png` → `app.ico` 嵌入 EXE 和窗口标题栏 |

### 技术架构

| 层 | 组件 |
|----|------|
| Models | `Announcement`、`LogEntry`、`LaunchConfig` |
| ViewModels | `MainViewModel`（分页管理）、`LaunchViewModel`（启动逻辑）、`GuardianViewModel`（进程守护+日志） |
| Views | `MainWindow`（导航栏+内容区）、`LaunchPage`、`GuardianPage` |
| Services | `ProcessManager`（核心：进程生命周期、日志重定向、payload 文件监控）、`AnnouncementService` |
| Styles | `App.xaml` 集中定义所有颜色/画笔/按钮/文本样式 |

### 关键踩坑

1. **`ResourceDictionary.MergedDictionaries` 路径解析失败**：WPF 编译后 `Source` 相对路径在运行时无法解析，改为将所有样式资源直接定义在 `App.xaml` 的 `Application.Resources` 中。

2. **`CommandParameter` 类型不匹配**：XAML 中 `CommandParameter="0"` 传递的是字符串，`RelayCommand<int>` 的 `parameter is int` 始终为 false，命令从未执行。改为 `RelayCommand<object>` + `Convert.ToInt32(param)`。

3. **`_selectedPageIndex` 默认值 0 导致首帧不渲染**：`SetProperty` 检测到初始值等于目标值时返回 false，`CurrentPage` 从未被赋值。初始化为 -1 解决。

4. **stdout/stderr 顺序读取死锁**：`ReadToEndAsync()` 顺序调用会在进程 stderr 缓冲区满时死锁。改为 `Task.WhenAll` 并行读取。

5. **`Dispatcher.Invoke` 导致日志卡顿**：所有日志添加改为 `Dispatcher.BeginInvoke(..., DispatcherPriority.Background)`，UI 更新自动合并批处理。

6. **`ListBox` 虚拟化 + 回收模式**：启用 `VirtualizingPanel.IsVirtualizing="True"` + `VirtualizationMode="Recycling"` + `IsDeferredScrollingEnabled="True"`，仅渲染可见行，万级日志不卡顿。

7. **TabControl 多余 Label**：`TabControl` 默认渲染选中项的 `ToString()`。设置 `ContentTemplate="{x:Null}"` 消除。

### 文件索引

| 文件 | 作用 |
|------|------|
| `BlueOath.Launcher.Wpf.csproj` | 项目文件（`net8.0-windows`，`UseWPF`，`System.Management`） |
| `App.xaml` / `App.xaml.cs` | 应用入口，`StartupUri="MainWindow.xaml"`，集中定义所有样式资源 |
| `MainWindow.xaml` / `MainWindow.xaml.cs` | 主窗口，导航栏 + 内容区，`FindRoot()` 定位项目根目录 |
| `Views/LaunchPage.xaml` / `.cs` | 启动页（公告面板 + 启动按钮） |
| `Views/GuardianPage.xaml` / `.cs` | 守护页（进程状态 + 日志控制台 + 自动滚动） |
| `ViewModels/MainViewModel.cs` | 分页管理，`RelayCommand<T>` 通用命令 |
| `ViewModels/LaunchViewModel.cs` | 启动逻辑，状态文本映射 |
| `ViewModels/GuardianViewModel.cs` | 进程守护，日志分页管理 |
| `Services/ProcessManager.cs` | 核心引擎：5 阶段启动流程，WMI 清理，进程输出重定向，payload 日志文件监控 |
| `Services/AnnouncementService.cs` | 从嵌入资源加载公告 JSON |
| `Resources/announcements.json` | 公告数据（4 条中文公告） |
| `Resources/app.ico` | 游戏图标（PNG→ICO 转换） |
| `Converters/ValueConverters.cs` | `BooleanToVisibilityConverter`、`BooleanInvertConverter` |
| `Views/Styles/*.xaml` | 样式参考文件（已不加载，实际样式在 App.xaml） |
| `BlueOath.Launcher.lnk` | 项目根目录快捷方式，双击启动 |
