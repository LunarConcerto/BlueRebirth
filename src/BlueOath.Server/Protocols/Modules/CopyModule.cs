using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>关卡/战斗模块：copy.* / copyinfo.* / battle.*。</summary>
internal sealed class CopyModule(BattleService battle) : IGameModule
{
    public string Prefix => "copy";

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "copy.StartBase":
                result = ModuleResult.Ok(await battle.BuildStartBaseRetAsync(request, ctx.ProfileId, ctx.Ct));
                break;
            case "copy.AttackBase":
                result = ModuleResult.Ok(GameServices.BuildAttackBaseRet(request.Args));
                break;
            case "copy.PassBase":
                var ret = await battle.BuildPassBaseRetAsync(request, ctx.ProfileId, ctx.Ct);
                // 通关后推送最新关卡进度（剧情/海域各一分支）。
                var account = await ctx.GetAccountAsync();
                int copyId = GameServices.DecodePassBaseCopyId(request.Args ?? []);
                int copyType = ChapterCopyLoader.GetCopyType(copyId);
                byte[] copyPush = TMessageCodec.EncodeResponse(new TResponse(
                    Method: "copy.GetCopy",
                    Ret: copyType == 2
                        ? GameServices.EncodeSeaCopyInfo(account.SeaProgress)
                        : GameServices.EncodePlotCopyInfo(int.MaxValue, account.CopyProgress),
                    Time: (uint)ctx.Now));
                result = new ModuleResult { Ret = ret, PostPushes = [copyPush] };
                break;
            case "copy.QuitBase":
                result = ModuleResult.Ok(GameServices.BuildQuitBaseRet(request.Args));
                break;
            case "copy.GetCopy":
            case "copy.UnLockCopy":
                result = ModuleResult.Ok(GameServices.EncodePlotCopyInfo());
                break;
            case "copyinfo.GetCopyInfo":
                result = ModuleResult.Ok(GameServices.BuildCopyInfoRet(request.Args ?? []));
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
