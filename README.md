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

## 客户端启动

```powershell
dotnet run --project .\src\BlueOath.Launcher\BlueOath.Launcher.csproj -- --region=jp --original
```

没有经过运行时验证的 x86 注入点会被启动器拒绝，避免对客户端执行未知补丁。

## 基线与 Mod

`tools/baseline.ps1` 生成 `baseline.json`，记录两服版本、架构和关键文件 SHA-256。示例 Mod 位于 `Mods/example.mod`。`BlueOath.Mods` 负责清单、目标版本、依赖和加载顺序发现，并将事件排队给后续 xLua runtime handoff。

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
