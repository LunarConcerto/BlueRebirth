local BuildItemFactoryEnd = class("game.guide.guideTrigger.BuildItemFactoryEnd", GR.requires.GuideTriggerBase)
local nLandsMax = 10

function BuildItemFactoryEnd:initialize(nType)
  self.type = nType
  self.nTargetBuildingType = MBuildingType.ItemFactory
  self.bAlreadyOpen = false
end

function BuildItemFactoryEnd:onStart()
  local bOpen = self:_checkOpen()
  self.bAlreadyOpen = bOpen
  self.bBuildOver = false
  if not bOpen then
    eventManager:RegisterEvent(LuaEvent.BuildingEndAfter, self.onBuildEnd, self)
  end
end

function BuildItemFactoryEnd:onBuildEnd(nBuildinId)
  if self:_checkOpen() then
    self.bBuildOver = true
  end
end

function BuildItemFactoryEnd:onEnd()
  eventManager:UnregisterEvent(LuaEvent.BuildingEndAfter, self.onBuildEnd)
end

function BuildItemFactoryEnd:tick()
  if not UIHelper.IsPageOpen("BuildingMainPage") then
    return
  end
  if self.bAlreadyOpen then
    self:sendTrigger()
  else
    if not self.bBuildOver then
      return
    end
    if UIHelper.IsPageOpen("BuildingOpenPage") then
      return
    end
    self:sendTrigger()
  end
end

function BuildItemFactoryEnd:_checkOpen()
  if Data == nil then
    return
  end
  local tblBuildingData = Data.buildingData
  if tblBuildingData == nil then
    return
  end
  for i = 1, nLandsMax do
    local tblOneBuildingData, bHaveBuilding = tblBuildingData:GetBuildingByIndex(i)
    if bHaveBuilding then
      local nTid = tblOneBuildingData.Tid
      local nStatus = tblOneBuildingData.status
      local nBuildingType = tblBuildingData:_getBuildType(nTid)
      if nBuildingType == self.nTargetBuildingType and self:_buildingStatusAvailable(nStatus) then
        return true
      end
    end
  end
end

function BuildItemFactoryEnd:_buildingStatusAvailable(nStatus)
  return nStatus ~= BuildingStatus.Adding and nStatus ~= BuildingStatus.Upgrading
end

return BuildItemFactoryEnd
