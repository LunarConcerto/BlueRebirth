local PlayerHeadFrameLogic = class("logic.PlayerHeadFrameLogic")

function PlayerHeadFrameLogic:initialize()
  self:ResetData()
end

function PlayerHeadFrameLogic:ResetData()
end

function PlayerHeadFrameLogic:GetNowHeadFrame()
  local curDataFrame = Data.userData:GetPlayerHeadFrame()
  local isSMarry = self:IsSecretaryMarried()
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
  if curDataFrame == InitialHeadFrame.Default or curDataFrame == InitialHeadFrame.Marry then
    if isSMarry then
      frameInfo = allFrameList[InitialHeadFrame.Marry]
    else
      frameInfo = allFrameList[InitialHeadFrame.Default]
    end
  end
  if frameInfo == nil then
    curDataFrame = InitialHeadFrame.Default
    frameInfo = allFrameList[curDataFrame]
  end
  return curDataFrame, frameInfo
end

function PlayerHeadFrameLogic:IsSecretaryMarried()
  local isMarry = false
  local isSecretaryMarried = Data.userData:GetUserData().HeadShow
  if isSecretaryMarried and isSecretaryMarried == 1 then
    isMarry = true
  end
  return isMarry
end

function PlayerHeadFrameLogic:GetHeadFrameByUid(info)
  if info.Uid == Data.userData:GetUserData().Uid then
    local curDataFrame = Data.userData:GetPlayerHeadFrame()
    local isSMarry = self:IsSecretaryMarried()
    return self:__GetFrameInfo(curDataFrame, isSMarry)
  else
    local curDataFrame = info.HeadFrame
    local isSMarry = info.HeadShow == 1 and true or false
    return self:__GetFrameInfo(curDataFrame, isSMarry)
  end
end

return PlayerHeadFrameLogic
