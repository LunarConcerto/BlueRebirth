# 苍蓝誓约（JP 1.4.0）本地复原 — 阶段总结

> 记录至当前会话为止的全部工作、进度与主要矛盾点。

## 一、项目目标与总体架构

**目标**：让日服客户端 `blueoath.exe`（1.4.0）离线运行，连到本地服务器（`127.0.0.1`，KCP/UDP 7201），完成可重复的「登录 → 服务器列表 → 选服 → 游戏 socket 登录」闭环。

**已验证的二进制（SHA-256）**：

- `GameAssembly.dll` `8AEE607813A759E047D81C2428990609322DE072437DD4597F80E8E3FAD1D404`
- `UnityPlayer.dll` `88C45E6394C4C42F6698319C9B85D29C1AB461F8EBD6284CA9EE931F2050D63D`
- `new_sdk.dll`（联云/lianyun SDK）`1CF7BF8C8B25C3C7F26F839AE8A4D32F1D3A4966ECCC826C8669C8AB5759DB0B`

**基础设施（均已就位）**：

| 组件 | 作用 |
| --- | --- |
| `BlueOath.Server` | 本地 TLS/HTTP/KCP 服务器（登录 + 服务器列表 + KCP 游戏登录，端口 7201） |
| `BlueOath.Injector` + `BlueOath.Payload` | x86 注入 DLL（xinput 劫持）：SDK 边界 hook、网络重定向（DNS/connect/TLS）、TLS 信任补丁 |
| `BlueOath.Tools` | IL2CPP 元数据解析、methodPointers 定位、RVA 目录 |
| `lua_tools/BlueoathLua` | 国服 1.5.20 反编译 Lua 源码（交叉验证用） |

## 二、已完成的里程碑（M1–M4）

| 阶段 | 状态 | 关键成果 |
| --- | --- | --- |
| M1 配置数据目录化 | ✅ | `config_*.db` XOR 0x55 解码、逐表字段/哈希、序章 0-4 基准 |
| M2 IL2CPP 消息类型 | ✅ | registration RVA `0x01b1b878`、`TArgLogin`/`TRetLogin` 字段与 protobuf tag 解析 |
| M3 协议 ID 与事件映射 | ✅ | `SocketService.Login`→`LogicSocketClient.Send` 操作码 2；11 字节头 + protobuf codec 已实现并通过测试 |
| M4 Wire Format | ✅ | **游戏逻辑走 KCP over UDP**（非 TCP）；KCP 24 字节头 codec + ARQ 可靠性层已实现并单测通过 |
| TLS 信任补丁 | ✅ | `UnityPlayer.dll` `0x8E1573` 处 `and eax,0xFFFFFFF7` 掩码 NOT_TRUSTED（旧补丁点在日志分支、无效，已纠正） |

**登录是两段式**（M5 确认）：

1. SDK 登录（`BabelTimeSDKManager.Login 0x2D1870` → `new_sdk.login`）
2. 游戏 socket 登录（服务器列表 → 选服 → `SocketService.Login 2281232` → `LogicSocketClient.Send` 操作码 2，KCP/UDP）

## 三、两条技术路线的现状

### 路线 A：Bypass SDK + 直接驱动 C# 方法（`-BypassSdk`）

payload hook `new_sdk.dll` 全部导出，`HookTickLoop` 手动派发假 SDK 事件（init=1 / switch=27 / platform=1007 / login=2 …），并**直接调用 C# 方法**打通链路：

```
GetServiceList(0x2D0530) → GetLastServiceList(0x2CF960, /phone/loginrole/)
→ SelectService(0x2D3780) → getHash(拦截) → Connect(0x2A2770)
```

**卡点**：`Connect` 崩溃 —— `NetLogic.mono`（静态字段 `0x11d30bc8`）为 **NULL**。

### 路线 B：只重定向（redirect-only，本会话切换）

去掉 `-BypassSdk`，让游戏正常场景流程跑（让 Unity 创建 NetMono），payload 只做网络重定向。

**卡点**：游戏卡在 SDK bootstrap（`getPlData`→`login` 之间），SDK 异步回调不派发。

## 四、关键逆向成果（本会话新增）

### NetLogic 对象图（解释路线 A 卡死的根因）

```
NetLogic.mono  (静态字段 @0x11d30bc8, 类型 NetMono)   ← 运行时为 NULL
   └─ .netService  (NetMonoBase 字段, 类型 NetMixService, 偏移 0x5c)
        └─ [0]  (连接对象)
```

- `NetLogic` 只有一个字段 `mono`；`NetMono`/`NetMonoBase` 是带 `Update/Start/Init` 的 **MonoBehaviour 式类**。
- 搜遍整个 `.text` 段：**没有任何指令写 `0x11d30bc8`**（`89 05/C7 05` 等所有写形式都无），字段落在 `.data` 零初始化区。
- 结论：`mono` 由 **Unity 场景系统**创建（挂在 GameObject 上的组件），不是 IL2CPP 代码能写的。所以「做法 2 直接写字段」不成立——它不是一个可写的 host/port 字符串，而是一个需要场景生命周期的 MonoBehaviour 实例。
- 另确认：`NetLogic.Connect(host,port)` 方法体**根本不读 host/port 参数**，尾跳 `0x2a4990` 才读 `[ebp+0xc]`（host）。

### 关键 RVA 目录（GameAssembly.dll，ImageBase `0x10000000`）

```
# NetLogic
Init=0x2A2C70  Connect=0x2A2770  Disconnect=0x2A2A40  InitLuaCallbacks=0x2A2BB0  Cleanup=0x2A26E0
# BabelTimeSDKManager
Login=0x2D1870  GetServiceList=0x2D0530  SelectService=0x2D3780  GetLastServiceList=0x2CF960
# SDKConfigGetter
GetConfig=0x2E07E0  SetConfigResult=0x2E0860  Update=0x2E0CC0
```

### new_sdk.dll（联云 SDK）逆向

```
导出: initSDK=0x3A780  login=0x3A850  tickLoop=0x3AA40  getServerList=0x3AB60
      getHash=0x3AC80  getVersionInfo=0x3B730  callUniversalWebFunction=0x3D210
      callUniversalFunctionWithBack=0x3D2C0
URL:  /login?  /gethash/?  /gethash.php  /phone/serverlist/  /phone/loginrole/
      /phone/getversion/  /phone/getPlData/getPlData/  /phone/switch/getstate  /phone/applereview/  /c.gif  index.php?
字段: errornu errordesc newuser uid Pid ServerID UID qid uuid packageVersion
回调事件: PLFUNCTION(平台数据)=1007, getversion=5, login=2, switch=27, applereview=19
```

**关键发现**：`callUniversalWebFunction` 返回 **int 状态码**（不是字符串，日志为 `<unreadable>`），getPlData 的响应本应由 SDK 异步回调派发 event 1007，但**本地永远不派发**。且 SDK 内**不含**平台数据字段名（`networkCheck/screenWidth/…`），说明 SDK 不解析平台数据、只应透传原始响应——但这条异步链在本地断了。

### 本地服务器新增端点（本会话）

`/phone/getversion/`、`/login?`、`/gethash`、修正 `/phone/getPlData/getPlData/`（返回完整平台数据）。

## 五、当前主要矛盾点

1. **路线 A 死锁**：绕过 SDK 直接调 C# 方法 → 跳过了 Unity 场景流程 → `NetLogic.mono`（NetMono 组件）永远是 NULL → `Connect` 空指针崩溃。而 `mono` 无法通过「写字段」补上（无写路径、需场景上下文）。

2. **路线 B 死锁**：SDK 的异步回调派发（switch 27 / applereview 19 / getPlData 1007 / getversion 5 / login 2）在本地重定向环境下**不稳定/不完整**。已做 hybrid 补丁（手动派发 event 1007），游戏能推进到 `getversion`，但——
   - **非确定性**：同样代码，一次运行推进到 getversion（11 个请求），另一次只到 getPlData（5 个请求）。
   - `getversion` 返回 501（已加 handler 待验证）、`switch` 返回 `errornu="-1"`（响应格式仍不对）。

3. **根本张力**：走 SDK 真实异步链（路线 B）→ 依赖一个本地环境里不可靠的异步回调；绕过 SDK（路线 A）→ 拿不到 Unity 场景创建的 NetMono 组件。

## 六、下一步可选方向

1. **补齐路线 B 的 SDK 响应**：修 `getversion`/`switch` 响应格式，并解决异步回调的非确定性问题（可能需把 switch/applereview/getversion 也像 getPlData 一样手动派发）。
2. **探究「谁在什么时候创建 NetMono」**：确认 NetMono 在哪个场景/脚本 Awake 里挂载，尝试在 bypass 模式下补触发（但大概率仍需 Unity 场景上下文）。
3. **换底层入口连**：绕过 `NetLogic.Connect` 这层，直接驱动 `LogicSocketClient`(0x3B79D0 附近)/`KcpLogicSocket` 的底层连接（仍需弄清实例状态与参数）。


## 七、debug 开发者通道深挖（会话新增）

### 7.1 运行时调试控制台

- 游戏内置两套控制台：第三方 `Opencoding.Console.DebugConsole`（含命令输入框 InputField）和 `BabelTime.RuntimeConsoleLite`。
- **打开手势**：三指长按 ≈1 秒（`ConsoleRecognizer.Update` 里 `Input.touchCount==3` 且按住超过 `RECO_TIME=1.0`）。
- PC 上「手指」由 `FingerGes.FGMouseInputProvider` 用**鼠标三键（左/右/中）模拟**，即同时按住三键 1 秒。
- 控制台显示方法：`DebugConsole.ShowConsoleInstantly`（RVA `0xD2FD30`，实例方法）、`get_Instance`（`0xD307D0`）、`set_IsVisible`（`0x10D30A20`）。
- 实测 hook 调用 `ShowConsoleInstantly`：链式读 `g[0x11d269c4] +0x5c +0x20` 得到 `DebugConsole.Instance`，但值为 **NULL**——因为控制台 MonoBehaviour 也是场景加载时才创建的。

### 7.2 切服/切平台调试开关

- `DebugConfig.m_switch_ServerPlatform` 类型为枚举 **`SwitchServerAndPlatform`**：`China_Debug_Android / China_Debug_iOS / Japan_Debug_Android / Japan_Debug_iOS`。
- 与 SDK 配置里的 **`host_debug`**（日志里出现过 `debug.blueoath.com`）是同一套 debug 服机制。

### 7.3 SDK 模拟登录模式（真正的「短登录通道」）

- `isDebug()`（`new_sdk.dll` `0x3C7B0`）**恒返回 1**（debug 恒开）。
- config 里 `isSimulation=1` + `simulateHashHost=<url>` → 登录被跳过（`is simulation, skip login`），hash 直接来自 `simulateHashHost + "/gethash.php"`（`getHashBySimulation`）。
- 登录对象全局 `0x1005EF54`：`[+0x128]`=isSimulation(byte)、`[+0x12C]`=simulateHashHost(std::string)。
- 已实现运行时 patch（`TryPatchSimulationMode`）+ 服务器 `/gethash.php` 端点；getPL/getOS 在模拟模式下改读 `[+0x144]/[+0x15C]`，需同时调 `setSimulationInfo`（`0x3CE20`）填充 pl/os/pid。

### 7.4 NetMono 是时间问题（但触发条件微妙）

- 轮询 `0x11d30bc8`：有一次运行在 ~10s 变成 `0x18DE5470`（非空），证明 **NetMono 确实会被创建，只是晚于 Connect(~6s)**。
- 但改成「等 NetMono 再 Connect」后，后续多次运行 NetMono **始终 NULL**——说明 NetMono 的创建不是单纯靠时间，而是由**登录页场景加载**触发，而场景加载在 bypass 模式下不可靠（甚至可能是 Connect 崩溃触发的场景重载/恢复）。

### 7.5 SetConfigResult 链路已确认

- `BabelTimeSDKManager 启动` → `GetConfig(0x2E07E0)` → `callUniversalWebFunction(1007,"getPlData/getPlData")`。
- `OnCallBackImpl` 里 `cmp esi,0x3ef(1007)` → `SetConfigResult(0x2E0860)`。
- **hook 抓到**：我手动派的平台数据（`errornu:0`）确实到达 `SetConfigResult`（payload 格式正确）；但 **SDK 自己的 getPlData 处理会派发 `errornu:-1`**（其响应解析失败，期望的响应格式与我服务器返回的不一致）。

## 八、收敛后的核心卡点

**唯一根卡点**：`getPlData(平台数据) → 加载登录页场景` 这一跳没打通。

```
getPlData → event 1007 → SetConfigResult(errornu:0 已收到) → 标记配置完成
        → (User.sdkfinish 事件?) → 加载登录页场景
                                    ├─ NetMono 创建（mono 字段填充，Connect 才能过）
                                    └─ DebugConsole 创建（控制台才能打开）
```

场景一加载，NetMono 和控制台就都有了，Connect 空指针、控制台打不开会一并解决。当前卡在 SetConfigResult 之后「配置完成 → 场景加载」这一段；且 SDK 自派 `errornu:-1` 与手派 `errornu:0` 存在竞争，运行间非确定性明显。

## 九、下一步方向

1. **深挖 SetConfigResult 内部 + `User.sdkfinish` 事件的消费者**，找到「配置完成 → 加载登录页场景」这一跳，把它补上。
2. **搞清 SDK getPlData 期望的响应格式**（为什么 SDK 派 `errornu:-1` 而不是 `errornu:0`），让它和手派不再竞争。

## 十、NetMono 结构与真实卡点（会话新增）

### 10.1 NetMono 是纯 C# MonoBehaviour（不经 Lua）

- 类型链：`BabelTime.Net.NetLogic`(9273, 唯一字段 `mono`=NetMono) / `NetMono`(9274) / `NetMonoBase`(9275) / `NetMixService`(9283)。
- `NetMonoBase` 字段：`cachedTransform`、`cachedGameObject`、`<netService>k__BackingField`（netService 在 `[+0x5c]`，前面是 MonoBehaviour 原生头 0x54 字节）。
- `NetMono` 方法：`.ctor/Update/Start/CheckInternet/OnApplicationPause/Init`。**Start() 只做 `InvokeRepeating("CheckInternet",1.0f,1.0f)`**，不写 mono；`Init()`(实例) 读 `[0x11D30BD4]`/`[0x11D30AE4]` 两个静态字符串，`new NetCore` 存 `[this+0x14]`。
- Lua 源码里搜不到 `NetMono`（tolua 未暴露），它是 Unity 场景/`AddComponent` 创建的。

### 10.2 mono 字段只能通过反射写（无直接写路径）

- 全 `.text` 段对 `0x11D30BC8` 的 35 处引用**全部是 `mov eax,[0x11D30BC8]`（读）**，后跟 `mov eax,[eax+0x5C]`（读 netService）；**0 处写**（`89 05`/`C7 05`/`A3`/`C6 05` 均无）。
- GameAssembly 里**没有 "NetMono" 字符串字面量**（无 `AddComponent("NetMono")`/`GetField("mono")` 字符串反射）。
- 结论：`NetLogic.mono = this` 的赋值在编译产物里不存在，由 `il2cpp_field_static_set_value`（运行时反射 SetValue）或 Unity 序列化机制间接触发。

### 10.3 真实卡点：SDK init 之后没走到 login（场景根本没触发）

最新 redirect 模式日志的稳定序列（configStr 已写入 `errornu:0`，但 **NetLogic.instance 在 5/10/15s 始终 NULL**）：

```
getPlData(event1007, errornu:0) → SetConfigResult → configStr ✓
getversion(event5, errornu:0) ✓
switch(event27) → errornu:-1   ← SDK 自派（GetErrorMsg+SendLog，非致命，只记日志）
retention(event9) ✓
(无 event2/login)  ← 卡在这里，new_sdk.login 从未被调用
```

即：**SDK 的 HTTP 初始化检查都完成了，但 `login` 从没被调用**，于是登录页场景（创建 NetMono）永远不加载。`switch` 的 `errornu:-1` 只是记一条错误日志（`OnCallBackImpl` 里 `SDKHelper.GetErrorMsg(27)` + `SendLog`），不是阻塞点。

### 10.4 下一步

1. **找 login 触发条件**：`BabelTimeSDKManager.Login`(0x2D1870) 由 Lua `PlatformWrapper:login()` 调用；追踪 SDK init 完成后的「自动登录」条件（`SDKInitFinish`、`OnCallBackImpl` 里 `PostNotification(200052)` 通知、或 Lua 启动流程）——为什么 redirect 下没触发。
2. 若确认 login 是 Lua 侧在等某个事件（如 200052 通知未发出），补上该通知即可让整条链路自然推进到场景加载、NetMono 创建。

## 十一、场景加载的真正触发点：StageLaunch.StartGame（会话新增）

### 11.1 场景切换链路已定位

- `BabelTime.GD.StageLaunch`(10239) 是 C# 启动场景，`StageTick`(0x1EC000) 内是资源卸载状态机（state 0-4）。
- **`StageLaunch.StartGame`(0x1EC180, virtual) 就是转登录场景的方法**，反汇编确认其执行序列：
  1. `mov [this+0x24], 5`（置终态）
  2. `PScrObjIniter.get_Instance`、`InitSound`(0x1EBE20)、`InitSoundSetting`(0x1EBAD0)
  3. **`call BabelTimeSDKManager.Start`(0x2D4750)**（触发 SDK init，0x1EC455 处）
  4. UI 检查：`push [0x11D269A4]; push 0; call 0x1112AF60` → `test eax,eax; je 跳过`
  5. 检查通过则 `StageMgr.get_Ins`(0x1ED5F0) → 虚调 `StageMgr.Goto(1=eStageLogin, ...)`（**加载登录场景 → NetMono 创建**）
- 即 **场景加载（NetMono）由 `StartGame` 末尾的 `Goto(eStageLogin)` 触发，且被第 4 步的 UI 检查（字符串 `[0x11D269A4]`）门控**。

### 11.2 其他关键确认

- `BabelTimeSDKManager.Start`(0x2D4750) 是 **static** 方法（flags 0x0096），被 `StageLaunch.StartGame`(0x1EC455) 和 0xA64BB7 两处调用；它内部经 `SimpleLuaClient.get_luaEnv`(0x101E9F40) 调 Lua 函数（`[0x11D1B584]`/`[0x11D3D1AC]`）。
- `SDKInitFinish` 属性 getter=0x2D5000 / setter=0x2D5110，**均无直接调用者**（走 tolua/反射）；backing field 在 `[SDKManager 实例 +0x38]`。
- `OnCallBackImpl`(0x2D1930) 事件分发 `cmp esi,id`：19/99/29/2/98/14/27/31/1007 —— **没有 event 1(init) 和 5(getversion)**（这两个走别的回调路径）。
- `StageMgr.Goto`(0x1ECD80) 无直接调用者（virtual，经 Lua `CSharpStageMgr:Goto`）。

### 11.3 下一步（聚焦 StartGame 门控）

1. **确认 StartGame 是否被调用 / 卡在第几步**：给 `StageLaunch.StartGame`(0x1EC180) 加诊断 hook（仿 `GetServiceList` trampoline），记录它是否进入、SDK init 调用后 UI 检查（`[0x11D269A4]` 字符串）返回什么。
2. **读出门控字符串**：把 `[0x11D269A4]`/`[0x11D269C8]` 加进 payload 的 `TryLogJpSdkStringSlots`，运行时读出它到底是哪个 UI 页名，判断门控条件。
3. 继续验证「切服 Debug 服」这条原生通道是否能触发一次完整的重新初始化（含场景加载）。

## 十二、通用启动流程追踪：真实卡点已定位（会话新增）

### 12.1 通用 hook 机制

- 新增 `InstallTraceHook`：批量给 (name, rva, stolenLen) 装 trampoline，动态生成 stub（`pushad; push hookId; mov eax,LogTraceHook; call; popad; jmp stolen`），`LogTraceHook` 打 `TRACE[n] enter <name>`。
- 24 个节点已挂钩（StageMgr/StageLaunch/StageLogin/NetLogic/SDKManager/SDKConfigGetter），另加 `StageMgr.Goto` 专用 hook 捕获 `stageId`。

### 12.2 实测启动流程（redirect 模式，稳定）

```
StageMgr.Tick (第1~2帧)
-> BabelTimeSDKManager.Init (SDK init, event 1 完成)
-> SDKConfigGetter.GetConfig (getPlData)
-> StageMgr.Goto(stageId=5 = eStageLaunch)
-> BabelTimeSDKManager.OnCallBack (event 9 retention)
-> StageMgr.Tick (第3帧)
-> StageMgr.DelayGoto
-> StageLaunch.StageEnter   <- 启动场景已进入
-> 【主线程冻结】StageTick 状态机从未运行，StartGame 从未调用
```

**结论（推翻之前的判断）**：
- SDK init 能完成（event 1 正常派发），不是卡点。
- `StageMgr.Goto(eStageLaunch)` 正常调用，不是卡点。
- 真正的卡点：`StageLaunch.StageEnter`（只把 state 置 0）之后、`StageTick`（资源加载状态机）之前，主线程冻结。
- `StageTick`(0x1EC000) 是 virtual 方法，全 `.text` 无 direct call/jmp，走 IL2CPP shared generic vtable 分发（`StageMgr.Tick` 里 `[vtable+0x64]` + rgctx 校验，经 `call 0x283010` 助手），所以 hook 0x1EC000 不触发是正常的。

### 12.3 下一步

1. 定位冻结点：在 StageMgr.Tick 的 vtable 分发（`[0x11D2DF94]` rgctx / `0x283010` 助手）还是 StageTick state 0（读 `[0x11D2C42C]`/`[0x11D269C8]` 两个单例，raw NULL 会访问违例）。
2. 检查这两个单例是否为 NULL、`0x283010` 助手内部逻辑；若 state 0 因单例 NULL 崩溃则补上该单例或 patch 判空。

### 12.4 StageTick 走「shared generic method」分派（会话新增，确认卡点方向）

- `StageMgr.Tick`(0x1ED170) 里调用的助手实际是 **`StageTickDispatchHelper`(RVA `0xC08360`)**（之前笔误成 0x283010），它就是 StageTick 的分发器。
- 助手逻辑：`[this+0xC]` 缓存命中则返回；`[this+0x10]` 标志为 0 则返回；`[this+8]` 空则返回；否则 `mov eax,[arg3+0xC][+0x60][+0x10]` 取方法指针 → `mov eax,[eax]` 解引用 → `call eax`。
- 实测方法指针链：`[0x11d22f1c]` 在启动早期为 NULL，**会自初始化**（进入 helper 时已是 `0x1A01D868`）；链最终解引用出 **`GameAssembly.dll+0x1435D30`**。
- **`0x1435D30` 是 IL2CPP 的「universal shared method」分派器**（shared generic method 的通用入口）：读 MethodInfo → `call 0x10423220` 做 rgctx 查表 → `mov edi,[edi+eax*4+0x10]` 取出真正方法指针（+1 编码）→ 调用。
- 结论：**StageTick 不是直接调用，而是走 shared generic 分派（StageLaunch 继承自泛型基类 `StageBase<T>` 导致）**，这解释了 hook `0x1EC000`（StageTick 函数体）不触发的原因。冻结发生在这个 shared 分派 → StageTick state 0 这条链上，用户判断「问题在 vtable 分发而非单例」成立。

### 12.5 下一步

1. 反汇编 `0x1435D30` 后半段找到真正 `call` 方法指针处，确认解引用出的 StageTick 实际地址、以及 `0x10423220`（rgctx 查表）是否返回了正确指针。
2. 若查表正常、StageTick 实际被调到 `0x1EC000`，则冻结在 StageTick state 0（读 `[0x11D2C42C]`/`[0x11D269C8]`），需在 state 0 入口 hook 捕获这两个单例的实时值确认。

## 十三、硬 bypass 尝试与最终收敛（会话新增，本轮结束点）

### 13.1 关键修正：状态机根本没跑，null guard 白打

- 给 shared 分派器 `0x1435D30` 的 `dec edi`（0x1435DB7）加捕获 hook，结果 **0 次触发** —— 即 `0x1435D30` 根本没被调用。
- 结合「StageEnter 已进、StageTick 没跑」：**冻结点在 Goto(eStageLaunch) → 状态机分派之间，比 state 0 更靠前**。
- 因此之前 patch 的 `test byte [eax+0xC2]` → `test eax,eax`（打 `0x1EC05B`）和 checkArg2 trampoline（打 `0x112AF60`）**都打在从未执行到的代码上，无效**。
- 真正分派链断点：`StageMgr.Tick → helper(0xC08360) → 检查 [StageMgr+0x10] 标志 → call eax → 0x1435D30 → state 0`，其中 helper 因 `[this+0x10]` 标志为 0 而提前 return 的可能性最大（尚未 hook 确认）。

### 13.2 state 0 读的两个单例是「场景 MonoBehaviour 泛型单例」

- `[0x11d2c42c]` / `[0x11d269c8]` / `[0x11d269a4]` 全 `.text` 只有读（`mov eax,[..]; test byte [eax+0xC2],1` = Unity 假空检查）、没有写 → 走 `Tsingleton<T>` 泛型单例机制（赋值经泛型静态字段通道，非直接写）。
- 实测 `[0x11d22f1c]`（分派链）会自初始化，但这三个**场景单例一直是 NULL**（场景没创建 MonoBehaviour）。
- 冻结是**原生访问违例**（`throw NullReferenceException` hook 全程未触发，排除托管异常）。

### 13.3 硬 bypass（手动构造对象图）——已写、卡在 classFromName

**对象图（已确认）**：`[0x11D30BC8]=mono(NetMono) → [mono+0x5C]=netService(NetMixService) → [netService]=conn`。

**已实现的 `TryManualNetLogicSetup()`**（trigger 移到 SDK event 1 之后，避免早期运行时未初始化）：
1. `il2cpp_class_from_name` 拿类 → `il2cpp_object_new` 造对象。
2. 写 `[mono+0x5C]=netService`、`[0x11D30BC8]=mono`。
3. 调 `NetLogic.Init`(0x2A2C70) + `NetLogic.Connect`(0x2A2770, host, 7201)。

**卡点**：`il2cpp_class_from_name` 拿不到类 —— `"Assembly-CSharp"`/`"Assembly-CSharp.dll"`/`"Assembly-CSharp-firstpass"` 全返回 null，`nullptr`（搜全部）崩溃。metadata v24 的 images 表结构与本机记忆不符（imagesSize=22568，36/40/52 字节 stride 均不整除，读出程序集名乱码），确定不了真正程序集名。

### 13.4 本轮关键地址目录（已全部验证可用）

```
# il2cpp 导出（GameAssembly.dll）
il2cpp_class_from_type   = 0x162C8F0   (thunk -> 0x1600310 -> 0x163C260)
il2cpp_class_from_name   = 0x162C900
il2cpp_class_get_name    = 0x162CA00
il2cpp_class_get_namespace=0x162C870
il2cpp_field_static_set_value = 0x162CC80
il2cpp_object_new        = 0x162D050
il2cpp_string_new        = 0x162D630

# NetLogic（BabelTime.Net）
Init=0x2A2C70  Connect=0x2A2770  Disconnect=0x2A2A40  InitLuaCallbacks=0x2A2BB0
# StageLaunch
StageEnter=0x1EBFF0  StageTick=0x1EC000  StartGame=0x1EC180
# StageMgr
Goto=0x1ECD80  Tick=0x1ED170
# 分发
StageTickDispatchHelper=0xC08360  universal shared dispatcher=0x1435D30（查表在 0x1435DB3）
# 单例字段
[0x11D30BC8]=NetLogic.mono  [0x11d2c42c]/[0x11d269c8]/[0x11d269a4]=场景单例  [0x11d22f1c]=分派链根
```

### 13.5 未解决 & 下次可做的

1. **确定 `il2cpp_class_from_name` 的正确程序集名**（或改用 `il2cpp_class_from_type`，从 types 表 `pointers[3]=0x1179E008` + 类型定义 typeIndex 拿 `Il2CppType*`），打通硬 bypass 的对象创建。
2. **hook helper `0xC08360` 入口读 `[this+0x10]` 标志**，确认状态机没跑是不是因为标志为 0。
3. 根本矛盾仍在：redirect 模式下 Unity 场景系统没把那些 MonoBehaviour 单例创建出来，场景加载为何不完成是最终的深水区。

### 13.6 本轮方法论教训

- **静态反查 IL2CPP 元数据结构性价比极低**（fieldOffsets 运行时才初始化、metadataUsage 编码对不上、images 表结构不明）；**运行时 hook 读内存才是正道**。
- **每加一个 hook 可能扰动时序**，导致冻结点漂移（frame 1 ↔ frame 3），诊断和功能 patch 要拆开验证（已做：`[debug] diagnostics` 开关 + `TryApplyStageTickNullGuardPatch`）。
- **「满足自然流程」是无底洞**（场景加载是黑盒）；**硬 bypass（手动构造对象图）是有终点的方向**，但被 classFromName 这个小坑挡住，尚未验证可行性。

### 13.7 il2cppdumper 完整符号表已到手（决定性进展）

跑通了 `Il2CppDumper-x86.exe`（Metadata/Il2Cpp Version 24，CodeRegistration `0x11b1b73c`、MetadataRegistration `0x11b1b878`），产物在 `E:\逆向工程\苍蓝誓约项目\il2cppdump\`：
`dump.cs`(19.8MB)、`script.json`(57.5MB，地址→方法名)、`il2cpp.h`(30.9MB)、`stringliteral.json`、`DummyDll/`。

**程序集名确定**：主程序集是 `Assembly-CSharp.dll`（image 62，TypeDefIndex 5599~11579）。`NetLogic`/`NetMono`/`NetMixService` 均在命名空间 `BabelTime.Net`。

**精确对象图**（dump.cs 字段偏移 + 反汇编核对）：

```
NetLogic.mono (static @0x11D30BC8) → NetMono : NetMonoBase : MonoBehaviour
  → netService (NetMonoBase 相对偏移 0x14 + MonoBehaviour 原生头 0x48 = 运行时 0x5C) → NetMixService : NetService
    → core (NetService @0x8) → NetCore
      → conn (NetCore @0x8) → NetSocket
        → socket (NetSocket @0x10) → System.Net.Sockets.Socket
```

注意：il2cppdumper 给的字段偏移是**相对托管字段起点**的（`netService // 0x14`），运行时真实偏移要加 MonoBehaviour 原生头 `0x48`（`0x48+0x14=0x5C`，与 `mov eax,[eax+0x5C]` 吻合）。这解释了之前 `mono` 静态字段偏移 `0x37723703` 看着像乱码的原因。

**冻结点已精确定位**（推翻「状态机没跑」的旧结论）：

```
StageMgr.Tick(0x1ED170) → FSMBaseCtrl<StageBase>.Tick(0xC08360，共享泛型)
  → 0x10171740（虚调用，不是 universal shared dispatcher 0x1435D30）
    → StageLaunch.Tick(0x1EC000) state 0：
        mov eax,[0x11d2c42c]        ; 单例实例 = NULL
        test byte ptr [eax+0xc2],1  ; ★ NULL 解引用 → 原生访问违例
```

- 之前的「shared dispatch 捕获 hook 0x1435DB7 0 次触发」是**挂错了地方**——真正分派走的是 `0x10171740`，状态机其实跑到了 state 0。
- `[0x11d269a4]`/`[0x11d269c8]` 不是单例实例，而是 **MethodInfo(RGCTX) 全局**（`TSingleton<T>.GetInstance` 的泛型上下文）；`[0x11d269a4]` = `TSingleton<TransitionManager>.GetInstance`。真正的单例实例 `s_Instance` 是 GetInstance 内部 `[class+0x60]` 读出来的静态字段，是 NULL。
- **null guard patch 的 bug**：Patch 2（`CheckArg2Trampoline`）检查的是 arg2（method/RGCTX，恒非空），而崩溃点其实在 GetInstance 内部 `test byte ptr [s_Instance+0xc2]`（s_Instance=NULL）。所以 Patch 2 不生效。
- `StageMgr` 字段（dump.cs）：`isLoading@0x18`、`resLoadMgr@0x24`、`lastStateType@0x28`、`nextStateType@0x2C`、`currentEnterParam@0x30`、`preGoToNext@0x34`、`timer@0x38`、`duration@0x3C`(=0.5s)、`loadProgress@0x40`。`Goto` 里 `TransitionManager` 为 NULL 只跳过 Lua 转场动画（不致命），真正的崩溃在 state 0。
- **重大修正**：`0x1435D30` 不是「universal shared dispatcher」，而是 `System.Collections.Generic.Dictionary<int, object>$$get_Item`（`statePool.getItem(nextStateType)` 的共享泛型实现）。之前挂 `0x1435DB7` 捕获「分派」等于挂在了字典查找上，所以 0 次触发、误判「状态机没跑」。真正的 Tick 分派走 `0x10171740`（虚调用）。
- `StageLaunch.Tick` 状态机：state 0 读 `UIPageManager.GetInstance()`(RGCTX 全局 `0x11d269c8`) + `[0x11d119c8]`(带 netService@0x5c 的单例) + 清理 `[0x11d2c42c]`；state 1=`ClearLuaAndSqlite`、state 2=`CheckUnloadState`、state 3=`ClearCache`+转场、state 4=抛异常。这些全是场景 MonoBehaviour 单例，场景没加载所以全 NULL。
- `FSMBaseCtrl<T>` 字段：`statePool@0x8`、`currState@0xC`、`hadDefaultState@0x10`、`defaultState@0x14`。`DelayGoto`(0x1ECBD0) 是真正的切状态方法。

### 13.8 下一步（符号表已把门打开）

1. **修正 null guard**：Patch 1（`0x1EC05B` `test byte→test eax,eax`）已正确跳过第一个单例；Patch 2 需改为在 GetInstance 内部或调用点 `0x1EC085 je→跳到 state=2/return` 处处理 NULL（而不是抛异常），让状态机能继续跑。
2. **硬 bypass 修正**：`il2cpp_class_from_name` 第一参数是 `Il2CppImage*` 不是字符串！要用 `il2cpp_domain_get` + `il2cpp_domain_get_assemblies` + `il2cpp_assembly_get_image` + `il2cpp_image_get_name` 迭代出 `Assembly-CSharp` 的 image，再 `classFromName(image,"BabelTime.Net","NetMono")`。这些导出在 0x162C8F0~0x162D630 的 thunk 表里（每 0x10 字节一个 `jmp 0x1160xxxx`）。
3. 深水区仍在：为何场景没把那些 MonoBehaviour 单例创建出来（资源加载不完成）。

### 13.9 重要修正 + SDK 原生导出表

**修正（推翻 13.7 里的两处误判）**：

1. **`NetLogic.mono` 不是固定在 `0x11D30BC8`**。`0x11D30BC8` 是 `NetLogic_TypeInfo` 全局（Il2CppClass*）。真正的 `mono` 走 `static_fields`：
   ```
   NetLogicClass = [0x11D30BC8]            (TypeInfo 全局, Il2CppClass*)
   static_fields = [NetLogicClass + 0x5C]  (Il2CppClass 的 static_fields 指针)
   mono          = [static_fields + 0]     (NetMono 实例)
   ```
   Init/Connect 反汇编里那个 `mov eax,[0x11D30BC8]; mov eax,[eax+0x5C]` 的 `0x5C` 是 **Il2CppClass 的 static_fields 偏移**，不是 netService 偏移。

2. **`NetMono.netService` 运行时偏移是 `0x14`，不是 `0x5C`**。il2cppdumper 给的字段偏移（`cachedTransform@0xC`、`cachedGameObject@0x10`、`netService@0x14`）就是运行时偏移——MonoBehaviour 托管部分只加 `m_CachedPtr`@0x8（Il2CppObject 头 8 字节 + m_CachedPtr 4 字节）。Connect 反汇编 `mov [ebx+0x14],esi` 直接印证。之前「0x48 原生头 + 0x14 = 0x5C」是错的。
   - 真正的 `netService@0x5C` 是**另一个对象** `[0x11d119c8]`（StageTick state 0 / Connect 里读的那个「带 netService 的 MonoBehaviour 单例」），不是 NetMono。

**修正后的对象图**：
```
mono(NetMono) = [[NetLogicClass+0x5C]+0]
  → netService(NetMixService) = [mono+0x14]
    → core(NetCore) = [netService+0x8]
      → conn(NetSocket) = [core+0x8]
```

**关键推论**：`NetLogic.Connect` 自己会建整个对象图（mono==null 时 `GameObject.AddComponent<NetMono>()` + new NetMixService + new NetCore + 接线），然后 `tail-call NetSocket.Connect(conn, host, port)`。所以硬 bypass **不需要** `il2cpp_class_from_name`——直接调 `NetLogic.Connect(host, port)` 即可。已据此重写 `TryManualNetLogicSetup`。

**SDK 原生导出表（`new_sdk.dll`，x86，按名导出未混淆）**：
```
initSDK=0x3A780  login=0x3A850  loginDemo=0x3A7F0  logout=0x3A880
getHash=0x3AC80  getHashWithSimulation=0x3D960   getServerList=0x3AB60
getLoginedServerInfo=0x3C650  isLogined=0x3D130
getPL=0x3BCC0  getOS=0x3BDD0  getPid=0x3CEE0  getGN=0x3BEE0  getUUID=0x3BBD0
getHost=0x3C9F0  getLogHost=0x3C800  getSDKVersion=0x3C8F0  getVersionInfo=0x3B730
setSimulationInfo=0x3CE20  setDebugEnv=0x3D560  tickLoop=0x3AA40
getNotice=0x3ACF0  getSuperNotice=0x3CD00  getForceFix=0x3D730  getDeviceInfo=0x3CC10
getDeviceFeature=0x3C0D0  getIdfa=0x3C7D0  getNetworkCapture=0x3DB80  getLocaleInfo=0x3DCF0
?getPlatform@@YAPAVPlatform@bt@@XZ=0x151D0 (C++ mangled)
```
（其余 UI/支付/通知类导出略；完整清单可用 `pefile` 直接 dump，见 `new_sdk.dll` 导出目录 RVA 0x5A8B0。）

**待办（代码已改，待验证）**：
- `TryManualNetLogicSetup` 已改为直接调 `NetLogic.Connect`（event 1 触发）。
- `NetLogicInstanceReady()` 已改为读 `[[NetLogicClass+0x5C]+0]`（原实现误读 TypeInfo 全局，恒真）。
- 需跑一次 `debug-game.ps1` 验证 Connect 在场景冻结前能否成功建连。
