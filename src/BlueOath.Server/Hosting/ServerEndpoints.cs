namespace BlueOath.Server.Hosting;

/// <summary>
/// 各监听器实际绑定的端口。监听器在启动时（打印 ready 之前）回填这些值，
/// 使其他组件（主要是 HTTP 引导响应器）能对外通告正确的端点。
/// </summary>
internal sealed class ServerEndpoints
{
    /// <summary>主端口（JSON 帧游戏协议 + HTTP 引导共用）。</summary>
    public int Port { get; set; }

    /// <summary>游戏登录 TCP 端口（NetSocket 帧），未启用时为 null。</summary>
    public int? GameLoginPort { get; set; }

    /// <summary>游戏登录 KCP/UDP 端口，未启用时为 null。</summary>
    public int? KcpGameLoginPort { get; set; }

    /// <summary>GM WebUI 端口，未启用时为 null。</summary>
    public int? GmPort { get; set; }

    /// <summary>返回引导响应中使用的游戏登录端口，未配置时回退到默认 7201。</summary>
    public int ResolvedGameLoginPort => GameLoginPort is > 0 ? GameLoginPort.Value : 7201;
}
