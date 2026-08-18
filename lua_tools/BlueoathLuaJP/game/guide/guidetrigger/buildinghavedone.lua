local BuildingHaveDone = class("game.guide.guideTrigger.BuildingHaveDone", GR.requires.GuideTriggerBase)
local nLandsMax = 10

function BuildingHaveDone:initialize(nType, nBuildingType)
  self.type = nType
  self.nTargetBuildingType = nBuildingType
end

function BuildingHaveDone:tick()
  if not UIHelper.IsPageOpen("BuildingMainPage") then
    return
  end
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
        self:sendTrigger()
      end
    end
  end
end

function BuildingHaveDone:_buildingStatusAvailable(nStatus)
  return nStatus ~= BuildingStatus.Adding and nStatus ~= BuildingStatus.Upgrading
end

return BuildingHaveDone
