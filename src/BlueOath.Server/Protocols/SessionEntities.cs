namespace BlueOath.Server.Protocols;

/// <summary>登录处理结果：协议操作码 + 编码后的响应负载 + 关联的 profileId。</summary>
internal sealed record LoginPayload(int Operation, byte[] Payload, string ProfileId);
