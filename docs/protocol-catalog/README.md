# Blue Oath protocol and event catalog

> Generated schema `1.2` at `2026-08-13T04:13:05.9947679+00:00`. Static candidates are not wire-level confirmations.

## Evidence model

- **confirmed**: directly observed in loopback runtime capture or SDK callback logs.
- **inferred**: supported by paired request/response names or strong static evidence.
- **candidate**: isolated metadata/binary string requiring call-site or runtime validation.

## Coverage

| Client | Message candidates | Protocol symbols | Hosts | Metadata strings |
| --- | ---: | ---: | ---: | ---: |
| `jp-1.4.0` | 73 | 1351 | 0 | 97587 |
| `cn-1.5.20` | 73 | 1348 | 0 | 96695 |

## Confirmed SDK events

| ID | Semantic name | Trigger | Parameters | Confidence |
| ---: | --- | --- | --- | ---: |
| 1 | `sdk_initialized` | `initSDK callback` | `ActionType`, `errornu` | 95% |
| 19 | `apple_review` | `getAppleReview` | `errornu`, `applereview` | 95% |
| 27 | `switch_state` | `switch/getstate` | `errornu`, `errordesc`, `DNS_sw.state` | 95% |
| 1007 | `platform_data` | `getPlData/getPlData` | `errornu`, `errordesc`, `data (shape unresolved)` | 95% |

## Confirmed HTTP endpoints

| Method | Path | Host | Evidence |
| --- | --- | --- | --- |
| `POST` | `/c.gif` | `haina.blueoath.com` | `runtime\captures\jp-live-20260813-081704\traffic\20260813-001707.889-0007.json` |
| `POST` | `/index.php?` | `debug.blueoath.com` | `runtime\captures\jp-live-20260813-081704\traffic\20260813-001705.957-0004.json` |
| `POST` | `/phone/applereview/` | `mapijpshipgirl.blueoath.com` | `runtime\captures\jp-live-20260813-081704\traffic\20260813-001705.906-0002.json` |
| `POST` | `/phone/getPlData/getPlData/` | `mapijpshipgirl.blueoath.com` | `runtime\captures\jp-live-20260813-081704\traffic\20260813-001705.924-0003.json` |
| `POST` | `/phone/switch/getstate` | `mapijpshipgirl.blueoath.com` | `runtime\captures\jp-live-20260813-070248\traffic\20260812-230250.088-0001.json` |
| `GET` | `/sdk/gettime` | `msdk.zuiyouxi.com` | `runtime\captures\jp-live-20260813-081704\traffic\20260813-001705.876-0001.json` |

## Cross-version message surface

- Shared: **73**
- JP only: **0**
- CN only: **0**

See `message-candidates.csv` for the complete list and `catalog.json` for automation.

## Highest-value login candidates

### jp-1.4.0

- `TArgCreateUser`: C2S/request; pair `unresolved`; fields `_Uname, _Class, extensionObject`; inferred (85%)
- `TArgLogin`: C2S/request; pair `TRetLogin`; fields `_Pid, _Timestamp, _OpenDateTime, _Hash, _SampleInfo, extensionObject`; inferred (85%)
- `TArgUniteLogin`: C2S/request; pair `unresolved`; fields `_Uname, extensionObject`; inferred (85%)
- `TArgUserId`: C2S/request; pair `unresolved`; fields `_Uid, extensionObject`; inferred (85%)
- `TArgUserLogin`: C2S/request; pair `TRetUserLogin`; fields `_Uid, extensionObject`; inferred (85%)
- `TArgUserRank`: C2S/request; pair `TRetUserRank`; fields `_RankType, extensionObject`; inferred (85%)
- `TRetGetOtherUserInfo`: S2C/response; pair `unresolved`; fields `_Uid, _Uname, _Head, _HeadFrame, _Sex, _Class, _Level, _VipLevel, _Power, _AchievePoint, _Htid, _GuildId, _GuildName, _VipExp, extensionObject`; inferred (85%)
- `TRetGetUserInfo`: S2C/response; pair `unresolved`; fields `_Uid, _Uname, _LastLoginTime, _Head, _HeadFrame, _Sex, _Class, _VipLevel, _RecoverData, _Level, _Exp, _Diamond, _Gold, _Vigour, _Spirit, _HeroShopPoint, _AwakeShopPoint, _PetShopPoint, _Prestige, _Token, _Achievement, _Reputation, _RefreshTime, _GuildCoin, _HeroSoul, _GodSoul, _PetSoul, _SoulJade, _AchievePoint, _Power, _VipExp, _ChangeUNameTimes, _LoginDays, _CreateTime, _GuildCopyAtkNum, _ArenaPoint, extensionObject`; inferred (85%)
- `TRetGetUsers`: S2C/response; pair `unresolved`; fields `_ArrUser, extensionObject`; inferred (85%)
- `TRetGuildUserInfo`: S2C/response; pair `unresolved`; fields `_GuildId, _MessageCount, _QuitTime, _SkillList, _SacrificeTime, _SacrificeBox, _ApplyList, _DelApplyList, _Apply, _Post, _SacrificeMode, _SacrificeReward, _Event, _FirstReward, _DailyRewardTime, _LastAtkTime, extensionObject`; inferred (85%)
- `TRetLogin`: S2C/response; pair `TArgLogin`; fields `_Ret, _FeignRoleId, extensionObject`; inferred (85%)
- `TRetPsUserRankData`: S2C/response; pair `unresolved`; fields `_User, _Star, _ThumbsUpCount, extensionObject`; inferred (85%)
- `TRetUserLogin`: S2C/response; pair `TArgUserLogin`; fields `_Ret, _BanMsg, _BanTime, extensionObject`; inferred (85%)
- `TRetUserRank`: S2C/response; pair `TArgUserRank`; fields `_UserRank, _User, extensionObject`; inferred (85%)

### cn-1.5.20

- `TArgCreateUser`: C2S/request; pair `unresolved`; fields `_Uname, _Class, extensionObject`; inferred (85%)
- `TArgLogin`: C2S/request; pair `TRetLogin`; fields `_Pid, _Timestamp, _OpenDateTime, _Hash, _SampleInfo, extensionObject`; inferred (85%)
- `TArgUniteLogin`: C2S/request; pair `unresolved`; fields `_Uname, extensionObject`; inferred (85%)
- `TArgUserId`: C2S/request; pair `unresolved`; fields `_Uid, extensionObject`; inferred (85%)
- `TArgUserLogin`: C2S/request; pair `TRetUserLogin`; fields `_Uid, extensionObject`; inferred (85%)
- `TArgUserRank`: C2S/request; pair `TRetUserRank`; fields `_RankType, extensionObject`; inferred (85%)
- `TRetGetOtherUserInfo`: S2C/response; pair `unresolved`; fields `_Uid, _Uname, _Head, _HeadFrame, _Sex, _Class, _Level, _VipLevel, _Power, _AchievePoint, _Htid, _GuildId, _GuildName, _VipExp, extensionObject`; inferred (85%)
- `TRetGetUserInfo`: S2C/response; pair `unresolved`; fields `_Uid, _Uname, _LastLoginTime, _Head, _HeadFrame, _Sex, _Class, _VipLevel, _RecoverData, _Level, _Exp, _Diamond, _Gold, _Vigour, _Spirit, _HeroShopPoint, _AwakeShopPoint, _PetShopPoint, _Prestige, _Token, _Achievement, _Reputation, _RefreshTime, _GuildCoin, _HeroSoul, _GodSoul, _PetSoul, _SoulJade, _AchievePoint, _Power, _VipExp, _ChangeUNameTimes, _LoginDays, _CreateTime, _GuildCopyAtkNum, _ArenaPoint, extensionObject`; inferred (85%)
- `TRetGetUsers`: S2C/response; pair `unresolved`; fields `_ArrUser, extensionObject`; inferred (85%)
- `TRetGuildUserInfo`: S2C/response; pair `unresolved`; fields `_GuildId, _MessageCount, _QuitTime, _SkillList, _SacrificeTime, _SacrificeBox, _ApplyList, _DelApplyList, _Apply, _Post, _SacrificeMode, _SacrificeReward, _Event, _FirstReward, _DailyRewardTime, _LastAtkTime, extensionObject`; inferred (85%)
- `TRetLogin`: S2C/response; pair `TArgLogin`; fields `_Ret, _FeignRoleId, extensionObject`; inferred (85%)
- `TRetPsUserRankData`: S2C/response; pair `unresolved`; fields `_User, _Star, _ThumbsUpCount, extensionObject`; inferred (85%)
- `TRetUserLogin`: S2C/response; pair `TArgUserLogin`; fields `_Ret, _BanMsg, _BanTime, extensionObject`; inferred (85%)
- `TRetUserRank`: S2C/response; pair `TArgUserRank`; fields `_UserRank, _User, extensionObject`; inferred (85%)

## Unresolved wire facts

- Numeric message IDs and the mapping from IDs to IL2CPP message types.
- Exact protobuf field numbers/types and required/default semantics.
- Game TCP/KCP frame header, compression, encryption and sequence fields.
- Event 1007 `data` object shape and its consuming callback.

These must be filled by type-layout extraction and targeted call-site analysis, then recorded in `adapter-template.json` rather than embedded as version checks in game logic.
