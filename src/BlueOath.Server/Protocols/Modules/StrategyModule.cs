using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 战术模块：strategy.*。strategy.GetStrategy 返回全部战术（Level=1 解锁），
/// 使客户端战术页面不再显示"未解锁"；Learn/Upgrade/Reset/Apply 返回成功。
/// </summary>
internal sealed class StrategyModule : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["strategy"];

    public Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result = request.Method switch
        {
            "strategy.GetStrategy" => ModuleResult.Ok(ProtocolEncoder.EncodeStrategyRet(
                StrategyConfigLoader.All.Select(s => ((int)s.Id, 1)), resetNum: 0)),
            "strategy.Learn" or "strategy.Upgrade" or "strategy.Reset" or "strategy.Apply" => ModuleResult.Ok([]),
            _ => ModuleResult.Empty,
        };
        return Task.FromResult(result);
    }
}