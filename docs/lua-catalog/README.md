# Lua 代码资料库（某游戏 JP 1.4.0）

> **已全量反编译日服 Lua**（2026-08）：1526 个 `.lua` 文件反编译成功，
> 落地在 `lua_tools/BlueoathLuaJP/`。日服字节码本质是**标准 Lua 5.3.5**
> （4 字节指令、标准 LUAC_DATA），只有 header 两处小改（format=`01`、
> sizeof Instruction 字段写 `8` 作为「红鲱鱼」）。此前文档里「可变长指令 /
> CRLF 转义 / 紧凑编码」等结论，是 `tools/extract-lua.py` 用文本模式写文件
> （`open(...,"w",encoding="utf-8",errors="ignore")`）把二进制字节码当文本写、
> 丢掉了 `0x93` 等非 UTF-8 字节、并把 LF 转成 CRLF 造成的**提取损坏假象**，已证伪。
>
> **重要**：国服（CN）完整反编译源码在 `lua_tools/BlueoathLua/`（1397 个 `.lua`）。
> 日服与国服是同一款游戏、逻辑基本一致；日服有 129 个国服没有的文件（含 13 个空
> stub）及少量差异（SDK `new_sdk.dll`、服务器列表字段等），现已能直接从日服字节码
> 反编译对照。

## 字节码格式（正确结论，2026-08 定稿）

日服字节码 = **标准 Lua 5.3.5**（x86 版，`xlua.dll` 内嵌 VM，版本串 `Lua 5.3.5`），
仅 header 两处小改：

| 偏移 | 内容 | 值 | 说明 |
| --- | --- | --- | --- |
| 0-3 | 签名 | `1B 4C 75 61` | 标准 |
| 4 | 版本 | `53` | Lua 5.3 |
| 5 | format | `01` | 官方为 `00`，fork 改成 `01` |
| 6-11 | LUAC_DATA | `19 93 0D 0A 1A 0A` | **标准 6 字节** |
| 12 | sizeof(int) | `04` | 标准 |
| 13 | sizeof(size_t) | `04` | x86 |
| 14 | sizeof(Instruction) | `08` | **红鲱鱼**（实际指令 4 字节，见下） |
| 15 | sizeof(lua_Integer) | `08` | 标准 |
| — | sizeof(lua_Number) | 省略 | 隐含 8（比官方少一个字段） |
| 16-23 | LUAC_INT | `78 56 00...` = `0x5678` | 标准 |
| 24-31 | LUAC_NUM | 370.5 | 标准 |

header 共 **32 字节**（官方 33，因为少了 sizeof(lua_Number)）。

- **指令 = 官方 4 字节**（`opcode(6)|A(8)<<6|C(9)<<14|B(9)<<23`）。header 里
  sizeof(Instruction)=`08` 只是骗过按标准 header 校验的工具；反汇编 `xlua.dll` 的
  `LoadCode`（`LoadFunction` 内）可见代码段按 `sizecode*4` 字节读入，即 4 字节指令。
- 反汇编 `xlua.dll` 的 `checkHeader` 确认：format 校验 `1`、checksize 4 个字段
  （`4,4,8,8`，无 lua_Number）、LUAC_INT `0x5678`、LUAC_NUM `370.5`。

### 反编译方法（可复现）

1. **正确解包**：`tools/extract-normalize.py` 用 UnityPy 读 TextAsset，用
   `ta.m_Script.encode('utf-8','surrogateescape')` 还原原始字节（`m_Script` 里的
   非法 UTF-8 字节被 Python 存成了 surrogate，如 `0x93`→`\udc93`），**二进制写盘**。
2. **归一化 header**：把 `format` 字节 `01`→`00`、`sizeof(Instruction)` `08`→`04`、
   在 offset 16 插入 `sizeof(lua_Number)=08`，得到标准 33 字节 header。
   输出到 `runtime/lua-normalized/`。
3. **反编译**：`tools/decompile-all.py` 用 unluac（支持 Lua 5.3）逐个反编译，
   输出到 `lua_tools/BlueoathLuaJP/`。

- 分析脚本：`tools/extract-normalize.py`（解包+归一化）、`tools/decompile-all.py`
  （批量反编译）、`tools/lua-strings.py`（字节码字符串检索）。
- 反编译器：unluac（`java -jar unluac.jar <file>`，已下载到
  `%TEMP%\opencode\unluac.jar`）。

## 目录结构（`runtime/lua-extract/`）

| 目录 | 内容 |
| --- | --- |
| `common/` | constants / functions / globalrefrence / custom_time |
| `config/` | 客户端配置（`clientconfig/*.lua`、`clientscript/*.lua`） |
| `data/` | 游戏数据（activity/guild/ship 等） |
| `event/` | 事件系统 |
| `fsm/` | 有限状态机 |
| `game/`、`game2d/` | 战斗/2D 逻辑 |
| `genluaapi/` | **xLua 生成的 C# 绑定**（`babeltime.*wrap.lua`） |
| `logic/` | 业务逻辑（`loginlogic.lua`、`serverlogic.lua`、`shipLogic` 等） |
| `net/` | **protobuf 库**（`protobuf/`）+ 生成的消息定义（`protobuflua/*_pb.lua`） |
| `service/` | 服务层 |
| `stage/` | 场景/关卡（`stagegamebase`、`stagemain` 等） |
| `system/` | 系统级逻辑 |
| `ui/page/` | UI 页面（`loginpage`、`server/serverpage`、`home`、`battle` 等） |
| `util/` | `platformmanager.lua`（SDK 封装）、`announcementmanager.lua` 等 |
| `xlua/`、`unityengine/`、`tolua.lua` | xLua 运行时桥接 |

顶层：`init.lua`、`check.lua`、`socket_net.lua`、`platformwrapper.lua`、
`event.lua`、`macro.lua`、`slot.lua` 等。

## 关键文件（登录 / 服务器列表 / 网络）

| 文件 | 角色 |
| --- | --- |
| `util/platformmanager.lua` | SDK 封装：`getServiceList`、`login`、`loginSuccess`、`getRoleId`、`getServerOpenTime` 等 |
| `logic/loginlogic.lua` | 登录逻辑：`ConnectServer`、`SendLogin`、`TArgLogin`、`GetCacheServerId` |
| `logic/serverlogic.lua` | 服务器逻辑：`GetServerNameById`、`serverNameTab` |
| `ui/page/loginpage.lua` | 登录页：`_SDKLogin`、`_SDKGetServerList`、`_SDKGetServerListCallBack`、`_OnServerSelect` |
| `ui/page/server/serverpage.lua` | 选服页：`_ChooseServer`、`getServiceList`、`serverList` |
| `socket_net.lua` | 网络层：`Connect`、`Send`、`ProtobufSerializer`、`SocketConnState` |
| `genluaapi/sdk.babeltimesdkmanagerwrap.lua` | xLua 绑定 C# `BabelTimeSDKManager` |
| `genluaapi/babeltime.net.netlogicwrap.lua` | xLua 绑定 C# `BabelTime.Net.NetLogic` |
| `net/protobuflua/*_pb.lua` | protobuf 消息定义（`TArgLogin`/`TRetLogin`/`user_pb` 等） |

## 服务器列表 entry 字段（关键：M5 待补的一环）

`getServiceList`（Lua 封装 C# `BabelTimeSDKManager.GetServiceList` → 原生
`new_sdk.getServerList`）返回 JSON。国服反编译源码 `util/platformmanager.lua`
的 `getServiceListAndAllServiceNotic` 明确解析结构：

```
result.root.notice          -- 公告
result.root.item[]          -- 服务器列表数组，每项字段：
  name            -- 服务器名
  serverIndex     -- 服务器序号
  new             -- 是否新服
  groupid         -- 服务器组 ID
  openDateTime    -- 开服时间
  status          -- 状态
  tj              -- 推荐标记（recommend）
  hot             -- 热度
  host            -- 连接地址 IP
  port            -- 端口
  recommend_weight-- 推荐权重
```

日服字节码 `util/platformmanager.lua` 同样含 `root`/`notice`/`item`/`serverIndex`/
`host`/`openDateTime`/`hot`/`recommend_weight`（与国服一致，仅无 `tj`），即**日服服务器
列表 JSON 结构与国服相同**（`result.root.item[]`）。此前误当作「日服特有字段」的
`serverId`/`ServerID`/`serverIp`/`flag`/`openTime`/`ready_open_weight` 实际来自**其它
函数**（`sendUserInfo` 用 `ServerID`、`getBrowseActive`/`GameAnnouncementState` 用
`serverId`、`getServerOpenTime` 用 `openTime`、SDK 登录响应用 `flag`），**不是服务器
列表 entry 字段**。`new_sdk.dll` 里的 `serverlist` 字符串是请求 URL 路径
（`POST /phone/serverlist/`）而非响应字段；SDK 不解析响应体，直接把原始 JSON 存进
内部全局 string 交给 Lua 解析。本地服务 `/phone/serverlist/` 应返回
`{"errornu":"0","root":{"notice":{...},"item":[{name,serverIndex,new,groupid,openDateTime,status,hot,host,port,recommend_weight}]}}`。

> 本地服务 `BlueOath.Server` 的 `/phone/serverlist/` 响应应据此字段构造，替换
> 此前临时猜测的 `serverid/servername/ip/port/status/state`。

## 登录流程（Lua 侧）

```
loginpage._SDKLogin                        -- SDK 登录（new_sdk.login，已 bypass）
  └─ loginpage._SdkLoginSuccess / _LoginOk  -- 登录成功回调
loginpage._SDKGetServerList                -- 拉服务器列表（getServiceList）
  └─ _SDKGetServerListCallBack / _GetLastServiceListSuccess  -- 解析 serverlist
loginpage._OnServerSelect / serverpage._ChooseServer         -- 选服
loginlogic.ConnectServer(host, port)       -- 连接游戏服务器（NetLogic.Connect）
loginlogic.SendLogin                        -- 发 TArgLogin { Pid, Uid, Uname }
  └─ socket_net.Send / ProtobufSerializer   -- 走 KCP/UDP（C# LogicSocketClient）
```

C# 侧对应（`BabelTimeSDKManager`，RVA 均 JP/CN 两套）：

| C# 方法 | JP RVA | 作用 |
| --- | --- | --- |
| `GetServiceList` | `0x2D0530` | 发起服务器列表请求（内部调 `Platform.getServerList`→原生 `new_sdk.getServerList`，返回状态码 1） |
| `GetLastServiceList` | `0x2CF960` | 读回 SDK 内部缓存的服务器列表字符串 |
| `SelectService` | `0x2D3780` | 选定服务器（按 `groupid`） |
| `Login` | `0x2D1870` | SDK 登录（→ `new_sdk.login`） |

> 注意：`getServerList` 只返回状态码，服务器列表经 `GetLastServiceList` 读回，
> `SelectService` 选服后才有连接地址。payload 目前只手动触发了 `Login` +
> `GetServiceList`，**未驱动 `GetLastServiceList`/`SelectService`/`ConnectServer`
> 这条 Lua 状态机**，因此游戏尚未发起 KCP 连接。

## 网络层

- `socket_net.lua` 用 `net.ProtobufSerializer` + `net.ProtobufTypeManager`
  （`net/protobuf/*` 自带的 protobuf 编解码）。
- 连接参数 `host` + `port`，状态机 `SocketConnState{Disconnected, Connecting,
  Connected, Disconnecting}`。
- 底层 C# `BabelTime.Net.NetLogic`（`genluaapi/babeltime.net.netlogicwrap.lua`）。

## 对后续推进的意义

1. **服务器列表字段已确认**，本地服务 `/phone/serverlist/` 可按 `groupid/port/
   status/flag/serverId/serverIp/recommend_weight/openTime/name` 构造响应，替掉
   临时猜测字段。
2. **登录/选服/连接流程已串起来**，Lua 侧 `ConnectServer(host,port)` + C# 侧
   `LogicSocketClient` 对应关系明确。
3. 若要完整可读逻辑，下一步需写 Lua 5.3 变体（Instruction 8 字节）反编译器，
   或改用标准 Lua 5.3 反编译器并适配 header。
