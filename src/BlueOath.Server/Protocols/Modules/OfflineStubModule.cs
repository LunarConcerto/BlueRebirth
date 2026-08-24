using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>
/// 兜底模块：处理尚未实现 / 离线模式下不适用的协议方法，统一返回空应答
/// （等价旧实现里数百个返回 <c>[]</c> 的 stub）；同时承载少数系统级方法
/// （GetSvrTime / cachedata.CacheData）。
/// </summary>
internal sealed class OfflineStubModule : IGameModule
{
    public string Prefix => "";

    public Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        byte[] ret = request.Method switch
        {
            "GetSvrTime" => TMessageCodec.EncodeRetGetSvrTime(ctx.Now, ctx.Now),
            "cachedata.CacheData" => ProtocolEncoder.EncodeCacheDataRet(),
            _ => []
        };
        return Task.FromResult(ModuleResult.Ok(ret));
    }
}
