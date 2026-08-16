# Lua 代码资料库（苍蓝誓约 JP 1.4.0）

> 由 AssetBundle 提取 + 字符串级静态分析生成。Lua 源码已编译为字节码，本资料库
> 记录可提取的结构信息（目录、关键文件、字符串常量、登录流程、服务器列表字段）。
>
> **重要：已有国服（CN）完整反编译 Lua 源码**，位于
> `lua_tools/BlueoathLua/`（1397 个可读 `.lua` 文件，覆盖 `logic/`、`UI/`、
> `util/`、`net/`、`genluaapi/` 等）。国服与日服是同一款游戏，核心游戏逻辑（登录、
> 网络、选服、数据类）基本一致，可直接对照参考；日服特有差异（SDK `new_sdk.dll`、
> 服务器列表 JSON 字段、服务器地址）需结合字节码字符串常量交叉确认。

## 提取方式与现状

- Lua 逻辑打包在 Unity AssetBundle `StreamingAssets/bundles/share/lua/*` 里，
  为 **TextAsset**（`assets/generatedfiles/lua/32bit/...`）。
- 共提取 **1526 个 .lua 文件**（约 11.6 MB），落地在 `runtime/lua-extract/`。
- Lua 是**编译后的字节码**（Lua 5.3 变体，自定义 header：format=`0x01`、
  Instruction 尺寸 `0x08`，非官方 format），**非明文**。字符串常量（类名/方法名/
  局部变量名/JSON 字段名）可直接提取；完整逻辑需自写反编译器（Instruction 为
  8 字节的变体）。

## 字节码格式（已确认部分）

header（33 字节）：

| 偏移 | 内容 | 值 |
| --- | --- | --- |
| 0-3 | 签名 | `1B 4C 75 61`（`\x1bLua`） |
| 4 | 版本 | `53`（Lua 5.3） |
| 5 | format | `01`（非官方，官方为 `00`） |
| 6-12 | LUAC_DATA | `19 0D 0D 0A 1A 0D 0A`（7 字节，含 CRLF） |
| 13-16 | sizeof | `04 04 08 08`（int=4, size_t=4, Instruction=8, lua_Integer=8；lua_Number 省略，隐含 8） |
| 17-24 | LUAC_INT | `78 56 00...` = `0x5678` |
| 25-32 | LUAC_NUM | 370.5（double） |

字符串（源码名用 flag+string，常量用 type+string）：

- 源码：`flag(1) [0=无/1=有] + len(1=strlen+1) + data(strlen)`，无 NUL。
- 常量字符串：`type(1) + len(1=strlen+1) + data(strlen)`。

常量类型（1 字节 tag）：`0`=nil、`1`=bool、`3`=num(float, 8B)、`0x13`=int(8B)、
`4`=短字符串、`0x14`=长字符串。

函数原型（顶层 chunk）字段顺序：

```
source(flag+string)  linedefined(i32 LE)  lastlinedefined(i32 LE)
numparams(u8)  is_vararg(u8)  maxstack(u8)  sizecode(i32 LE)
code(sizecode × Instruction)  sizek(i32)  constants  sizep(i32)  protos
sizeupvalues(i32)  upvalue描述  debug(sizelineinfo, lineinfo, sizelocvars,
locals, sizeupvalues, upvalue名)
```

- debug 段已确认：`sizelineinfo(i32) + lineinfo[i32] + sizelocvars(i32) + locals
  (name+startpc+endpc) + sizeupvalues(i32) + upvalue 名(string)`，均为 4 字节 LE。
- 主 chunk 固定 1 个 upvalue `_ENV`（debug 末尾可看到 `_ENV` 字符串）。

**尚未破解**：Instruction 的具体位布局（8 字节 64 位变体）与 `sizek` 等计数字段
的精确边界。`check.lua`（仅 1 条 `RETURN`，195 字节）的 code 为
`26 00 00 00 00 00 00 01`，说明 opcode 在低 6 位（`0x26`=RETURN）、A=0、B=1 在
最高字节（bits 56-63），但该布局与 `activityssrdata.lua`（sizecode=17）的 code
段（57 字节）对不齐，存在「17 条指令放不进 code 段」的矛盾，需进一步定位
fork 的指令编码（疑似「64 位指令集」第三方修改版）。

> 已尝试 `lua_tools/cLuaDecompiler.exe`（Coldzer0/LuaDecompiler，支持 5.1-5.5 +
> `--opcode-table`），对日服字节码报 `invalid LUAC_DATA in 5.3 header`（自定义
> LUAC_DATA 7 字节 + Instruction 8 字节，非官方格式），无法直接反编译。
> **再试「归一化 header」**：把 header 改成标准 5.3（format=0x00、LUAC_DATA 6 字节、
> sizeof 5 字节）后，反编译器能过 header；但 Instruction 设 4 时在 offset 191
> 报 `unknown constant type 0x5`（code/常量错位），设 8 时直接报
> `only 4-byte instructions supported`。**由此确认日服 Instruction=8 字节**，
> 该反编译器硬编码 4 字节、无法处理 8 字节指令。
> **但已有国服反编译源码（`lua_tools/BlueoathLua/`）可直接对照，无需再破解日服
> 指令编码**；日服特有差异仅需字节码字符串常量交叉确认。
- 分析脚本（可复现）：`tools/extract-lua.py`（UnityPy 解包，依赖 `pip install
  UnityPy`）、`tools/lua-strings.py`（字节码字符串提取 + 关键词检索）。

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
