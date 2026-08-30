using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>每日副本协议：数据快照与条约模式选择。</summary>
internal sealed class DailyCopyModule(DailyCopyService dailyCopy) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["dailycopy"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "dailycopy.GetData":
            {
                var account = await dailyCopy.GetRefreshedAccountAsync(ctx.ProfileId, ctx.Now, ctx.Ct);
                return new ModuleResult
                {
                    Ret = [],
                    PostPushes = [DailyCopyService.BuildUpdatePush(account.DailyCopy, (uint)ctx.Now)],
                };
            }
            case "dailycopy.SelectEx":
            {
                (int chapterId, bool selectEx) = DecodeSelectEx(request.Args ?? []);
                var account = await dailyCopy.SetSelectExAsync(
                    ctx.ProfileId, chapterId, selectEx, ctx.Now, ctx.Ct);
                return new ModuleResult
                {
                    Ret = [],
                    PostPushes = [DailyCopyService.BuildUpdatePush(account.DailyCopy, (uint)ctx.Now)],
                };
            }
            default:
                return ModuleResult.Empty;
        }
    }

    private static (int ChapterId, bool SelectEx) DecodeSelectEx(byte[] args)
    {
        int chapterId = 0;
        bool selectEx = false;
        ProtocolDecoder.ProtoReader reader = new(args);
        while (reader.TryReadField(out int field, out int wire))
            switch (field)
            {
                case 1 when wire == 0:
                    chapterId = checked((int)reader.ReadVarint());
                    break;
                case 2 when wire == 0:
                    selectEx = reader.ReadVarint() != 0;
                    break;
                default:
                    reader.Skip(wire);
                    break;
            }
        return (chapterId, selectEx);
    }
}
