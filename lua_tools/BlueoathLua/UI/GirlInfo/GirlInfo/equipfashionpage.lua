local EquipFashionPage = class("UI.GirlInfo.GirlInfo", LuaUIPage)

function EquipFashionPage:DoInit()
  self.heroSkillType = {}
  self.m_selectRigth = nil
  self.index = nil
  self.toggleParts = {}
  self.EffcetSelectType = {
    [EquipBigType.One] = {},
    [EquipBigType.Two] = {},
    [EquipBigType.Three] = {},
    [EquipBigType.Four] = {},
    [EquipBigType.Five] = {},
    [EquipBigType.Six] = {}
  }
  self.togIndex = 0
end

function EquipFashionPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickTip, self)
  self:RegisterEvent(LuaEvent.CloseWebView, self._UnmuteMusic, self)
end

function EquipFashionPage:DoOnOpen()
  local params = self:GetParam()
  self.heroId = params.heroId
  self.fashionId = params.fashionId
  if params.equipType ~= nil then
    self.equipType = params.equipType
  end
  self.serMapEffects = Logic.equipLogic:GetSerMapEffects(self.heroId)
  self:SpecDealSerEffects()
  self:OpenTopPage("EquipFashionPage", 1, "\232\163\133\229\164\135\231\137\185\230\149\136", self, true)
  self:_LoadTogs()
end

function EquipFashionPage:SpecDealSerEffects()
  local shipInfoConfig = Logic.shipLogic:GetShipInfoByHeroId(self.heroId)
  if shipInfoConfig.sf_id == 1024031 and next(self.serMapEffects[4]) == nil and next(self.serMapEffects[5]) == nil then
    self.serMapEffects[4][1302] = true
    self.serMapEffects[5][1303] = true
    local Effects = {}
    table.insert(Effects, {
      type = 4,
      EffectId = {1302}
    })
    table.insert(Effects, {
      type = 5,
      EffectId = {1303}
    })
    local args = {
      HeroId = self.heroId,
      Effects = Effects
    }
  end
end

function EquipFashionPage:_LoadTogs()
  local fashionCfg = Logic.fashionLogic:GetFashionConfig(self.fashionId)
  self.heroSkillType = configManager.GetDataById("config_ship_fleet", fashionCfg.belong_to_ship).equip_fashion_type
  UIHelper.CreateSubPart(self.tab_Widgets.obj_toggle, self.tab_Widgets.trans_tgGroup, #self.heroSkillType, function(index, tabPart)
    local showTypeData = configManager.GetDataById("config_equip_fashion_showtype", self.heroSkillType[index])
    UIHelper.SetText(tabPart.tx_name, showTypeData.name)
    self.tab_Widgets.tog_tgGroup:RegisterToggle(tabPart.toggle)
    if self.equipType ~= nil and self.equipType == self.heroSkillType[index] then
      self.togIndex = index - 1
    end
    table.insert(self.toggleParts, tabPart)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_tgGroup, self, "", self._SwitchTogs)
  self.tab_Widgets.tog_tgGroup:SetActiveToggleIndex(self.togIndex)
end

function EquipFashionPage:_SwitchTogs(index)
  self.index = index + 1
  local showType = self.heroSkillType[index + 1]
  self.toggleParts[self.index].isOn = true
  for i, part in pairs(self.toggleParts) do
    part.tween_tog:Play(i ~= self.index)
  end
  self:_LoadItemInfo(showType)
end

function EquipFashionPage:_LoadItemInfo(showType)
  local equipEffectByType = Logic.equipLogic:GetEquipEffectByType(self.heroId, showType)
  if equipEffectByType == nil then
    logError("\232\175\165\231\177\187\229\158\139\232\163\133\229\164\135\229\143\150\231\137\185\230\149\136\228\184\186\231\169\186")
    return
  end
  local sortEquipEffect = Logic.equipLogic:EquipEffectSort(equipEffectByType, showType, self.fashionId)
  self.tab_Widgets.obj_noEffect:SetActive(#sortEquipEffect == 1)
  self.tab_Widgets.obj_scrollbar.gameObject:SetActive(#sortEquipEffect ~= 1)
  UIHelper.SetText(self.tab_Widgets.tx_noEffect, UIHelper.GetString(7700002))
  local oneTabpart = {}
  self.tab_Widgets.tween_fashion:ResetToBeginning()
  self.tab_Widgets.tween_fashion:Play(true)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_ItemMemory, self.tab_Widgets.trans_ContentMemory, #sortEquipEffect, function(index, tabPart)
    local skillFashion = configManager.GetDataById("config_skill_fashion", sortEquipEffect[index])
    local effectId = sortEquipEffect[index]
    effectId = tonumber(effectId)
    UIHelper.SetText(tabPart.txt_name, skillFashion.skill_fashion_name)
    UIHelper.SetImage(tabPart.im_activity, skillFashion.show_picture)
    tabPart.obj_xuanzhong:SetActive(false)
    if self.serMapEffects[showType][tonumber(effectId)] then
      self.serMapEffects[showType][tonumber(effectId)] = nil
      self.EffcetSelectType[showType][tonumber(effectId)] = true
    end
    if #sortEquipEffect == 1 then
      tabPart.obj_item:SetActive(false)
    end
    if index == 1 then
      oneTabpart = {
        effectId = effectId,
        tabPart = tabPart,
        showType = showType
      }
    end
    if self.EffcetSelectType[showType][tonumber(effectId)] ~= nil then
      tabPart.obj_xuanzhong:SetActive(self.EffcetSelectType[showType][tonumber(effectId)])
    else
      tabPart.obj_xuanzhong:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_itemEffect, self._SelectEffect, self, {
      effectId = sortEquipEffect[index],
      tabPart = tabPart,
      showType = showType,
      index = index
    })
    UGUIEventListener.AddButtonOnClick(tabPart.btn_play, self._PlayAdvio, self, tonumber(effectId))
  end)
  if next(self.EffcetSelectType[showType]) == nil then
    oneTabpart.tabPart.obj_xuanzhong:SetActive(true)
    self.EffcetSelectType[oneTabpart.showType][tonumber(oneTabpart.effectId)] = true
  end
end

function EquipFashionPage:_SelectEffect(go, params)
  local tabPart = params.tabPart
  local effectId = params.effectId
  local showType = params.showType
  local index = params.index
  local tabEffect = {}
  for k, v in pairs(self.EffcetSelectType[showType]) do
    table.insert(tabEffect, v)
  end
  if self.EffcetSelectType[showType][tonumber(effectId)] and 1 < #tabEffect then
    tabPart.obj_xuanzhong:SetActive(false)
    self.EffcetSelectType[showType][tonumber(effectId)] = nil
  elseif self.EffcetSelectType[showType][tonumber(effectId)] and #tabEffect == 1 then
    tabPart.obj_xuanzhong:SetActive(true)
    self.EffcetSelectType[showType][tonumber(effectId)] = true
    noticeManager:OpenTipPage(self, UIHelper.GetString(7700003))
  else
    tabPart.obj_xuanzhong:SetActive(true)
    self.EffcetSelectType[showType][tonumber(effectId)] = true
  end
end

function EquipFashionPage:_PlayAdvio(go, effectId)
  if effectId == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(7700004))
    return
  end
  SoundManager.Instance:PlayMusic("Role_unlock")
  Logic.equipLogic:_PlayAdvio(effectId)
end

function EquipFashionPage:_ClickTip()
  UIHelper.OpenPage("HelpPage", {content = 7700001})
end

function EquipFashionPage:_UnmuteMusic()
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
end

function EquipFashionPage:DoOnHide()
end

function EquipFashionPage:DoOnClose()
  local Effects = {}
  for k, v in pairs(self.heroSkillType) do
    local tabEffects = self.EffcetSelectType[v]
    for key, value in pairs(self.serMapEffects[v]) do
      tabEffects[key] = value
    end
    local EffectId = {}
    for key, value in pairs(tabEffects) do
      table.insert(EffectId, tonumber(key))
    end
    local effect = {type = v, EffectId = EffectId}
    table.insert(Effects, effect)
  end
  local args = {
    HeroId = self.heroId,
    Effects = Effects
  }
  Service.heroService:_SendEquipEffect(args)
end

return EquipFashionPage
