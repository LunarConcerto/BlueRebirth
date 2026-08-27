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
}
