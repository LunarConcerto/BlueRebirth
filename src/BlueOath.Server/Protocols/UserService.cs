using BlueOath.Core;
using BlueOath.Protocol;

namespace BlueOath.Server.Protocols;

/// <summary>用户档案服务：user.SetUserSecretary / ChangeName / SetMessage / SetPlayerHeadFrame / SetHead。</summary>
internal sealed class UserService(GameServices services)
{
    /// <summary>
    /// 处理用户档案更新（秘书舰/改名/签名/头像/头像框）。
    /// 解码对应协议的 arg，更新 PlayerCharacter，落盘，返回空响应。
    /// </summary>
    internal async Task<byte[]> BuildUserProfileUpdateAsync(TRequest request, string profileId, CancellationToken ct,
        string field)
    {
        if (request.Args is null) return [];
        PlayerAccount account = await services.GetOrCreateAccountAsync(profileId, ct);
        PlayerCharacter c = account.Character;

        if (field == "Secretary")
        {
            // TSetUserSecretaryArg: SecretaryId(1, uint32)
            ulong secId = ProtocolDecoder.DecodeVarintField(request.Args, 1);
            if (secId == 0) return [];
            c = c with { SecretaryId = (uint)secId };
        }
        else if (field == "Name")
        {
            // TUserChangeNameArg: Name(1, string)
            string? name = ProtocolDecoder.DecodeStringField(request.Args, 1);
            if (string.IsNullOrWhiteSpace(name)) return [];
            c = c with { Name = name };
        }
        else if (field == "Message")
        {
            // TSetUserMsgArg: Message(1, string)
            string? msg = ProtocolDecoder.DecodeStringField(request.Args, 1);
            c = c with { Message = msg ?? "" };
        }
        else if (field == "HeadFrame")
        {
            // TUserSetPlayerHeadFrameArg: headFrameId(1, int32)
            ulong frameId = ProtocolDecoder.DecodeVarintField(request.Args, 1);
            c = c with { HeadFrame = (int)frameId };
        }
        else if (field == "Head")
        {
            // TNewHeadBuyHeadArg: ShipFleetId(1, int32), ProfileID(2, int32) — 取 ProfileID
            ulong profileId_i = ProtocolDecoder.DecodeVarintField(request.Args, 2);
            if (profileId_i == 0) return [];
            c = c with { Head = (int)profileId_i };
        }
        else
        {
            return [];
        }

        account = account with { Character = c };
        await services.SaveAccountAsync(account, ct);
        return [];
    }
}
