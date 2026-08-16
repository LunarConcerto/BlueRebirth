local PlayerHeadFrameData = class("data.PlayerHeadFrameData", Data.BaseData)
InitialHeadFrame = {Default = 1, Marry = 2}

function PlayerHeadFrameData:initialize()
  self:ResetData()
end

function PlayerHeadFrameData:ResetData()
  self.m_ownedHeadFrames = {}
  self.m_allHeadFrames = self:__SetAllHeadFrameData()
end

function PlayerHeadFrameData:SetData(data)
  if data then
    self.m_ownedHeadFrames = data.ownedHeadFrames
  end
end

function PlayerHeadFrameData:GetOwnedHeadFrameData()
  local tmp = {}
  for _, v in pairs(self.m_ownedHeadFrames) do
    tmp[v] = v
  end
  return tmp
end

function PlayerHeadFrameData:GetAllHeadFrameData()
  return self.m_allHeadFrames
end

function PlayerHeadFrameData:__SetAllHeadFrameData()
  local tmp = {}
  local headFrameData = configManager.GetData("config_player_head_frame")
  for k, v in pairs(headFrameData) do
    tmp[k] = v
  end
  return tmp
end

return PlayerHeadFrameData
