local InteractionItemLogic = class("logic.PresetFleetLogic")

function InteractionItemLogic:initialize()
  self:RegisterAllEvent()
  self:ResetData()
end

function InteractionItemLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdateBagItem, self._SendUpdateByType, self)
end

function InteractionItemLogic:ResetData()
end

function InteractionItemLogic:ClickInteractionItemRet(itemId)
  local itemConfig = configManager.GetDataById("config_interaction_item", itemId)
  if itemConfig.interaction_item_type == InteractionItemType.HalloweenPumpkin or itemConfig.interaction_item_type == InteractionItemType.childSignGift then
    if not Data.interactionItemData:GetIsInteractionItemInPeriod(itemId) then
      noticeManager:ShowTip(UIHelper.GetString(330001))
      return
    end
    local interactionItemTab = {interactionItem = itemId}
    Service.interactionItemService:SetInteractionItems(interactionItemTab, itemId)
  elseif itemConfig.interaction_item_type == InteractionItemType.SnowGlobe then
    SoundManager.Instance:PlayAudio("UI_Button_HomePage_0015")
    UIHelper.OpenPage("ValentineCrystalPage", {BallId = itemId})
  elseif itemConfig.interaction_item_type == InteractionItemType.PaperCut then
    local ownedPaperCutting = Data.interactionItemData:GetOwnedSpringPaperFlowerInPeriod()
    local clickedPaperCutting = Data.interactionItemData:GetClickedSpringPaperFlower()
    if not ownedPaperCutting[itemId] then
      noticeManager:OpenTipPage(self, 270022)
      return
    end
    if clickedPaperCutting[itemId] then
      return
    end
    local interactionItemTab = {interactionItem = itemId}
    Service.interactionItemService:ClickSpringPaperFlower(interactionItemTab, itemId)
  elseif itemConfig.interaction_item_type == InteractionItemType.Posters then
    SoundManager.Instance:PlayAudio("UI_Button_HomePage_0015")
    UIHelper.OpenPage("PosterPage", {Point = itemId})
  end
end

function InteractionItemLogic:GetItemReward(state)
  local itemConfig = configManager.GetDataById("config_interaction_item", state)
  if itemConfig.interaction_item_type == InteractionItemType.HalloweenPumpkin then
    self:GetClickEventReward(state)
  elseif itemConfig.interaction_item_type == InteractionItemType.childSignGift then
    self:GetClickNoEventReward(state)
  end
end

function InteractionItemLogic:GetClickNoEventReward(state)
  local itemRewardId = configManager.GetDataById("config_interaction_item", state).reward
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = Logic.rewardLogic:FormatRewardById(itemRewardId)
  })
end

function InteractionItemLogic:GetClickEventReward(state)
  local itemConfig = configManager.GetDataById("config_interaction_item", state)
  local itemRewardId = itemConfig.reward
  local itemEvent = itemConfig.interaction_event
  local showDatas = {}
  if itemEvent == 0 then
    local rewardList = configManager.GetDataById("config_rewards", itemRewardId).rewards
    for _, reward in pairs(rewardList) do
      local show = {}
      show.Type = reward[1]
      show.ConfigId = reward[2]
      show.Num = reward[3]
      table.insert(showDatas, show)
    end
  end
  if itemEvent == -1 then
    return
  else
    UIHelper.OpenPage("ActivityHalloweenAnimatePage", {eventId = itemEvent, rewards = showDatas})
  end
end

function InteractionItemLogic:GetFurnitureReward(state)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = Logic.rewardLogic:FormatRewardById(state)
  })
end

function InteractionItemLogic:GetRemindItem()
  local unClickHalloweenPumpkin = Data.interactionItemData:GetRemainHalloweenPumpkin()
  local ownedPaperCutting = Data.interactionItemData:GetOwnedSpringPaperFlowerInPeriod()
  local UNClickChildGift = Data.interactionItemData:GetRemainChildSignGift()
  local InfoItem = self:_GetShowInfoItemId()
  local DecorateBagItem = self:_GetShowDecorateBagItemId()
  local DecorateBagTheme = self:_GetShowDecorateBagTheme()
  local DecoratePoster = self:_GetShowPosters()
  local theReminditem = {}
  for i, v in pairs(unClickHalloweenPumpkin) do
    theReminditem[v] = v
  end
  for i, v in pairs(ownedPaperCutting) do
    theReminditem[v] = v
  end
  for i, v in pairs(UNClickChildGift) do
    theReminditem[v] = v
  end
  for i, v in pairs(InfoItem) do
    theReminditem[v] = v
  end
  for i, v in pairs(DecorateBagItem) do
    theReminditem[v] = v
  end
  for i, v in pairs(DecorateBagTheme) do
    theReminditem[v] = v
  end
  for i, v in pairs(DecoratePoster) do
    theReminditem[v] = v
  end
  return theReminditem
end

function InteractionItemLogic:_GetShowDecorateBagItemId()
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local visibleItem = {}
  for i, v in pairs(ownedItem) do
    if v == VisibleState.YES then
      local info = configManager.GetDataById("config_interaction_item_bag", i)
      local id = info.interactionitem
      if info.interactionitem_bag_group == 0 and info.type == InteractionBagItemType.Other then
        visibleItem[id] = id
      end
    end
  end
  return visibleItem
end

function InteractionItemLogic:_GetShowDecorateBagTheme()
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local curTheme = Data.interactionItemData:GetMutexFurnitureTheme()
  local tmp = {}
  if curTheme == 0 or curTheme == OldFurnitureTheme.Christmas or curTheme == OldFurnitureTheme.Spring then
    return tmp
  else
    local themeItemList = configManager.GetDataById("config_interaction_item_bag_group", curTheme).interactionitem_bag or {}
    for _, furId in pairs(themeItemList) do
      if ownedItem[furId] then
        local furShowId = configManager.GetDataById("config_interaction_item_bag", furId).interactionitem
        tmp[furShowId] = furShowId
      end
    end
  end
  return tmp
end

function InteractionItemLogic:_GetShowInfoItemId()
  local tmp = {}
  local itemData = configManager.GetData("config_interaction_item")
  for k, v in pairs(itemData) do
    if v.item_info_id and v.item_info_id ~= nil and v.item_info_id ~= 0 then
      tmp[k] = v.item_info_id
    end
  end
  local tmpp = {}
  for k, v in pairs(tmp) do
    if 0 < Data.bagData:GetItemNum(v) then
      table.insert(tmpp, k)
    end
  end
  return tmpp
end

function InteractionItemLogic:_GetFurnitureActivityConfig()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.FurnitureDecoration)
  local currency = FurnitureCionItemId.ChristmasSnowCoin
  if actId == FurnitureActivityKey.ChristmasFurniture then
    currency = FurnitureCionItemId.ChristmasSnowCoin
  elseif actId == FurnitureActivityKey.SpringFurniture then
    currency = FurnitureCionItemId.SpringCoin
  end
  return actId, currency
end

function InteractionItemLogic:GetShowToyIdByBallId(ballId)
  local ballMap = Data.interactionItemData:GetBallToyState()
  local snowBabyId = ballMap[ballId] or 0
  if ballId == ActivityInteractionItemId.ChristmasCrystalBallId then
    snowBabyId = Data.activitychristmasshopData:GetCrystalBallToyId()
  end
  local ownedHeroList = Data.activitychristmasshopData:GetToyList()
  if snowBabyId and snowBabyId ~= 0 then
    return snowBabyId
  else
    return 0
  end
end

function InteractionItemLogic:GetBallAndToyPositionId()
  local ballToBag = {}
  local ballToDoll = {}
  local bagToBall = {}
  local itemData = configManager.GetData("config_interaction_item")
  for k, v in pairs(itemData) do
    if v.item_info_id and v.item_info_id ~= nil and v.item_info_id ~= 0 then
      ballToBag[k] = v.item_info_id
      bagToBall[v.item_info_id] = k
      ballToDoll[k] = v.interaction_item_attach[1]
    end
  end
  return ballToBag, ballToDoll, bagToBall
end

function InteractionItemLogic:_SendUpdateByType()
  local _, _, bagToBall = self:GetBallAndToyPositionId()
  local updateMap = Data.bagData:GetUpdateMap()
  for k, v in pairs(updateMap) do
    if bagToBall[k] ~= nil then
      eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
    end
  end
end

function InteractionItemLogic:_GetShowPosters()
  local pointConfig = configManager.GetDataById("config_parameter", 377).arrValue
  return pointConfig
end

function InteractionItemLogic:GetPosterByPoint(point)
  local posterMap = Data.interactionItemData:GetPosterStateData()
  return posterMap[point] or 0
end

function InteractionItemLogic:GetCanShowPosterEffect(point)
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local notClick = PlayerPrefs.GetInt(uid .. "PosterPage" .. point, 0) == 0
  local notOccupy = self:GetPosterByPoint(point) == 0
  local _, tmpPoster = self:GetDecorateBagOther()
  local tmp = {}
  for i, v in pairs(tmpPoster) do
    table.insert(tmp, v)
  end
  local havePoster = #tmp ~= 0
  if notClick and notOccupy and havePoster then
    return true
  end
  return false
end

function InteractionItemLogic:GetDecorateBagFurTheme()
  local itemData = configManager.GetData("config_interaction_item_bag_group")
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local tmp = {}
  for i, v in pairs(itemData) do
    local furList = v.interactionitem_bag
    local ishave = false
    for _, furid in pairs(furList) do
      if ownedItem[furid] then
        ishave = true
        break
      end
    end
    if ishave then
      table.insert(tmp, v)
    end
  end
  return tmp
end

function InteractionItemLogic:GetDecorateBagOther()
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local tmp = {}
  local tmpPoster = {}
  for i, v in pairs(ownedItem) do
    local itemInfo = configManager.GetDataById("config_interaction_item_bag", i)
    if itemInfo.interactionitem_bag_group == 0 then
      table.insert(tmp, itemInfo)
      if itemInfo.type == InteractionBagItemType.Poster then
        tmpPoster[i] = i
      end
    end
  end
  return tmp, tmpPoster
end

function InteractionItemLogic:GetDecorateThemeNew(themeId)
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local mapFur = {}
  for i, v in pairs(ownedItem) do
    local group = configManager.GetDataById("config_interaction_item_bag", i).interactionitem_bag_group
    if group == themeId then
      mapFur[i] = i
    end
  end
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  for i, itemId in pairs(mapFur) do
    local isNew = PlayerPrefs.GetBool(uid .. "DecorateFurnitureBagItem" .. itemId, true)
    if isNew then
      return true
    end
  end
  return false
end

return InteractionItemLogic
