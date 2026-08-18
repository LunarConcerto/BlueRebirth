local DynamicUserOpeElement = class("game.Guide.Kits.DynamicUserOpeElement")
local daily_ex_component_change = {
  [1] = "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/1/bu_copy/img_girl/btn_change",
  [2] = "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/2/bu_copy/img_girl/btn_change",
  [3] = "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/3/bu_copy/img_girl/btn_change",
  [4] = "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/4/bu_copy/img_girl/btn_change"
}
local daily_ex_change_chapterId = {
  20003,
  20001,
  20004,
  20002
}
local daily_ex_change_info = {
  "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/1/bu_copy/Image_drop",
  "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/2/bu_copy/Image_drop",
  "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/3/bu_copy/Image_drop",
  "MainRoot/CopyPage/obj_subParent/DailyCopyPage/copys/Viewport/Content/4/bu_copy/Image_drop"
}

function DynamicUserOpeElement:initialize()
  self.tblDynamicConfig = {}
  self:initConfig()
end

function DynamicUserOpeElement:initConfig()
  self.tblDynamicConfig[GUIDE_COMPONENT_ID.ItemFactoryPath] = self.__getItemFactoryPath
  self.tblDynamicConfig[GUIDE_COMPONENT_ID.DormRoomPath] = self.__getDormRoomPath
  self.tblDynamicConfig[GUIDE_COMPONENT_ID.dailycopy_ex_1] = self.getDailyCopyExComChange
  self.tblDynamicConfig[GUIDE_COMPONENT_ID.dailycopy_ex_2] = self.getDailyCopyExComShow
end

function DynamicUserOpeElement:isDynamic(nId)
  if self.tblDynamicConfig == nil then
    return false
  end
  local func = self.tblDynamicConfig[nId]
  return func ~= nil
end

function DynamicUserOpeElement:getDynamicUserOpeConfig(nId)
  if self.tblDynamicConfig == nil then
    return false
  end
  local func = self.tblDynamicConfig[nId]
  if func == nil then
    return nil
  end
  return func(self)
end

function DynamicUserOpeElement:__getItemFactoryPath()
  local tblResult = self:__getBuildingPathByType(MBuildingType.ItemFactory)
  return tblResult
end

function DynamicUserOpeElement:__getDormRoomPath()
  local tblResult = self:__getBuildingPathByType(MBuildingType.DormRoom)
  return tblResult
end

function DynamicUserOpeElement:__getBuildingPathByType(nTargetType)
  local tblResult = {}
  local highLightPathFormat = "MainRoot/BuildingMainPage/sv_map/Viewport/Content/other/%s/build"
  local opePathFormat = "MainRoot/BuildingMainPage/sv_map/Viewport/Content/other/%s/btn"
  local nIndex = self:getBuildingIndexByType(nTargetType)
  tblResult.highLightPath = string.format(highLightPathFormat, nIndex)
  tblResult.opePath = string.format(opePathFormat, nIndex)
  tblResult.opeType = 0
  return tblResult
end

function DynamicUserOpeElement:getBuildingIndexByType(nTargetType)
  if Data == nil then
    return nil
  end
  local tblBuildingData = Data.buildingData
  if tblBuildingData == nil then
    return nil
  end
  for i = 2, 10 do
    local tblOneBuildingData, bHaveBuilding = tblBuildingData:GetBuildingByIndex(i)
    if bHaveBuilding then
      local nTid = tblOneBuildingData.Tid
      local nStatus = tblOneBuildingData.status
      local nBuildingType = tblBuildingData:_getBuildType(nTid)
      if nBuildingType == nTargetType then
        return i
      end
    end
  end
  return nil
end

function DynamicUserOpeElement:getDailyCopyExComChange()
  local nId = -1
  for i = 1, 4 do
    local bPass = Logic.dailyCopyLogic:CheckOpenTreaty(daily_ex_change_chapterId[i])
    if bPass then
      nId = i
      break
    end
  end
  if nId == -1 then
    logError("daily chapter not pass")
    return nil
  end
  local com = self:getDailyCopyExComChangeById(nId)
  return com
end

function DynamicUserOpeElement:getDailyCopyExComChangeById(nId)
  if nId == nil or 4 < nId or nId < 1 then
    return nil
  end
  local strPath = daily_ex_component_change[nId]
  local tblResult = {}
  tblResult.highLightPath = strPath
  tblResult.opePath = strPath
  tblResult.opeType = 0
  return tblResult
end

function DynamicUserOpeElement:getDailyCopyExComShow()
  local nId = -1
  for i = 1, 4 do
    local bPass = Logic.dailyCopyLogic:CheckOpenTreaty(daily_ex_change_chapterId[i])
    if bPass then
      nId = i
      break
    end
  end
  if nId == -1 then
    logError("daily chapter not pass")
    return nil
  end
  local com = self:getDailyCopyExComShowById(nId)
  return com
end

function DynamicUserOpeElement:getDailyCopyExComShowById(nId)
  if nId == nil or 4 < nId or nId < 1 then
    return nil
  end
  local strPath = daily_ex_change_info[nId]
  local tblResult = {}
  tblResult.opePath = "GuiderRoot/GuidePage/btnOptional"
  tblResult.highLightPath = strPath
  tblResult.opeType = 0
  return tblResult
end

return DynamicUserOpeElement
