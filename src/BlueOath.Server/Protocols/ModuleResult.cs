namespace BlueOath.Server.Protocols;

/// <summary>
/// 模块处理结果：应答 payload + 应答前/后的主动推送。
/// 会话层按「PrePushes → 应答 → PostPushes」顺序写回客户端。
/// </summary>
internal sealed class ModuleResult
{
    /// <summary>空结果（无应答、无推送）。</summary>
    public static ModuleResult Empty { get; } = new();

    /// <summary>应答 payload（TResponse.Ret）；为空表示不发送应答。</summary>
    public byte[] Ret { get; init; } = [];

    /// <summary>业务错误码；0 表示成功，非 0 时客户端进入失败回调。</summary>
    public int Err { get; init; }

    /// <summary>业务错误说明。</summary>
    public string ErrMsg { get; init; } = "";

    /// <summary>应答前需发送的推送（如 guide.GuideInfo / user.UpdateUserInfo）。</summary>
    public IReadOnlyList<byte[]> PrePushes { get; init; } = [];

    /// <summary>应答后需发送的推送（如购买后刷新数据）。</summary>
    public IReadOnlyList<byte[]> PostPushes { get; init; } = [];

    public static ModuleResult Ok(byte[] ret) => new() { Ret = ret };
}
