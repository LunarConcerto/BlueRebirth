using BlueOath.Core;
using BlueOath.Storage;
using BlueOath.Server.Infrastructure;
using BlueOath.Server.Listeners;
using BlueOath.Server.Protocols;
using BlueOath.Server.Sessions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Console;

namespace BlueOath.Server.Hosting;

/// <summary>
/// 组合根：根据启动参数构建 Generic Host，注册所有服务、监听器与日志。
/// </summary>
internal static class ServerHostBuilder
{
    public static IHost Build(ServerOptions options)
    {
        var builder = Host.CreateApplicationBuilder();

        // 所有诊断日志走 stderr（或 game-login 文件）；stdout 只保留启动器与集成测试
        // 读取的那一行 ready JSON。
        builder.Logging.ClearProviders();
        builder.Logging.SetMinimumLevel(LogLevel.Information);
        builder.Logging.AddConsole(console => console.LogToStandardErrorThreshold = LogLevel.Trace);
        // game-login 帧日志只写文件，避免在 stderr 重复打印。
        builder.Logging.AddFilter<ConsoleLoggerProvider>(GameLoginFileLoggerProvider.Category, LogLevel.None);
        builder.Logging.AddProvider(new GameLoginFileLoggerProvider());

        // GM WebUI 的日志广播器（SSE 实时推送）。
        var logBroadcast = new LogBroadcastProvider();
        builder.Logging.AddProvider(logBroadcast);

        builder.Services.AddSingleton(options);
        builder.Services.AddSingleton<ServerEndpoints>();
        builder.Services.AddSingleton<SqliteGameRepository>(sp =>
            new SqliteGameRepository(sp.GetRequiredService<ServerOptions>().DataRoot));
        builder.Services.AddSingleton<GameService>(sp =>
            new GameService(
                sp.GetRequiredService<SqliteGameRepository>(),
                sp.GetRequiredService<ServerOptions>().Profile));

        // --tls-auto 时在主端口上启用 TLS，一次性生成开发证书并注册为单例。
        if (options.EnableTls)
            builder.Services.AddSingleton(DevelopmentTlsMaterial.Create(
                options.TlsOutputRoot ?? Path.Combine(options.DataRoot, "_tls")));

        // 协议/会话处理器（无状态，单例共享）。
        builder.Services.AddSingleton<GameServices>();
        builder.Services.AddSingleton<BootstrapHttpResponder>();
        builder.Services.AddSingleton<JsonGameSession>();
        builder.Services.AddSingleton<BootstrapHttpSession>();

        // 领域服务（共享服务之上的按域拆分）。
        builder.Services.AddSingleton<UserService>();
        builder.Services.AddSingleton<BuildShipService>();
        builder.Services.AddSingleton<ShopService>();
        builder.Services.AddSingleton<BattleService>();
        builder.Services.AddSingleton<HeroService>();

        // 协议模块（每域一个类）+ 路由器。
        builder.Services.AddSingleton<IGameModule, PlayerModule>();
        builder.Services.AddSingleton<IGameModule, MailModule>();
        builder.Services.AddSingleton<IGameModule, GuideModule>();
        builder.Services.AddSingleton<IGameModule, BathroomModule>();
        builder.Services.AddSingleton<IGameModule, FashionModule>();
        builder.Services.AddSingleton<IGameModule, ShopModule>();
        builder.Services.AddSingleton<IGameModule, HeroModule>();
        builder.Services.AddSingleton<IGameModule, UserModule>();
        builder.Services.AddSingleton<IGameModule, BuildShipModule>();
        builder.Services.AddSingleton<IGameModule, CopyModule>();
        builder.Services.AddSingleton<MessageRouter>();
        builder.Services.AddSingleton<GameLoginSession>();

        // GM 模块（WebUI + 命令解析）。
        builder.Services.AddSingleton(logBroadcast);
        builder.Services.AddSingleton<GmCommandHandler>();
        builder.Services.AddSingleton<GmWebListener>();

        // 主监听器可选择性携带 TLS 材质，故用工厂构造（未启用 TLS 时 GetService 返回 null）。
        builder.Services.AddSingleton<FrontDoorTcpListener>(sp => new FrontDoorTcpListener(
            sp.GetRequiredService<ServerOptions>(),
            sp.GetRequiredService<ServerEndpoints>(),
            sp.GetRequiredService<JsonGameSession>(),
            sp.GetRequiredService<BootstrapHttpSession>(),
            sp.GetService<DevelopmentTlsMaterial>(),
            sp.GetRequiredService<ILogger<FrontDoorTcpListener>>()));
        builder.Services.AddSingleton<GameLoginTcpListener>();

        // 按注册顺序启动，保证 ready 打印前所有端口已绑定。
        builder.Services.AddSingleton<IHostedService>(sp => sp.GetRequiredService<FrontDoorTcpListener>());
        builder.Services.AddSingleton<IHostedService>(sp => sp.GetRequiredService<GameLoginTcpListener>());
        builder.Services.AddSingleton<IHostedService>(sp => sp.GetRequiredService<GmWebListener>());

        return builder.Build();
    }
}
