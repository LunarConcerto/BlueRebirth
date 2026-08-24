using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 协议模块接口：每个模块负责一类协议前缀（如 <c>hero</c> / <c>shop</c>），
/// 由 <see cref="MessageRouter"/> 按方法名前缀路由分发。
/// </summary>
internal interface IGameModule
{
    /// <summary>模块前缀（如 "hero"），匹配 "hero.*" 方法。</summary>
    string Prefix { get; }

    /// <summary>处理一个 C2S 请求，返回应答与前后推送。</summary>
    Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request);
}
