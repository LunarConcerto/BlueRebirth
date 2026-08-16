local BuildingHeroSelectPage = class("UI.Building.BuildingHeroSelectPage", LuaUIPage)
local selectHeroItem = require("ui.page.Common.CommonSelect.SelectHeroItem")
local sortMap = {
  HeroSortType.BuildingCharacter,
  HeroSortType.Mood,
  HeroSortType.Status
}

function BuildingHeroSelectPage:DoInit()
  self.filterRule = {}
  self.sortRule = 1
  self.startShipNum = nil
  self.startMaxFood = nil
  self.m_outPostInfo = false
end

function BuildingHeroSelectPage:DoOnOpen()
  local params = self:GetParam()
  if params.outpost then
    self:OpenTopPage("BuildingHeroSelectPage", 1, UIHelper.GetString(4600001), self, true)
    self.m_outPostInfo = true
    self.tab_Widgets.zongzhanli:SetActive(true)
    self.tab_Widgets.foodResource:SetActive(false)
    self.buildingId = params.buildingId
  else
    self.m_outPostInfo = false
    self:OpenTopPage("BuildingHeroSelectPage", 1, UIHelper.GetString(920000128), self, true)
    self.tab_Widgets.zongzhanli:SetActive(false)
    self.tab_Widgets.foodResource:SetActive(true)
  end
  self.m_selectId = params.selectedHeroId
  self.heroInfoList = params.heroInfoList
  self.selectMax = params.selectMax
  self.buildingData = params.buildingData
  self.onSelect = params.onSelect
  if self.buildingData then
    self.buildingType = Logic.buildingLogic:GetBuildingTypeById(self.buildingData.Id)
    self.buildingCfg = configManager.GetDataById("config_buildinginfo", self.buildingData.Tid)
  end
  self.itemType = CommonHeroItem.Building
  if self.m_outPostInfo then
    self.itemType = CommonHeroItem.MubarOurpost
  end
  self.sortType = MHeroSortType.Building
  local sortFilterData = Logic.sortLogic:GetHeroSort(self.itemType)
  if self.buildingType ~= MBuildingType.DormRoom or self.m_outPostInfo then
    if sortFilterData then
      self.descendantOrder = sortFilterData[1]
      self.filterRule = sortFilterData[2][1]
      self.sortRule = sortFilterData[2][2]
      self.showOnlyLocked = sortFilterData[2][3]
    end
  else
    self.sortRule = 2
    self.descendantOrder = false
    self.showOnlyLocked = false
  end
  self.tab_Widgets.toggle_sort.isOn = self.descendantOrder
  self.objCostList = {}
  self.m_tabTog = {}
  self.m_tabSelectShip = {}
  if params.selectedHeroList then
    self.m_tabSelectShip = clone(params.selectedHeroList)
  end
  Logic.buildingLogic:SetSaveBuildingHero(self.m_tabSelectShip)
  self.curFood, self.maxFood = Logic.buildingLogic:GetBuildFoodProgress()
  self.tab_Widgets.slider_bg.fillAmount = self.curFood / self.maxFood
  self:_showTitle(self.buildingData)
  self:FilterAndSort()
  self:ShowSelectedInfo(true)
  self:_ShowFoodSilder(0)
  self:PlayBgm()
  if self.m_outPostInfo then
    self:ShowBattlePower()
  end
end

function BuildingHeroSelectPage:ShowBattlePower()
  if self.m_tabSelectShip then
    local power = 0
    for i = 1, #self.m_tabSelectShip do
      local heroAttr = Logic.attrLogic:GetBattlePower(self.m_tabSelectShip[i], FleetType.Normal, nil)
      power = power + heroAttr
    end
    UIHelper.SetText(self.tab_Widgets.tx_desc, string.format(UIHelper.GetString(4600009), tostring(power)))
  end
end

function BuildingHeroSelectPage:PlayBgm()
  local fromPage = UIPageManager:GetReturnPageName()
  if fromPage == "BuildingListPage" then
    SoundManager.Instance:PlayMusic("System|Infrastructure")
  elseif not self.m_outPostInfo then
    SoundManager.Instance:PlayMusic(self.buildingCfg.building_scene_bgm)
  end
end

function BuildingHeroSelectPage:_showTitle(data)
  local widgets = self:GetWidgets()
  if data == nil then
    if self.m_outPostInfo then
      UIHelper.SetText(widgets.tx_titlecn, UIHelper.GetString(4600001))
      local realSortRule = sortMap[self.sortRule]
      UIHelper.SetText(widgets.txt_sort, HeroSortHelper.GetSortName(realSortRule))
    end
    return
  end
  local tid = data.Tid
  local titlecn = Logic.buildingLogic:GetBuildName(tid)
  local titleeng = Logic.buildingLogic:GetBuildEngName(tid)
  UIHelper.SetText(widgets.tx_titlecn, titlecn)
  UIHelper.SetText(widgets.tx_titleeng, titleeng)
  local realSortRule = sortMap[self.sortRule]
  UIHelper.SetText(widgets.txt_sort, HeroSortHelper.GetSortName(realSortRule))
end

function BuildingHeroSelectPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._BuildingConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancle, self._BuildingCancel, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rarity, self._OnFilter, self)
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  UGUIEventListener.AddButtonToggleChanged(self.tab_Widgets.toggle_sort, self.FilterAndSort, self)
end

function BuildingHeroSelectPage:LoadHeroList(heroTab)
  self.marriageEffectList = {}
  self:StopMarriageTimer()
  self.tabParts = {}
  if self.m_tabSelectShip then
    self.m_selectFids = self:_GetSelectTids(self.m_tabSelectShip)
  end
  self:_CacheBathAndBuildHero()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.sv_layout, self.tab_Widgets.sv_item, #heroTab, function(tabParts)
    for nIndex, tabPart in pairs(tabParts) do
      nIndex = tonumber(nIndex)
      self.tabParts[nIndex] = tabPart
      local item = selectHeroItem:new()
      local itemType = self.itemType
      if self.m_outPostInfo then
        itemType = CommonHeroItem.Building
      end
      item:Init(self, tabPart, heroTab[nIndex], nIndex, itemType, function()
        table.insert(self.marriageEffectList, tabPart.tex_anim1)
        table.insert(self.marriageEffectList, tabPart.tex_anim2)
        table.insert(self.marriageEffectList, tabPart.tex_anim3)
      end)
      if self.m_outPostInfo then
        tabPart.zhanli:SetActive(true)
        local heroId = heroTab[nIndex].HeroId
        local heroAttr = Logic.attrLogic:GetBattlePower(heroId, FleetType.Normal, nil)
        UIHelper.SetText(tabPart.tx_character, string.format(UIHelper.GetString(4600010), tostring(heroAttr)))
      else
        tabPart.zhanli:SetActive(false)
      end
    end
    local count = #self.marriageEffectList
    if 0 < count then
      self:PlayMarriageEffect()
    else
      self:StopMarriageTimer()
    end
  end)
  self:_showSelectNum()
end

function BuildingHeroSelectPage:PlayMarriageEffect(effectList, count)
  if not self.marriageTimer then
    local enableTime = 0.3
    local disableTime = 3.3
    local finishTime = 6.5
    local curTime = 0
    local preTime = 0
    local func = function(deltaTime)
      if curTime < enableTime and curTime + deltaTime > enableTime then
        curTime = curTime + deltaTime
        self:SetEffectEnabled(self.marriageEffectList, #self.marriageEffectList, true)
      end
      if curTime < disableTime and curTime + deltaTime > disableTime then
        curTime = curTime + deltaTime
        self:SetEffectEnabled(self.marriageEffectList, #self.marriageEffectList, false)
      end
      if curTime < finishTime and curTime + deltaTime > finishTime then
        curTime = 0
      else
        curTime = curTime + deltaTime
      end
    end
    self.marriageTimer = CustomTimer.New(func, total, -1)
    self.marriageTimer:Start()
  end
end

function BuildingHeroSelectPage:SetEffectEnabled(effectList, count, enabled)
  for i = 1, count, 3 do
    effectList[i]:SetActive(enabled)
    effectList[i + 1]:SetActive(enabled)
    effectList[i + 2]:SetActive(enabled)
  end
end

function BuildingHeroSelectPage:StopMarriageTimer()
  if self.marriageTimer then
    self.marriageEffectList = {}
    self.marriageTimer:Stop()
    self.marriageTimer = nil
  end
end

function BuildingHeroSelectPage:Selected(go, isOn, params)
  if Logic.forbiddenHeroLogic:CheckForbiddenInSystem(params.heroId, ForbiddenType.Building) then
    params.tog.isOn = false
    return
  end
  self.m_selectId = params.heroId
  local inOther = false
  local oldFoodCost = 0
  local buildingData = Data.buildingData:GetHeroBuilding(params.heroId)
  if buildingData and not self.m_outPostInfo then
    inOther = buildingData.Id ~= self.buildingData.Id
    local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
    oldFoodCost = buildingCfg.foodcost
    local curFoodCost = self.buildingCfg.foodcost
  end
  local foodCostDelta = 0
  local showFoodChange = false
  if isOn then
    local replace = false
    local checkSameTid = Logic.assistNewLogic:CheckHeroCanSupport(self.m_selectId)
    if self.m_tabSelectShip and self.selectMax == 1 and 0 < #self.m_tabSelectShip then
      if not checkSameTid then
        noticeManager:ShowTip(UIHelper.GetString(3002033))
        params.tog.isOn = false
        isOn = false
        return
      end
      if self.m_beforeSelectTog then
        self.m_beforeSelectTog.isOn = false
      end
      table.remove(self.m_tabSelectShip, 1)
      replace = true
    end
    if self.m_tabSelectShip and self.selectMax > 1 and #self.m_tabSelectShip >= self.selectMax then
      noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(110018), self.selectMax))
      params.tog.isOn = false
      isOn = false
      return
    end
    local index = self.m_tabSelectShip and Logic.assistNewLogic:CheckCanSupport(self.m_tabSelectShip, self.m_selectId) or nil
    if index or checkSameTid == false then
      params.tog.isOn = not isOn
      noticeManager:ShowTip(UIHelper.GetString(3002033))
      isOn = false
      return
    end
    if not replace and curFoodCost then
      showFoodChange = true
      foodCostDelta = curFoodCost
    else
      foodCostDelta = 0
    end
    table.insert(self.m_tabSelectShip, self.m_selectId)
    self.m_beforeSelectTog = params.tog
  else
    if curFoodCost then
      foodCostDelta = -curFoodCost
    end
    local idPos = self:_GetSelectPos()
    table.remove(self.m_tabSelectShip, idPos)
  end
  if inOther and curFoodCost then
    if isOn then
      foodCostDelta = curFoodCost - oldFoodCost
    else
      foodCostDelta = -curFoodCost + oldFoodCost
    end
  end
  self:ShowSelectedInfo(isOn)
  self:LoadHeroList(self.m_tabSortHero)
  self:_ShowFoodSilder(foodCostDelta)
  if foodCostDelta and showFoodChange and 0 < foodCostDelta then
    self:ShowChangeNumber(foodCostDelta)
  end
  if self.m_outPostInfo then
    self:ShowBattlePower()
  end
end

function BuildingHeroSelectPage:ShowSelectedInfo(selected)
  local heroId = self.m_selectId
  if not heroId and self.m_tabSelectShip then
    heroId = self.m_tabSelectShip[1]
  end
  local showInfo = heroId ~= nil and selected
  self.tab_Widgets.obj_none:SetActive(not showInfo)
  self.tab_Widgets.girl_info:SetActive(showInfo)
  if heroId and selected then
    local heroData = Data.heroData:GetHeroById(heroId)
    if not heroData then
      return
    end
    local name = Logic.shipLogic:GetRealName(heroId)
    UIHelper.SetText(self.tab_Widgets.tx_name, name)
    local shipShow = Logic.shipLogic:GetShipShowById(heroData.TemplateId)
    local icon = Logic.shipLogic:GetHeroSquareIcon(shipShow.ss_id)
    UIHelper.SetImage(self.tab_Widgets.img_hero, icon)
    local quality = Logic.shipLogic:GetQualityByHeroId(heroId)
    UIHelper.SetImage(self.tab_Widgets.img_quality, QualityIcon[quality])
    local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
    local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
    if moodInfo then
      UIHelper.SetImage(self.tab_Widgets.im_mood, moodInfo.mood_icon)
    end
    local percent = curMood / moodLimit[2]
    self.tab_Widgets.mood_slider.value = percent
    local shipMainCfg = configManager.GetDataById("config_ship_main", heroData.TemplateId)
    local characterIds = shipMainCfg.character
    local characterLevels = shipMainCfg.characterlevel
    UIHelper.CreateSubPart(self.tab_Widgets.info_item, self.tab_Widgets.info_trans, #characterIds, function(index, tabPart)
      local characterId = characterIds[index]
      local level = characterLevels[index]
      local characterCfg = configManager.GetDataById("config_character", characterId)
      UIHelper.SetText(tabPart.tx_title, characterCfg.name .. "(lv" .. level .. ")")
      local descStr = ""
      local descList = Logic.buildingLogic:GetCharacterAdditionStr(characterId, level)
      for i, desc in ipairs(descList) do
        descStr = descStr .. UIHelper.GetLocString(desc.strId, desc.value)
        descStr = descStr .. "\n"
      end
      descStr = string.sub(descStr, 1, -2)
      UIHelper.SetText(tabPart.tx_desc, descStr)
      local descHeight = tabPart.tx_desc.preferredHeight
      tabPart.layout_item.preferredHeight = descHeight + 30
    end)
  end
end

function BuildingHeroSelectPage:_GetSelectPos()
  for k, v in pairs(self.m_tabSelectShip) do
    if v == self.m_selectId then
      return k
    end
  end
end

function BuildingHeroSelectPage:_GetSelectTids(herolist)
  local res = {}
  for k, heroId in pairs(herolist) do
    local buildingType = Data.buildingData:GetHeroBuildingType(heroId)
    local heroData = Data.heroData:GetHeroById(heroId)
    if heroData then
      local tid = heroData.TemplateId
      local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
      local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
      res[sf_id] = buildingType and buildingType or 0
    end
  end
  return res
end

function BuildingHeroSelectPage:_CacheBathAndBuildHero()
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local buildingHero = Data.buildingData:GetBuildingHero()
  local outpostHero = Data.mubarOutpostData:GetOutPostHeroData()
  self.m_cachBathFids = self:_GetSelectTids(bathHero)
  self.m_cachBuildingFids = self:_GetSelectTids(buildingHero)
  self.m_cachOutpostFids = self:_GetSelectTids(outpostHero)
end

function BuildingHeroSelectPage:_GetCacheBathInfo()
  return self.m_cachBathFids
end

function BuildingHeroSelectPage:_GetCacheBuildingInfo()
  return self.m_cachBuildingFids
end

function BuildingHeroSelectPage:_GetCacheOutpostInfo()
  return self.m_cachOutpostFids
end

function BuildingHeroSelectPage:GetBuildingTid()
  if self.buildingData ~= nil then
    return self.buildingData.Tid
  end
  return nil
end

function BuildingHeroSelectPage:_BuildingConfirm()
  if self.onSelect then
    if self.m_outPostInfo then
      local canSelect, ErrorCode = Logic.mubarOutpostLogic:CheckBuildingConditionCanSelect(self.buildingId, self.m_tabSelectShip)
      if not canSelect then
        local errMsg
        if ErrorCode == -1 then
          local tabParams = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                self.onSelect(self.buildingId, self.m_tabSelectShip)
                self:CloseSelf()
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(4600020), tabParams)
          return
        elseif ErrorCode == -2 then
          local tabParams = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                self.onSelect(self.buildingId, self.m_tabSelectShip)
                self:CloseSelf()
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(4600018), tabParams)
          return
        elseif ErrorCode == -3 then
          local tabParams = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                moduleManager:JumpToFunc(FunctionID.BathRoom)
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(3002031), tabParams)
          return
        end
        noticeManager.ShowTip(errMsg)
        return
      end
      self.onSelect(self.buildingId, self.m_tabSelectShip)
    else
      self.onSelect(self.buildingData.Id, self.m_tabSelectShip)
    end
    self:CloseSelf()
  else
    self:DefaultSelect()
  end
end

function BuildingHeroSelectPage:DefaultSelect()
  local ok, msg = Logic.buildingLogic:CheckAndSendBuildHero(self.m_tabSelectShip, self.buildingData, function()
    Service.buildingService:SendSetHero(self.buildingData.Id, self.m_tabSelectShip)
    self:CloseSelf()
  end)
  if msg and msg ~= "" then
    noticeManager:ShowTip(msg)
  end
end

function BuildingHeroSelectPage:_OnFilter()
  UIHelper.OpenPage("SortPage", {
    self.filterRule,
    self.sortRule,
    self.showOnlyLocked or false,
    SortType = self.sortType
  })
end

function BuildingHeroSelectPage:_UpdateHeroSort(tabSortParams)
  self.filterRule = tabSortParams[1]
  self.sortRule = tabSortParams[2]
  self.showOnlyLocked = tabSortParams[3]
  if self.buildingType ~= MBuildingType.DormRoom or self.m_outPostInfo then
    Logic.sortLogic:SetHeroSort(self.itemType, {
      self.descendantOrder,
      tabSortParams
    })
    Logic.sortLogic:SaveBuildingSort(BuildingSortKey.BuildingHero, {
      self.descendantOrder,
      tabSortParams
    })
  end
  local realSortRule = sortMap[self.sortRule]
  UIHelper.SetText(self.tab_Widgets.txt_sort, HeroSortHelper.GetSortName(realSortRule))
  self:FilterAndSort()
end

function BuildingHeroSelectPage:FilterAndSort()
  if self.tab_Widgets.toggle_sort.isOn then
    self.descendantOrder = true
    UIHelper.SetLocText(self.tab_Widgets.txt_order, 190002)
  else
    self.descendantOrder = false
    UIHelper.SetLocText(self.tab_Widgets.txt_order, 190001)
  end
  local realSortRule = sortMap[self.sortRule]
  local id
  if self.buildingData ~= nil and self.buildingData.Id ~= nil then
    id = self.buildingData.Id
  end
  self.m_tabSortHero = HeroSortHelper.FilterAndSortBuilding(self.heroInfoList, self.filterRule, realSortRule, self.descendantOrder, id)
  if self.showOnlyLocked then
    Logic.buildingLogic:ShowOnlyLockedHero(self.m_tabSortHero)
  end
  self:LoadHeroList(self.m_tabSortHero)
end

function BuildingHeroSelectPage:_BuildingCancel()
  self:CloseSelf()
end

function BuildingHeroSelectPage:_showSelectNum()
  local widgets = self:GetWidgets()
  Logic.buildingLogic:SetSaveBuildingHero(self.m_tabSelectShip)
  local num, total = Logic.buildingLogic:GetBuildHeroProgress()
  local cur = self.m_tabSelectShip and #self.m_tabSelectShip or 0
  UIHelper.SetText(widgets.tx_num, cur .. "/" .. self.selectMax)
  self:_FoodNum(self.m_tabSelectShip)
end

function BuildingHeroSelectPage:_FoodNum(curHeroIds)
  if self.m_outPostInfo then
    return
  end
  local curCount = #curHeroIds
  if self.startShipNum == nil then
    self.startShipNum = curCount
  end
  local buildingCfg = configManager.GetDataById("config_buildinginfo", self.buildingData.Tid)
  if buildingCfg.type == MBuildingType.FoodFactory then
    local oldMax = self.maxFood
    self.maxFood = Logic.buildingLogic:GetMaxFoodByHero(self.buildingData.Tid, curHeroIds)
    self.maxDelta = self.maxFood - oldMax
  end
end

function BuildingHeroSelectPage:_ShowFoodSilder(costFood)
  if self.m_outPostInfo then
    return
  end
  local widgets = self:GetWidgets()
  self.curFood = self.curFood - costFood
  local maxDelta = self.maxDelta or 0
  self.curFood = self.curFood + maxDelta
  self.maxDelta = 0
  if self.curFood < 0 then
    widgets.tx_foodNum.text = "<color=#FF0000>" .. self.curFood .. "</color>" .. "/" .. self.maxFood
  else
    widgets.tx_foodNum.text = self.curFood .. "/" .. self.maxFood
  end
  local value = self.curFood / self.maxFood
  widgets.Slider_Food.value = value
  local oldValue = widgets.slider_bg.fillAmount
  if value < oldValue then
    Logic.buildingLogic:StartSliderAnim(oldValue, value, function(curValue)
      widgets.slider_bg.fillAmount = curValue
    end)
  else
    widgets.slider_bg.fillAmount = value
  end
end

function BuildingHeroSelectPage:ShowChangeNumber(costFood)
  if 0 < costFood then
    UIHelper.SetText(self.tab_Widgets.txt_cost, string.format("-%d", costFood))
    local objSource = self.tab_Widgets.txt_cost.gameObject
    local objCost = UIHelper.CreateGameObject(objSource, objSource.transform.parent)
    objCost:SetActive(true)
    local transSlider = self.tab_Widgets.trans_slider
    local width = transSlider.rect.width
    local position = transSlider.anchoredPosition
    local percent = self.tab_Widgets.Slider_Food.value
    local posX = position.x - width / 2 + percent * width
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

function BuildingHeroSelectPage:ClearObjList()
  for obj, v in pairs(self.objCostList) do
    if not IsNil(obj) then
      GameObject.Destroy(obj)
    end
  end
  self.objCostList = {}
end

function BuildingHeroSelectPage:DoOnHide()
  self:ClearObjList()
  self:StopMarriageTimer()
end

function BuildingHeroSelectPage:DoOnClose()
  Logic.buildingLogic:StopSliderAnim()
  Logic.buildingLogic:SetSaveBuildingHero({})
  if self.buildingCfg and self.buildingCfg.type ~= MBuildingType.DormRoom or self.m_outPostInfo then
    local data = {
      self.descendantOrder,
      {
        self.filterRule,
        self.sortRule,
        self.showOnlyLocked
      }
    }
    Logic.sortLogic:SetHeroSort(self.itemType, data)
    Logic.sortLogic:SaveBuildingSort(BuildingSortKey.BuildingHero, data)
  end
end

return BuildingHeroSelectPage
