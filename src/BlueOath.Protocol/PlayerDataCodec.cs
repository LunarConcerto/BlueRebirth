namespace BlueOath.Protocol;

/// <summary>
/// Resources consumed by a single build formula. Currently empty; extend with the
/// TBuildProject fields (Items/Gold) when real build data is needed.
/// </summary>
public sealed record BuildProject();

/// <summary>A single ship-building formula (building / builded / waiting).</summary>
public sealed record BuildFormula(long EndTime = 0, BuildProject? Project = null, int HeroId = 0);

/// <summary>Payload for the <c>build.BuildsInfo</c> server message.</summary>
public sealed record BuildsInfoRet(
    IReadOnlyList<BuildFormula>? BuildedList = null,
    IReadOnlyList<BuildFormula>? BuildingList = null,
    IReadOnlyList<BuildFormula>? WaitingList = null,
    BuildFormula? BuildedLast = null);

/// <summary>One hero currently taking a bath.</summary>
public sealed record BathHeroInfo(
    uint HeroId = 0, int Pos = 0, int IsAuto = 0, long StartTime = 0,
    long BathTime = 0, int BuffId = 0, long BuffTime = 0, int Power = 0);

/// <summary>Payload for the <c>bathroom.BathroomInfo</c> server message.</summary>
public sealed record BathroomInfo(IReadOnlyList<BathHeroInfo>? HeroList = null, int IsAllAuto = 0);

/// <summary>One hero owned by the player (THeroGrid). Extend with Equips/PSkill/CurHp/etc. as needed.</summary>
public sealed record HeroGrid(uint HeroId = 0, int TemplateId = 0, int Lvl = 0, int Fashioning = 0);

/// <summary>Payload for the <c>hero.UpdateHeroBagData</c> server message (THeroInfo).</summary>
public sealed record HeroBag(IReadOnlyList<HeroGrid>? HeroInfo = null, int HeroBagSize = 0);

/// <summary>
/// Encodes the player-scope data pushed to the client after login (build queue, bathroom, ...).
/// Field numbers are taken from build_pb.lua / bathroom_pb.lua.
/// </summary>
public static class PlayerDataCodec
{
    public static byte[] Encode(BuildsInfoRet value)
    {
        using var output = new MemoryStream();
        if (value.BuildedList is not null)
            foreach (var item in value.BuildedList) WriteMessage(output, 1, Encode(item));
        if (value.BuildingList is not null)
            foreach (var item in value.BuildingList) WriteMessage(output, 2, Encode(item));
        if (value.WaitingList is not null)
            foreach (var item in value.WaitingList) WriteMessage(output, 3, Encode(item));
        if (value.BuildedLast is not null) WriteMessage(output, 4, Encode(value.BuildedLast));
        return output.ToArray();
    }

    public static byte[] Encode(BuildFormula value)
    {
        using var output = new MemoryStream();
        // EndTime is written explicitly (0 means "finished") so the client always sees a
        // number; BuildLogic.GetPushNoticeParams compares it and would error on nil.
        WriteVarintField(output, 1, unchecked((ulong)value.EndTime));
        if (value.Project is not null) WriteMessage(output, 2, Encode(value.Project));
        if (value.HeroId != 0) WriteVarintField(output, 3, unchecked((ulong)value.HeroId));
        return output.ToArray();
    }

    public static byte[] Encode(BuildProject _) => [];

    public static byte[] Encode(BathroomInfo value)
    {
        using var output = new MemoryStream();
        if (value.HeroList is not null)
            foreach (var item in value.HeroList) WriteMessage(output, 1, Encode(item));
        if (value.IsAllAuto != 0) WriteVarintField(output, 2, unchecked((ulong)value.IsAllAuto));
        return output.ToArray();
    }

    public static byte[] Encode(BathHeroInfo value)
    {
        using var output = new MemoryStream();
        // HeroId/StartTime are written explicitly so the client never sees nil; the notice
        // handler indexes args[1].HeroId and reads v.StartTime.
        WriteVarintField(output, 1, value.HeroId);
        if (value.Pos != 0) WriteVarintField(output, 2, unchecked((ulong)value.Pos));
        if (value.IsAuto != 0) WriteVarintField(output, 3, unchecked((ulong)value.IsAuto));
        WriteVarintField(output, 4, unchecked((ulong)value.StartTime));
        if (value.BathTime != 0) WriteVarintField(output, 5, unchecked((ulong)value.BathTime));
        if (value.BuffId != 0) WriteVarintField(output, 6, unchecked((ulong)value.BuffId));
        if (value.BuffTime != 0) WriteVarintField(output, 7, unchecked((ulong)value.BuffTime));
        if (value.Power != 0) WriteVarintField(output, 8, unchecked((ulong)value.Power));
        return output.ToArray();
    }

    public static byte[] Encode(HeroBag value)
    {
        using var output = new MemoryStream();
        if (value.HeroInfo is not null)
            foreach (var hero in value.HeroInfo) WriteMessage(output, 1, Encode(hero));
        if (value.HeroBagSize != 0) WriteVarintField(output, 2, unchecked((ulong)value.HeroBagSize));
        return output.ToArray();
    }

    public static byte[] Encode(HeroGrid value)
    {
        using var output = new MemoryStream();
        if (value.HeroId != 0) WriteVarintField(output, 1, value.HeroId);
        if (value.TemplateId != 0) WriteVarintField(output, 2, unchecked((ulong)value.TemplateId));
        if (value.Lvl != 0) WriteVarintField(output, 4, unchecked((ulong)value.Lvl));
        if (value.Fashioning != 0) WriteVarintField(output, 22, unchecked((ulong)value.Fashioning));
        return output.ToArray();
    }

    private static void WriteMessage(Stream output, int field, byte[] body)
    {
        WriteVarint(output, (ulong)((field << 3) | 2));
        WriteVarint(output, (ulong)body.Length);
        output.Write(body);
    }

    private static void WriteVarintField(Stream output, int field, ulong value)
    {
        WriteVarint(output, (ulong)(field << 3));
        WriteVarint(output, value);
    }

    private static void WriteVarint(Stream output, ulong value)
    {
        while (value >= 0x80)
        {
            output.WriteByte((byte)(value | 0x80));
            value >>= 7;
        }
        output.WriteByte((byte)value);
    }
}
