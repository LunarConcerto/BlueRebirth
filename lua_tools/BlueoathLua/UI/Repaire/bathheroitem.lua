local BathHeroItem = class("UI.Repaire.BathHeroItem")

function BathHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.index = nil
  self.inPoolHero = nil
  self.heroState = BathHeroStateType.Other
  self.limitTime = 0
end

function BathHeroItem:Init(obj, tabPart, data, index, inPoolHero, bathTimeControl, tblParts)
  self.page = obj
  self.tabPart = tabPart
  self.heroInfo = data
  self.index = index
  self.inPoolHero = inPoolHero
  self:_SetHeroInfo(bathTimeControl, tblParts)
  if tblParts ~= nil then
    self.page:onRectRefresh(tblParts)
    self:_AddDragEvent()
    self:_AddClickEvent()
  end
end

function BathHeroItem:_SetHeroInfo(bathTimeControl, tblParts)
  self.tabPart.objCopy:SetActive(self.heroInfo ~= nil)
  self.tabPart.objMaskBg:SetActive(self.heroInfo ~= nil)
  self.tabPart.objNull:SetActive(self.heroInfo == nil)
  if self.heroInfo == nil then
    return
  end
  self.limitTime = configManager.GetDataById("config_bathroom_item", 90001).time
  local fleetData = Logic.fleetLogic:GetHeroFleetMap()
  local inBuilding = Logic.buildingLogic:IsBuildingHero(self.heroInfo.HeroId)
  local inOutpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpost(self.heroInfo.HeroId)
  local sameShipInPool, isNoumenon, inPoolHeroInfo = Logic.repaireLogic:CheckSameShip(self.inPoolHero, self.heroInfo)
  self.tabPart.objState:SetActive(true)
  self.tabPart.obj_auto:SetActive(false)
  self.tabPart.obj_inbathmask:SetActive(false)
  self.tabPart.obj_bathEff:SetActive(false)
  self.tabPart.im_gongzuozhong:SetActive(false)
  self.tabPart.im_sushezhong:SetActive(false)
  if not (not inBuilding or sameShipInPool) or inOutpost then
    local buildingType = Data.buildingData:GetHeroBuildingType(self.heroInfo.HeroId)
    if buildingType and buildingType == MBuildingType.DormRoom then
      self.tabPart.im_sushezhong:SetActive(true)
      self.heroState = BathHeroStateType.DormRoom
    else
      self.heroState = BathHeroStateType.Working
      self.tabPart.im_gongzuozhong:SetActive(true)
    end
    self:DoWorkAnim()
  else
    self.tabPart.im_sushezhong:SetActive(false)
    self.tabPart.im_gongzuozhong:SetActive(false)
  end
  if fleetData[self.heroInfo.HeroId] and not sameShipInPool then
    local fleetName, heroInFleetIndex = Logic.fleetLogic:GetHeroFleetName(self.heroInfo.HeroId)
    UIHelper.SetText(self.tabPart.tx_status, fleetName)
  elseif sameShipInPool then
    if isNoumenon then
      local param = {
        self.tabPart,
        inPoolHeroInfo,
        self.index
      }
      if tblParts ~= nil then
        bathTimeControl:AddPoolHero(param)
      else
        bathTimeControl:AddFleetHero(param)
      end
      local allAuto = Data.bathroomData:GetAllAuto()
      local show = allAuto == 1 and allAuto or inPoolHeroInfo.IsAuto
      self.tabPart.obj_auto:SetActive(show == 1)
      if inPoolHeroInfo.StartTime > 0 then
        local surplusTime = inPoolHeroInfo.StartTime + self.limitTime - time.getSvrTime()
        UIHelper.SetText(self.tabPart.tx_status, UIHelper.GetCountDownStr(surplusTime))
      else
        UIHelper.SetText(self.tabPart.tx_status, "00:00:00")
      end
      self.tabPart.obj_inbathmask:SetActive(true)
      self.tabPart.obj_bathEff:SetActive(true)
    else
      UIHelper.SetText(self.tabPart.tx_status, "\229\183\178\229\156\168\230\177\160\228\184\173")
    end
  else
    self.tabPart.objState:SetActive(false)
  end
  ShipCardItem:LoadVerticalCard(self.heroInfo.HeroId, self.tabPart.childpart, VerCardType.FleetBottom)
  local heroLv = Data.heroData:GetHeroById(self.heroInfo.HeroId).Lvl
  self.tabPart.textLv.text = math.tointeger(heroLv)
  self.tabPart.objMask:SetActive(false)
  self.tabPart.objGolden:SetActive(false)
  self.tabPart.img_mood.gameObject:SetActive(false)
  self.tabPart.im_fight_mood.gameObject:SetActive(true)
  local moodInfo = Logic.marryLogic:GetLoveInfo(self.heroInfo.HeroId, MarryType.Mood)
  UIHelper.SetImage(self.tabPart.im_fight_mood, moodInfo.mood_icon, true)
  local mood_bound = configManager.GetDataById("config_parameter", 142).arrValue
  local girlData = Data.heroData:GetHeroById(self.heroInfo.HeroId)
  local currMoodNum = Logic.marryLogic:GetMoodNum(girlData, self.heroInfo.HeroId)
  UIHelper.SetImage(self.tabPart.imgHp, "uipic_ui_card_im_xuetiao_hong")
  self.tabPart.slider.gameObject:SetActive(false)
  self.tabPart.moodslider.gameObject:SetActive(true)
  if self.page ~= nil then
    self:_SetMoodSlider(currMoodNum, mood_bound[2])
  end
  self:_SetAdvance()
end

function BathHeroItem:_OnClickBathHero(go, param)
  eventManager:SendEvent(LuaEvent.BATH_ClickBathingCard, param.HeroId)
end

function BathHeroItem:_AddDragEvent()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.tab_Widgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnPointDown(objEvent, function()
    self.page:_OnClickCard(self.tabPart, self.heroInfo, self.index, objEvent)
  end)
  UGUIEventListener.AddButtonOnPointUp(objEvent, function()
    self.tabPart.objGolden:SetActive(false)
    self.tabPart.objMask:SetActive(false)
    if self.page.pop ~= nil then
      GameObject.Destroy(self.page.pop)
      self.page.tab_Widgets.obj_float:SetActive(false)
      self.page.pop = nil
    end
  end)
end

function BathHeroItem:_SetAdvance()
  self.tabPart.obj_star:SetActive(true)
  local starTab = {
    self.tabPart.obj_star1,
    self.tabPart.obj_star2,
    self.tabPart.obj_star3,
    self.tabPart.obj_star4,
    self.tabPart.obj_star5,
    self.tabPart.obj_star6
  }
  local startNum = self.heroInfo.Advance
  for i, v in ipairs(starTab) do
    local show = i <= startNum or false
    starTab[i]:SetActive(show)
  end
end

local timecountMax = 30
local timetotal = 1

function BathHeroItem:_SetMoodSlider(currMoodNum, maxMoodNum)
  if self.page.m_CacheSlider == nil then
    self.page.m_CacheSlider = {}
  end
  self.page.m_CacheSlider[self.tabPart.moodslider] = self.heroInfo.HeroId
  if self.page.m_MoodSliderData == nil then
    self.page.m_MoodSliderData = {}
  end
  if self.page.m_MoodSliderData[self.heroInfo.HeroId] == nil then
    self.page.m_MoodSliderData[self.heroInfo.HeroId] = {
      LastMoodNum = currMoodNum,
      MoodSlider = self.tabPart.moodslider,
      Proce = currMoodNum
    }
  end
  local moodSliderData = self.page.m_MoodSliderData[self.heroInfo.HeroId]
  moodSliderData.MoodSlider = self.tabPart.moodslider
  if moodSliderData.LastMoodNum ~= currMoodNum then
    if moodSliderData.timer ~= nil then
      moodSliderData.timer:Stop()
      moodSliderData.timer = nil
    end
    local timecount = 0
    local delta = (currMoodNum - moodSliderData.LastMoodNum) / timecountMax
    moodSliderData.timer = self.page:CreateTimer(function()
      timecount = timecount + 1
      if timecount >= timecountMax then
        moodSliderData.Proce = currMoodNum
      else
        moodSliderData.Proce = delta + moodSliderData.Proce
      end
      if self.page.m_CacheSlider[moodSliderData.MoodSlider] == self.heroInfo.HeroId then
        moodSliderData.MoodSlider.value = moodSliderData.Proce / maxMoodNum
      end
    end, timetotal / timecountMax, timecountMax)
    moodSliderData.timer:Start()
    moodSliderData.LastMoodNum = currMoodNum
  else
    moodSliderData.MoodSlider.value = moodSliderData.Proce / maxMoodNum
  end
end

function BathHeroItem:_AddClickEvent()
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  if IsNil(objEvent) then
    local obj = UIHelper.CreateGameObject(self.page.tab_Widgets.obj_sourceEvent, self.tabPart.objSelf.transform)
    obj.name = "obj_event"
    objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  end
  UGUIEventListener.AddButtonOnClick(objEvent, self._OnClickBathHero, self, self.heroInfo)
end

function BathHeroItem:DoWorkAnim()
  self.dotIndex = 1
  self.dotAnimTimer = self.page:CreateTimer(function()
    self:DoDotAnim()
  end, 1, -1, false)
  self.page:StartTimer(self.dotAnimTimer)
  self:DoDotAnim()
end

function BathHeroItem:DoDotAnim()
  local tabPart = self.tabPart
  for i = 1, 2 do
    if self.heroState == BathHeroStateType.Working then
      if tabPart["im_zhong" .. i] then
        tabPart["im_zhong" .. i]:SetActive(i == self.dotIndex)
      end
    elseif self.heroState == BathHeroStateType.DormRoom and tabPart["im_sushezhong" .. i] then
      tabPart["im_sushezhong" .. i]:SetActive(i == self.dotIndex)
    end
  end
  self.dotIndex = self.dotIndex + 1
  if self.dotIndex == 4 then
    self.dotIndex = 1
  end
end

return BathHeroItem
