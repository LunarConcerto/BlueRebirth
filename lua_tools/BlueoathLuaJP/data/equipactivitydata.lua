local EquipActivityData = class("data.EquipActivityData")

function EquipActivityData:initialize()
  self:ResetData()
  self:RegisterAllEvent()
end

function EquipActivityData:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.BattleStageLeave, self.ResetPointAdd, self)
end

function EquipActivityData:ResetData()
  self.mInfo = {}
  self.m_PointDelta = {}
end

function EquipActivityData:UpdateData(TRet)
  logDebug("EquipActivityData UpdateData", TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.Info ~= nil and #TRet.Info > 0 then
    local old = self:_SvrOldInfo()
    for _, info in ipairs(TRet.Info) do
      if info.EquipId == nil or 0 >= info.EquipId then
        self.mInfo = {}
      else
        self.mInfo[info.EquipId] = info
      end
    end
    self:_SvrPointAdd(old)
  end
end

function EquipActivityData:GetInfo()
  return self.mInfo or {}
end

function EquipActivityData:GetInfoByEquipId(equipId)
  return self.mInfo[equipId]
end

function EquipActivityData:GetPowerPointByEquipId(equipId)
  local info = self:GetInfoByEquipId(equipId) or {}
  local powerpoint = info.PowerPoint or 0
  return powerpoint
end

function EquipActivityData:GetIsRewardByEquipId(equipId)
  local info = self:GetInfoByEquipId(equipId) or {}
  local isreward = info.IsReward or 0
  return isreward
end

function EquipActivityData:GetAddRule(equipId)
  local info = self:GetInfoByEquipId(equipId) or {}
  return info.ExtraRule or 0
end

function EquipActivityData:GetInfo()
  return self.mInfo
end

function EquipActivityData:GetPointAddById(equipId)
  return self.m_PointDelta[equipId] or 0
end

function EquipActivityData:_SvrPointAdd(old)
  if next(old) == nil then
    return
  end
  local new = self:GetInfo()
  local res, oldPoint = {}, 0
  for id, info in pairs(new) do
    if old[id] then
      oldPoint = old[id].PowerPoint or 0
      local delta = self:GetPowerPointByEquipId(id) - oldPoint
      if 0 < delta then
        res[id] = delta
      elseif delta < 0 then
        logError("activity point delta less then zero!!!, EquipId:" .. id .. " Old Point:" .. oldPoint .. " New Point:" .. self:GetPowerPointByEquipId(id))
      end
    end
  end
  self.m_PointDelta = res
end

function EquipActivityData:ResetPointAdd()
  self.m_PointDelta = {}
end

function EquipActivityData:_SvrOldInfo()
  local res = {}
  local orgin = self:GetInfo()
  for id, info in pairs(orgin) do
    res[id] = info
  end
  return res
end

return EquipActivityData
