using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>邮件模块：mail.*（列表/打开/删除/领取）。</summary>
internal sealed class MailModule(GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["mail"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "mail.GetMailList":
            case "mail.OpenMail":
            case "mail.DeleteMail":
            case "mail.DeleteAllMail":
            case "mail.ReceiveNewMail":
                result = ModuleResult.Ok(BuildMailListRet(ctx.Now));
                break;
            case "mail.FetchItem":
            case "mail.FetchAllItems":
                result = new ModuleResult
                {
                    Ret = await BuildFetchMailRetAsync(ctx, request),
                    PostPushes = [await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct)],
                };
                break;
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    /// <summary>把 GM 邮件配置转换为 MailList 实体列表（IsGotReawrd=0，可反复领取）。</summary>
    private IReadOnlyList<MailList> BuildMailEntities(int now) =>
        services.GmMails.Select(m => new MailList(
            m.Mid,
            Subject: m.Subject,
            Content: m.Content,
            ReceiveTime: now,
            ReadTime: 0,
            IsGotReawrd: 0,
            Items: [new MailItem(GameServices.GoodsTypeCurrency, m.CurrencyType, m.Num)],
            DeleteTime: 0)).ToList();

    /// <summary>邮件列表响应（mail.GetMailList/OpenMail/DeleteMail/DeleteAllMail/ReceiveNewMail 共用）。</summary>
    private byte[] BuildMailListRet(int now)
    {
        IReadOnlyList<MailList> list = BuildMailEntities(now);
        return PlayerDataCodec.Encode(new MailListRet(list.Count, List: list));
    }

    /// <summary>
    /// 邮件领取（mail.FetchItem / mail.FetchAllItems）：发放对应邮件的货币并落盘，邮件不删除
    /// （IsGotReawrd 保持 0，客户端仍显示"领取"按钮，实现无限领取）。返回 TMailListRet{list, Reward}。
    /// </summary>
    private async Task<byte[]> BuildFetchMailRetAsync(GameContext ctx, TRequest request)
    {
        ulong mid = request.Args is null ? 0UL : TMessageCodec.DecodeMailMid(request.Args);
        PlayerAccount account = await ctx.GetAccountAsync();
        List<CommonReward> rewards = new();
        foreach (GmMailConfig mail in services.GmMails)
        {
            if (request.Method == "mail.FetchItem" && mail.Mid != mid)
                continue;
            account = GameServices.AddCurrency(account, mail.CurrencyType, mail.Num);
            rewards.Add(new CommonReward(GameServices.GoodsTypeCurrency, mail.CurrencyType, mail.Num));
        }

        if (rewards.Count > 0)
            await services.SaveAccountAsync(account, ctx.Ct);
        IReadOnlyList<MailList> list = BuildMailEntities(ctx.Now);
        return PlayerDataCodec.Encode(new MailListRet(list.Count, List: list, Reward: rewards));
    }
}
