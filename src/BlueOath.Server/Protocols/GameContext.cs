using BlueOath.Core;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 单个 C2S 请求的上下文：携带当前会话的 profileId、服务器时间、取消令牌，
/// 以及共享服务（<see cref="Services"/>）用于访问账号/编解码/共享实体操作。
/// </summary>
internal sealed class GameContext
{
    /// <summary>当前会话关联的档案 ID。</summary>
    public required string ProfileId { get; init; }

    /// <summary>服务器当前时间（Unix 秒）。</summary>
    public required int Now { get; init; }

    /// <summary>请求取消令牌。</summary>
    public required CancellationToken Ct { get; init; }

    /// <summary>共享服务（账号加载、编解码、货币/道具/舰娘操作等）。</summary>
    public required GameLoginMessageHandler Services { get; init; }

    /// <summary>加载（或创建）当前账号。</summary>
    public Task<PlayerAccount> GetAccountAsync() => Services.GetOrCreateAccountAsync(ProfileId, Ct);
}
