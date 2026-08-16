local BuildingListPage = class("UI.Building.Building2D.BuildingListPage", LuaUIPage)
local sortMap = {
  HeroSortType.Mood,
  HeroSortType.BuildingCharacter
}
local dragDir = {Horizontal = 1, Vertical = 2}

function BuildingListPage:DoInit()
  self.curTabPart = nil
end

function BuildingListPage:DoOnOpen()
  self:OpenTopPage("BuildingListPage", 1, "\232\191\155\233\169\187\230\128\187\232\167\136", self, true)
  Logic.buildingLogic:UpdateBuildings(false)
  local sortFilterData = Logic.sortLogic:GetHeroSort(CommonHeroItem.BuildingList)
  if sortFilterData then
    self.descendantOrder = sortFilterData[1]
    self.filterRule = sortFilterData[2][1]
    self.sortRule = sortFilterData[2][2]
    self:SetSortRule(self.sortRule)
  else
    self.descendantOrder = true
    self.filterRule = {}
    self:SetSortRule(2)
  end
  self.sortType = MHeroSortType.BuildingList
  local cur, max = Logic.buildingLogic:GetBuildFoodProgress()
  self.tab_Widgets.slider_bg.fillAmount = cur / max
  self.objCostList = {}
  self.invalidHeroId = {}
  self.tab_Widgets.tog_sort.isOn = self.descendantOrder
  self:SetSortOrder(self.descendantOrder)
  self:_Refresh()
end

function BuildingListPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_sort, self.OnBtnSort, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.tog_sort, self.OnToggleSort, self)
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self.OnBuildingRefresh, self)
  self:RegisterEvent(LuaCSharpEvent.LoseFocus, function(self, param)
    self:_DestoryFloat()
  end)
end

function BuildingListPage:_DestoryFloat()
  if self.floatCard ~= nil then
    GameObject.Destroy(self.floatCard)
    self.tab_Widgets.float_card:SetActive(false)
    self.floatCard = nil
    if self.curTabPart then
      self.curTabPart.obj_white:SetActive(false)
    end
  end
end

function BuildingListPage:OnBuildingRefresh()
  self:_Refresh()
  self:ShowChangeNumber()
end

function BuildingListPage:_Refresh()
  self.dirtyBuildings = {}
  self.chooseHeroList = Logic.buildingLogic:GetBuildingListData()
  self.builds = Logic.buildingLogic:GetCurBuildingsInfo()
  self.showHeroList = self.chooseHeroList
  self:_ShowBuidingList()
  self:_ShowFoodSilder()
end

function BuildingListPage:_ShowBuidingList()
  local builds = self.builds
  if 0 < #builds then
    self:_showTitle(builds[1].Tid)
  end
  local widgets = self:GetWidgets()
  widgets.tog_group:ClearToggles()
  self.buildingParts = {}
  self.heroSlotParts = {}
  UIHelper.CreateSubPart(widgets.obj_build, widgets.trans_build, #builds, function(index, tabPart)
    self.buildingParts[builds[index].Id] = tabPart
    self:_SetBuildingItem(tabPart, builds[index], index)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group, self, nil, self._OnSelectBuildingItem)
  if not self.selectedIndex then
    self.selectedIndex = 0
  end
  widgets.tog_group:SetActiveToggleIndex(self.selectedIndex)
end

function BuildingListPage:_SetBuildingItem(widgets, datas, index)
  local name = Logic.buildingLogic:GetBuildName(datas.Tid)
  local icon = Logic.buildingLogic:GetBuildIcon(datas.Tid)
  UIHelper.SetText(widgets.tx_name, name)
  UIHelper.SetText(widgets.tx_lv, datas.Level)
  UIHelper.SetImage(widgets.im_icon, icon)
  local state = Logic.buildingLogic:GetStatusStr(datas.Status)
  UIHelper.SetText(widgets.tx_state, state)
  local max = Logic.buildingLogic:GetOneBuildingHeroMax(datas.Tid)
  local heros = self.dirtyBuildings[datas.Id] or datas.HeroList
  UIHelper.CreateSubPart(widgets.obj_hero, widgets.trans_hero, 5, function(index, tabPart)
    if index <= max then
      tabPart.obj_lock:SetActive(false)
      tabPart.im_quality.gameObject:SetActive(heros[index] ~= nil)
      tabPart.slider_mood.gameObject:SetActive(heros[index] ~= nil)
      tabPart.img_mood.gameObject:SetActive(heros[index] ~= nil)
      tabPart.obj_badMood:SetActive(heros[index] ~= nil)
      tabPart.obj_character:SetActive(false)
      if heros[index] then
        local ship = Data.heroData:GetHeroById(heros[index])
        local shipInfo = Logic.shipLogic:GetShipShowByHeroId(ship.HeroId)
        UIHelper.SetImage(tabPart.img_icon, tostring(shipInfo.ship_icon5))
        UIHelper.SetText(tabPart.tx_lv, "Lv." .. Mathf.ToInt(ship.Lvl))
        UIHelper.SetImage(tabPart.im_quality, BuildingQualityIcon[ship.quality])
        local buildingCfg = configManager.GetDataById("config_buildinginfo", datas.Tid)
        local characters, levels = Logic.buildingLogic:GetHeroBuildingCharacter(buildingCfg.type, ship.TemplateId)
        tabPart.obj_character:SetActive(0 < #characters)
        if 0 < #characters then
          local characterCfg = configManager.GetDataById("config_character", characters[1])
          UIHelper.SetText(tabPart.txt_character, string.format("%sLv.%s", characterCfg.name, levels[1]))
        end
        UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[ship.type])
        local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(ship.HeroId, MarryType.Mood)
        if moodInfo then
          UIHelper.SetImage(tabPart.img_mood, moodInfo.mood_icon)
          local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
          local percent = curMood / moodLimit[2]
          tabPart.slider_mood.value = percent
          tabPart.obj_badMood:SetActive(curMood == 0)
        end
        local objEvent = tabPart.obj_event
        UGUIEventListener.AddOnDrag(objEvent, self._OnDragSelectCard, self, {
          tabPart = tabPart,
          heroInfo = ship,
          index = index,
          dir = dragDir.Horizontal
        })
        UGUIEventListener.AddOnEndDrag(objEvent, self._OnEndDrag, self, {
          tabPart = tabPart,
          heroInfo = ship,
          dir = dragDir.Horizontal,
          buildingId = datas.Id
        })
      else
        UGUIEventListener.ClearDragListener(tabPart.obj_event)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.obj_event, self._OnClickHeroSlot, self, {
        data = datas,
        heroId = heros[index]
      })
      self.heroSlotParts[datas.Id] = self.heroSlotParts[datas.Id] or {}
      table.insert(self.heroSlotParts[datas.Id], tabPart)
    else
      tabPart.slider_mood.gameObject:SetActive(false)
      tabPart.img_mood.gameObject:SetActive(false)
      tabPart.im_quality.gameObject:SetActive(false)
      tabPart.obj_lock:SetActive(true)
      tabPart.obj_badMood:SetActive(false)
    end
  end)
  self.tab_Widgets.tog_group:RegisterToggle(widgets.tog_item)
end

function BuildingListPage:UpdateHeroList()
  local widgets = self:GetWidgets()
  local heroList = self.showHeroList
  local count = #heroList
  UIHelper.SetText(self.tab_Widgets.txt_idle, count)
  UIHelper.SetInfiniteItemParam(widgets.list_choose, widgets.obj_choose, count, function(partDic)
    local tabTemp = {}
    for k, v in pairs(partDic) do
      tabTemp[tonumber(k)] = v
    end
    for index, tabPart in pairs(tabTemp) do
      local heroInfo = heroList[index]
      local icon = Logic.shipLogic:GetShipShowByHeroId(heroInfo.HeroId).ship_icon5
      UIHelper.SetImage(tabPart.img_icon, icon)
      UIHelper.SetImage(tabPart.img_quality, BuildingQualityIcon[heroInfo.quality])
      local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(heroInfo.HeroId, MarryType.Mood)
      if moodInfo then
        UIHelper.SetImage(tabPart.img_mood, moodInfo.mood_icon)
        local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
        local percent = curMood / moodLimit[2]
        tabPart.mood_slider.value = percent
        tabPart.obj_badMood:SetActive(curMood == 0)
      end
      local character = self.heroCharacter[heroInfo.HeroId]
      tabPart.obj_character:SetActive(character and 0 < character.cid)
      if 0 < character.cid then
        local characterCfg = configManager.GetDataById("config_character", character.cid)
        UIHelper.SetText(tabPart.txt_character, string.format("%sLv.%s", characterCfg.name, character.level))
      end
      local objEvent = tabPart.obj_event
      UGUIEventListener.AddOnDrag(objEvent, self._OnDragSelectCard, self, {
        tabPart = tabPart,
        heroInfo = heroInfo,
        index = index,
        dir = dragDir.Vertical
      })
      UGUIEventListener.AddOnEndDrag(objEvent, self._OnEndDrag, self, {
        tabPart = tabPart,
        heroInfo = heroInfo,
        dir = dragDir.Vertical
      })
    end
  end)
end

function BuildingListPage:_OnDragSelectCard(go, eventData, params)
  local widgets = self:GetWidgets()
  local tabPart = params.tabPart
  local heroInfo = params.heroInfo
  local objEvent = tabPart.obj_event
  local fix = tabPart.fix_drag
  local delta = eventData.delta
  local dir = params.dir
  if Logic.forbiddenHeroLogic:CheckForbiddenInSystem(heroInfo.HeroId, ForbiddenType.Building) then
    return
  end
  self.curTabPart = tabPart
  if self.invalidHeroId[heroInfo.HeroId] then
    return
  end
  local width = tabPart.img_icon.rectTransform.rect.width
  local threshold = width / 15
  local scale = Screen.height / 750
  threshold = threshold * scale
  local dragging = false
  if dir == dragDir.Horizontal then
    dragging = threshold < math.abs(delta.x) or threshold < math.abs(delta.y)
  else
    dragging = threshold < math.abs(delta.y) and threshold > math.abs(delta.x)
  end
  if dragging and self.floatCard and heroInfo.HeroId ~= self.floatCardHeroId then
    self.invalidHeroId[self.floatCardHeroId] = true
    self:_DestroyFloatCard()
    self:HideRecommand()
  end
  if not dragging and dir == dragDir.Vertical and heroInfo.HeroId ~= self.floatCardHeroId then
    self:_DestroyFloatCard()
    self:HideRecommand()
  end
  if self.floatCard == nil and dragging then
    self.floatCardHeroId = heroInfo.HeroId
    local widgets = self:GetWidgets()
    self.floatTabPart = tabPart
    self.floatCard = UIHelper.CreateGameObject(tabPart.obj_head, widgets.float_card)
    CSUIHelper.SetParent(objEvent.transform, widgets.obj_outDrag.gameObject.transform)
    self.floatCard.transform.pivot = Vector2.New(0.5, 0.5)
    self:ShowRecommand(heroInfo)
  end
  if self.floatCard and heroInfo.HeroId == self.floatCardHeroId then
    fix:OnEndDrag(eventData)
    fix:StopMove()
    fix.bEnable = false
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    self.floatCard.transform.position = finalPos
    tabPart.obj_white:SetActive(true)
  end
end

function BuildingListPage:_OnEndDrag(go, eventData, params)
  local tabPart = params.tabPart
  local heroInfo = params.heroInfo
  local dir = params.dir
  local delta = eventData.delta
  local oldBuildingId = params.buildingId
  if self.invalidHeroId[heroInfo.HeroId] then
    self.invalidHeroId[heroInfo.HeroId] = nil
  end
  CSUIHelper.SetParent(go.transform, tabPart.obj_self.transform)
  tabPart.fix_drag.bEnable = true
  tabPart.obj_white:SetActive(false)
  self:HideRecommand()
  if self.floatCard and heroInfo.HeroId == self.floatCardHeroId then
    self:CheckHeroSet(eventData.position, eventData.pressEventCamera, heroInfo, tabPart, oldBuildingId)
  end
  if heroInfo.HeroId == self.floatCardHeroId then
    self:_DestroyFloatCard()
  end
end

function BuildingListPage:ShowRecommand(heroInfo)
  local shipMain = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
  local characters = {}
  for i, cid in ipairs(shipMain.character) do
    characters[cid] = true
  end
  for buildingId, tabPart in pairs(self.buildingParts) do
    local buildingData = Data.buildingData:GetBuildingById(buildingId)
    local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    for i, cid in ipairs(buildingCfg.characters) do
      if characters[cid] then
        tabPart.obj_recommand:SetActive(true)
        break
      end
    end
  end
end

function BuildingListPage:HideRecommand()
  for _, tabPart in pairs(self.buildingParts) do
    tabPart.obj_recommand:SetActive(false)
  end
end

function BuildingListPage:_DestroyFloatCard()
  if self.floatCard then
    self.floatTabPart.obj_white:SetActive(false)
    self.floatTabPart.fix_drag.bEnable = true
    GameObject.Destroy(self.floatCard)
    self.floatCard = nil
  end
end

function BuildingListPage:RemoveFromOldBuilding(oldId, heroId)
  local oldData = Data.buildingData:GetBuildingById(oldId)
  local oldList = clone(oldData.HeroList)
  for i = #oldList, 1, -1 do
    if oldList[i] == heroId then
      table.remove(oldList, i)
      break
    end
  end
  return oldList, oldData
end

function BuildingListPage:CheckHeroSet(position, camera, heroInfo, dragPart, oldBuildingId)
  local heroList = {}
  local buildingData, otherData
  local otherList = {}
  local setIn = false
  self.costFood = 0
  local removeDrag = false
  local invalidDropArea = self.tab_Widgets.viewport:RectangleContainsScreenPoint(position, camera)
  for buildingId, tabPartList in ipairs(self.heroSlotParts) do
    for i, tabPart in ipairs(tabPartList) do
      if tabPart.trans_item:RectangleContainsScreenPoint(position, camera) and invalidDropArea then
        setIn = true
        if oldBuildingId and oldBuildingId ~= buildingId then
          otherList, otherData = self:RemoveFromOldBuilding(oldBuildingId, heroInfo.HeroId)
          local otherCfg = configManager.GetDataById("config_buildinginfo", otherData.Tid)
          self.costFood = self.costFood - otherCfg.foodcost
          removeDrag = true
        end
        if oldBuildingId and oldBuildingId ~= buildingId or not oldBuildingId then
          buildingData = Data.buildingData:GetBuildingById(buildingId)
          heroList = self.dirtyBuildings[buildingId] or clone(buildingData.HeroList)
          local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
          local exist = heroList[i]
          if exist then
            heroList[i] = heroInfo.HeroId
            break
          end
          table.insert(heroList, heroInfo.HeroId)
          self.costFood = self.costFood + buildingCfg.foodcost
          break
        end
      end
    end
  end
  if oldBuildingId and not setIn then
    heroList, buildingData = self:RemoveFromOldBuilding(oldBuildingId, heroInfo.HeroId)
    removeDrag = true
  end
  if buildingData then
    local onPassCheck = function()
      self.dirtyBuildings[buildingData.Id] = heroList
      if otherData then
        self.dirtyBuildings[otherData.Id] = otherList
      end
      self:OnHeroChangedTemp()
      self:SyncBuildingHero()
      if removeDrag then
        UGUIEventListener.ClearDragListener(dragPart.obj_event)
      end
    end
    local ok, msg = Logic.buildingLogic:CheckBuildingListHero(heroList, buildingData, otherList, otherData, function()
      onPassCheck()
    end)
    if msg and msg ~= "" then
      noticeManager:ShowTip(msg)
    end
    if ok then
      onPassCheck()
    end
  end
end

function BuildingListPage:OnHeroChangedTemp()
  Data.buildingData:UpdateCurFood()
  Data.buildingData:UpdateBuildingHero()
  Logic.buildingLogic:RefreshBuildingHeroSfId()
  local oldChooseList = self.chooseHeroList
  self.chooseHeroList = Logic.buildingLogic:GetBuildingListData()
  self.builds = Logic.buildingLogic:GetCurBuildingsInfo()
  self:_ShowBuidingList()
  self:_ShowFoodSilder()
end

function BuildingListPage:DoCountDown(data, widgets)
  local countDown = Logic.buildingLogic:GetUpgradeCountDown(data)
  if countDown <= 0 then
    data.Status = BuildingStatus.Working
    local state = Logic.buildingLogic:GetStatusStr(data.State)
    UIHelper.SetText(widgets.tx_state, state)
    Service.buildingService:FinishBuilding(data.Id)
  end
end

function BuildingListPage:_OnClickHeroSlot(go, params)
  local max = Logic.buildingLogic:GetOneBuildingHeroMax(params.data.Tid)
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  UIHelper.OpenPage("BuildingHeroSelectPage", {
    heroInfoList = tabShowHero,
    selectMax = max,
    selectedHeroList = params.data.HeroList,
    buildingData = params.data,
    selectedHeroId = params.heroId
  })
end

function BuildingListPage:_OnSelectBuildingItem(index)
  self.selectedIndex = index
  local builds = Logic.buildingLogic:GetCurBuildingsInfo()
  local heros = builds[index + 1].HeroList
  local widgets = self:GetWidgets()
  widgets.trans_heroRoot.gameObject:SetActive(0 < #heros)
  if 0 < #heros then
    self:_ShowHeroInfo(heros)
  end
  self:SortChooseHeroByBuilding()
  local builds = Logic.buildingLogic:GetCurBuildingsInfo()
  local buildingData = builds[self.selectedIndex + 1]
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.type == MBuildingType.DormRoom then
    if self.cacheRule == nil and self.cacheOrder == nil then
      self:CacheSortRuleAndOrder()
    end
    self:SetSortOrder(false)
    self:SetSortRule(1)
    self.filterRule = {}
  elseif self.cacheRule and self.cacheOrder ~= nil then
    self:SetSortOrder(self.cacheOrder)
    self:SetSortRule(self.cacheRule)
    self.filterRule = self.cacheFilter
    self:ClearCacheRuleAndOrder()
  end
  self.selectedBuildingId = buildingData.Id
  self.selectedBuildingType = buildingCfg.type
  self:FilterAndSort()
  self:UpdateHeroList()
end

function BuildingListPage:CacheSortRuleAndOrder()
  self.cacheRule = self.sortRule
  self.cacheFilter = self.filterRule
  self.cacheOrder = self.descendantOrder
end

function BuildingListPage:ClearCacheRuleAndOrder()
  self.cacheRule = nil
  self.cacheOrder = nil
  self.cacheFilter = nil
end

function BuildingListPage:SetSortRule(sortRule)
  self.sortRule = sortRule
  local realSortRule = sortMap[self.sortRule]
  UIHelper.SetText(self.tab_Widgets.txt_sort, HeroSortHelper.GetSortName(realSortRule))
end

function BuildingListPage:SetSortOrder(descendent)
  self.descendantOrder = descendent
  if descendent then
    UIHelper.SetLocText(self.tab_Widgets.txt_order, 190002)
  else
    UIHelper.SetLocText(self.tab_Widgets.txt_order, 190001)
  end
end

function BuildingListPage:SortChooseHeroByBuilding()
  local builds = Logic.buildingLogic:GetCurBuildingsInfo()
  local buildingData = builds[self.selectedIndex + 1]
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  local buildingType = buildingCfg.type
  self.heroCharacter = {}
  self.heroBuildingType = {}
  local heroList = self.showHeroList
  local heroMood = {}
  for i, heroInfo in ipairs(heroList) do
    local _, mood = Logic.marryLogic:GetLoveInfo(heroInfo.HeroId, MarryType.Mood)
    heroMood[heroInfo.HeroId] = mood
    local shipMainCfg = configManager.GetDataById("config_ship_main", heroInfo.TemplateId)
    local characters = shipMainCfg.character
    local characterLvs = shipMainCfg.characterlevel
    local value = 0
    local cid = 0
    local level = 1
    for i, characterId in ipairs(characters) do
      local characterCfg = configManager.GetDataById("config_character", characterId)
      local addition = characterCfg.characteraddition[buildingType]
      local recipeAddCount = #characterCfg.recipeaddition
      if buildingType == MBuildingType.ItemFactory and 0 < recipeAddCount or addition and 0 < addition then
        value = 1
        cid = characterId
        level = characterLvs[i]
        break
      end
    end
    self.heroBuildingType[heroInfo.HeroId] = value
    self.heroCharacter[heroInfo.HeroId] = {cid = cid, level = level}
  end
end

function BuildingListPage:_ShowHeroInfo(heros)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_hero, widgets.trans_heroRoot, #heros, function(index, tabPart)
    local shipData = Data.heroData:GetHeroById(heros[index])
    if shipData then
      local shipConfig = Logic.shipLogic:GetShipShowByHeroId(shipData.HeroId)
      local name = Logic.shipLogic:GetRealName(heros[index])
      local charNames = Logic.shipLogic:GetHeroCharcaterStr(shipData.TemplateId)
      local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(shipData.HeroId, MarryType.Mood)
      if moodInfo then
        UIHelper.SetImage(tabPart.im_icon, moodInfo.mood_icon, true)
      end
      UIHelper.SetText(tabPart.tx_name, name)
      UIHelper.SetText(tabPart.tx_char, charNames[1])
      if charNames[2] ~= nil then
        tabPart.tx_char2.gameObject:SetActive(true)
        UIHelper.SetText(tabPart.tx_char2, charNames[2])
      else
        tabPart.tx_char2.gameObject:SetActive(false)
      end
    end
  end)
end

function BuildingListPage:_showTitle(tid)
  local widgets = self:GetWidgets()
  local titleeng = Logic.buildingLogic:GetBuildEngName(tid)
  UIHelper.SetText(widgets.tx_titlecn, UIHelper.GetString(3002066))
  UIHelper.SetText(widgets.tx_titleeng, titleeng)
end

function BuildingListPage:ShowChangeNumber()
  if self.costFood and self.costFood > 0 then
    UIHelper.SetText(self.tab_Widgets.txt_cost, string.format("-%d", self.costFood))
    local objSource = self.tab_Widgets.txt_cost.gameObject
    local objCost = UIHelper.CreateGameObject(objSource, objSource.transform.parent)
    local transSlider = self.tab_Widgets.trans_slider
    local width = transSlider.rect.width
    local position = transSlider.anchoredPosition
    local percent = self.tab_Widgets.Slider_Food.value
    local posX = position.x - width / 2 + percent * width
    objCost:SetActive(true)
    local tweenPos = objCost:GetComponent(TweenPosition.GetClassType())
    tweenPos.from = Vector3.New(posX, tweenPos.from.y, tweenPos.from.z)
    tweenPos.to = Vector3.New(posX, tweenPos.to.y, tweenPos.to.z)
    tweenPos:Play()
    self.objCostList[objCost] = true
    table.insert(self.objCostList, objCost)
    self:PerformDelay(2.1, function()
      self.objCostList[objCost] = nil
      if not IsNil(objCost) then
        GameObject.Destroy(objCost)
      end
    end)
  end
end

function BuildingListPage:ClearObjList()
  for obj, v in pairs(self.objCostList) do
    if not IsNil(obj) then
      GameObject.Destroy(obj)
    end
  end
  self.objCostList = {}
end

function BuildingListPage:_ShowFoodSilder()
  local widgets = self:GetWidgets()
  local cur, max = Logic.buildingLogic:GetBuildFoodProgress()
  if cur < 0 then
    widgets.tx_foodNum.text = "<color=#FF0000>" .. cur .. "</color>" .. "/" .. max
  else
    widgets.tx_foodNum.text = cur .. "/" .. max
  end
  widgets.Slider_Food.value = cur / max
  local oldValue = widgets.slider_bg.fillAmount
  Logic.buildingLogic:StartSliderAnim(oldValue, cur / max, function(curValue)
    if widgets.slider_bg ~= nil and not IsNil(widgets.slider_bg) then
      widgets.slider_bg.fillAmount = curValue
    end
  end)
end

function BuildingListPage:OnBtnSort()
  UIHelper.OpenPage("SortPage", {
    self.filterRule,
    self.sortRule,
    SortType = self.sortType
  })
end

function BuildingListPage:OnToggleSort()
  if self.tab_Widgets.tog_sort.isOn then
    self:SetSortOrder(true)
  else
    self:SetSortOrder(false)
  end
  local realSortRule = sortMap[self.sortRule]
  self.showHeroList = HeroSortHelper.FilterAndSortBuilding(self.chooseHeroList, self.filterRule, realSortRule, self.descendantOrder, self.selectedBuildingId)
  self:UpdateHeroList()
end

function BuildingListPage:_UpdateHeroSort(tabSortParams)
  self.filterRule = tabSortParams[1]
  self:SetSortRule(tabSortParams[2])
  self:FilterAndSort()
  if self.selectedBuildingType ~= MBuildingType.DormRoom then
    local data = {
      self.descendantOrder,
      tabSortParams
    }
    Logic.sortLogic:SetHeroSort(CommonHeroItem.BuildingList, data)
    Logic.sortLogic:SaveBuildingSort(BuildingSortKey.BuildingList, data)
  end
end

function BuildingListPage:FilterAndSort()
  local realSortRule = sortMap[self.sortRule]
  self.showHeroList = HeroSortHelper.FilterAndSortBuilding(self.chooseHeroList, self.filterRule, realSortRule, self.descendantOrder, self.selectedBuildingId)
  self:SortChooseHeroByBuilding()
  self:UpdateHeroList()
end

function BuildingListPage:SyncBuildingHero()
  if next(self.dirtyBuildings) ~= nil then
    local buildingIdList = {}
    local heroIdList = {}
    for buildingId, heroList in pairs(self.dirtyBuildings) do
      table.insert(buildingIdList, buildingId)
      for i, heroId in ipairs(heroList) do
        table.insert(heroIdList, heroId)
      end
      table.insert(heroIdList, -1)
    end
    Service.buildingService:SendSetBuildingListHero(buildingIdList, heroIdList)
  end
end

function BuildingListPage:DoOnHide()
  self:SyncBuildingHero()
  self:ClearObjList()
  self:_DestroyFloatCard()
end

function BuildingListPage:DoOnClose()
  if self.selectedBuildingType ~= MBuildingType.DormRoom then
    local data = {
      self.descendantOrder,
      {
        self.filterRule,
        self.sortRule
      }
    }
    Logic.sortLogic:SetHeroSort(CommonHeroItem.BuildingList, data)
    Logic.sortLogic:SaveBuildingSort(BuildingSortKey.BuildingList, data)
  end
end

return BuildingListPage
