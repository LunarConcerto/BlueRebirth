using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>传统舰船建造模块：配方、队列、快速完成与领取。</summary>
internal sealed class BuildModule(ConstructionService construction, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["build"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        switch (request.Method)
        {
            case "build.BuildsInfo":
                return ModuleResult.Ok(await construction.BuildInfoAsync(ctx.ProfileId, ctx.Now, ctx.Ct));

            case "build.BuildingByFormula":
            {
                ConstructionService.MutationResult mutation =
                    await construction.StartAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                if (!mutation.Changed) return Error(mutation);
                PlayerAccount account = await ctx.GetAccountAsync();
                uint now = (uint)ctx.Now;
                return new ModuleResult
                {
                    Ret = mutation.Ret,
                    PrePushes =
                    [
                        BuildInfoPush(account, now),
                        services.BuildBagPush(account, now),
                        await services.BuildUpdateUserInfoPushAsync(ctx.ProfileId, now, ctx.Ct),
                    ],
                };
            }

            case "build.BuildQuicklyFinish":
            {
                ConstructionService.MutationResult mutation =
                    await construction.QuicklyFinishAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                if (!mutation.Changed) return Error(mutation);
                PlayerAccount account = await ctx.GetAccountAsync();
                uint now = (uint)ctx.Now;
                return new ModuleResult
                {
                    Ret = mutation.Ret,
                    PrePushes = [BuildInfoPush(account, now), services.BuildBagPush(account, now)],
                };
            }

            case "build.BuildReceive":
            {
                ConstructionService.MutationResult mutation =
                    await construction.ReceiveAsync(request, ctx.ProfileId, ctx.Now, ctx.Ct);
                if (!mutation.Changed) return Error(mutation);
                PlayerAccount account = await ctx.GetAccountAsync();
                uint now = (uint)ctx.Now;
                List<Hero> added = account.Dock.Heroes
                    .Where(hero => mutation.AddedHeroIds?.Contains(hero.HeroId) == true).ToList();
                List<byte[]> pushes = [BuildInfoPush(account, now)];
                if (added.Count > 0)
                {
                    pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
                        Method: "hero.UpdateHeroBagData",
                        Ret: PlayerDataCodec.Encode(new HeroBag(
                            added.Select(GameServices.ToHeroGrid).ToList(), account.Dock.BagSize)),
                        Time: now)));
                    pushes.Add(TMessageCodec.EncodeResponse(new TResponse(
                        Method: "illustrate.IllustrateInfo",
                        Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                            IllustrateList: added.Select(hero => new IllustrateInfo(
                                GameServices.ToIllustrateId(hero.TemplateId), now)).ToList(),
                            IllustrateEquipList: [new IllustrateEquipInfo()])),
                        Time: now)));
                    pushes.Add(services.BuildEquipPush(account, now));
                }
                return new ModuleResult { Ret = mutation.Ret, PrePushes = pushes };
            }

            default:
                return ModuleResult.Empty;
        }
    }

    internal static byte[] BuildInfoPush(PlayerAccount account, uint now) =>
        TMessageCodec.EncodeResponse(new TResponse(
            Method: "build.BuildsInfo",
            Ret: ConstructionService.EncodeInfo(account.Construction),
            Time: now));

    private static ModuleResult Error(ConstructionService.MutationResult mutation) => new()
    {
        Ret = mutation.Ret,
        Err = 1,
        ErrMsg = mutation.Error,
    };
}
