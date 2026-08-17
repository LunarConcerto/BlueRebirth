using System.Text.Json;
using BlueOath.Server.Hosting;
using BlueOath.Server.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace BlueOath.Server;

/// <summary>
/// 服务器入口：解析命令行参数，组装并启动 Generic Host，向标准输出打印就绪信息后进入运行状态。
/// </summary>
internal static class Program
{
    public static async Task Main(string[] args)
    {
        var options = ServerOptions.Parse(args);

        // 抓包目录提前创建，避免连接到达时再失败。
        if (options.CaptureRoot is not null)
            Directory.CreateDirectory(options.CaptureRoot);

        // 仅生成 TLS 开发证书（供启动脚本/OpenSSL 代理使用）后即退出。
        if (options.TlsMaterialOnly)
        {
            using var material = DevelopmentTlsMaterial.Create(
                options.TlsOutputRoot ?? Path.Combine(options.DataRoot, "_tls"));
            Console.WriteLine(JsonSerializer.Serialize(new
            {
                ready = true,
                tlsMaterial = true,
                rootCertificate = material.RootCertificatePath,
                leafCertificate = material.LeafCertificatePath,
                leafPem = material.LeafPemPath,
                leafKeyPem = material.LeafKeyPemPath
            }));
            return;
        }

        // 组装并启动 Host。StartAsync 返回时各监听器已完成端口绑定，
        // 因此随后输出的 ready JSON 中的端口为真实端口。
        using var host = ServerHostBuilder.Build(options);
        await host.StartAsync();

        var endpoints = host.Services.GetRequiredService<ServerEndpoints>();
        var tls = host.Services.GetService<DevelopmentTlsMaterial>();

        // stdout 的第一行必须是这段 ready JSON：启动器与集成测试都读取并解析它。
        Console.WriteLine(JsonSerializer.Serialize(new
        {
            ready = true,
            port = endpoints.Port,
            gameLoginPort = endpoints.GameLoginPort,
            kcpGameLoginPort = endpoints.KcpGameLoginPort,
            region = options.Profile.Region.ToString(),
            version = options.Profile.ClientVersion,
            tls = tls is not null,
            rootCertificate = tls?.RootCertificatePath,
            leafCertificate = tls?.LeafCertificatePath,
            leafPem = tls?.LeafPemPath,
            leafKeyPem = tls?.LeafKeyPemPath,
            capture = options.CaptureRoot
        }));
        Console.Out.Flush();

        // 阻塞直到收到 Ctrl+C（由 Generic Host 的 ConsoleLifetime 处理）。
        await host.WaitForShutdownAsync();
    }
}
