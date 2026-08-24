using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 协议路由器：按方法名前缀把 C2S 请求分发到对应的 <see cref="IGameModule"/>。
/// 未匹配到任何已实现模块时回落到 <see cref="OfflineStubModule"/>（离线空响应）。
/// </summary>
internal sealed class MessageRouter
{
    private readonly GameLoginMessageHandler _services;
    private readonly IReadOnlyList<IGameModule> _modules;
    private readonly OfflineStubModule _stub;

    public MessageRouter(GameLoginMessageHandler services, IEnumerable<IGameModule> modules)
    {
        _services = services;
        _modules = modules.ToList();
        _stub = new OfflineStubModule();
    }

    /// <summary>解析 player.Login 请求中的 Pid（供会话建立 profileId 关联）。</summary>
    public string ResolveLoginProfileId(TRequest request) => _services.ResolveLoginProfileId(request);

    /// <summary>分发请求并返回模块处理结果。</summary>
    public Task<ModuleResult> DispatchAsync(TRequest request, string profileId, CancellationToken ct)
    {
        var ctx = new GameContext
        {
            ProfileId = profileId,
            Now = checked((int)DateTimeOffset.UtcNow.ToUnixTimeSeconds()),
            Ct = ct,
            Services = _services,
        };
        var module = _modules.FirstOrDefault(m => request.Method.StartsWith(m.Prefix + ".", StringComparison.Ordinal));
        return (module ?? _stub).HandleAsync(ctx, request);
    }
}
