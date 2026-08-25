using BlueOath.Core;
using BlueOath.Protocol;
using BlueOath.Server.Configs;

namespace BlueOath.Server.Protocols;

/// <summary>抽卡模块：buildship.*（BuildShip / BuildShipInfo / BuildShipBox / BuildShipReward）。</summary>
internal sealed class BuildShipModule(BuildShipService buildShip, GameServices services) : IGameModule
{
    public IReadOnlyList<string> Prefixes => ["buildship"];

    public async Task<ModuleResult> HandleAsync(GameContext ctx, TRequest request)
    {
        ModuleResult result;
        switch (request.Method)
        {
            case "buildship.BuildShip":
                var ret = await buildShip.BuildBuildShipRetAsync(request, ctx.ProfileId, ctx.Ct);
                // 应答前推送新抽到的舰娘（船坞 + 图鉴），客户端据此刷新列表。
                var pre = new List<byte[]>();
                if (ret.Length != 0)
                {
                    var account = await ctx.GetAccountAsync();
                    var newIds = services.GetLastBuildHeroIds();
                    var newHeroes = account.Dock.Heroes
                        .Where(h => newIds.Contains(h.HeroId))
                        .Select(ToHeroGridWithName)
                        .ToList();
                    if (newHeroes.Count > 0)
                    {
                        var now = (uint)ctx.Now;
                        pre.Add(TMessageCodec.EncodeResponse(new TResponse(
                            Method: "hero.UpdateHeroBagData",
                            Ret: PlayerDataCodec.Encode(new HeroBag(newHeroes, account.Dock.BagSize)),
                            Time: now)));
                        pre.Add(TMessageCodec.EncodeResponse(new TResponse(
                            Method: "illustrate.IllustrateInfo",
                            Ret: PlayerDataCodec.Encode(new IllustrateInfoRet(
                                IllustrateList: newHeroes
                                    .Select(h => new IllustrateInfo((h.TemplateId - 1) / 10, now, 0, false, null, 0))
                                    .ToList(),
                                IllustrateEquipList: [new IllustrateEquipInfo()])),
                            Time: now)));
                    }
                }
                result = new ModuleResult { Ret = ret, PrePushes = pre };
                break;
            case "buildship.BuildShipInfo":
                result = ModuleResult.Ok(new byte[] { 0x08, 0x00 }); // DrawInfo: empty
                break;
            case "buildship.BuildShipBox":
            case "buildship.BuildShipReward":
            default:
                result = ModuleResult.Empty;
                break;
        }
        return result;
    }

    private static HeroGrid ToHeroGridWithName(Hero h)
    {
        var grid = GameServices.ToHeroGrid(h);
        return grid with { Name = ShipHandbookLoader.GetShipName(h.TemplateId) };
    }
}
