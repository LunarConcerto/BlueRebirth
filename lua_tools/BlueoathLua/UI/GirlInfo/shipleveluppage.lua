local ShipLevelupPage = class("UI.GirlInfo.ShipLevelupPage", LuaUIPage)

function ShipLevelupPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_item_count = 0
  self.m_item_id = 0
end

function ShipLevelupPage:_refresh(pb)
  local widgets = self:GetWidgets()
  self:showExpItem()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local level = heroInfo.Lvl
  local exp, needExp = self:GetExpInfo()
  if level > self.levelPre or exp > self.expPre then
    widgets.effect:SetActive(false)
    widgets.effect:SetActive(true)
    if level > self.levelPre then
      widgets.effectLevelUp:SetActive(false)
      widgets.effectLevelUp:SetActive(true)
      UIHelper.SetText(widgets.textLevel, level)
    end
    for index, info in pairs(pb.ItemList) do
      if info and info.Id and info.Id > 0 then
        local tabPart = self.itemTable[info.Id]
        tabPart.tween:SetActive(false)
        tabPart.tween:SetActive(true)
      end
    end
    local exp, needExp = self:GetExpInfo()
    if exp / needExp > widgets.slider.value then
      self.tweenSlider = TweenSlider.Add(widgets.slider.gameObject, 0.3, widgets.slider.value, exp / needExp)
    elseif exp / needExp <= widgets.slider.value then
      self.tweenSlider = TweenSlider.Add(widgets.slider.gameObject, 0.3, widgets.slider.value, 1)
    end
    self.tweenSlider:Play(true)
    local timer = self:CreateTimer(function()
      if self.ShowSlider then
        self:ShowSlider()
      end
    end, 0.3, 1, false)
    timer:Start()
  else
    self:ShowSlider()
  end
end

function ShipLevelupPage:ShowSlider()
  local widgets = self:GetWidgets()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local level = heroInfo.Lvl
  self.levelPre = level
  UIHelper.SetText(widgets.textLevel, level)
  local exp, needExp = self:GetExpInfo()
  local state = Logic.developLogic:GetLHeroState(self.heroId)
  local e_state = Logic.developLogic.E_HeroLvState
  if state == e_state.FULL then
    widgets.slider.value = 1
    UIHelper.SetText(widgets.textRadio, UIHelper.GetString(911012))
  elseif state == e_state.FURTHER then
    widgets.slider.value = 1
    UIHelper.SetText(widgets.textRadio, needExp .. "/" .. needExp)
  else
    widgets.slider.value = exp / needExp
    self.expPre = exp
    UIHelper.SetText(widgets.textRadio, exp .. "/" .. needExp)
  end
end

function ShipLevelupPage:GetExpInfo()
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local level = heroInfo.Lvl
  local exp = heroInfo.Exp
  if self.m_item_id > 0 and 0 < self.m_item_count then
    local config = configManager.GetDataById("config_ship_exp_item", self.m_item_id)
    local maxLevel = Logic.shipLogic:GetLevelMaxByHeroId(self.heroId) - 1
    if #config.level_limit ~= 0 then
      maxLevel = math.min(maxLevel, config.level_limit[2])
    end
    exp = exp + config.exp * self.m_item_count
    for i = level, maxLevel do
      local needExp = Logic.shipLogic:GetHeroLevelExp(i)
      if exp > needExp then
        exp = exp - needExp
        level = level + 1
      else
        break
      end
    end
  end
  local needExp = Logic.shipLogic:GetHeroLevelExp(level)
  return exp, needExp
end

function ShipLevelupPage:_refreshExpItem()
  for id, tabPart in pairs(self.itemTable) do
    local config = configManager.GetDataById("config_ship_exp_item", id)
    self:ShowExpItemSub(config, tabPart)
  end
end

function ShipLevelupPage:ShowExpItemSub(config, tabPart)
  local widgets = self:GetWidgets()
  UIHelper.SetImage(tabPart.img_icon, config.icon)
  UIHelper.SetImage(tabPart.img_icon_float, config.icon)
  UIHelper.SetImage(tabPart.img_frame, QualityIcon[config.quality])
  local num = Logic.bagLogic:GetBagItemNum(config.id)
  UIHelper.SetText(tabPart.txt_num, "x" .. num)
  local str = string.format(UIHelper.GetString(911004), config.exp)
  UIHelper.SetText(tabPart.txt_exp, str)
  local flag = Logic.shipLogic:CheckLevelUpMaxById(self.heroId, config.id)
  tabPart.mask:SetActive(not flag or num <= 0)
  local posWorld = widgets.trans.position
  local posLocal = tabPart.obj.transform:InverseTransformPoint(posWorld)
  tabPart.tweenPosition.to = posLocal
  if 0 < num then
    UGUIEventListener.AddButtonOnLongPress(tabPart.obj, function(obj, val)
      self:_ItemPressCB(config, tabPart)
    end)
    UGUIEventListener.AddButtonOnPointUp(tabPart.obj, function()
      self:_ItemUpCB(config.id)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.obj, function()
      self:_ItemClickCB(config.id)
    end)
  else
    UGUIEventListener.ClearButtonEventListener(tabPart.obj)
    UGUIEventListener.AddButtonOnClick(tabPart.obj, function()
      globalNoitceManager:ShowItemInfoPage(GoodsType.REWARD_SHIPLEVELUP_ITEM, config.id)
    end)
  end
end

function ShipLevelupPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local heroId = params.heroId
  self.heroId = heroId
  UIHelper.CreateSubPart(widgets.objShip, widgets.contentShip, 1, function(index, tabPart)
    ShipCardItem:LoadVerticalCard(heroId, tabPart.luaPart)
  end)
  self:showExpItem()
  self:ShowSlider()
end

function ShipLevelupPage:showExpItem()
  local widgets = self:GetWidgets()
  local configAll = Logic.shipLogic:GetExpItemTable()
  self.itemTable = {}
  UIHelper.CreateSubPart(widgets.objItem, widgets.contentItem, #configAll, function(index, tabPart)
    local config = configAll[index]
    self:ShowExpItemSub(config, tabPart)
    self.itemTable[config.id] = tabPart
  end)
end

function ShipLevelupPage:_ItemPressCB(config, tabPart)
  SoundManager.Instance:PlayAudio("UI_Button_EquipIntensifyPage_0003")
  self.m_item_id = config.id
  self.m_item_count = 0
  local duration = configManager.GetDataById("config_parameter", 179).value / 10000
  self:StopAllTimer()
  self.m_timer = self:CreateTimer(function()
    self:_PressLogic(tabPart)
  end, duration, -1, false)
  self:StartTimer(self.m_timer)
end

function ShipLevelupPage:_PressLogic(tabPart)
  local widgets = self:GetWidgets()
  if not noticeManager:GetIsClose() then
    return
  end
  local config = configManager.GetDataById("config_ship_exp_item", self.m_item_id)
  local maxLevel = Logic.shipLogic:GetLevelMaxByHeroId(self.heroId) - 1
  if #config.level_limit ~= 0 then
    maxLevel = math.min(maxLevel, config.level_limit[2])
  end
  local configParameter = configManager.GetDataById("config_parameter", 70)
  local maxLevelLimit = configParameter.value - 1
  maxLevel = math.min(maxLevel, maxLevelLimit)
  local itemId = config.id
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local level = heroInfo.Lvl
  local exp = heroInfo.Exp
  exp = exp + config.exp * self.m_item_count
  for i = level, maxLevel do
    local needExp = Logic.shipLogic:GetHeroLevelExp(i)
    if exp > needExp then
      exp = exp - needExp
      level = level + 1
    else
      break
    end
  end
  local num = Logic.bagLogic:GetBagItemNum(config.id)
  local timesMax = configManager.GetDataById("config_parameter", 177).value
  local ok, msg = self:_CheckHeroLvFurther(self.heroId, level)
  if not ok then
    self:_SendAddExp(itemId)
    noticeManager:ShowTip(msg)
    return
  end
  if maxLevelLimit < level then
    self:_SendAddExp(itemId)
    noticeManager:ShowTipById(911006)
    return
  elseif maxLevel < level then
    self:_SendAddExp(itemId)
    noticeManager:ShowTipById(911002)
    return
  elseif num <= self.m_item_count then
    self:_SendAddExp(itemId)
    globalNoitceManager:ShowItemInfoPage(GoodsType.REWARD_SHIPLEVELUP_ITEM, itemId)
    return
  elseif timesMax < self.m_item_count then
    self:_SendAddExpMax(itemId)
    return
  else
    self.m_item_count = self.m_item_count + 1
    local num = Logic.bagLogic:GetBagItemNum(itemId)
    local numLeft = num - self.m_item_count
    UIHelper.SetText(tabPart.txt_num, "x" .. numLeft)
    local flag = Logic.shipLogic:CheckLevelUpMaxById(self.heroId, itemId)
    tabPart.mask:SetActive(not flag or numLeft <= 0)
    if self.tweenSlider then
      self.tweenSlider:Destroy(self.tweenSlider)
      self.tweenSlider = nil
    end
    local exp, needExp = self:GetExpInfo()
    self.tweenSlider = TweenSlider.Add(widgets.slider.gameObject, 0.2, widgets.slider.value, exp / needExp)
    self.tweenSlider:Play(true)
    tabPart.tween:SetActive(false)
    tabPart.tween:SetActive(true)
    widgets.effect:SetActive(false)
    widgets.effect:SetActive(true)
    if level > self.levelPre then
      widgets.effectLevelUp:SetActive(false)
      widgets.effectLevelUp:SetActive(true)
    end
    self.levelPre = level
    self.expPre = exp
    UIHelper.SetText(widgets.textLevel, level)
    UIHelper.SetText(widgets.textRadio, exp .. "/" .. needExp)
  end
end

function ShipLevelupPage:_ItemUpCB(id)
  if self.m_item_id > 0 then
    self:_SendAddExp(id)
  end
  self:StopAllTimer()
end

function ShipLevelupPage:_SendAddExp(id)
  local num = Logic.bagLogic:GetBagItemNum(id)
  if self.m_item_count > 0 and num >= self.m_item_count then
    local msg = {
      HeroId = self.heroId,
      ItemList = {
        {
          Id = id,
          Num = self.m_item_count
        }
      }
    }
    Service.heroService:SendAddExp(msg)
  end
  self:StopAllTimer()
  self.m_item_count = 0
  self.m_item_id = 0
end

function ShipLevelupPage:_SendAddExpMax(id)
  if self.m_item_count > 0 then
    local num = Logic.bagLogic:GetBagItemNum(id)
    local msg = {
      HeroId = self.heroId,
      ItemList = {
        {Id = id, Num = num}
      }
    }
    Service.heroService:SendAddExp(msg)
  end
  self:StopAllTimer()
  self.m_item_count = 0
  self.m_item_id = 0
end

function ShipLevelupPage:_ItemClickCB(id)
  local num = Logic.bagLogic:GetBagItemNum(id)
  if num <= 0 then
    globalNoitceManager:ShowItemInfoPage(GoodsType.REWARD_SHIPLEVELUP_ITEM, id)
    return
  end
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local ok, msg = self:_CheckHeroLvFurther(self.heroId, heroInfo.Lvl)
  if not ok then
    noticeManager:ShowTip(msg)
    return false
  end
  local result = Logic.shipLogic:CheckLevelUpMax(self.heroId)
  if result then
    noticeManager:ShowTipById(911002)
    return false
  end
  local result = Logic.shipLogic:CheckLevelUpMaxById(self.heroId, id)
  if not result then
    noticeManager:ShowTipById(911001)
    return false
  end
  local msg = {
    HeroId = self.heroId,
    ItemList = {
      {Id = id, Num = 1}
    }
  }
  Service.heroService:SendAddExp(msg)
  self:StopAllTimer()
  self.m_item_count = 0
  self.m_item_id = 0
end

function ShipLevelupPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnClose, self.btnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnLevelUp, self.btnLevelUp, self)
  self:RegisterEvent(LuaEvent.HeroAddExp, self._refresh, self)
end

function ShipLevelupPage:btnClose()
  UIHelper.ClosePage("ShipLevelupPage")
end

function ShipLevelupPage:btnLevelUp()
  if not self:btnLevelUpCheck() then
    return
  end
  local expItem = Logic.shipLogic:GetExpItemTableByHeroId(self.heroId)
  local msg = {
    HeroId = self.heroId,
    ItemList = expItem
  }
  Service.heroService:SendAddExp(msg)
end

function ShipLevelupPage:btnLevelUpCheck()
  local result = Logic.shipLogic:CheckLevelUpByItem(self.heroId)
  if not result then
    noticeManager:ShowTipById(911003)
    local templateId = Logic.shipLogic:GetExpItemIdLessByHeroId(self.heroId)
    globalNoitceManager:ShowItemInfoPage(GoodsType.REWARD_SHIPLEVELUP_ITEM, templateId)
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local ok, msg = self:_CheckHeroLvFurther(self.heroId, heroInfo.Lvl)
  if not ok then
    noticeManager:ShowTip(msg)
    return false
  end
  local result = Logic.shipLogic:CheckLevelUpMax(self.heroId)
  if result then
    noticeManager:ShowTipById(911002)
    return false
  end
  return true
end

function ShipLevelupPage:_CheckHeroLvFurther(heroId, lv)
  local max = Logic.developLogic:GetHeroMaxLv()
  if lv >= max then
    return false, UIHelper.GetString(911006)
  end
  local cid = Data.heroData:GetHeroLFurtherId(heroId)
  local fl = Logic.developLogic:GetLFurtherMax(cid)
  if lv >= fl then
    return false, UIHelper.GetString(911011)
  end
  return true, ""
end

return ShipLevelupPage
