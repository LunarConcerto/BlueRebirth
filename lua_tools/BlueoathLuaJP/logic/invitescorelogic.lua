local InviteScoreLogic = class("logic.InviteScoreLogic")

function InviteScoreLogic:initialize()
  self:ResetData()
end

function InviteScoreLogic:ResetData()
end

function InviteScoreLogic:TriggerInviteScore(type)
  if type == InviteScoreType.GetSSRHero then
    if not Data.inviteScoreData:IsFirstSSR() then
      return
    end
  elseif type == InviteScoreType.GetNewFashion then
    if not Data.inviteScoreData:IsFirstFaishon() then
      return
    end
  elseif type == InviteScoreType.EndBattle and not self:CheckFirstBattleWin() then
    return
  end
  self:OpenInviteScorePage()
  local argTab = {inviteScoreType = type}
  Service.inviteScoreService:SetInviteStateByType(argTab)
end

function InviteScoreLogic:OpenInviteScorePage()
  log("open page!")
  if isAndroid then
    local isScore = Data.inviteScoreData:GetIsInviteScored()
    if not isScore then
      UIHelper.OpenPage("InviteScorePage")
    end
  elseif isIOS then
    local tab = {appleId = 1484471032}
    log("--------- tab:", tab)
    PlatformWrapper:CallUniversalFunction("showInAppComment", tab)
  elseif isWindows then
  end
end

function InviteScoreLogic:CheckFirstBattleWin()
  local regTime = platformManager:GetAccountCreateTime()
  if regTime == nil then
    logError("nil\239\188\154regTime", regTime)
    return false
  end
  local dayList = configManager.GetDataById("config_parameter", 336).arrValue
  local isInTime = false
  for _, v in pairs(dayList) do
    local deltaDay = time.getDaysBetween(regTime)
    log("deltaDay:", deltaDay, " dayList: ", dayList, "dayList9[i]:", v)
    if deltaDay == v - 1 then
      isInTime = true
      log(" true !")
    end
  end
  local isFirstBattleWin = Data.inviteScoreData:IsFirstBattleWin()
  local canOpen = isFirstBattleWin and isInTime
  return canOpen
end

function InviteScoreLogic:CheckResetVersion()
  local myVersion = Data.inviteScoreData:GetrecordInviteScoreVersion()
  local newVersion = platformManager:GetInviteScoreVersion() or 0
  log("---server(data)->sdk()->", myVersion, newVersion)
  if myVersion < newVersion then
    Data.inviteScoreData:SetIsScored(InviteScoreSign.notScore)
    local argTab = {inviteScoreVersion = newVersion}
    Service.inviteScoreService:CheckAndResetInviteState(argTab)
  end
end

return InviteScoreLogic
