local Building2DDetailPage = class("UI.Building.Building2D.Building2DDetailPage", LuaUIPage)
local FunctionIndex = {
  Recipe = 1,
  Recipe_compose = 2,
  Information = 3
}
local BuildingRecipes = {
  [FunctionIndex.Recipe] = "recipe",
  [FunctionIndex.Recipe_compose] = "recipe_compose"
}

function Building2DDetailPage:DoInit()
end

function Building2DDetailPage:DoOnOpen()
  self:OpenTopPage("Building2DDetailPage", 1, UIHelper.GetString(920000126), self, true, function()
    self:_OnBack()
  end)
  local widgets = self:GetWidgets()
  Logic.buildingLogic:UpdateBuildings(false)
  self.produceTimerData = {}
  self.buildingListParts = {}
  self.produceMatParts = {}
  self.configIndex = FunctionIndex.Recipe
  local buildingData = self:GetParam().data
  widgets.obj_reddot:SetActive(buildingData.ItemCount == 0)
  self.buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  self.productId = self.buildingCfg.productid[2]
  self.choosedRecipeId = buildingData.RecipeId
  self.choosedRecipe_composeId = 0
  self.produceComposeCount = 0
  self.produceCount = self:GetProduceCount()
  self.selectedIndex = 0
  self.composeMaxNum = 99
  local buildings = Data.buildingData:GetBuildingsByType(self.buildingCfg.type)
  self:BtnSelectedArrAdd()
  local index = Logic.buildingLogic:GetDetailTabIndex()
  if index then
    self.selectedIndex = index
  else
    for i, data in ipairs(buildings) do
      if data.Id == buildingData.Id then
        self.selectedIndex = i - 1
      end
    end
  end
  self:ShowBuildingList(buildings)
  local showItem = self:GetParam().showItem
  if showItem then
    self:_SwitchToItemPanal()
  else
    self:_SwitchToInfoPanel()
  end
  self:PlayBgm(self.buildingCfg.type)
  self:CheckComposeReddot()
end

function Building2DDetailPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_down, self._Degrade, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_up, self._Upgrade, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_get, self._Receive, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_info, self._SwitchToInfoPanel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_make, self._SwitchToItemPanal, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self._ChooseRecipe, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_addNum, self._AddItemNum, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_subNum, self._SubItemNum, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_start, self._StartProduce, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_apply, self._Apply, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_getItem, self._ReceiveItem, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_max, self._BtnMax, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_min, self._BtnMin, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_speedup, self._BtnSpeedup, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_preset, self._BtnPreset, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_recipe, self._BtnRecipe, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_compose, self._StartRecipeCompose, self)
  self:RegisterEvent(LuaEvent.BuildingReceiveResult, self._OnReceiveResult, self)
  self:RegisterEvent(LuaEvent.BuildingFinish, self._BuildingFinish, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self._Refresh, self)
  self:RegisterEvent(LuaEvent.BuildingProduceItem, self._OnProduceItem, self)
  self:RegisterEvent("Building2DDetailPage_ComposeItem", self._ComposeItemFinish, self)
  self:RegisterEvent(LuaEvent.UpdateBuildingHero, self._UpdateBuildingHero, self)
  self:RegisterEvent(LuaEvent.SpeedupOk, self._SpeedupOk, self)
  self.tab_Widgets.txt_input.onValueChanged:AddListener(function(msg)
    self:_Input(msg)
  end)
end

function Building2DDetailPage:BtnSelectedArrAdd()
  local widgets = self:GetWidgets()
  self.btnSelectArr = {}
  self.btnSelectArr[FunctionIndex.Information] = widgets.obj_infoSelected
  self.btnSelectArr[FunctionIndex.Recipe_compose] = widgets.obj_composeSelected
  self.btnSelectArr[FunctionIndex.Recipe] = widgets.obj_produceSelected
end

function Building2DDetailPage:FunctionBtnSelectd(index)
  for i = 1, #self.btnSelectArr do
    if index == i then
      self.btnSelectArr[i]:SetActive(true)
    else
      self.btnSelectArr[i]:SetActive(false)
    end
  end
end

function Building2DDetailPage:PlayBgm(btype)
  SoundManager.Instance:PlayMusic(self.buildingCfg.building_scene_bgm)
end

function Building2DDetailPage:GetCongfigNameByIndex()
  return BuildingRecipes[self.configIndex]
end

function Building2DDetailPage:GetCongfigFullNameByIndex()
  return "config_" .. self:GetCongfigNameByIndex()
end

function Building2DDetailPage:_Refresh()
  local buildings = Data.buildingData:GetBuildingsByType(self.buildingCfg.type)
  self:ShowBuildingList(buildings)
  self:SetBtns()
end

function Building2DDetailPage:ShowBuildingList(buildings)
  self.buildings = buildings
  local widgets = self:GetWidgets()
  widgets.building_tog_group:ClearToggles()
  UIHelper.CreateSubPart(widgets.obj_build, widgets.trans_build, #buildings, function(index, tabPart)
    local data = buildings[index]
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    UIHelper.SetText(tabPart.tx_name, cfg.name)
    UIHelper.SetText(tabPart.tx_lv, data.Level)
    UIHelper.SetImage(tabPart.im_building, cfg.typeicon)
    local status = Logic.buildingLogic:GetShowStatus(data, cfg)
    UIHelper.SetText(tabPart.tx_state, Logic.buildingLogic:GetStatusStr(status, cfg.type, data))
    UIHelper.SetText(tabPart.tx_num, string.format("%s/%s", #data.HeroList, cfg.heronumber))
    widgets.building_tog_group:RegisterToggle(tabPart.item_tog)
    self.buildingListParts[data.Id] = {tabPart = tabPart, buildingData = data}
    if self.selectedIndex == index - 1 then
      self.selectedPart = tabPart
    end
    if cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory or cfg.type == MBuildingType.ItemFactory or cfg.type == MBuildingType.DormRoom then
      tabPart.tx_state.gameObject:SetActive(true)
      tabPart.obj_state:SetActive(true)
    else
      tabPart.tx_state.gameObject:SetActive(false)
      tabPart.obj_state:SetActive(false)
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.building_tog_group, self, "", self._OnClickBuild)
  self.checkDirty = true
  widgets.building_tog_group:SetActiveToggleIndex(self.selectedIndex)
  for k, v in pairs(self.buildingListParts) do
    if v.buildingData.Status == BuildingStatus.Adding or v.buildingData.Status == BuildingStatus.Upgrading then
      self:StartUpgradeTimer()
      break
    end
  end
end

function Building2DDetailPage:SetClickIndex(index)
  if self.index == nil then
    self.index = index
  end
end

function Building2DDetailPage:GetClickIndex()
  if self.index == nil then
    return 0
  end
  return self.index
end

function Building2DDetailPage:_OnClickBuild(index)
  local widgets = self:GetWidgets()
  local buildingData = self.buildings[index + 1]
  if self.selectedIndex and self.selectedIndex ~= index and self.selectedPart then
    local cfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    local show = cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory or cfg.type == MBuildingType.ItemFactory or cfg.type == MBuildingType.DormRoom
    self.selectedPart.obj_state:SetActive(show)
  end
  if self:GetClickIndex() ~= index then
    self.choosedRecipe_composeId = 0
  end
  self:SetClickIndex(index)
  self.selectedIndex = index
  local tabPart = self.buildingListParts[buildingData.Id].tabPart
  tabPart.obj_state:SetActive(false)
  self.selectedPart = tabPart
  widgets.obj_reddot:SetActive(buildingData.ItemCount == 0)
  self:SelectBuilding(buildingData)
end

function Building2DDetailPage:CheckComposeReddot()
  local showDot = Logic.redDotLogic.FactoryItemIsClicked()
  local widgets = self:GetWidgets()
  widgets.compose_reddot:SetActive(showDot)
end

function Building2DDetailPage:SelectBuilding(buildingData)
  self.buildingData = buildingData
  self.buildingCfg = configManager.GetDataById("config_buildinginfo", self.buildingData.Tid)
  self.productId = self.buildingCfg.productid[2]
  self.choosedRecipeId = self.buildingData.RecipeId
  self.produceCount = self:GetProduceCount()
  self:_UpdateBuildInfo()
  if self.configIndex == FunctionIndex.Recipe then
    self:_UpdateItemInfo()
  else
    if self.configIndex == FunctionIndex.Recipe_compose then
      self:_UpdateRecipeComposeItemInfo(self.choosedRecipe_composeId)
    else
    end
  end
end

function Building2DDetailPage:SetBtns()
  local widgets = self:GetWidgets()
  if self.productId then
    if self.productId == CurrencyType.GOLD or self.productId == CurrencyType.SUPPLY then
      widgets.btn_get.gameObject:SetActive(true)
    else
      widgets.btn_get.gameObject:SetActive(false)
    end
    widgets.btn_info.gameObject:SetActive(false)
    widgets.btn_make.gameObject:SetActive(false)
  else
    widgets.btn_get.gameObject:SetActive(false)
    widgets.btn_info.gameObject:SetActive(true)
    widgets.btn_make.gameObject:SetActive(true)
  end
  local enabled = self.buildingCfg.type ~= MBuildingType.Office and self.buildingData.Level > 1
  widgets.btn_down.interactable = enabled
  local buildType = self.buildingCfg.type
  widgets.btn_info.gameObject:SetActive(buildType == MBuildingType.ItemFactory)
  widgets.btn_make.gameObject:SetActive(buildType == MBuildingType.ItemFactory)
  widgets.btn_recipe.gameObject:SetActive(buildType == MBuildingType.ItemFactory)
end

function Building2DDetailPage:_SwitchToInfoPanel()
  local widgets = self:GetWidgets()
  widgets.obj_buildRoot:SetActive(true)
  widgets.obj_itemRoot:SetActive(false)
  self:FunctionBtnSelectd(FunctionIndex.Information)
  self:SetBtns()
end

function Building2DDetailPage:_UpdateBuildInfo()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_name, self.buildingCfg.name)
  UIHelper.SetText(widgets.tx_lv, "Lv." .. self.buildingData.Level)
  UIHelper.SetImage(widgets.im_buildIcon, self.buildingCfg.typeicon)
  local recipeId = self.buildingData.RecipeId
  if 0 < recipeId and 0 < self.buildingData.ItemCount and self.configIndex ~= FunctionIndex.Recipe_compose then
    local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), recipeId)
    local itemCfg = Logic.bagLogic:GetItemByTempateId(recipeCfg.item[1], recipeCfg.item[2])
    UIHelper.SetImage(widgets.img_item, itemCfg.icon, true)
    widgets.img_item.gameObject:SetActive(true)
    widgets.obj_itembg:SetActive(true)
  else
    widgets.img_item.gameObject:SetActive(false)
    widgets.obj_itembg:SetActive(false)
  end
  local heroList = self.buildingData.HeroList
  local heroSlotCount = self.buildingCfg.heronumber
  UIHelper.CreateSubPart(widgets.obj_hero, widgets.trans_shipslot, 5, function(index, tabPart)
    tabPart.obj_mask:SetActive(index > heroSlotCount)
    if index <= heroSlotCount then
      tabPart.im_quality.gameObject:SetActive(heroList[index] ~= nil)
      if heroList[index] then
        local ship = Data.heroData:GetHeroById(heroList[index])
        if ship then
          local shipInfo = Logic.shipLogic:GetShipShowByHeroId(ship.HeroId)
          tabPart.im_icon.gameObject:SetActive(true)
          UIHelper.SetImage(tabPart.im_icon, tostring(shipInfo.ship_icon5))
          UIHelper.SetStar(tabPart.Star, tabPart.StarPrt, ship.Advance)
          UIHelper.SetText(tabPart.tx_lv, "Lv." .. Mathf.ToInt(ship.Lvl))
          UIHelper.SetImage(tabPart.im_quality, QualityIcon[ship.quality])
          UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[ship.type])
          tabPart.tx_name.gameObject:SetActive(true)
          local shipName = Logic.shipLogic:GetRealName(ship.HeroId)
          UIHelper.SetText(tabPart.tx_name, shipName)
          tabPart.obj_mood:SetActive(true)
          local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
          local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(heroList[index], MarryType.Mood)
          if moodInfo then
            UIHelper.SetImage(tabPart.img_mood, moodInfo.mood_icon)
            tabPart.obj_badMood:SetActive(curMood == 0)
          end
          local percent = curMood / moodLimit[2]
          tabPart.slider_mood.value = percent
        end
      else
        tabPart.tx_name.gameObject:SetActive(false)
        tabPart.obj_mood:SetActive(false)
        tabPart.obj_badMood:SetActive(false)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.item, self._OnClickAddHero, self, heroList[index])
    else
      tabPart.tx_name.gameObject:SetActive(false)
      tabPart.obj_mood:SetActive(false)
      tabPart.im_quality.gameObject:SetActive(false)
      tabPart.obj_badMood:SetActive(false)
    end
  end)
  local effectedRecipes = {}
  local recipeEffectCount = 0
  local effects = Logic.buildingLogic:GetBuildingEffects(self.buildingCfg.type)
  local heroEffectCount = #effects.HeroEffects
  if self.buildingCfg.type == MBuildingType.ItemFactory then
    effectedRecipes = Logic.buildingLogic:GetItemRecipeAdd(self.buildingData)
    recipeEffectCount = #effectedRecipes
  end
  UIHelper.CreateSubPart(widgets.obj_heroEffect, widgets.trans_heroEffect, heroEffectCount + recipeEffectCount, function(index, tabPart)
    if index <= heroEffectCount then
      local effectFunc = effects.HeroEffects[index]
      local key, valueStr, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
      if effectFunc == HeroEffect.ItemProduceSpeedAdd or effectFunc == HeroEffect.CoinProduceSpeedAdd then
        tabPart.tx_key.gameObject:SetActive(0 < value)
        tabPart.tx_value.gameObject:SetActive(0 < value)
      end
      UIHelper.SetText(tabPart.tx_key, key)
      UIHelper.SetText(tabPart.tx_value, valueStr)
    else
      index = index - heroEffectCount
      local effectedRecipe = effectedRecipes[index]
      local recipeTypeCfg = Logic.buildingLogic:GetRecipeTypeCfg(effectedRecipe.recipeType)
      UIHelper.SetText(tabPart.tx_key, recipeTypeCfg.name .. UIHelper.GetString(3000039))
      local value = effectedRecipe.add * 100
      value = Logic.buildingLogic:KeepFloat2(value)
      UIHelper.SetText(tabPart.tx_value, string.format("%s%%", value))
    end
  end)
  UIHelper.CreateSubPart(widgets.obj_buildEffect, widgets.trans_buildEffect, #effects.BuildingEffects, function(index, tabPart)
    local effectFunc = effects.BuildingEffects[index]
    local key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
    UIHelper.SetText(tabPart.tx_key, key)
    UIHelper.SetText(tabPart.tx_value, value)
    if effectFunc == BuildingEffect.ProductCount then
      self.produceTimerData.tabPart = tabPart
      self.produceTimerData.effectFunc = effectFunc
    end
  end)
  local pre, characterStr = Logic.buildingLogic:GetCharacterStr(self.buildingData)
  UIHelper.SetText(widgets.tx_character, string.format("%s%s", pre, characterStr))
  UIHelper.SetText(widgets.tx_des, UIHelper.GetString(self.buildingCfg.desc))
end

function Building2DDetailPage:StartProduceTimer()
  if self.productId == CurrencyType.GOLD or self.productId == CurrencyType.SUPPLY then
    self:StopProduceTimer()
    self.produceTimer = self:CreateTimer(function()
      self:DoProduceUpdate()
    end, 10, -1, false)
    self:StartTimer(self.produceTimer)
    self:DoProduceUpdate()
  end
end

function Building2DDetailPage:DoProduceUpdate()
  local effectFunc = self.produceTimerData.effectFunc
  local tabPart = self.produceTimerData.tabPart
  local key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
  UIHelper.SetText(tabPart.tx_key, key)
  UIHelper.SetText(tabPart.tx_value, value)
end

function Building2DDetailPage:StopProduceTimer()
  if self.produceTimer then
    self:StopTimer(self.produceTimer)
    self.produceTimer = nil
  end
end

function Building2DDetailPage:StartUpgradeTimer()
  self:StopUpgradeTimer()
  self.upgradeTimer = self:CreateTimer(function()
    self:DoUpgradeCountDown()
  end, 1, -1, false)
  self:StartTimer(self.upgradeTimer)
  self:DoUpgradeCountDown()
end

function Building2DDetailPage:DoUpgradeCountDown()
  for buildingId, timerData in pairs(self.buildingListParts) do
    local tabPart = timerData.tabPart
    local data = timerData.buildingData
    if data.Status == BuildingStatus.Adding or data.Status == BuildingStatus.Upgrading then
      local countDown = Logic.buildingLogic:GetUpgradeCountDown(data)
      if 0 <= countDown then
        local buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
        UIHelper.SetText(tabPart.tx_state, Logic.buildingLogic:GetStatusStr(data.Status, buildingCfg.type, data))
      else
        self.buildingListParts[data.Id] = nil
        if next(self.buildingListParts) == nil then
          self:StopUpgradeTimer()
        end
      end
    end
  end
end

function Building2DDetailPage:StopUpgradeTimer()
  if self.upgradeTimer then
    self:StopTimer(self.upgradeTimer)
  end
  self.upgradeTimer = nil
end

function Building2DDetailPage:_SwitchToItemPanal()
  self.configIndex = FunctionIndex.Recipe
  local widgets = self:GetWidgets()
  widgets.obj_buildRoot:SetActive(false)
  widgets.obj_itemRoot:SetActive(true)
  UIHelper.SetText(self.tab_Widgets.txt_input, self.produceCount)
  self:SetBtns()
  self:FunctionBtnSelectd(FunctionIndex.Recipe)
  self:_UpdateItemInfo()
end

function Building2DDetailPage:_SwitchToRecipeItemPanal()
  local widgets = self:GetWidgets()
  widgets.obj_buildRoot:SetActive(false)
  widgets.obj_itemRoot:SetActive(true)
  self.choosedRecipe_composeId = 0
  self:SetBtns()
  self:_UpdateRecipeComposeItemInfo(0)
end

function Building2DDetailPage:_OnClickAddHero(go, heroId)
  local buildingData = self.buildingData
  local max = self.buildingCfg.heronumber
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  UIHelper.OpenPage("BuildingHeroSelectPage", {
    heroInfoList = tabShowHero,
    selectMax = max,
    selectedHeroList = buildingData.HeroList,
    buildingData = buildingData,
    selectedHeroId = heroId
  })
end

function Building2DDetailPage:_Receive()
  local checkResource, errMsg = Logic.buildingLogic:CheckReceiveResource(self.buildingData)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  local count = Logic.buildingLogic:Produce(self.buildingData)
  if count <= 0 then
    return
  end
  Service.buildingService:ReceiveBuilding(self.buildingData.Id)
end

function Building2DDetailPage:_Upgrade()
  local targetLevel, errMsg = Logic.buildingLogic:CheckUpgradeLevel(self.buildingData)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  UIHelper.OpenPage("BuildingGradeChangeTip", {
    opType = MBuildingTipType.LevelUp,
    buildingData = self.buildingData,
    targetLevel = targetLevel
  })
end

function Building2DDetailPage:_Degrade()
  if self.buildingCfg.type == MBuildingType.Office then
    return
  end
  if self.buildingData.Level <= 1 then
    return
  end
  local targetLevel, errMsg = Logic.buildingLogic:CheckDegradeLevel(self.buildingData)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  UIHelper.OpenPage("BuildingGradeChangeTip", {
    opType = MBuildingTipType.LevelDown,
    buildingData = self.buildingData,
    targetLevel = targetLevel
  })
end

function Building2DDetailPage:_OnClickHeroSlot(go, param)
end

function Building2DDetailPage:_ChooseRecipe()
  UIHelper.OpenPage("BuildingItemChooseRecipe", {
    buildingTid = self.buildingCfg.id,
    onSelect = function(recipeId, index)
      self:OnSelectRecipe(recipeId, index)
    end,
    Index = self.configIndex
  })
end

function Building2DDetailPage:OnSelectRecipe(recipeId, index)
  self.configIndex = index
  UIHelper.SetText(self.tab_Widgets.txt_input, 1)
  if index == FunctionIndex.Recipe then
    self.choosedRecipeId = recipeId
    self.produceCount = 1
    self:FunctionBtnSelectd(FunctionIndex.Recipe)
    self:_UpdateItemInfo()
  else
    self.choosedRecipe_composeId = recipeId
    self.produceComposeCount = 1
    self:_UpdateRecipeComposeItemInfo(recipeId)
  end
end

function Building2DDetailPage:_SetComposeBtn(setOpen)
  self.tab_Widgets.obj_compose:SetActive(setOpen)
  self.tab_Widgets.obj_time:SetActive(not setOpen)
  self.tab_Widgets.tx_time.gameObject:SetActive(not setOpen)
  self.tab_Widgets.obj_timeStr:SetActive(not setOpen)
  self.tab_Widgets.btn_speedup.gameObject:SetActive(not setOpen)
  self.tab_Widgets.obj_upstr:SetActive(not setOpen)
  self.tab_Widgets.btn_getItem.gameObject:SetActive(not setOpen)
  self.tab_Widgets.tx_itemNum.gameObject:SetActive(not setOpen)
  if setOpen then
    UIHelper.SetText(self.tab_Widgets.txt_input, self.produceComposeCount)
    UIHelper.SetText(self.tab_Widgets.tx_clickselect, UIHelper.GetString(3200012))
    UIHelper.SetText(self.tab_Widgets.tx_detail, UIHelper.GetString(3200013))
    UIHelper.SetText(self.tab_Widgets.tx_numstr, UIHelper.GetString(3200014))
  else
    UIHelper.SetText(self.tab_Widgets.txt_input, self.produceCount)
    UIHelper.SetText(self.tab_Widgets.tx_clickselect, UIHelper.GetString(910000244))
    UIHelper.SetText(self.tab_Widgets.tx_detail, UIHelper.GetString(910000242))
    UIHelper.SetText(self.tab_Widgets.tx_numstr, UIHelper.GetString(910000246))
    self:CheckApplyDirty()
  end
end

function Building2DDetailPage:_UpdateRecipeComposeItemInfo(recipeId)
  self:_SetComposeBtn(true)
  self:FunctionBtnSelectd(FunctionIndex.Recipe_compose)
  local widgets = self:GetWidgets()
  local status = BuildingStatus.Idle
  if status == BuildingStatus.Working then
    UIHelper.SetText(widgets.txt_start, UIHelper.GetString(3002070))
  else
    UIHelper.SetText(widgets.txt_start, UIHelper.GetString(3002071))
  end
  if recipeId and 0 < recipeId then
    local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), recipeId)
    widgets.btn_speedup.gameObject:SetActive(false)
    local item = recipeCfg.item
    local tableIndex = configManager.GetDataById("config_table_index", item[1])
    local produceItem = configManager.GetDataById(tableIndex.file_name, item[2])
    UIHelper.SetImage(widgets.item_bg, QualityIcon[produceItem.quality])
    UIHelper.SetImage(widgets.item_icon, produceItem.icon)
    UIHelper.SetText(widgets.item_name, produceItem.name)
    widgets.trans_itemInput.gameObject:SetActive(true)
    self.produceMatParts = {}
    UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_itemInput, 3, function(index, tabPart)
      local material = recipeCfg["rawmaterial" .. index]
      if next(material) ~= nil then
        tabPart.obj_item.gameObject:SetActive(true)
        tableIndex = configManager.GetDataById("config_table_index", material[1])
        local matItem = configManager.GetDataById(tableIndex.file_name, material[2])
        UIHelper.SetText(tabPart.tx_name, matItem.name)
        UIHelper.SetImage(tabPart.im_icon, matItem.icon)
        UIHelper.SetImage(tabPart.im_frame, QualityIcon[matItem.quality])
        local ownCount = Logic.bagLogic:GetConsumeCurrNum(material[1], material[2])
        local costCount = self.produceComposeCount * material[3]
        local color = ownCount < costCount and "#FF0000" or "#1ac13a"
        UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s/%s</color>", color, ownCount, costCount))
        UGUIEventListener.AddButtonOnClick(tabPart.btn, self._OnClickMaterial, self, material)
        table.insert(self.produceMatParts, {material = material, tabPart = tabPart})
      else
        tabPart.obj_item.gameObject:SetActive(false)
      end
    end)
    widgets.btn_item:SetActive(true)
  else
    widgets.trans_itemInput.gameObject:SetActive(false)
    widgets.btn_item:SetActive(false)
  end
  UIHelper.SetText(widgets.txt_input, self.produceComposeCount)
end

function Building2DDetailPage:_UpdateItemInfo()
  self:_SetComposeBtn(false)
  local widgets = self:GetWidgets()
  local status = self.buildingData.Status
  if status == BuildingStatus.Working then
    UIHelper.SetText(widgets.txt_start, UIHelper.GetString(3002070))
  else
    UIHelper.SetText(widgets.txt_start, UIHelper.GetString(3002071))
  end
  if self.choosedRecipeId and self.choosedRecipeId > 0 then
    local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), self.choosedRecipeId)
    local showSpeedup = self.buildingData.Status == BuildingStatus.Working and self.configIndex ~= FunctionIndex.Recipe_compose
    showSpeedup = showSpeedup and 0 < recipeCfg.cost_energy and self.choosedRecipeId == self.buildingData.RecipeId
    widgets.btn_speedup.gameObject:SetActive(showSpeedup)
    local item = recipeCfg.item
    local tableIndex = configManager.GetDataById("config_table_index", item[1])
    local produceItem = configManager.GetDataById(tableIndex.file_name, item[2])
    UIHelper.SetImage(widgets.item_bg, QualityIcon[produceItem.quality])
    UIHelper.SetImage(widgets.item_icon, produceItem.icon)
    UIHelper.SetText(widgets.item_name, produceItem.name)
    if (status ~= BuildingStatus.Working or self.dirty) and self.configIndex ~= FunctionIndex.Recipe_compose then
      self:UpdateCostTime()
    end
    widgets.trans_itemInput.gameObject:SetActive(true)
    self.produceMatParts = {}
    UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_itemInput, 3, function(index, tabPart)
      local material = recipeCfg["rawmaterial" .. index]
      if next(material) ~= nil then
        tableIndex = configManager.GetDataById("config_table_index", material[1])
        local matItem = configManager.GetDataById(tableIndex.file_name, material[2])
        UIHelper.SetText(tabPart.tx_name, matItem.name)
        UIHelper.SetImage(tabPart.im_icon, matItem.icon)
        UIHelper.SetImage(tabPart.im_frame, QualityIcon[matItem.quality])
        local ownCount = Logic.bagLogic:GetConsumeCurrNum(material[1], material[2])
        local costCount = self.produceCount * material[3]
        local color = ownCount < material[3] and "#FF0000" or "#1ac13a"
        UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s/%s</color>", color, ownCount, costCount))
        UGUIEventListener.AddButtonOnClick(tabPart.btn, self._OnClickMaterial, self, material)
        table.insert(self.produceMatParts, {material = material, tabPart = tabPart})
      else
        tabPart.obj_item.gameObject:SetActive(false)
      end
    end)
    widgets.btn_item:SetActive(true)
  else
    widgets.trans_itemInput.gameObject:SetActive(false)
    widgets.btn_item:SetActive(false)
  end
  UIHelper.SetText(widgets.txt_input, self.produceCount)
  if self.buildingData.Status == BuildingStatus.Working and 0 < self.buildingData.RecipeId then
    self:StartProduceItemTimer()
  end
  local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  UIHelper.SetText(widgets.tx_itemNum, string.format("%s/%s", finishCount, self.buildingCfg.productmax))
end

function Building2DDetailPage:UpdateCostTime()
  if self.choosedRecipeId > 0 then
    local widgets = self:GetWidgets()
    local remainTime = Logic.buildingLogic:GetProduceItemTime(self.buildingData, self.choosedRecipeId, self.produceCount)
    local timeStr = time.getHoursString(remainTime)
    UIHelper.SetText(widgets.tx_time, timeStr)
  end
end

function Building2DDetailPage:UpdateItemCount()
  local deltaCount = 1
  if self.buildingData.RecipeId == self.choosedRecipeId then
    local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    deltaCount = self.produceCount - remainCount
  else
    deltaCount = self.produceCount
  end
  deltaCount = math.max(deltaCount, 1)
  for i, data in ipairs(self.produceMatParts) do
    local material = data.material
    local tabPart = data.tabPart
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(material[1], material[2])
    local costCount = self.produceCount * material[3]
    local color = ownCount < deltaCount * material[3] and "#FF0000" or "#1ac13a"
    UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s/%s</color>", color, ownCount, costCount))
  end
end

function Building2DDetailPage:UpdateComposeItemCount()
  for i, data in ipairs(self.produceMatParts) do
    local material = data.material
    local tabPart = data.tabPart
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(material[1], material[2])
    local costCount = self.produceComposeCount * material[3]
    local color = ownCount < costCount and "#FF0000" or "#1ac13a"
    UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s/%s</color>", color, ownCount, costCount))
  end
end

function Building2DDetailPage:_AddItemNum()
  if self.configIndex == FunctionIndex.Recipe_compose then
    self:_AddComposeItemNum()
    return
  end
  if self.choosedRecipeId and self.choosedRecipeId > 0 then
    local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    local max = self.buildingCfg.productmax - finishCount
    if max >= self.produceCount + 1 then
      self.produceCount = self.produceCount + 1
      self:CheckApplyDirty()
      self:UpdateComposeItemCount()
    else
      noticeManager:ShowTip(UIHelper.GetString(3002061))
      return
    end
    if self.produceCount == remainCount and self.choosedRecipeId == self.buildingData.RecipeId then
      self:DoCountDown()
    else
      local widgets = self:GetWidgets()
      UIHelper.SetText(widgets.txt_input, self.produceCount)
      self:UpdateCostTime()
    end
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
    return
  end
end

function Building2DDetailPage:_AddComposeItemNum()
  if self.choosedRecipe_composeId and self.choosedRecipe_composeId > 0 then
    local max = 99
    if max >= self.produceComposeCount + 1 then
      self.produceComposeCount = self.produceComposeCount + 1
      self:UpdateComposeItemCount()
    else
      noticeManager:ShowTip(UIHelper.GetString(3002061))
      return
    end
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.txt_input, self.produceComposeCount)
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
    return
  end
end

function Building2DDetailPage:_SubComposeItemNum()
  if self.choosedRecipe_composeId and self.choosedRecipe_composeId > 0 then
    if 1 <= self.produceComposeCount - 1 then
      self.produceComposeCount = self.produceComposeCount - 1
      self:UpdateItemCount()
    else
      noticeManager:ShowTip(UIHelper.GetString(3002062))
      return
    end
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.txt_input, self.produceComposeCount)
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
    return
  end
end

function Building2DDetailPage:_SubItemNum()
  if self.configIndex == FunctionIndex.Recipe_compose then
    self:_SubComposeItemNum()
    return
  end
  if self.choosedRecipeId and self.choosedRecipeId > 0 then
    local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    if 0 <= self.produceCount - 1 then
      self.produceCount = self.produceCount - 1
      self:CheckApplyDirty()
      self:UpdateItemCount()
    else
      noticeManager:ShowTip(UIHelper.GetString(3002062))
      return
    end
    if self.produceCount == remainCount and self.choosedRecipeId == self.buildingData.RecipeId then
      self:DoCountDown()
    else
      local widgets = self:GetWidgets()
      UIHelper.SetText(widgets.txt_input, self.produceCount)
      self:UpdateCostTime()
    end
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
    return
  end
end

function Building2DDetailPage:GetMaxCount(recipeId, curMax, remainCount)
  local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), recipeId)
  local maxCount = curMax
  if recipeCfg.rawmaterial1 and #recipeCfg.rawmaterial1 > 0 then
    local reqCount = recipeCfg.rawmaterial1[3]
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(recipeCfg.rawmaterial1[1], recipeCfg.rawmaterial1[2])
    local count = math.floor(ownCount / reqCount)
    if maxCount > count then
      maxCount = count
    end
  end
  if recipeCfg.rawmaterial2 and 0 < #recipeCfg.rawmaterial2 then
    local reqCount = recipeCfg.rawmaterial2[3]
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(recipeCfg.rawmaterial2[1], recipeCfg.rawmaterial2[2])
    local count = math.floor(ownCount / reqCount)
    if maxCount > count then
      maxCount = count
    end
  end
  if recipeCfg.rawmaterial3 and 0 < #recipeCfg.rawmaterial3 then
    local reqCount = recipeCfg.rawmaterial3[3]
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(recipeCfg.rawmaterial3[1], recipeCfg.rawmaterial3[2])
    local count = math.floor(ownCount / reqCount)
    if maxCount > count then
      maxCount = count
    end
  end
  if recipeId == self.buildingData.RecipeId then
    maxCount = remainCount + maxCount
  end
  if curMax < maxCount then
    maxCount = curMax
  end
  return maxCount
end

function Building2DDetailPage:_BtnMax()
  if self.configIndex == FunctionIndex.Recipe then
    self:_BtnProduceMax()
    return
  else
    self:_BtnComposeMax()
  end
end

function Building2DDetailPage:_BtnProduceMax()
  if self.choosedRecipeId and self.choosedRecipeId > 0 then
    local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    local max = self.buildingCfg.productmax - finishCount
    max = self:GetMaxCount(self.choosedRecipeId, max, remainCount)
    local addCount = max - self.produceCount
    self.produceCount = max
    self:CheckApplyDirty()
    self:UpdateItemCount(addCount)
    if self.produceCount == remainCount and self.choosedRecipeId == self.buildingData.RecipeId then
      self:DoCountDown()
    else
      local widgets = self:GetWidgets()
      UIHelper.SetText(widgets.txt_input, self.produceCount)
      self:UpdateCostTime()
    end
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
  end
end

function Building2DDetailPage:_BtnComposeMax()
  if self.choosedRecipe_composeId and self.choosedRecipe_composeId > 0 then
    local max = self.composeMaxNum
    max = self:GetMaxCount(self.choosedRecipe_composeId, max, 0)
    if max == 0 then
      local msg = Logic.buildingLogic:CheckProduceItemCost(self.choosedRecipe_composeId, 1, self:GetCongfigFullNameByIndex())
      if msg then
        noticeManager:ShowTip(msg)
      end
    end
    self.produceComposeCount = max
    self:UpdateComposeItemCount()
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.txt_input, self.produceComposeCount)
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
  end
end

function Building2DDetailPage:_BtnMin()
  if self.configIndex == FunctionIndex.Recipe then
    self:_BtnProduceMin()
  else
    self:_BtnComposeMin()
  end
end

function Building2DDetailPage:_BtnProduceMin()
  if self.choosedRecipeId and self.choosedRecipeId > 0 then
    local _, _, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    local subCount = self.produceCount
    self.produceCount = 0
    self:CheckApplyDirty()
    if self.produceCount == remainCount and self.choosedRecipeId == self.buildingData.RecipeId then
      self:DoCountDown()
    else
      local widgets = self:GetWidgets()
      UIHelper.SetText(widgets.txt_input, self.produceCount)
      self:UpdateCostTime()
    end
    self:UpdateItemCount(-subCount)
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
  end
end

function Building2DDetailPage:_BtnComposeMin()
  if self.choosedRecipe_composeId and self.choosedRecipe_composeId > 0 then
    self.produceComposeCount = 1
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.txt_input, self.produceComposeCount)
    self:UpdateComposeItemCount()
  else
    noticeManager:ShowTip(UIHelper.GetString(3002057))
  end
end

function Building2DDetailPage:_Input(msg)
  local length = string.len(msg)
  if 3 < length then
    msg = string.sub(msg, 1, 3)
    self.tab_Widgets.txt_input.text = msg
    return
  end
  if msg == "" then
    msg = "0"
    self.tab_Widgets.txt_input.text = msg
    return
  end
  if string.len(msg) > 1 and string.sub(msg, 1, 1) == "0" then
    msg = msg.sub(msg, 2)
    self.tab_Widgets.txt_input.text = msg
    return
  end
  local count = tonumber(self.tab_Widgets.txt_input.text)
  if not count or count < 0 then
    self.tab_Widgets.txt_input.text = "1"
    return
  end
  local text = self.tab_Widgets.txt_input.text
  if self.configIndex == FunctionIndex.Recipe then
    self.produceCount = tonumber(text)
    self:CheckApplyDirty()
    self:UpdateItemCount()
  else
    self.produceComposeCount = tonumber(text)
    self:UpdateComposeItemCount()
  end
end

function Building2DDetailPage:CheckMaxLimit()
  local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  local curMax = self.buildingCfg.productmax - finishCount
  if curMax < self.produceCount then
    self.produceCount = curMax
  end
end

function Building2DDetailPage:_StartRecipeCompose()
  local produceCount = tonumber(self.tab_Widgets.txt_input.text)
  if produceCount == 0 then
    noticeManager:ShowTip(UIHelper.GetString(3002058))
    return
  end
  local errMsg = Logic.buildingLogic:CheckProduceItemCost(self.choosedRecipe_composeId, produceCount, self:GetCongfigFullNameByIndex(FunctionIndex.Recipe_compose))
  if errMsg then
    noticeManager:ShowTip(errMsg)
    return
  end
  self.configIndex = FunctionIndex.Recipe_compose
  Service.buildingService:ComposeItem(self.buildingData.Id, self.choosedRecipe_composeId, produceCount)
end

function Building2DDetailPage:_StartProduce()
  self:CheckMaxLimit()
  self.tab_Widgets.txt_input.text = self.produceCount
  local _, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  local max = self.buildingCfg.productmax
  if finishCount >= max then
    noticeManager:ShowTip(UIHelper.GetString(3002061))
    return
  end
  if self.buildingData.Status == BuildingStatus.Idle and self.produceCount == 0 then
    noticeManager:ShowTip(UIHelper.GetString(3002058))
    return
  end
  if self.buildingData.Status == BuildingStatus.Working and self.produceCount == self.buildingData.ItemCount and self.choosedRecipeId == self.buildingData.RecipeId then
    noticeManager:ShowTip(UIHelper.GetString(3002059))
    return
  end
  local producingCount = self:GetProduceCount()
  local deltaCount = self.produceCount - producingCount
  if self.choosedRecipeId ~= self.buildingData.RecipeId and deltaCount == 0 then
    noticeManager:ShowTip(UIHelper.GetString(3002058))
    return
  end
  local errMsg = Logic.buildingLogic:CheckProduceItemCost(self.choosedRecipeId, deltaCount)
  if errMsg then
    noticeManager:ShowTip(errMsg)
    return
  end
  Service.buildingService:ProduceItem(self.buildingData.Id, self.choosedRecipeId, self.produceCount)
end

function Building2DDetailPage:StartProduceItemTimer()
  if self.buildingCfg.type == MBuildingType.ItemFactory and self.buildingData.Status == BuildingStatus.Working then
    self:StopProduceItemTimer()
    self.produceItemTimer = self:CreateTimer(function()
      self:DoCountDown()
    end, 1, -1, false)
    self:StartTimer(self.produceItemTimer)
  end
  self:DoCountDown()
end

function Building2DDetailPage:DoCountDown()
  if self.configIndex == FunctionIndex.Recipe_compose then
    return
  end
  local remainTime, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_itemNum, string.format("%s/%s", finishCount, self.buildingCfg.productmax))
  if not self.dirty then
    UIHelper.SetText(widgets.txt_input, remainCount)
    local timeStr = time.getHoursString(remainTime)
    UIHelper.SetText(widgets.tx_time, timeStr)
    self.produceCount = remainCount
  end
  if remainCount == 0 then
    self.produceCount = 0
  end
  local partData = self.buildingListParts[self.buildingData.Id]
  UIHelper.SetText(partData.tabPart.tx_state, Logic.buildingLogic:GetStatusStr(self.buildingData.Status, self.buildingCfg.type, self.buildingData))
  if self.buildingData.Status == BuildingStatus.Idle then
    self:StopProduceItemTimer()
    self:_Refresh()
  end
end

function Building2DDetailPage:StopProduceItemTimer()
  if self.produceItemTimer then
    self:StopTimer(self.produceItemTimer)
    self.produceItemTimer = nil
  end
end

function Building2DDetailPage:CheckApplyDirty()
  local widgets = self:GetWidgets()
  local dirty = false
  if self.buildingData.Status == BuildingStatus.Working then
    dirty = self.buildingData.RecipeId ~= self.choosedRecipeId
    if not dirty then
      local producingCount = self:GetProduceCount()
      dirty = self.produceCount ~= producingCount
    end
    widgets.btn_apply.gameObject:SetActive(dirty)
  elseif self.buildingData.Status == BuildingStatus.Idle then
    if self.produceCount > 0 then
      dirty = self.choosedRecipeId > 0
    end
    widgets.btn_apply.gameObject:SetActive(false)
  end
  if self.configIndex == FunctionIndex.Recipe then
    widgets.obj_compose:SetActive(false)
  else
    widgets.obj_compose:SetActive(true)
  end
  self.dirty = dirty
end

function Building2DDetailPage:GetProduceCount()
  if self.buildingData and self.buildingData.Status == BuildingStatus.Working then
    local remainTime, finishCount, remainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
    return remainCount
  end
  return 0
end

function Building2DDetailPage:_Apply()
  self:CheckMaxLimit()
  self.tab_Widgets.txt_input.text = self.produceCount
  local deltaCount = self.produceCount
  if self.choosedRecipeId == self.buildingData.RecipeId then
    local producingCount = self:GetProduceCount()
    deltaCount = self.produceCount - producingCount
  elseif deltaCount == 0 then
    noticeManager:ShowTip(UIHelper.GetString(3002058))
    return
  end
  local errMsg = Logic.buildingLogic:CheckProduceItemCost(self.choosedRecipeId, deltaCount)
  if errMsg then
    noticeManager:ShowTip(errMsg)
    return
  end
  Service.buildingService:ProduceItem(self.buildingData.Id, self.choosedRecipeId, self.produceCount)
end

function Building2DDetailPage:_ReceiveItem()
  local _, produceCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  if 0 < produceCount then
    Service.buildingService:ReceiveItem(self.buildingData.Id)
  end
end

function Building2DDetailPage:_OnReceiveResult(result)
  local tabReward = {}
  if result and result.ItemInfo and next(result.ItemInfo) ~= nil then
    Logic.rewardLogic:ShowCommonReward(result.ItemInfo, "Building2DDetailPage")
    for k, v in pairs(result.ItemInfo) do
      table.insert(tabReward, {
        currencyId = v.ConfigId,
        Num = v.Num
      })
    end
  end
  local dotinfo = {
    info = "all_resource_get",
    item_num = tabReward
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function Building2DDetailPage:_OnProduceItem(result)
  if result and result.ItemInfo and next(result.ItemInfo) ~= nil then
    Logic.rewardLogic:ShowCommonReward(result.ItemInfo, "Building2DDetailPage")
  end
  self:_UpdateItemInfo()
  self:_ItemChangeDotinfo()
end

function Building2DDetailPage:_ComposeItemFinish(result)
  local itemInfo = result.ItemInfo
  UIHelper.OpenPage("GetRewardsPage", {Rewards = itemInfo, DontMerge = true})
  self:_UpdateRecipeComposeItemInfo(self.choosedRecipe_composeId)
end

function Building2DDetailPage:_OnClickMaterial(go, item)
  globalNoitceManager:ShowItemInfoPage(item[1], item[2])
end

function Building2DDetailPage:_BuildingFinish(buildingId)
  Logic.buildingLogic:ShowBuildingFinish(buildingId)
end

function Building2DDetailPage:_BtnSpeedup()
  local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), self.choosedRecipeId)
  if recipeCfg.cost_energy == 0 then
    noticeManager:ShowTip(UIHelper.GetString(3200000))
    return
  end
  local curStrength = Data.userData:GetCurrency(CurrencyType.STRENGTH)
  if curStrength <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(3200001))
    return
  end
  UIHelper.OpenPage("ProductionSpeedUpPage", {
    recipeId = self.choosedRecipeId,
    buildingData = self.buildingData
  })
end

function Building2DDetailPage:_BtnPreset()
  UIHelper.OpenPage("BuildingPresetFleetPage", {
    buildingId = self.buildingData.Id
  })
end

function Building2DDetailPage:_BtnRecipe()
  self.configIndex = FunctionIndex.Recipe_compose
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  PlayerPrefs.SetBool(uid .. "composeReddot", false)
  self:CheckComposeReddot()
  self.produceComposeCount = 1
  UIHelper.SetText(self.tab_Widgets.txt_input, self.produceComposeCount)
  self:_SwitchToRecipeItemPanal()
end

function Building2DDetailPage:_Dotinfo()
  local tabHeroName, tabCharacter = self:_DotInfoSameInfo()
  local effectFunc
  if self.buildingCfg.type == MBuildingType.FoodFactory then
    effectFunc = BuildingEffect.MaxAdd
  else
    effectFunc = HeroEffect.Productivity
  end
  local value = self:DotInfoEffect(effectFunc)
  local dotinfo = {
    info = "girl_change",
    building_id = self.buildings[1].Tid,
    ship_name = tabHeroName,
    character_id = tabCharacter,
    effect = value
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function Building2DDetailPage:_ItemChangeDotinfo()
  local tabHeroName, tabCharacter = self:_DotInfoSameInfo()
  local value = self:DotInfoEffect(HeroEffect.Productivity)
  local item_id = 0
  if self.choosedRecipeId and self.choosedRecipeId ~= 0 then
    local recipeCfg = configManager.GetDataById(self:GetCongfigFullNameByIndex(), self.choosedRecipeId)
    local item = recipeCfg.item
    item_id = item[2]
  end
  local dotinfo = {
    info = "item_change",
    ship_name = tabHeroName,
    character_id = tabCharacter,
    effect = value,
    item_id = item_id
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function Building2DDetailPage:_DotInfoSameInfo()
  local tabHeroName = {}
  local tabCharacter = {}
  local heroData = {}
  local shipMainCfg = {}
  local sm_id, name
  for k, v in pairs(self.buildingData.HeroList) do
    sm_id = Data.heroData:GetHeroById(v).TemplateId
    local charIds = Logic.buildingLogic:GetHeroBuildingCharacter(self.buildingCfg.type, sm_id)
    name = Logic.shipLogic:GetRealName(v)
    heroData = Data.heroData:GetHeroById(v)
    shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
    table.insert(tabHeroName, name)
    table.insert(tabCharacter, charIds)
  end
  return tabHeroName, tabCharacter
end

function Building2DDetailPage:DotInfoEffect(effectFunc)
  local key = {}
  local value
  if self.buildingCfg.type == MBuildingType.ItemFactory and self.choosedRecipeId ~= 0 and self.choosedRecipeId ~= nil then
    value = Logic.buildingLogic:GetProduceRecipeProductivity(self.buildingData, self.choosedRecipeId)
    value = Logic.buildingLogic:KeepFloat2(value / 100)
    value = value .. "%"
  end
  if value == nil then
    key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
  end
  return value
end

function Building2DDetailPage:_OnBack()
  local buildingData = self:GetParam().data
  local mode = Logic.buildingLogic:GetMode()
  if buildingData.Id ~= self.buildingData.Id and mode == BuildingMode._3D then
    local page3d = UIPageManager:GetPageFromHistory("Building3DScenePage")
    if page3d then
      page3d:SaveParam({
        buildingId = self.buildingData.Id
      })
    end
  end
  
  local function task()
    self:_CloseSelf()
  end
  
  local param = {Task = task}
  UIHelper.OpenPage("BuildingSwitchPage", param, UILayer.ATTENTION, false)
end

function Building2DDetailPage:_SpeedupOk()
  noticeManager:ShowTip(UIHelper.GetString(3200006))
end

function Building2DDetailPage:_CloseSelf()
  UIHelper.ClosePage("Building2DDetailPage")
end

function Building2DDetailPage:_UpdateBuildingHero()
  self:_Dotinfo()
end

function Building2DDetailPage:DoOnHide()
  Logic.buildingLogic:SetDetailTabIndex(self.selectedIndex)
end

function Building2DDetailPage:DoOnClose()
  Logic.buildingLogic:SetDetailTabIndex(nil)
end

return Building2DDetailPage
