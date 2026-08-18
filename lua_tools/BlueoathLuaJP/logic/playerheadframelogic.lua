local PlayerHeadFrameLogic = class("logic.PlayerHeadFrameLogic")

function PlayerHeadFrameLogic:initialize()
  self:ResetData()
end

function PlayerHeadFrameLogic:ResetData()
end

function PlayerHeadFrameLogic:GetNowHeadFrame()
  local curDataFrame = Data.userData:GetPlayerHeadFrame()
  local curHeadId = Data.userData:GetUserHead()
  local isSMarry = self:IsSecretaryMarried(curHeadId)
  return self:__GetFrameInfo(curDataFrame, isSMarry)
end

function PlayerHeadFrameLogic:GetOtherHeadFrame(info)
  local curDataFrame = info.HeadFrame
  local isSMarry = info.HeadShow == 1 and true or false
  return self:__GetFrameInfo(curDataFrame, isSMarry)
end

function PlayerHeadFrameLogic:__GetFrameInfo(id, isSMarry)
  local curDataFrame = id
  if curDataFrame == 0 then
    curDataFrame = InitialHeadFrame.Default
  end
  local allFrameList = Data.playerHeadFrameData:GetAllHeadFrameData()
  local frameInfo = allFrameList[curDataFrame]
  if frameInfo == nil then
    curDataFrame = InitialHeadFrame.Default
    frameInfo = allFrameList[curDataFrame]
  end
  return curDataFrame, frameInfo
end

function PlayerHeadFrameLogic:IsSecretaryMarried(headId)
  local isMarry = false
  local sf_id = configManager.GetDataById("config_profile", headId).belongshipid
  local tabHaveHero = Data.heroData:GetHeroData()
  for _, v in pairs(tabHaveHero) do
    if v.MarryTime > 0 then
      local smCfg = configManager.GetDataById("config_ship_main", v.TemplateId)
      local siCfg = configManager.GetDataById("config_ship_info", smCfg.ship_info_id)
      if siCfg.sf_id == sf_id then
        isMarry = true
        break
      end
    end
  end
  return isMarry
end

function PlayerHeadFrameLogic:GetHeadFrameByUid(info)
  if info.Uid == Data.userData:GetUserData().Uid then
    local curDataFrame = Data.userData:GetPlayerHeadFrame()
    local curHeadId = Data.userData:GetUserHead()
    local isSMarry = self:IsSecretaryMarried(curHeadId)
    return self:__GetFrameInfo(curDataFrame, isSMarry)
  else
    local curDataFrame = info.HeadFrame
    local isSMarry = info.HeadShow == 1 and true or false
    return self:__GetFrameInfo(curDataFrame, isSMarry)
  end
end

return PlayerHeadFrameLogic
