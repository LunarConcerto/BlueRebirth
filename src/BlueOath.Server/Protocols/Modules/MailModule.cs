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
                    PostPushes = await BuildFetchPostPushesAsync(ctx),
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
            Items: [ToMailItem(m)],
            DeleteTime: 0)).ToList();

    /// <summary>邮件列表响应（mail.GetMailList/OpenMail/DeleteMail/DeleteAllMail/ReceiveNewMail 共用）。</summary>
    private byte[] BuildMailListRet(int now)
    {
        IReadOnlyList<MailList> list = BuildMailEntities(now);
        return PlayerDataCodec.Encode(new MailListRet(list.Count, List: list));
    }

    /// <summary>
    /// 邮件领取（mail.FetchItem / mail.FetchAllItems）：按配置发放对应邮件的货币或道具并落盘，
    /// 邮件不删除（IsGotReawrd 保持 0，客户端仍显示"领取"按钮，实现无限领取）。
    /// 返回 TMailListRet{list, Reward}。
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
            account = ApplyMailReward(account, mail);
            rewards.Add(ToCommonReward(mail));
        }

        if (rewards.Count > 0)
            await services.SaveAccountAsync(account, ctx.Ct);
        IReadOnlyList<MailList> list = BuildMailEntities(ctx.Now);
        return PlayerDataCodec.Encode(new MailListRet(list.Count, List: list, Reward: rewards));
    }

    /// <summary>领取后的数据推送：用户信息（货币）+ 仓库（道具），供客户端刷新。</summary>
    private async Task<IReadOnlyList<byte[]>> BuildFetchPostPushesAsync(GameContext ctx)
    {
        var account = await ctx.GetAccountAsync();
        return
        [
            await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, (uint)ctx.Now, ctx.Ct),
            services.BuildBagPush(account, (uint)ctx.Now),
        ];
    }

    /// <summary>邮件附件实体：直接用配置的 GoodsType（客户端按 config_table_index[GoodsType] 渲染）。</summary>
    private static MailItem ToMailItem(GmMailConfig mail) => new(mail.GoodsType, mail.ConfigId, mail.Num);

    /// <summary>发放邮件奖励到账号：货币走 AddCurrency，其余（道具/材料）走 AddBagItem。</summary>
    private static PlayerAccount ApplyMailReward(PlayerAccount account, GmMailConfig mail) =>
        mail.GoodsType == GameServices.GoodsTypeCurrency
            ? GameServices.AddCurrency(account, mail.ConfigId, mail.Num)
            : GameServices.AddBagItem(account, mail.ConfigId, mail.Num);

    /// <summary>领取奖励的 CommonReward（返回给客户端的 Reward 列表）。</summary>
    private static CommonReward ToCommonReward(GmMailConfig mail) => new(mail.GoodsType, mail.ConfigId, mail.Num);
}
