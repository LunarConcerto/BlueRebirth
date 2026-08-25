using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 协议模块接口：每个模块负责一类（或多类）协议前缀（如 <c>hero</c> / <c>tactic</c> / <c>shop</c>），
/// 由 <see cref="MessageRouter"/> 按方法名前缀路由分发。
/// </summary>
internal interface IGameModule
{
    /// <summary>模块前缀列表（如 ["hero", "tactic"]），匹配 "hero.*" / "tactic.*" 方法。</summary>
    IReadOnlyList<string> Prefixes { get; }

    /// <summary>处理一个 C2S 请求，返回应答与前后推送。</summary>
    Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request);
}
