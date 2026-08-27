# 苍蓝誓约本地复原

这是一个面向本地离线复原的 .NET 8 工程骨架。原始日服和国服客户端目录保持不变。

当前分阶段目标和完成门槛见 [项目 Roadmap](docs/ROADMAP.zh-CN.md)。

协议、IL2CPP 类型与配置知识库可重复生成：

```powershell
dotnet run --project .\src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-il2cpp
dotnet run --project .\src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-wire
dotnet run --project .\src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-protocol
dotnet run --project .\src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-config
```

协议分析会在 `docs\protocol-catalog` 生成机器可读目录及 `jp-1.4.0.proto`、`cn-1.5.20.proto` 草案。草案中的 tag 具有 `ProtoMemberAttribute` 和严格属性顺序证据，但在提取到 attribute 构造参数或真实 wire fixture 前仍标为推断。

## Protobuf 登录验证

服务端已支持独立的回环 protobuf 登录验证端口：

```powershell
dotnet run --project .\src\BlueOath.Server\BlueOath.Server.csproj -- --port=0 --game-login-port=0 --region=jp --data=.\runtime\jp
```

该端口已实现 `TArgLogin -> SQLite 档案创建/加载 -> TRetLogin`，并使用静态逆向确认的客户端 wire 布局：C2S 请求为 `channel:u8 + operation:u8 + sessionId:i64-le + state:u8 + protobuf`；登录操作码为 `2`。S2C 响应使用 handler `5`，protobuf 信封为 `TAckPack -> TNetOperation { opCode=2, data=TRetLogin }`。JP/CN 对应函数结构一致，证据输出在 `docs/il2cpp-catalog/wire-analysis.json`。

## KCP 登录端点（真实传输）

游戏逻辑 socket 实际走 **KCP over UDP**（不是 TCP），服务端提供对应的 UDP 端点：

```powershell
dotnet run --project .\src\BlueOath.Server\BlueOath.Server.csproj -- --port=0 --kcp-game-login-port=0 --region=jp --data=.\runtime\jp
```

`BlueOath.Protocol/KcpCodec.cs` 提供 KCP 包层编解码（24 字节头，LE 端序），`KcpConnection.cs` 提供 ARQ 可靠性（累计 ACK、超时重传、死链检测）。端点已通过回环集成测试（假客户端 UDP 分片发登录、收 KCP 响应、解回 `TRetLogin`）。应用层仍复用上述 11 字节头 + protobuf 布局。

## 构建

```powershell
dotnet restore .\BlueOath.Local.sln
dotnet build .\BlueOath.Local.sln --no-restore
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj --no-build
```

The optional process-level TCP test can be run with `--integration`; the default suite does not spawn child processes.

## 本地服务

```powershell
dotnet run --project .\src\BlueOath.Server\BlueOath.Server.csproj -- --port=0 --region=jp --data=.\runtime\jp
```

服务只监听 `127.0.0.1`，启动时输出 JSON 健康信息和实际端口。协议当前使用长度前缀 JSON 作为可测试的临时 wire format；`ProtocolProfile` 为替换为真实 protobuf/KCP 适配器预留边界。

## WPF 图形化启动器

`src/BlueOath.Launcher.Wpf` 提供了一个可视化的 WPF 启动器，替代原有的 `run-game.bat` 和 `start-client.bat` 脚本。

### 快速启动

双击项目根目录下的 `BlueOath.Launcher.lnk` 快捷方式，或运行：

```powershell
dotnet run --project src\BlueOath.Launcher.Wpf\BlueOath.Launcher.Wpf.csproj
```

### 功能

| 功能 | 说明 |
|------|------|
| 启动页 | 公告面板（数据驱动 `announcements.json`）+ 启动按钮 |
| 正常启动 | 完整流程：清理残留进程 → TLS 证书 → 服务器 → 代理 → 注入游戏 |
| 调试启动 | 仅启动代理 + 客户端，连接已运行的服务器（默认端口 7080） |
| 进程守护 | 实时显示服务器/代理/游戏客户端进程状态（绿点/红点） |
| 日志控制台 | 4 个子分页：服务器 / 代理 / 客户端 / 系统 |
| 自动滚动 | 日志新增时自动滚动到最新行 |
| WMI 进程清理 | 通过 WMI 查询命令行，精确匹配并清理残留的 `BlueOath.Server.dll` 进程 |
| 游戏图标 | 嵌入游戏原始图标 `uipic_ui_common_im_icon_100.png` |

### 架构

```
src/BlueOath.Launcher.Wpf/
├── Models/          # Announcement, LogEntry, LaunchConfig
├── ViewModels/      # MainViewModel, LaunchViewModel, GuardianViewModel
├── Views/           # MainWindow, LaunchPage, GuardianPage + Styles
├── Services/        # ProcessManager (核心), AnnouncementService
├── Converters/      # BooleanToVisibility, BooleanInvert
└── Resources/       # announcements.json, app.ico
```

样式集中定义在 `App.xaml` 的 `Application.Resources` 中，后续替换样式只需编辑该文件。

### 技术栈

- **WPF on .NET 8.0**（`net8.0-windows`）
- **MVVM** 模式（手写基类，无额外 NuGet 依赖）
- `System.Management`（WMI 进程清理）
- `System.Diagnostics.Process`（进程生命周期管理）

## 客户端启动（控制台）

```powershell
dotnet run --project .\src\BlueOath.Launcher\BlueOath.Launcher.csproj -- --region=jp --original
```

没有经过运行时验证的 x86 注入点会被启动器拒绝，避免对客户端执行未知补丁。

## 基线与 Mod

`tools/baseline.ps1` 生成 `baseline.json`，记录两服版本、架构和关键文件 SHA-256。示例 Mod 位于 `Mods/example.mod`；`Mods/future-chapter.mod` 会在 JP 1.4.0 主线“始動編”末尾加入一个不可进入的 `0/0` 占位篇章。`BlueOath.Mods` 负责清单、目标版本、依赖和加载顺序发现，并将事件排队给后续 xLua runtime handoff。

### xLua Mod Loader（JP 1.4.0 实验版）

Payload 会等待已知版本的 `xlua.dll` 加载，在一次正常 `lua_pcallk` 返回后从游戏 Lua
线程执行 `Mods/bootstrap.lua`。实验版只接受基线中的 JP 1.4.0 `xlua.dll` SHA-256；
未知版本会记录 `hook refused` 并保持客户端代码不变。
如需紧急回退，可用 `tools/build-native.ps1 -DisableLuaMods` 构建不含 Loader 的主 Payload；
隔离 Probe 仍会保留，便于继续诊断。

首次验证时查看 `native/bin-x86/BlueOath.Payload.log`：

```text
[LuaModLoader] lua_pcallk hook installed; waiting for Lua environment
[LuaModLoader] lua: [BlueOath.Mods] future-chapter.mod/main.lua: configManager hooks installed
[LuaModLoader] lua: [BlueOath.Mods] future-chapter.mod/main.lua: CopyLogic empty-chapter guards installed
[LuaModLoader] lua: [BlueOath.Mods] example.mod/main.lua: example.mod bootstrap active
[LuaModLoader] lua: [BlueOath.Mods] bootstrap complete; loaded 2 mod(s)
[LuaModLoader] bootstrap executed successfully: ...\\Mods\\bootstrap.lua
```

`bootstrap.lua` 当前通过一个显式入口列表加载 `future-chapter.mod/main.lua` 和
`example.mod/main.lua`。前者验证客户端配置与逻辑方法可以安全覆盖，后者验证普通明文 Lua
文件能够进入客户端运行时。通用的 `mod.json` 依赖排序、生命周期事件和模块覆盖仍属于后续工作。

若完整 Payload 还受其它版本相关 hook 影响，可使用构建产物
`native/bin-x86/BlueOath.LuaLoaderProbe.dll` 隔离验证 Loader；该 Probe 不包含网络、SDK、
战斗或 UI hook，也不会被发布器打进正式包。

## 客户端配置数据库

游戏客户端的 SQLite 配置表以 JSON 为数据单元，已知表结构为
`DBObject(id, indexid, jsonbytes)`。其中 `jsonbytes` 不是明文 JSON：读取其原始比特流后，
需要将每个字节与 `0x55` 进行异或，才能还原数据：

```text
decoded[i] = encoded[i] XOR 0x55
```

异或运算可逆，因此重新编码时使用相同操作：

```text
encoded[i] = decoded[i] XOR 0x55
```

当前将此规则作为已知的配置解码线索。解码后的文本编码、是否还有压缩层，以及不同表或客户端版本是否采用完全相同的处理流程，仍需通过样本和客户端调用点验证。

### 配置 <-> Excel 双向转换

一键脚本（导出到 `<仓库>\excel`，反导时自动备份原配置）：

```powershell
.\export-config.bat [jp|cn]   # 导出：所有 config_*.db -> <仓库>\excel
.\import-config.bat [jp|cn]   # 反导：<仓库>\excel -> 配置数据库（自动备份）
```

脚本底层调用 `BlueOath.Tools` 的 `--config-excel` 子命令，把加密的 `config_*.db` 导出为可编辑的
`.xlsx`，也能把编辑后的 Excel 反导回配置数据库。每个表一个 `.xlsx` 文件（`config_<表>.xlsx`），
内含两个工作表：

- `data`：业务行，列为 `id` / `indexid` / `json`（`json` 为已解密的明文 JSON，直接编辑即可）。
- `_meta`：元数据行（`id = nill` 的整表校验哈希，`jsonbytes_base64` 为已解密字节，一般无需改动）。

导出：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --config-excel --region=jp [--output=<目录>]
```

默认输出到 `<仓库>\config-excel\<region>`，并生成 `_manifest.json` 记录每张表源库 SHA-256。
`--region` 支持 `jp` / `cn`，也可用 `--config-root=<目录>` 直接指定任意 config 目录。

反导回数据库（默认原位写回，写回前自动备份被覆盖的 `.db`）：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --config-excel-import --region=jp --input=<目录或单个.xlsx>
```

- `--input` 可指向整个导出目录，或单个 `config_*.xlsx`（表名取自文件名）。
- 默认写回原 config 目录；如需先落到暂存目录验证，加 `--output=<目录>`。
- 反导前自动把将被覆盖的 `.db` 备份到 config 目录旁的 `config-backup\<时间戳>\`；用 `--no-backup` 可关闭。

整目录快照备份（一次性保护原始配置）：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --config-excel-backup --region=jp [--output=<目录>]
```

自检（临时目录内完成一次导出/反导字节级回环验证）：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --config-excel-self-test
```

### 配置 -> C# 强类型类（仅结构）

解析每张表的 JSON 结构（跨全部业务行推断字段类型），生成仅含结构的 C# DTO 类，供本地服反序列化配置使用：

```powershell
.\generate-config-cs.bat [jp|cn]   # 生成到 src\BlueOath.Server\configs
```

底层命令：

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --config-cs --region=jp --output=src\BlueOath.Server\configs [--namespace=BlueOath.Server.Configs]
```

- 每张表一个 `Config<表名>.cs`，命名空间 `BlueOath.Server.Configs`。
- 字段名转 PascalCase，并带 `[JsonPropertyName("原字段名")]` 保证 JSON 双向映射。
- 类型推断：整数 -> `long`，浮点/整浮混用 -> `double`，字符串 -> `string`，布尔 -> `bool`，
  数组 -> `List<T>`（支持 `List<List<T>>` 嵌套），类型混用/结构不明 -> `object`（可空）。
- 生成目录会先清理旧的 `Config*.cs`，再整体重写，可安全重复运行。
