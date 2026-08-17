# 苍蓝誓约本地服（BlueOath.Server）代码规范

> 适用范围：`src/BlueOath.Server` 项目（含 `Hosting` / `Listeners` / `Sessions` / `Protocols` / `Infrastructure` 各层）。
> 目标：让本地服后续的改动保持风格一致、职责清晰、可测试。本规范为**现状约定**——现有代码已按此编写，新增代码请遵守。

## 1. 项目分层与命名空间

按职责拆层，每层一个子命名空间；命名空间名与目录名一致：

| 命名空间 | 目录 | 职责 |
| --- | --- | --- |
| `BlueOath.Server` | （根） | 入口、参数解析 |
| `BlueOath.Server.Hosting` | `Hosting/` | 组合根、端口共享 |
| `BlueOath.Server.Listeners` | `Listeners/` | 传输监听（`IHostedService`） |
| `BlueOath.Server.Sessions` | `Sessions/` | 每个连接的处理循环 |
| `BlueOath.Server.Protocols` | `Protocols/` | 协议/业务处理器（编解码、响应构建） |
| `BlueOath.Server.Infrastructure` | `Infrastructure/` | 通用基础设施（TLS、日志、流包装） |

规则：
- 一律使用 **file-scoped namespace**（`namespace X;`）。
- 依赖方向：`Listeners → Sessions → Protocols → Infrastructure/Hosting`；`Hosting` 负责把各层装配起来，各层之间只通过构造函数注入，不直接 `new` 具体依赖。

## 2. 文件组织

- **一个文件一个主类型**，文件名与类型名一致（含 `record`）。
- 仅当某类型被唯一一处使用且语义内聚时才嵌套（如 `KcpGameLoginListener` 内的 `KcpPeer`、`GameLoginFileLoggerProvider` 内的 `GameLoginFileLogger`）。
- 小的伴生 `record`（如 `TrafficAnalysis`、`BootstrapHttpResponse`）可与其使用者放同一文件，但放在使用类之前。

## 3. 命名规范

| 元素 | 风格 | 示例 |
| --- | --- | --- |
| 类型（class/record/interface/enum） | PascalCase | `FrontDoorTcpListener`、`ServerEndpoints` |
| 方法 | PascalCase | `BuildResponse`、`RunAsync`、`StartAsync` |
| 属性 | PascalCase | `ResolvedGameLoginPort`、`GameLoginPort` |
| 私有字段 | `_camelCase`，能 `readonly` 就 `readonly` | `_repo`、`_fileLogger`、`_listener` |
| 参数 / 局部变量 | camelCase | `connectionId`、`captureRoot`、`ct` |
| 常量 | PascalCase | `GameLoginFileLoggerProvider.Category`、`KcpCodec.HeaderLength` |

补充：
- 事件/回调用 `Async` 后缀标记返回值是 `Task`/`ValueTask`。
- 布尔相关属性/方法用 `Is` / `Has` / `Can` / `Looks` 前缀（如 `LooksLikeLocalFrame`、`LooksLikeHttp`）。
- 取消令牌参数命名：会话/业务方法用 `ct`；`BackgroundService.ExecuteAsync` 用 `stoppingToken`；`StartAsync`/`StopAsync` 重写用 `cancellationToken`（与基类签名一致）。

## 4. 类型与可见性

- 默认 `internal`；只有被其它程序集（`BlueOath.Core` / `.Protocol` / `.Storage` / `.Tests`）引用的类型才 `public`。本地服内部类型一律 `internal`。
- 类默认 `sealed`（`internal sealed class`），除非确需继承（本项目无）。
- 无状态工具类用 `internal static class`（如 `HttpTrafficAnalyzer`、`ServerHostBuilder`）。
- 纯数据用 `record`（位置参数）：`ServerOptions`、`TrafficAnalysis`、`BootstrapHttpResponse`。
- 需要运行时回填的可变共享状态才用带 `set` 的类（如 `ServerEndpoints`）。

## 5. 构造函数与字段

- 优先使用 **primary constructor**（C# 12）做简单依赖捕获，再在类体里落为 `private readonly` 字段：

  ```csharp
  internal sealed class JsonGameSession(GameService game, SqliteGameRepository repo)
  {
      private readonly GameService _game = game;
      private readonly SqliteGameRepository _repo = repo;
  }
  ```

- 当构造函数需要**计算字段**（例如从 `ILoggerFactory` 派生多个日志器、或依赖可空）时，退回传统构造函数：

  ```csharp
  internal sealed class GameLoginMessageHandler
  {
      public GameLoginMessageHandler(SqliteGameRepository repo, ILoggerFactory loggerFactory)
      {
          _repo = repo;
          _logger = loggerFactory.CreateLogger<GameLoginMessageHandler>();
          _fileLogger = loggerFactory.CreateLogger(GameLoginFileLoggerProvider.Category);
      }
  }
  ```

- 依赖一律通过**构造函数注入**，字段按 `readonly` 声明。

## 6. 注释规范

- 所有 `internal` 类型与有非平凡语义的成员都写中文 XML `<summary>`（一句话说清「是什么 / 为什么存在」）。
- 只在解释 **为什么（why）** 时写 `//` 行内注释，不写「做什么」的废话注释（代码自明）。
- 逆向得到的**硬编码依据**（字段号、模板 ID、字符串/数字类型差异、客户端解析行为等）必须用中文注释说明，避免后人当成魔法数字删掉。例如 `BootstrapHttpResponder` 每个端点、`GameLoginMessageHandler` 的秘书舰 `TemplateId/Fashioning`。
- 不写英文注释；新注释统一中文。

## 7. 日志规范

日志分级分出口，**stdout 是契约，禁止乱用**：

| 出口 | 用途 |
| --- | --- |
| stdout | 仅 `Program` 输出的 `ready` JSON（及 `--tls-material-only` JSON），启动器/测试读取 |
| stderr | 一般诊断（`kcp-game-login`、`capture[...]`、`session[...]` 等），经 `ILogger<T>` |
| `game-login.log` | 游戏登录帧诊断，经类别 `BlueOath.Server.GameLogin` + `GameLoginFileLoggerProvider` |

规则：
- 用 `ILogger`，**禁止** `Console.Write*`（`Program` 里的 ready JSON 是唯一例外）。
- 帧/包等敏感诊断用 `ILoggerFactory.CreateLogger(GameLoginFileLoggerProvider.Category)`；一般诊断用 `ILogger<T>`。
- 优先结构化日志占位符（`_logger.LogInformation("capture[{ConnectionId}] kind={Kind}", id, kind)`），异常单独作为 `LogError(ex, ...)` 的第一个参数。

## 8. 依赖注入与组合根

- 所有服务、监听器在 `Hosting/ServerHostBuilder.Build` 中集中注册，不在各层散落 `new`。
- 无状态处理器注册为单例；监听器同时注册为具体类型 + `IHostedService`，并按启动顺序注册（保证 ready 打印前端口已绑定）。
- 可选依赖（如 `--tls-auto` 才有的 `DevelopmentTlsMaterial`）用工厂构造 + `sp.GetService<T>()` 取 null，而不是注册 null 实例。

## 9. 异步与取消

- 所有 I/O 方法带 `CancellationToken` 并一路透传，不 `Task.Run` 包裹。
- 监听循环用 `BackgroundService`：在 `StartAsync` 同步绑定 socket 并回填 `ServerEndpoints`，在 `ExecuteAsync` 跑 accept/receive 循环。
- 停止时吞掉 `OperationCanceledException`（正常关闭），`finally` 里释放监听资源。
- 不需要在空取消令牌上等待时，用 `CancellationToken.None`（如抓包落盘 `File.WriteAllBytesAsync(..., CancellationToken.None)`）。

## 10. 异常处理

- 只在会话边界捕获 `Exception` 并记日志（不吞掉、不破坏连接外层）；业务校验用显式异常（`InvalidOperationException` / `KeyNotFoundException` / `InvalidDataException`）。
- 区分「可预期失败」与「协议错误」：非法帧用 `InvalidDataException`，业务不满足条件用 `InvalidOperationException`。

## 11. Nullable 与编译约束

- `Nullable` 已全局开启；仅在确有把握时用 `!`（如 `((IPEndPoint)listener.LocalEndpoint).Port`、`Client.LocalEndPoint!`），并补一句「为什么非空」的注释。
- 全局 `TreatWarningsAsErrors=true`：**提交前必须 0 警告 0 错误**。
- 语言版本 `latest`，可用 C# 12 特性（primary constructor、collection expression `[]`、`u8` 字符串等）。

## 12. 验证命令

```powershell
dotnet restore .\BlueOath.Local.sln
dotnet build  .\BlueOath.Local.sln --no-restore          # 必须 0 警告 0 错误
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj --no-build
dotnet run --project .\src\BlueOath.Tests\BlueOath.Tests.csproj --no-build -- --integration
```

## 13. 参考骨架

```csharp
using Microsoft.Extensions.Hosting;

namespace BlueOath.Server.Listeners;

/// <summary>一句话说明这个监听器负责哪套传输。</summary>
internal sealed class ExampleTcpListener : BackgroundService
{
    private readonly ServerOptions _options;
    private TcpListener? _listener;

    public ExampleTcpListener(ServerOptions options)
    {
        _options = options;
    }

    public override Task StartAsync(CancellationToken cancellationToken)
    {
        var listener = new TcpListener(IPAddress.Loopback, _options.Port);
        listener.Start();
        _listener = listener;
        return base.StartAsync(cancellationToken);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var listener = _listener;
        if (listener is null)
            return;

        try
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                var client = await listener.AcceptTcpClientAsync(stoppingToken);
                _ = HandleAsync(client, stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
        }
        finally
        {
            listener.Stop();
        }
    }

    private Task HandleAsync(TcpClient client, CancellationToken ct)
    {
        // TODO: 会话处理
        return Task.CompletedTask;
    }
}
```
