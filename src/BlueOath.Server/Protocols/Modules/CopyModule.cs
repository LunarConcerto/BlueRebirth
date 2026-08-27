using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>关卡/战斗模块：copy.* / copyinfo.* / battle.*。</summary>
internal sealed class CopyModule(BattleService battle) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["copy", "copyinfo", "battle"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "copy.StartBase":
                result = ModuleResult.Ok(await battle.BuildStartBaseRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "copy.GetRandomFactors":
                result = ModuleResult.Ok(EncodeGetRandomFactors(request.Args ?? [], ctx.Services));
                break;
            case "copy.AttackBase":
                result = ModuleResult.Ok(ProtocolEncoder.BuildAttackBaseRet(request.Args));
                break;
            case "copy.PassBase":
                var ret = await battle.BuildPassBaseRetAsync(request, ctx.ProfileId, ctx.Ct);
                // 通关后推送与关卡类型匹配的最新进度。
                var account = await ctx.GetAccountAsync();
                int copyId = ProtocolDecoder.DecodePassBaseCopyId(request.Args ?? []);
                int copyType = ChapterCopyLoader.GetCopyType(copyId);
                byte[] copyPush = TMessageCodec.EncodeResponse(new TResponse(
                    Method: "copy.GetCopy",
                    Ret: copyType switch
                    {
                        2 => ProtocolEncoder.EncodeSeaCopyInfo(account.SeaProgress),
                        33 => ProtocolEncoder.EncodeMubarCopyInfo(),
                        _ => ProtocolEncoder.EncodePlotCopyInfo(int.MaxValue, account.CopyProgress),
                    },
                    Time: (uint)ctx.Now));
                result = new ModuleResult { Ret = ret, PostPushes = [copyPush] };
                break;
            case "copy.QuitBase":
                result = ModuleResult.Ok(ProtocolEncoder.BuildQuitBaseRet(request.Args));
                break;
            case "copy.GetCopy":
            case "copy.UnLockCopy":
                result = ModuleResult.Ok(ProtocolEncoder.EncodePlotCopyInfo());
                break;
            case "copyinfo.GetCopyInfo":
                result = ModuleResult.Ok(ProtocolEncoder.BuildCopyInfoRet(request.Args ?? []));
                break;
            case "copy.StarReward":
            case "copy.FetchRewardBox":
            case "copy.DeleteRecord":
            case "copy.GetRecord":
            case "copy.TacticOn":
            case "copy.ChooseSfLv":
            case "copy.PassMiniGame":
            case "copy.PvpStartBase":
            case "copy.DotBase":
            case "battle.CreateMutiBattle":
            case "battle.createBattleInfo":
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    /// <summary>响应 copy.GetRandomFactors（TGetRandomFactorRet）。海域详情页按
    /// config_copy_display.random_factor_sets 请求随机因子；无响应会使 LevelDetailsPage
    /// 的 _GetRandFactorCallback 不触发（拷贝逻辑 SetRandFactors 缺失）。</summary>
    private static byte[] EncodeGetRandomFactors(byte[] args, GameServices services)
    {
        int copyId = 0;
        var reader = new ProtocolDecoder.ProtoReader(args);
        while (reader.TryReadField(out int field, out int wire))
            if (field == 1 && wire == 0) copyId = checked((int)reader.ReadVarint()); // CopyId(1)
            else reader.Skip(wire);
        ProtocolPackage ms = new();
        if (services.CopyRandomFactors.TryGetValue(copyId, out var entries))
            foreach (var e in entries)
            {
                // TRandomFactor{ Factors(1) repeated int32, GroupId(2), SetId(3) }
                ProtocolPackage tf = new();
                foreach (int f in e.Factors)
                    tf.Write(0x08, unchecked((ulong)f));
                if (e.GroupId != 0)
                    tf.Write(0x10, unchecked((ulong)e.GroupId));
                if (e.SetId != 0)
                    tf.Write(0x18, unchecked((ulong)e.SetId));
                ms.Write(0x0A, tf.ToArray()); // TGetRandomFactorRet.Factors(1)
            }
        // LastRefreshTime(2)=0 / IsShowTips(3)=false 默认省略
        return ms.ToArray();
    }
}
