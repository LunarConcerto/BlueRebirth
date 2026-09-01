# BlueRebirth Mod 开发手册

> 适用仓库：BlueRebirth  
> 当前客户端运行时：JP 1.4.0 实验版 xLua Loader  
> 文档依据：仓库中的 `Mods/bootstrap.lua`、`native/Payload/lua_mod_loader.cpp`、`BlueOath.Mods` 与服务端装备 Mod 实现

本文面向第一次接触 Lua、Unity 或 Mod 开发的读者，也可作为现阶段 Mod 接口的完整参考。先照“十分钟快速开始”做出第一个 Mod，再按需阅读后续章节。

## 1. 先读：当前能做什么

当前 Mod 系统仍处于实验阶段，已经可用的能力和预留能力并不完全相同。

| 能力 | 当前状态 | 说明 |
|---|---|---|
| 在游戏 Lua 线程执行外部明文 Lua | 可用 | 由原生 Payload Hook `xlua.dll!lua_pcallk` 后执行 |
| 修改客户端 Lua 全局表和函数 | 可用 | 可等待 `configManager`、`Logic` 等全局对象出现后打补丁 |
| 运行时覆盖客户端配置表 | 可用 | 可包装 `configManager.GetData` / `GetDataById` |
| 输出到 Payload 日志 | 可用 | 使用 `mod.info(...)` |
| 等待一个全局对象出现 | 可用 | 使用 `mod.watch_global(name, callback)` |
| 自动扫描 `mod.json` 并加载客户端 Mod | **尚不可用** | 客户端仍使用 `Mods/bootstrap.lua` 中的显式 `entries` 列表 |
| `enabled`、`targetClients`、`dependencies`、`loadOrder` 控制客户端加载 | **尚不可用** | 这些字段目前不会影响客户端 Lua Loader |
| `on_bootstrap` 生命周期 | 可用 | 每个成功加载的入口会调用一次 |
| `on_login`、`on_battle_result` 等生命周期 | **尚未接线** | 示例文件中存在函数名，但运行时不会调用 |
| 热重载 / 卸载 | **尚不可用** | 修改 Mod 后需要完全退出并重新启动客户端 |
| JP 1.4.0 客户端 | 可用 | Loader 会严格校验已知 `xlua.dll` SHA-256 |
| CN 1.5.20 客户端 | **尚不支持客户端加载** | 清单可写 CN 目标，但原生 Loader 当前只接受 JP xLua 哈希 |
| 服务端自定义装备配置 | 部分可用 | `equipment.json` 可把装备模板加入服务端装备目录 |
| 服务端自定义装备商品 | **尚未接入实时商店** | 商品会被解析和验证，但当前 `GameServices` 未调用 `MergeGoods` 合并到运行中商店 |
| C# Mod | **尚不可用** | `BlueOath.Mods` 目前只做发现、排序和事件排队，不执行 C# 或 Lua |

最重要的结论：**现阶段客户端 Mod 是一个加入 `bootstrap.lua` 显式列表的 Lua 文件，而不是仅靠放入带 `mod.json` 的目录就能自动启用。**

## 2. 运行原理

一次正常加载依次经过下面几步：

1. 启动器用 `BlueOath.Injector.exe` 启动游戏并注入 `BlueOath.Payload.dll`。
2. Payload 寻找 `Mods/bootstrap.lua`。
3. Payload 等待 `xlua.dll` 出现，计算其 SHA-256，并只接受已验证的 JP 1.4.0 版本。
4. Payload Hook `lua_pcallk`，等待游戏的 Lua 环境拥有 `package` 和 `loadfile`。
5. 一次游戏 Lua 调用成功返回后，Payload 在**同一个游戏 Lua 线程**执行 `bootstrap.lua`。
6. `bootstrap.lua` 依次加载 `entries` 中的入口，为每个入口创建独立环境。
7. 入口顶层代码执行成功后，若定义了 `on_bootstrap`，Loader 立即调用它。
8. Mod 通常在这里等待游戏全局对象，并在对象就绪后包装原函数或扩展配置。

这套设计有三个直接影响：

- 不要从后台线程调用游戏 Lua API；当前接口也没有提供创建线程的能力。
- Mod 加载得很早，`configManager`、`Logic` 等对象经常尚未创建，必须处理“现在存在”和“稍后出现”两种情况。
- 一个入口报错会让整次 bootstrap 失败；原生 Loader 约 5 秒后重试。排错时应修复错误并重启游戏，避免前面已经产生的副作用被重复执行。

## 3. 环境准备

### 3.1 只编写 Lua Mod

如果仓库现有原生产物可用，只需：

- Windows；
- 一个能以 UTF-8 保存文件的编辑器；
- 与基线一致的 JP 1.4.0 客户端；
- 仓库或发布包中的 `BlueOath.Payload.dll`、`BlueOath.Injector.exe` 和 `Mods` 目录。

推荐使用 VS Code，并安装任意 Lua 语法高亮扩展。Lua 版本按游戏 xLua 内嵌的 Lua 5.3 语法编写。

### 3.2 需要重新构建原生 Loader

需要以下组件：

- Visual Studio C++ Build Tools，包含 x86/x64 C++ 工具；
- CMake；
- PowerShell；
- .NET 8 SDK（构建整个仓库和运行测试时需要）。

构建原生组件：

```powershell
.\tools\build-native.ps1
```

输出位于：

```text
native/bin-x86/
├── BlueOath.Injector.exe
├── BlueOath.Payload.dll
├── BlueOath.LuaLoaderProbe.dll
└── BlueOath.Payload.log        # 游戏运行后生成
```

`-DisableLuaMods` 会构建不含实验 Loader 的主 Payload，开发 Mod 时不要使用：

```powershell
.\tools\build-native.ps1 -DisableLuaMods
```

Lua 文件和 `bootstrap.lua` 都由运行时读取。**只修改 Lua 一般不需要重新编译 Payload，但需要重启游戏。**

### 3.3 到底应该编辑哪个 `Mods` 目录

源码开发、已发布整包和客户端自身目录中可能同时出现同名 `Mods`，不要只凭目录名判断。

客户端 Lua Loader 以 Payload 所在目录为起点查找，实际采用的目录会写入日志：

```text
[LuaModLoader] mods root: C:\...\Mods
```

在标准源码布局中，Payload 位于 `native/bin-x86`，向上两级能找到仓库根目录的 `Mods`，所以客户端 Lua 开发通常编辑：

```text
<仓库>/Mods
```

在标准发布包中，Payload 位于 `<发布包>/native`，它会找到：

```text
<发布包>/Mods
```

服务端装备扩展的定位规则不同。给定 `--client-path=<客户端目录>` 时，它读取：

```text
<客户端目录的父目录>/Mods
```

未提供有效客户端路径时才回退到服务端程序目录下的 `Mods`。例如源码常用参数为：

```text
--client-path=<仓库>/blueoath/blueoath
```

此时服务端装备扩展实际读取：

```text
<仓库>/blueoath/Mods
```

这个目录可能是启动器或发布流程生成的运行副本，不一定与 `<仓库>/Mods` 自动同步。因此开发同时影响客户端与服务端的装备 Mod 时：

1. 先把 `<仓库>/Mods` 作为源码真源；
2. 查看客户端日志确认 Lua Loader 的实际根目录；
3. 根据服务端 `--client-path` 计算服务端 Mods 根目录；
4. 通过正常部署流程同步 Mod，或在本地测试前显式复制同一版本；
5. 查看服务端 `[equipment-mod] loaded ...` 日志确认它读到的版本。

不要在两个目录分别手改后长期并存，否则最容易出现“客户端显示的是新属性，服务端验证的却是旧属性”。

## 4. 十分钟快速开始

下面创建一个只写日志、不修改游戏的安全示例。

### 4.1 创建目录

在仓库的 `Mods` 下创建：

```text
Mods/
└── hello-world.mod/
    ├── mod.json
    └── main.lua
```

目录名建议使用小写 ASCII、数字和连字符，并以 `.mod` 结尾。这样路径清晰，也便于以后自动发现。

### 4.2 编写 `mod.json`

```json
{
  "id": "hello-world.mod",
  "version": "1.0.0",
  "entry": "main.lua",
  "targetClients": ["jp-1.4.0"],
  "dependencies": [],
  "loadOrder": 100,
  "enabled": true
}
```

虽然客户端当前不会读取它来决定是否加载，仍应从第一天维护正确的清单。服务端扩展和 C# 发现器会读取其中一部分字段，未来客户端自动加载也会依赖它。

`mod.json` 必须是严格 JSON：属性名和字符串使用双引号，不允许 `//` 注释，也不要在最后一个字段后留下尾随逗号。

### 4.3 编写 `main.lua`

```lua
function on_bootstrap(state)
  mod.info("Hello, BlueRebirth!")
  mod.info("root=" .. tostring(state.root))
  mod.info("entry=" .. tostring(state.entry))
end
```

文件建议保存为 UTF-8。为减少 Lua 解析器、旧工具或路径处理的差异，推荐使用 UTF-8 无 BOM 和 `/` 作为入口路径分隔符。

### 4.4 注册客户端入口

打开 `Mods/bootstrap.lua`，把入口加入 `entries`：

```lua
local entries = {
  "future-chapter.mod/main.lua",
  "custom-equipment.mod/main.lua",
  "fashion-preview-fix.mod/main.lua",
  "example.mod/main.lua",
  "hello-world.mod/main.lua"
}
```

这里的路径：

- 相对于 `Mods` 根目录；
- 必须是非空 UTF-8 字符串；
- 不能是绝对路径；
- 不能包含 `..` 父目录段；
- 最长 4096 字节；
- 只允许加载文本 Lua chunk。

### 4.5 启动并验证

使用图形启动器，或在仓库根目录运行：

```powershell
.\run-game.bat
```

只连接已经在 IDE 中运行的服务端时，可运行：

```powershell
.\start-client.bat
```

然后打开：

```text
native/bin-x86/BlueOath.Payload.log
```

应看到类似内容：

```text
[LuaModLoader] lua: [BlueOath.Mods] hello-world.mod/main.lua: Hello, BlueRebirth!
[LuaModLoader] lua: [BlueOath.Mods] bootstrap complete; loaded 5 mod(s)
[LuaModLoader] bootstrap executed successfully: ...\Mods\bootstrap.lua
```

没有日志时不要先猜 Lua 代码有问题，按第 12 章的顺序排查 Loader、Mods 根目录、哈希和入口。

### 4.6 第一次写 Lua：够用的基础

Lua 不需要声明变量类型。新 Mod 中尽量使用 `local`，避免无意创建环境级变量：

```lua
local name = "hello"       -- 字符串
local count = 1            -- 数字
local enabled = true       -- 布尔值
local missing = nil        -- 空值
local values = {10, 20}    -- 表，也可作为数组
```

Lua 数组通常从 `1` 开始，不是从 `0` 开始：

```lua
mod.info(values[1]) -- 10
```

表既能作数组，也能作字典：

```lua
local equipment = {
  id = 900001,
  name = "试作装备",
  props = {{8, 90}, {3200, 300}}
}
```

常用遍历：

```lua
for index, value in ipairs(values) do
  mod.info(tostring(index) .. "=" .. tostring(value))
end

for key, value in pairs(equipment) do
  mod.info(tostring(key) .. "=" .. tostring(value))
end
```

`ipairs` 适合从 1 开始的连续数组，遇到第一个空位通常停止；`pairs` 遍历所有键，但不保证顺序。

判断类型和空值：

```lua
if value == nil then
  mod.info("value is missing")
elseif type(value) == "table" then
  mod.info("value is a table")
end
```

Lua 中只有 `false` 和 `nil` 为假；数字 `0` 和空字符串 `""` 都为真。给表字段赋 `nil` 会删除该键：

```lua
equipment.name = nil
```

函数和可变参数：

```lua
local function add(left, right)
  return left + right
end

local function forward(...)
  return another_function(...)
end
```

字符串连接使用 `..`，调试未知类型前使用 `tostring`：

```lua
mod.info("id=" .. tostring(equipment.id))
```

注释写法：

```lua
-- 单行注释

--[[
多行注释
]]
```

最常见的初学错误：

- 把数组第一项写成 `[0]`；
- 用 `+` 连接字符串；
- 忘记 `local`；
- 把 `0` 当作假；
- 用 `#table` 统计带空洞或字典键的表；
- 混淆 `object.Method(x)` 与 `object:Method(x)`；
- 在访问 `value.field` 前没有检查 `value` 是否为表。

## 5. 标准目录与命名

一个普通客户端 Mod 推荐采用：

```text
Mods/my-feature.mod/
├── mod.json             # 清单
├── main.lua             # 唯一入口
├── lib/                 # 可选；辅助代码
├── data/                # 可选；数据文件（当前没有通用 JSON 读取 API）
├── assets/              # 可选；资源（当前没有通用资源注册 API）
├── README.md            # 推荐；用户说明、兼容性和卸载方法
└── CHANGELOG.md         # 可选；版本记录
```

当前原生接口只提供“读取并编译 Mod 根目录内文本 Lua”的内部能力，没有公开的通用 JSON、二进制文件或 Unity AssetBundle 加载 API。因此增加 `data` / `assets` 目录只是组织约定，不代表内容会自动加载。

命名建议：

- `id`：`作者或组织.功能.mod`，或与现有项目一致的 `功能.mod`；发布后不要随意更改。
- 目录：最好与 `id` 相同。
- Lua 局部变量：`snake_case`。
- 常量：`UPPER_SNAKE_CASE`。
- 自己写入共享表的标记：使用唯一前缀，例如 `__myname_feature_patched`。
- 自定义数值 ID：先检索客户端配置和其他 Mod，保留一段独占范围，并在 README 中记录。

## 6. `mod.json` 完整参考

当前清单模型为：

```json
{
  "id": "example.mod",
  "version": "1.0.0",
  "entry": "main.lua",
  "targetClients": ["jp-1.4.0", "cn-1.5.20"],
  "dependencies": [],
  "loadOrder": 100,
  "enabled": true
}
```

| 字段 | 类型 | 建议/含义 | 当前实际使用者 |
|---|---|---|---|
| `id` | 字符串 | 全局唯一且稳定的 Mod ID | C# 发现器、装备扩展日志 |
| `version` | 字符串 | 推荐语义化版本，如 `1.2.0` | 目前只保存，不比较 |
| `entry` | 字符串 | 相对 Mod 目录的入口 | C# 发现器检查文件存在；客户端当前忽略 |
| `targetClients` | 字符串数组 | 精确目标 ID；空数组表示不限制 | C# 发现器、服务端装备扩展 |
| `dependencies` | 字符串数组 | 依赖的 Mod ID | C# 发现器只检查 ID 是否存在 |
| `loadOrder` | 整数 | 越小越早；相同值按 ID 排序 | C# 发现器；客户端当前忽略 |
| `enabled` | 布尔值 | 是否启用 | C# 发现器、服务端装备扩展；客户端当前忽略 |

当前已知客户端 ID：

- `jp-1.4.0`
- `cn-1.5.20`

注意事项：

1. `targetClients` 是不区分大小写的精确匹配，不支持通配符和版本范围。
2. C# `ModManager` 按 `loadOrder` 和 `id` 排序，但不会根据依赖关系做拓扑排序。
3. `dependencies` 不支持版本约束，也不会把依赖自动排到前面。
4. 客户端显式列表的真实加载顺序就是 `entries` 的书写顺序。
5. 要在当前客户端禁用 Mod，必须从 `entries` 删除或注释对应行；仅将 `enabled` 改为 `false` 不够。

## 7. Lua 入口和运行环境

### 7.1 入口执行顺序

每个入口执行时会发生：

1. 创建一个新的 Mod 环境表。
2. 在环境中注入 `mod` API。
3. 环境通过 `__index = _G` 读取游戏全局变量。
4. 编译并执行入口顶层代码。
5. 若环境中存在 `on_bootstrap`，调用 `on_bootstrap(state)`。
6. 将环境保存到 `BlueOathMods.loaded[entry]`。

传给 `on_bootstrap` 的 `state` 为：

```lua
{
  root = "Mods 根目录的绝对路径",
  entry = "当前入口的相对路径"
}
```

### 7.2 环境不是安全沙箱

Mod 中普通的全局赋值会落到自己的环境：

```lua
my_private_value = 123
```

其他 Mod 不会通过普通全局查找看到它。但是：

- 读取会回退到真实 `_G`；
- 修改从 `_G` 取得的表会修改游戏共享状态；
- 可以显式调用 `rawset(_G, ...)`；
- 游戏的 Lua、Unity/xLua 桥接对象和调试库可能被访问。

所以这只是减少命名冲突的环境隔离，**不是权限或安全边界**。不要安装来源不明的 Mod。

### 7.3 当前生命周期

当前只有：

```lua
function on_bootstrap(state)
  -- 已接线，会调用
end
```

下面这些名字目前不会被 Loader 调用：

```lua
function on_login(state) end
function on_battle_result(result) end
function on_unload() end
```

不要把关键初始化放在未接线函数中。需要响应游戏事件时，现阶段应谨慎包装对应的游戏 Lua 方法，并保证可恢复、可重复和兼容其他包装器。

## 8. `mod` API 参考

### 8.1 `mod.info(message)`

向 `BlueOath.Payload.log` 写一行带入口名的日志：

```lua
mod.info("patch installed")
mod.info("value=" .. tostring(value))
```

输出示例：

```text
[LuaModLoader] lua: [BlueOath.Mods] my-feature.mod/main.lua: patch installed
```

建议每个 Mod 至少记录：

- 开始等待目标对象；
- 补丁成功安装；
- 关键数据注入成功；
- 捕获到的错误及堆栈。

不要在每帧或高频网络回调中大量写日志，否则会明显增大日志并影响排错。

### 8.2 `mod.watch_global(name, callback)`

等待 `_G[name]`：

```lua
function on_bootstrap()
  mod.watch_global("Logic", function(logic)
    mod.info("Logic is ready: " .. tostring(logic))
  end)
end
```

行为：

- 如果全局已经存在，立即调用回调；
- 如果尚不存在，注册一次性监听，在首次赋值时调用；
- 同一个全局名可由多个 Mod 同时监听；
- 每个回调错误都会被 `xpcall(..., debug.traceback)` 捕获并写入日志；
- 回调触发一次后，该名字的监听列表会被清除。

参数错误会直接断言：

- `name` 必须是字符串；
- `callback` 必须是函数。

限制：它监听的是正常触发 `_G` 元表 `__newindex` 的赋值。如果游戏用 `rawset(_G, name, value)` 绕过元表，监听不会触发。当前已验证对象采用的初始化方式可正常工作。

### 8.3 推荐的等待模板

```lua
local patched = false

local function patch_target(target)
  if patched or type(target) ~= "table" then
    return
  end

  local original = target.SomeMethod
  if type(original) ~= "function" then
    error("Target.SomeMethod is unavailable")
  end

  target.SomeMethod = function(self, ...)
    return original(self, ...)
  end

  patched = true
  mod.info("Target.SomeMethod hook installed")
end

function on_bootstrap()
  mod.watch_global("Target", patch_target)
  mod.info("waiting for Target")
end
```

优先使用 `mod.watch_global`。不要让每个 Mod 都自行替换 `_G.__newindex`，否则后加载的 Mod 很容易覆盖前一个监听器。仓库中的 `fashion-preview-fix.mod` 是共享监听器的推荐范例；其他早期示例中手写元表监听属于兼容代码，不应作为新 Mod 的首选模板。

## 9. 安全包装游戏函数

### 9.1 先判断调用风格

Lua 中下面两种调用不同：

```lua
object.Method(value)       -- 点调用，不自动传 object
object:Method(value)       -- 冒号调用，等价于 object.Method(object, value)
```

包装前必须在 `lua_tools/BlueoathLuaJP` 中检查原函数定义和调用点。

点调用包装示例，适用于当前 `configManager.GetData`：

```lua
local original_get_data = manager.GetData
manager.GetData = function(name, ...)
  local result = original_get_data(name, ...)
  return result
end
```

冒号调用包装示例：

```lua
local original = logic.SomeMethod
logic.SomeMethod = function(self, value, ...)
  return original(self, value, ...)
end
```

把 `self` 传错通常不会立刻在包装处报错，而会在更深层表现为 nil、配置缺失或 UI 初始化中断。

### 9.2 保留可变参数和多返回值

无须检查结果时，直接返回原调用可保留全部返回值：

```lua
target.Method = function(...)
  return original(...)
end
```

需要修改第一个结果时：

```lua
target.Method = function(...)
  local result = original(...)
  -- 修改 result
  return result
end
```

注意：第二种写法只保留第一个返回值。若原函数有多个返回值，应明确接收并返回：

```lua
local first, second = original(...)
return first, second
```

### 9.3 幂等性

补丁应做到重复调用结果不变：

```lua
local patched = false

local function patch(target)
  if patched then
    return
  end
  -- 校验并包装
  patched = true
end
```

向配置表插入数据时也要先检查目标 ID：

```lua
if configs[MY_ID] ~= nil then
  return configs
end
```

如果需要跨入口重试仍保持幂等，可在共享目标表上使用唯一标记：

```lua
if target.__author_feature_patched then
  return
end
target.__author_feature_patched = true
```

### 9.4 链式兼容

多个 Mod 可能包装同一方法。始终保存“安装当时的当前函数”，不要重新从别处寻找所谓原始函数：

```lua
local previous = target.Method
target.Method = function(...)
  local result = previous(...)
  -- 在前一层结果上继续处理
  return result
end
```

这样加载顺序会形成包装链。卸载尚不支持，因此不要在运行中把函数直接恢复成早先保存的版本，否则可能拆掉后来 Mod 的包装。

### 9.5 错误隔离

可恢复的安装逻辑应记录完整堆栈：

```lua
local function safely(label, action)
  local ok, failure = xpcall(action, debug.traceback)
  if not ok then
    mod.info(label .. " failed: " .. tostring(failure))
  end
  return ok
end
```

不要盲目 `pcall` 后忽略错误。静默失败会让 UI 只留下半初始化状态，比明确日志更难定位。

## 10. 运行时覆盖客户端配置

### 10.1 配置访问入口

客户端 Lua 主要通过：

```lua
configManager.GetData("config_table")
configManager.GetDataById("config_table", id)
```

访问配置。运行时扩展通常同时包装二者，否则：

- 遍历整表时能看到新项，但按 ID 查询不到；或
- 按 ID 查询能返回新项，但列表、排序或商店遍历看不到。

### 10.2 最小配置注入模板

```lua
local NEW_ID = 900100
local SOURCE_ID = 100
local patched = false

local function shallow_clone(source)
  local result = {}
  for key, value in pairs(source) do
    result[key] = value
  end
  return result
end

local function ensure_entry(configs)
  if type(configs) ~= "table" then
    return configs
  end
  if configs[NEW_ID] ~= nil then
    return configs
  end
  if type(configs[SOURCE_ID]) ~= "table" then
    mod.info("source template is missing: " .. tostring(SOURCE_ID))
    return configs
  end

  local entry = shallow_clone(configs[SOURCE_ID])
  entry.id = NEW_ID
  entry.name = "My entry"
  configs[NEW_ID] = entry
  mod.info("injected config id=" .. tostring(NEW_ID))
  return configs
end

local function patch_config_manager(manager)
  if patched or type(manager) ~= "table" then
    return
  end
  local previous_get_data = manager.GetData
  local previous_get_by_id = manager.GetDataById
  if type(previous_get_data) ~= "function" or
      type(previous_get_by_id) ~= "function" then
    error("configManager API is unavailable")
  end

  manager.GetData = function(name, ...)
    local data = previous_get_data(name, ...)
    if name == "config_target" then
      ensure_entry(data)
    end
    return data
  end

  manager.GetDataById = function(name, id, ...)
    if name == "config_target" and tonumber(id) == NEW_ID then
      local data = manager.GetData("config_target")
      return data and data[NEW_ID] or nil
    end
    return previous_get_by_id(name, id, ...)
  end

  patched = true
  mod.info("configManager hook installed")
end

function on_bootstrap()
  mod.watch_global("configManager", patch_config_manager)
end
```

### 10.3 浅拷贝与深拷贝

浅拷贝只复制第一层键。嵌套数组或表仍与原模板共享：

```lua
local copy = {}
for key, value in pairs(source) do
  copy[key] = value
end
```

如果要修改嵌套字段，应使用支持循环引用的深拷贝：

```lua
local function deep_clone(value, seen)
  if type(value) ~= "table" then
    return value
  end
  seen = seen or {}
  if seen[value] ~= nil then
    return seen[value]
  end
  local result = {}
  seen[value] = result
  for key, child in pairs(value) do
    result[deep_clone(key, seen)] = deep_clone(child, seen)
  end
  return result
end
```

修改共享的嵌套表会连带改变源模板，是新增配置最常见的隐蔽错误之一。

### 10.4 如何查表名、字段和 ID

仓库已经提供三类资料：

- `lua_tools/BlueoathLuaJP/`：日服 Lua 反编译代码，适合搜索实际调用方式；
- `docs/config-catalog/`：配置扫描结果和工具说明；
- `src/BlueOath.Server/configs/`：从真实配置推断生成的 C# 结构，适合查看 JSON 字段名和类型。

常用搜索：

```powershell
rg -n 'configManager\.GetData\("config_equip"' .\lua_tools\BlueoathLuaJP
rg -n 'configManager\.GetDataById\("config_equip"' .\lua_tools\BlueoathLuaJP
rg -n 'JsonPropertyName' .\src\BlueOath.Server\configs\ConfigEquip.cs
```

需要查看真实配置内容时，优先导出副本：

```powershell
.\export-config.bat jp
```

不要为了制作运行时 Mod 直接修改原客户端数据库。运行时覆盖可回退，也更容易与原始基线比较。

## 11. 客户端与服务端同时扩展：自定义装备

联网逻辑中，客户端显示一份配置，服务端又以自己的目录验证购买、强化、升星和分解。只改客户端通常只会“看起来存在”，服务端仍可能拒绝操作。

### 11.1 文件结构

```text
Mods/my-equipment.mod/
├── mod.json
├── main.lua
└── equipment.json
```

### 11.2 `equipment.json`

```json
{
  "equipment": [
    {
      "id": 900101,
      "sourceTemplateId": 30023,
      "overrides": {
        "name": "试作装备",
        "equip_prop": [[8, 90], [3200, 300]],
        "enhance_prop": [[8, 6], [3200, 20]],
        "drop_path": [],
        "no_resolve": 1
      }
    }
  ],
  "goods": [
    {
      "goodId": 990101,
      "shopId": 5,
      "type": 2,
      "itemId": 900101,
      "num": 1
    }
  ]
}
```

服务端处理方式：

1. 在 Mods 根目录递归扫描所有 `equipment.json`，按完整路径排序。
2. 要求同目录存在 `mod.json`。
3. 读取 `id`、`targetClients` 和 `enabled`。
4. 用 `sourceTemplateId` 从真实 `config_equip.db` 取得模板。
5. 深克隆序列化结果，用 `overrides` 顶层覆盖字段。
6. 无论 `overrides` 写什么，最终强制把 `e_id` 改成新 `id`。
7. 将结果加入服务端装备目录。

服务端从哪里寻找这个文件由 `--client-path` 决定，详见 3.3。单元测试直接读取仓库根目录 `Mods`，不代表真实运行的服务端一定使用同一路径。

装备校验规则：

- `id > 0`；
- `sourceTemplateId > 0`；
- 同一文件内不能有重复装备 ID；
- 不同 Mod 之间也不能有装备 ID 冲突；
- 新 ID 与基础 `config_equip.db` 冲突时会跳过；
- 源模板不存在时会跳过；
- 覆盖字段必须能反序列化为 `ConfigEquip` 的类型。

商品校验规则：

- `goodId > 0`；
- `shopId > 0`；
- `type` 当前必须为 `2`，表示装备；
- `num > 0`；
- `itemId` 必须引用同一个 `equipment.json` 中定义的装备；
- 商品 ID 在文件内及不同 Mod 间均不能重复。

### 11.3 当前商品限制

`goods` 目前会被加载、校验，`EquipmentModLoader.MergeGoods` 也已有测试，但运行中的 `GameServices` 尚未调用它。因此当前不能把 `goods` 当作“实时 GM 商店一定可购买”的稳定接口。

在接线完成前：

- 客户端 `main.lua` 可以让商品出现在客户端配置中；
- 服务端能识别 `equipment` 中的装备模板；
- 实时服务端商店仍可能找不到 `goodId` 并拒绝购买。

Mod README 应明确这一限制，不要向使用者承诺完整购买闭环。

### 11.4 客户端 Lua 必须保持一致

`main.lua` 中使用的：

- 装备 ID；
- 源模板 ID；
- 名称和属性；
- 商品 ID；
- 商品所含类型、物品 ID 和数量；

应与 `equipment.json` 完全一致。当前没有自动生成或一致性校验桥接，改动时要同时更新两边。可参考 `Mods/custom-equipment.mod`。

## 12. 调试与故障排查

### 12.1 日志在哪里

主要日志：

```text
native/bin-x86/BlueOath.Payload.log
```

发布包通常是：

```text
<发布包>/native/BlueOath.Payload.log
```

图形启动器还会把一次运行的日志组织到 `runtime/debug/<时间戳>/`。

服务端装备扩展使用标准错误输出，搜索：

```text
[equipment-mod]
```

### 12.2 正常 Loader 日志阶段

```text
[LuaModLoader] start requested
[LuaModLoader] mods root: ...\Mods
[LuaModLoader] lua_pcallk hook installed; waiting for Lua environment
[LuaModLoader] lua: [BlueOath.Mods] ...
[LuaModLoader] bootstrap executed successfully: ...\Mods\bootstrap.lua
```

如果日志停在某一步，就从该步继续排查。

### 12.3 常见错误对照

| 日志或现象 | 含义 | 处理 |
|---|---|---|
| `Mods/bootstrap.lua not found` | 没找到 Mods 根目录 | 检查目录位置或 `[mods] root` |
| `configured mods root has no bootstrap.lua` | 自定义根目录错误 | 检查路径和文件名 |
| `unsupported xlua.dll SHA-256=...; hook refused` | 客户端版本不匹配 | 使用基线 JP 1.4.0；不要绕过哈希保护 |
| `lua_pcallk prologue mismatch; hook refused` | 导出函数机器码与已验证版本不同 | 核对客户端和 Payload 架构/版本 |
| `required xLua exports are missing` | xLua ABI 不兼容 | 使用支持版本，或先做独立逆向验证 |
| `xlua.dll did not load within 60 seconds` | 游戏未正常加载 xLua | 查看游戏是否早退、注入是否过早失败 |
| `cannot read <entry>` | `entries` 路径错或文件不存在 | 使用相对 `Mods` 根目录的 `/` 路径 |
| `parent path segments are not allowed` | 入口含 `..` | 把文件放在 Mods 根目录内 |
| `cannot run ...` | 入口顶层 Lua 错误 | 查看其后的 Lua 堆栈和行号 |
| `bootstrap failed` 每 5 秒出现 | 某入口或 `on_bootstrap` 持续报错 | 修复后完全重启，避免重复副作用 |
| 有 bootstrap 成功但没有 Mod 日志 | 忘记加入 `entries`，或日志代码在未接线生命周期 | 注册入口，并把初始化放到 `on_bootstrap` |
| `waiting for ...` 后没有成功日志 | 目标全局未出现或名字不对 | 搜索原始 Lua 初始化位置，核对大小写 |
| 客户端看得到物品但操作失败 | 只改了客户端配置 | 同步实现服务端目录/协议逻辑 |
| `[equipment-mod] ignored ...` | JSON、清单、ID 或引用校验失败 | 按错误文本核对对应规则 |

### 12.4 Mods 根目录搜索规则

Payload 按以下顺序查找：

1. Payload 同目录 `bootstrap.ini` 的 `[mods] root`；
2. Payload 目录下的 `Mods`；
3. Payload 父目录下的 `Mods`；
4. Payload 祖父目录下的 `Mods`。

只有候选目录中存在 `bootstrap.lua` 才算有效。

配置示例：

```ini
[mods]
root=C:\GitHub\BlueRebirth\Mods
```

相对路径以 Payload 所在目录为基准。仓库脚本可能重新生成 `native/bin-x86/bootstrap.ini`，发布器也会复制 `native/bootstrap.ini`，因此最稳妥的布局仍是让 `Mods` 与包根目录保持标准相对位置。

### 12.5 最小化排错

当多个 Mod 一起启动失败：

1. 备份当前 `entries`。
2. 只保留一个仅调用 `mod.info` 的入口，确认 Loader 正常。
3. 每次只恢复一个 Mod。
4. 在目标函数包装前后分别记录日志。
5. 缩小到具体全局、具体方法或具体配置 ID。
6. 修复后重启，不在已经多次 bootstrap 重试的进程上判断结果。

不要通过删除哈希校验来“验证是不是版本问题”。哈希拒绝是在未知机器码上避免破坏客户端进程的安全边界。

## 13. 测试

### 13.1 构建和基础测试

```powershell
dotnet restore .\BlueOath.Local.sln
dotnet build .\BlueOath.Local.sln --no-restore
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj --no-build
```

### 13.2 Mod 相关测试

只跑装备 JSON 的单元测试：

```powershell
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj -- --equipment-mod
```

使用真实 JP `config_equip.db` 验证装备覆盖：

```powershell
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj -- --equipment-mod-config
```

后一个测试要求仓库标准位置已有 JP 客户端，或设置：

```powershell
$env:BLUEOATH_TEST_CLIENT_PATH = 'D:\Games\blueoath'
```

服装预览修复 Mod 的静态发现测试：

```powershell
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj -- --fashion-preview-mod
```

这些测试不能代替真实客户端验证。客户端 Lua 补丁至少应人工覆盖：

- 冷启动首次进入；
- 目标页面第一次打开和重复打开；
- 目标对象存在和缺失的边界；
- 原功能正常路径；
- 新增内容路径；
- 重启后存档或服务端状态；
- 与其他包装同一函数的 Mod 同时启用。

### 13.3 推荐的 Mod 自检清单

- [ ] `mod.json` 是合法 JSON。
- [ ] `id` 唯一且目录名一致。
- [ ] `entry` 文件存在。
- [ ] 已加入 `bootstrap.lua` 的 `entries`。
- [ ] 清单目标包含实际客户端。
- [ ] 只依赖 `on_bootstrap` 或明确实现了自己的游戏事件 Hook。
- [ ] 所有目标表和函数在包装前做类型检查。
- [ ] 正确处理点调用/冒号调用。
- [ ] 保留必要的参数和返回值。
- [ ] 补丁具有幂等保护。
- [ ] 配置新 ID 不与基础数据和其他 Mod 冲突。
- [ ] 修改嵌套配置前做深拷贝。
- [ ] 客户端与服务端 ID 和属性一致。
- [ ] 日志能明确区分等待、成功和失败。
- [ ] 完全重启客户端验证。

## 14. 兼容性与版本策略

### 14.1 不要把 JP 与 CN 当成换皮版本

两服的 Lua 代码、配置表、IL2CPP 类型和内容进度都可能不同。即使方法同名，也可能存在：

- 参数差异；
- 返回值差异；
- 配置字段差异；
- 初始化时序差异；
- 目标对象根本不存在。

当前客户端 Loader 只验证 JP 1.4.0。未经验证，不应在清单中宣称 CN 客户端运行时兼容。

### 14.2 兼容性检查写法

现有 `state` 没有直接提供客户端 ID，因此当前客户端兼容性主要由原生 xLua 哈希门槛保证。Mod 仍应对实际 API 做能力检查：

```lua
if type(target) ~= "table" then
  error("Target table is unavailable")
end
if type(target.Method) ~= "function" then
  error("Target.Method is unavailable")
end
```

对于可选增强，可记录并跳过；对于缺失后会破坏数据的关键依赖，应明确报错停止。

### 14.3 与其他 Mod 的冲突

常见冲突来源：

- 两个 Mod 使用相同数值 ID；
- 两个 Mod 都直接替换某函数却不调用前一层；
- 自行覆盖 `_G.__newindex`，没有链接原元方法；
- 修改同一配置字段，加载顺序决定最终值；
- 把共享模板的嵌套表当成副本修改；
- 一个 Mod 假设另一个 Mod 已加载，但 `entries` 顺序相反。

解决原则：唯一 ID、链式包装、共享 watcher、深拷贝、显式顺序、清楚记录依赖。当前真正的客户端顺序只能通过 `entries` 保证。

## 15. 性能与稳定性

- 不要在每帧函数里遍历整张配置表。
- 配置注入完成后写标记，避免每次 `GetData` 都重复深拷贝。
- 缓存只读查找结果前，先确认游戏不会在登录或切服时替换整张表。
- 不要在 Hook 中做磁盘 IO；当前公开 API也没有通用文件读取接口。
- 包装 UI 方法时，保证错误不会留下半更新页面。
- 不要修改参数表，除非已经确认调用者不会在调用后复用。
- 不要吞掉原函数错误；至少在开发版写入堆栈。
- 日志内容避免账号令牌、会话数据和大块配置全文。

## 16. 发布与卸载

### 16.1 发布前内容

一个可交付 Mod 至少应包含：

- Mod 目录；
- `mod.json`；
- `main.lua`；
- 安装说明：复制到哪个 `Mods` 目录；
- 当前阶段的 `bootstrap.lua entries` 修改说明；
- 支持的客户端版本；
- 已知限制；
- 卸载方法；
- 若涉及存档或服务端数据，说明回退风险。

不要让用户直接覆盖整个 `bootstrap.lua`。不同用户可能装有其他 Mod，应指导他们只添加或删除一行入口。

### 16.2 项目发布包

仓库发布器会把整个 `Mods` 目录复制到发布包：

```powershell
.\publish-release.bat
```

默认输出到：

```text
release/BlueOath-Release/
```

发布前应确保最新原生产物已构建，并检查发布包中同时存在：

```text
Mods/bootstrap.lua
Mods/<your-mod>/main.lua
native/BlueOath.Payload.dll
native/BlueOath.Injector.exe
```

### 16.3 卸载

当前没有运行时卸载。安全卸载步骤：

1. 完全退出客户端和本地服务端。
2. 从 `bootstrap.lua` 的 `entries` 删除入口。
3. 删除或移走 Mod 目录。
4. 如果 Mod 写入服务端存档，按 Mod 自己的迁移说明清理或保留数据。
5. 重启并确认日志不再出现该入口。

仅把 `mod.json.enabled` 改成 `false` 不能停用当前客户端 Lua 入口。

## 17. 现有示例怎么读

### `example.mod`

用途：最小入口和生命周期命名示意。

应学习：

- `mod.info`；
- `on_bootstrap(state)`。

不要误解：其中 `on_login` 和 `on_battle_result` 当前不会被调用。

### `fashion-preview-fix.mod`

用途：等待 `Logic`，再等待其中的 `fashionLogic`，安全包装一个方法。

应学习：

- `mod.watch_global`；
- 对目标类型和方法做检查；
- 保存并调用原函数；
- 补丁幂等标记；
- 冒号方法的 `self` 传递。

### `future-chapter.mod`

用途：同时覆盖配置访问和逻辑方法，插入不可进入的未来章节占位。

应学习：

- `GetData` 与 `GetDataById` 同步覆盖；
- 配置项存在性检查；
- 对空章节增加逻辑保护；
- 对多返回值的明确返回。

注意：它是较早实现，自己管理部分元表监听。新 Mod 应优先使用 bootstrap 提供的共享 `mod.watch_global`。

### `custom-equipment.mod`

用途：演示客户端配置与服务端 JSON 装备目录的双边扩展。

应学习：

- 深拷贝模板；
- 客户端与服务端使用同一 ID；
- 装备属性覆盖；
- `equipment.json` 格式。

注意：实时服务端商店商品合并仍未接线，见 11.3。

## 18. 进阶：修改框架本身

普通 Mod 作者通常不需要修改这一层。维护 Loader 时要理解以下边界。

### 18.1 原生 Loader

核心文件：

```text
native/Payload/lua_mod_loader.cpp
native/Payload/lua_mod_loader.h
native/CMakeLists.txt
tools/build-native.ps1
```

关键安全措施：

- 对 `xlua.dll` 做 SHA-256 白名单校验；
- 检查 `lua_pcallk` 函数序言；
- 在改写导出前先发布 trampoline，降低并发窗口风险；
- 只从 Mods 根目录加载相对文本路径；
- 禁止绝对路径和 `..`；
- 保存并恢复 Lua 栈顶；
- 只在游戏 Lua 调用成功返回后尝试 bootstrap。

支持新客户端版本时，不能只追加哈希。至少要重新确认：架构、导出集、调用约定、函数序言、偷取指令长度、Lua ABI 和完整客户端回归。

### 18.2 Lua bootstrap

核心文件：

```text
Mods/bootstrap.lua
```

未来自动发现需要解决：

- 解析 `mod.json`；
- 严格字段校验；
- 目标客户端过滤；
- 依赖拓扑排序和环检测；
- 每个 Mod 的错误隔离策略；
- 生命周期分发；
- 模块加载和文件 API；
- 热重载或明确不支持；
- 冲突诊断和版本约束。

在这些功能真正接线前，文档和 UI 都应继续把清单字段标为“元数据/预留”，不能表现成已经控制客户端加载。

### 18.3 C# `BlueOath.Mods`

核心文件：

```text
src/BlueOath.Mods/ModManager.cs
```

当前会：

- 递归发现 `mod.json`；
- 过滤 `enabled` 与目标客户端；
- 按 `loadOrder`、`id` 排序；
- 检查入口存在；
- 检查依赖 ID 是否在发现集合；
- 为已发现 Mod 排队 `ModEvent`。

当前不会：

- 执行入口；
- 与游戏 xLua 状态通信；
- 根据依赖拓扑重排；
- 检查依赖版本；
- 消费事件队列；
- 为客户端自动生成 `entries`。

## 19. FAQ

### 为什么我把目录放进 `Mods` 了却没有加载？

因为客户端尚未自动扫描清单。把 `目录名/main.lua` 显式加入 `Mods/bootstrap.lua` 的 `entries`。

### 为什么 `enabled: false` 后仍会运行？

客户端 Loader 当前忽略清单。删除或注释 `entries` 中的路径并重启。

### 为什么 `on_login` 不执行？

当前只接线了 `on_bootstrap`。`on_login` 只是未来接口示意。

### 能直接 `require("my_module")` 吗？

不要把它当成稳定的 Mod 模块接口。游戏的 `package.path` 不一定包含 Mods 目录，而且普通 `require` 不会自动使用入口的隔离环境。当前最稳妥方式是把小型实现放在入口中；需要多文件框架时，应先扩展 bootstrap 的受控模块加载能力。

### 能读取任意文件吗？

没有受支持且可跨客户端保证的通用文件 API。原生内部 loader 只接受 Mods 根目录内的相对文本 Lua，并禁止绝对路径和父目录跳转；游戏 Lua 环境是否还暴露 `io` 等标准库属于实现细节，不应作为可移植 Mod 接口依赖。环境并非安全沙箱，因此这也不代表不可信 Mod 没有文件访问风险。

### 能加载 DLL、C# 或 AssetBundle 吗？

当前 Mod API 不支持。原生 Payload 本身是框架组件，不等于面向 Mod 作者开放任意 DLL 加载。

### 修改 Lua 后能在游戏里刷新吗？

不能。bootstrap 成功后只执行一次，没有卸载或热重载。完全退出并重启客户端。

### 为什么新配置有时出现、有时没有？

通常是只包装了 `GetData` 或只包装了 `GetDataById`、源模板尚未存在、ID 冲突，或另一个 Mod 后加载并覆盖了包装。

### 为什么新装备显示正常却不能购买或强化？

显示来自客户端配置，购买和强化由服务端验证。必须同步扩展服务端；此外当前自定义商品尚未合并进实时 GM 商店。

### 如何选择新 ID？

先检索真实配置和所有 Mod，再选择较高且独占的一段，并在 Mod README 记录。不要只看一个表；商品 ID、装备 ID 等属于不同命名空间，但各自都必须避免冲突。

### Loader 拒绝未知 xLua 哈希怎么办？

使用支持的 JP 1.4.0 客户端。若要正式支持新版本，应按 18.1 完成 ABI 和 Hook 验证，不能简单关闭校验。

## 20. 提交 Mod 前的最终清单

- [ ] 功能说明简单明确，注明实验状态。
- [ ] 仅声明实际验证过的客户端版本。
- [ ] 清单字段完整，ID 和版本稳定。
- [ ] 入口已注册，顺序合理。
- [ ] 不依赖未接线生命周期。
- [ ] 不自行破坏全局元表监听链。
- [ ] 每个 Hook 保存并调用前一层函数。
- [ ] 点/冒号调用和多返回值处理正确。
- [ ] 补丁、数据注入和重复进入都幂等。
- [ ] ID 已与基础配置及其他 Mod 对照。
- [ ] 嵌套配置使用深拷贝。
- [ ] 客户端与服务端数据一致。
- [ ] 失败会写清楚的日志，不会静默吞错。
- [ ] 原始路径和正常功能没有回归。
- [ ] 完全重启验证过安装与卸载。
- [ ] README 写明已知限制和存档影响。

---

相关资料：

- [Lua 代码资料库](lua-catalog/README.md)
- [客户端配置目录](config-catalog/README.zh-CN.md)
- [配置工具链说明](config-catalog/tooling.zh-CN.md)
- [本地服代码规范](本地服代码规范.md)
- 仓库示例：`Mods/example.mod`、`Mods/fashion-preview-fix.mod`、`Mods/future-chapter.mod`、`Mods/custom-equipment.mod`
