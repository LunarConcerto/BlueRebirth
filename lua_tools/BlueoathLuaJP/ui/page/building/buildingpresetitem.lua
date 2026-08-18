local BuildingPresetItem = class("UI.Building.BuildingPresetItem")

function BuildingPresetItem:Init(params)
  self.context = params.context
  self.widgets = params.widgets
  self.data = params.data
  self.index = params.index
  local buildingData = Data.buildingData:GetBuildingById(self.data.BuildingId)
  self.buildingRec = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  self:RegisterAllEvent()
end

function BuildingPresetItem:RegisterAllEvent()
  local widgets = self.widgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_jilu, self.OnRecord, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_delete, self.OnDelete, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_resetname, self.OnChangeName, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_shangzhen, self.OnUseTactic, self)
end

function BuildingPresetItem:Show()
  local widgets = self.widgets
  local data = self.data
  UIHelper.SetText(widgets.tx_jianduiming, data and data.Name or "")
  widgets.Txt_tactic.gameObject:SetActive(false)
  widgets.tactic_Off.gameObject:SetActive(false)
  widgets.tactic_On.gameObject:SetActive(false)
  local unlockSlotCount = self.buildingRec.heronumber
  local heroIdList = data and data.HeroList or {}
  local count = #heroIdList
  if unlockSlotCount < count then
    count = unlockSlotCount
  end
  UIHelper.CreateSubPart(widgets.item_HeroCard, widgets.content_Fleet, 5, function(nIndex, tabPart)
    tabPart.obj_hero:SetActive(nIndex <= count)
    tabPart.im_AddHero:SetActive(nIndex > count)
    tabPart.obj_lock:SetActive(nIndex > unlockSlotCount)
    if nIndex <= count then
      self:InitCard(heroIdList[nIndex], tabPart)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self.OnClickCard, self)
  end)
  local notEmpty = data and not data.Empty
  widgets.btn_delete.gameObject:SetActive(notEmpty)
  widgets.btn_shangzhen.gameObject:SetActive(notEmpty)
  widgets.bg_weisheding:SetActive(not notEmpty)
  if not notEmpty then
    UIHelper.SetLocText(widgets.txt_default, 1900020)
  end
end

function BuildingPresetItem:InitCard(heroId, tabPart)
  local heroInfo = Data.heroData:GetHeroById(heroId)
  tabPart.textLv.text = Mathf.ToInt(heroInfo.Lvl)
  UIHelper.CreateSubPart(tabPart.obj_star, tabPart.trans_star, heroInfo.Advance, function(index, part)
  end)
  ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart, VerCardType.LevelDetails, nil, nil)
  local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
  local moodInfo, curMood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
  if moodInfo then
    UIHelper.SetImage(tabPart.img_mood, moodInfo.mood_icon)
  end
  local percent = curMood / moodLimit[2]
  tabPart.slider_mood.value = percent
  local buildType = self.buildingRec.type
  local charIds, charLevels = Logic.buildingLogic:GetHeroBuildingCharacter(buildType, heroInfo.TemplateId)
  tabPart.obj_character.gameObject:SetActive(0 < #charIds)
  if 0 < #charIds then
    local charNameStr = ""
    local charLevelStr = ""
    for i, id in ipairs(charIds) do
      local charName = Logic.shipLogic:GetCharacterName(id)
      local charLevel = charLevels[i]
      charNameStr = charNameStr .. charName
      charLevelStr = charLevelStr .. charLevel
      charNameStr = charNameStr .. "lv" .. charLevelStr .. "\n"
      if i < #charIds then
        charNameStr = charNameStr .. "\n"
      end
    end
    UIHelper.SetText(tabPart.txt_character, charNameStr)
  end
end

function BuildingPresetItem:OnRecord()
  if self.context.OnRecord then
    self.context:OnRecord(self.index)
  end
end

function BuildingPresetItem:OnAdd()
  if self.context.OnAdd then
    self.context:OnAdd(self.index)
  end
end

function BuildingPresetItem:OnDelete()
  if self.context.OnDelete then
    self.context:OnDelete(self.index)
  end
end

function BuildingPresetItem:OnUseTactic()
  if self.context.OnUseTactic then
    self.context:OnUseTactic(self.index)
  end
end

function BuildingPresetItem:OnChangeName()
  if self.context.OnChangeName and self.data then
    self.context:OnChangeName(self.index, self.data.BuildingId, self.data.Name)
  end
end

function BuildingPresetItem:OnClickCard()
  self:OnAdd()
end

function BuildingPresetItem:OnDragCard()
end

return BuildingPresetItem
