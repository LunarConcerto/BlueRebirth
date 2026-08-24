namespace BlueOath.Server.Protocols;

/// <summary>
/// Stub handlers for game modules that depend on heavy C# client-side logic (3D scenes,
/// UI timers, building interaction, etc.) that cannot be reproduced in the offline server.
/// All protocols return empty success responses (no error, no data payload).
/// </summary>
internal sealed partial class GameLoginMessageHandler
{
    // ─────────────────────────────────────────────────────────────
    //  Building module (20+ protocols)
    //  Reason: C# 3D building scene logic, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // building.AddBuilding
    // building.UpgradeBuilding
    // building.DegradeBuilding
    // building.SetHero
    // building.SetBuildingListHero
    // building.FinishBuilding
    // building.ReceiveBuilding
    // building.ProduceItem
    // building.ComposeItem
    // building.ReceiveItem
    // building.ReceiveAll
    // building.ReceiveResource
    // building.UpdateHeroAddition
    // building.UseStrengthSpeedup
    // building.TriggerNormalHeroPlot
    // building.TriggerSpecialHeroPlot
    // building.SaveTactic
    // building.SetTacticName
    // building.RemoveTactic

    // ─────────────────────────────────────────────────────────────
    //  Bathroom module (8 protocols)
    //  Reason: C# bathroom UI and timer logic, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // bathroom.BathStart
    // bathroom.BathEnd
    // bathroom.BathService
    // bathroom.BathAuto
    // bathroom.GetBathroomInfo
    // bathroom.BathChangeHero
    // bathroom.BathAllAuto
    // bathroom.BathStartAll

    // ─────────────────────────────────────────────────────────────
    //  Study module (5 protocols)
    //  Reason: C# study timer and skill system, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // study.GetStudyInfo
    // study.StartStudyPSkill
    // study.CancelStudyPSkill
    // study.EndStudyPSkill
    // study.SpeedUpStudy

    // ─────────────────────────────────────────────────────────────
    //  Strategy module (5 protocols)
    //  Reason: C# strategy tree UI logic, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // strategy.Learn
    // strategy.Upgrade
    // strategy.Reset
    // strategy.Apply
    // strategy.GetStrategy

    // ─────────────────────────────────────────────────────────────
    //  Build module (3 protocols)
    //  Reason: C# build queue timer logic, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // build.BuildingByFormula
    // build.BuildReceive
    // build.BuildQuicklyFinish

    // ─────────────────────────────────────────────────────────────
    //  BuildNotes module (2 protocols)
    //  Reason: C# social notes UI, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // buildnotes.GetNotesList
    // buildnotes.GiveLike

    // ─────────────────────────────────────────────────────────────
    //  Supply module (1 protocol)
    //  Reason: C# supply switching UI, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // supply.SupplySwitch

    // ─────────────────────────────────────────────────────────────
    //  Repair module (1 protocol)
    //  Reason: C# repair timer and dock UI, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // repair.RepairHero

    // ─────────────────────────────────────────────────────────────
    //  Guild module (23 protocols)
    //  Reason: Multiplayer social system, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // guild.Create
    // guild.Search
    // guild.GetList
    // guild.Apply
    // guild.CancelApply
    // guild.Verify
    // guild.Dismiss
    // guild.Modify
    // guild.Appoint
    // guild.Remove
    // guild.Transfer
    // guild.Upgrade
    // guild.Quit
    // guild.GetApplyList
    // guild.GetMemberList
    // guild.RejectAll
    // guild.AcceptAll
    // guild.Publicity
    // guild.SetGuildLevelOfShow
    // guild.Impeach
    // guild.AcceptAllMsg
    // guild.UpdateOurGuildData
    // guild.UpdateMyGuildData

    // ─────────────────────────────────────────────────────────────
    //  Guild War module (12 protocols)
    //  Reason: Multiplayer guild war, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // guildwar.GetGuildwarInfo
    // guildwar.GetRankList
    // guildwar.GetBaseInfo
    // guildwar.GetHeroLockInfo
    // guildwar.GetBattleReport
    // guildwar.BattleReport
    // guildwar.GetGuildReward
    // guildwar.GetRankUserList
    // guildwar.GetHaveScores
    // guildwar.GetHaveGuildReward
    // guildwar.GetGuildGradeId
    // guildwar.UpdateBaseInfo

    // ─────────────────────────────────────────────────────────────
    //  Guild Offer/Box/Task/BigActivity (17 protocols)
    //  Reason: Multiplayer guild subsystems, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // guildOffer.GetOfferList
    // guildOffer.SubmitOffer
    // guildOffer.ReceiveOffer
    // guildOffer.RefreshOffer
    // guildbox.GetGuildBox
    // guildbox.OpenBox
    // guildbox.ReceiveBox
    // guildbigactivity.GetInfo
    // guildbigactivity.Join
    // guildbigactivity.ReceiveReward
    // guildofferrank.GetRankList
    // guildofferrank.GetSelfRank
    // guildbigactivityrank.GetRankList
    // guildbigactivityrank.GetSelfRank
    // guildtask.GetTaskList
    // guildtask.GetTaskReward
    // guildtask.TaskTrigger

    // ─────────────────────────────────────────────────────────────
    //  Teaching module (16 protocols)
    //  Reason: Multiplayer teaching/mentoring system, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // teachingsvr.TeachingInfo
    // teachingsvr.MyTeacher
    // teachingsvr.TeacherList
    // teachingsvr.Apply
    // teachingsvr.Agree
    // teachingsvr.Refuse
    // teachingsvr.Delete
    // user.TeacherRank
    // teachingsvr.Appraise
    // teachingsvr.MyStudent
    // teachingsvr.StudentList
    // teachingsvr.PersonalInfo
    // teachingsvr.Search
    // teachingsvr.ApplyList
    // teachingsvr.GetOtherInfo
    // teachingsvr.TaskReward

    // ─────────────────────────────────────────────────────────────
    //  Match/Room/Multiplayer module (26 protocols)
    //  Reason: Multiplayer matchmaking and room system, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // matchsvr.CreateRoom
    // matchsvr.EnterRoom
    // matchsvr.ExitRoom
    // matchsvr.DismissRoom
    // matchsvr.Ready
    // matchsvr.Cancel
    // matchsvr.Kick
    // matchsvr.UploadTactic
    // matchsvr.GetRoomList
    // matchsvr.SwitchRoomPublicState
    // matchsvr.Start
    // match.UpdateRoomInfo
    // match.pveMatchRoomTimeout
    // room.GetRoomInfo
    // room.CreateRoom
    // room.EnterRoom
    // room.ExitRoom
    // room.DismissRoom
    // room.Ready
    // room.Cancel
    // room.Kick
    // room.Start
    // room.GetRoomList
    // room.SwitchRoomPublicState
    // room.UploadTactic
    // room.UpdateRoomInfo

    // ─────────────────────────────────────────────────────────────
    //  Battle Multiplayer module (6 protocols)
    //  Reason: Multiplayer battle system, offline mode not applicable
    // ─────────────────────────────────────────────────────────────
    // battle.CreateRoom
    // battle.JoinRoom
    // battle.MatchJoin
    // battle.MatchLeave
    // battle.createBattleInfo
    // battle.LeaveRoom
}