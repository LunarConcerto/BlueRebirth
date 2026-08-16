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
