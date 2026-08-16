local InteractionItemData = class("data.InteractionItemData", Data.BaseData)
FurnitureActivityKey = {ChristmasFurniture = 58, SpringFurniture = 75}
FurnitureActivityTable = {
  furnitureId = 1,
  furnitureReward = 2,
  furnitureCost = 3
}
PaperCutSign = {
  notgot = 0,
  got = 1,
  clicked = 2
}
VisibleState = {NO = 0, YES = 1}
decorateMutexType = {furnitureTheme = 1}
OldFurnitureTheme = {Christmas = 1, Spring = 2}

function InteractionItemData:initialize()
  self:ResetData()
end

function InteractionItemData:ResetData()
  self.m_itemMap = {}
  self.m_pumpkinMap = {}
  self.m_furnitureMap = {}
  self.m_ownedPaperFlowerMap = {}
  self.m_clickedPaperFlowerMap = {}
  self.m_BallToyMap = {}
  self.m_postersMap = {}
  self.m_bagItemMap = {}
  self.m_bagMutexMap = {}
end

function InteractionItemData:SetData(data)
  self:GetUsedItem(data)
end

function InteractionItemData:GetUsedItem(data)
  if data.halloweenPumpkin ~= nil and #data.halloweenPumpkin > 0 then
    for _, v in pairs(data.halloweenPumpkin) do
      self.m_pumpkinMap[v] = v
      self:RefreshEvent(v)
    end
  end
  if data.furniture ~= nil and 0 < #data.furniture then
    for _, v in pairs(data.furniture) do
      self.m_furnitureMap[v] = v
      self:RefreshEvent(v)
    end
  end
  if data.paperFlowerState ~= nil and 0 < #data.paperFlowerState then
    for _, v in pairs(data.paperFlowerState) do
      if v.state >= PaperCutSign.got then
        self.m_ownedPaperFlowerMap[v.id] = v.id
        if v.state == PaperCutSign.got then
          self:RefreshEvent(v)
        end
      end
      if v.state == PaperCutSign.clicked then
        self.m_clickedPaperFlowerMap[v.id] = v.id
        self:SetClickPaperCut(v.id)
      end
      if v.state == PaperCutSign.notgot then
        self.m_ownedPaperFlowerMap = self:_IRemoveKey(self.m_ownedPaperFlowerMap, v.id)
        self.m_clickedPaperFlowerMap = self:_IRemoveKey(self.m_clickedPaperFlowerMap, v.id)
        self:RefreshEvent(v)
      end
    end
  end
  if data.ballToyState ~= nil and 0 < #data.ballToyState then
    for _, v in pairs(data.ballToyState) do
      self.m_BallToyMap[v.ballId] = v.ToyId
      self:RefreshEvent(v)
    end
  end
  if data.posterState ~= nil and 0 < #data.posterState then
    for _, v in pairs(data.posterState) do
      self.m_postersMap[v.point] = v.posterId
      self:RefreshEvent(v)
    end
  end
  if data.interactionBagItem ~= nil and 0 < #data.interactionBagItem then
    for _, v in pairs(data.interactionBagItem) do
      if 0 < v.num then
        self.m_bagItemMap[v.id] = v.state
        self:RefreshEvent()
        eventManager:SendEvent(LuaEvent.GetNewDecorateItem)
      end
    end
  end
  if data.decorate ~= nil and 0 < #data.decorate then
    for _, v in pairs(data.decorate) do
      if v.typeId ~= nil then
        self.m_bagMutexMap[v.typeId] = v.curSelect
        self:RefreshEvent()
      end
    end
  end
end

function InteractionItemData:SetClickPaperCut(itemid)
  if self:GetIsInteractionItemInPeriod(itemid) then
    eventManager:SendEvent(LuaEvent.FreshPaperCutShow, itemid)
  end
end

function InteractionItemData:RefreshEvent()
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
end

function InteractionItemData:_IRemoveKey(tbl, key)
  local tmp = {}
  for k, v in pairs(tbl) do
    if k ~= key then
      tmp[k] = v
    end
  end
  return tmp
end

function InteractionItemData:GetAllPumpkinBySceneId()
  local allPumpkinMap = {}
  local sceneItems = configManager.GetDataById("config_home_scene_envir", homeEnvManager:GetSceneId()).intaction_item_id
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.HalloweenStory)
  local allItems = {}
  if actId and configManager.GetDataById("config_activity", actId).p2 ~= nil then
    allItems = configManager.GetDataById("config_activity", actId).p2
  end
  for _, v in pairs(allItems) do
    if self:GetIsInteractionItemInPeriod(v) then
      local itemConfig = configManager.GetDataById("config_interaction_item", v)
      if itemConfig.interaction_item_type == InteractionItemType.HalloweenPumpkin then
        table.insert(allPumpkinMap, v)
      end
    end
  end
  return allPumpkinMap
end

function InteractionItemData:GetOwnedSpringPaperFlower()
  return self.m_ownedPaperFlowerMap
end

function InteractionItemData:GetAllChildSignGiftByActivityId()
  local tmp = {}
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.JChildSign)
  if actId then
    local allMap = configManager.GetDataById("config_activity", actId)
    for _, v in pairs(allMap.p1) do
      if self:GetIsInteractionItemInPeriod(v) then
        local itemConfig = configManager.GetDataById("config_interaction_item", v)
        if itemConfig.interaction_item_type == InteractionItemType.childSignGift then
          table.insert(tmp, v)
        end
      end
    end
  end
  return tmp
end

function InteractionItemData:GetRemainHalloweenPumpkin()
  local allPumpkinMap = self:GetAllPumpkinBySceneId()
  local tmp = {}
  for _, v in pairs(allPumpkinMap) do
    if not self.m_pumpkinMap[v] then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:GetRemainChildSignGift()
  local allMap = self:GetAllChildSignGiftByActivityId()
  local tmp = {}
  local uid = tostring(Data.userData:GetUserData().Uid)
  local isFake = PlayerPrefs.GetBool(uid .. "ActivitySceneLoginFake", true)
  if isFake then
    return tmp
  end
  for _, v in pairs(allMap) do
    if not self.m_pumpkinMap[v] then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:IfisUnClick()
  local allMap = self:GetAllChildSignGiftByActivityId()
  local tmp = {}
  for _, v in pairs(allMap) do
    if not self.m_pumpkinMap[v] then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:GetClickedChildSignGift()
  local tmp = {}
  for _, v in pairs(self.m_pumpkinMap) do
    local itemConfig = configManager.GetDataById("config_interaction_item", v)
    if itemConfig.interaction_item_type == InteractionItemType.childSignGift then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:GetOwnedSpringPaperFlowerInPeriod()
  local tmp = {}
  for _, v in pairs(self.m_ownedPaperFlowerMap) do
    if self:GetIsInteractionItemInPeriod(v) then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:GetClickedSpringPaperFlower()
  local tmp = {}
  for _, v in pairs(self.m_clickedPaperFlowerMap) do
    if self:GetIsInteractionItemInPeriod(v) then
      tmp[v] = v
    end
  end
  return tmp
end

function InteractionItemData:GetBallToyState()
  return self.m_BallToyMap
end

function InteractionItemData:GetPosterStateData()
  return self.m_postersMap or {}
end

function InteractionItemData:GetInteractionBagItemData()
  return self.m_bagItemMap
end

function InteractionItemData:GetMutexFurnitureTheme()
  return self.m_bagMutexMap[decorateMutexType.furnitureTheme] or 0
end

function InteractionItemData:GetIsInteractionItemInPeriod(itemid)
  local itemConfig = configManager.GetDataById("config_interaction_item", itemid)
  if itemConfig.item_display_period <= 0 then
    return true
  elseif PeriodManager:IsInPeriodArea(itemConfig.item_display_period, itemConfig.period_area) then
    return true
  end
  return false
end

return InteractionItemData
