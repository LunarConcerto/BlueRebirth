local NationItemPage = class("UI.NationItemPage", LuaUIPage)
local timeInterval = configManager.GetDataById("config_parameter", 198).value

function NationItemPage:DoInit()
  self.m_timer = nil
  self.isCanClose = false
  self.showNum = 1
  self.num = 1
  self.printTimer = nil
end

function NationItemPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
end

function NationItemPage:DoOnOpen()
  self.itemId = self:GetParam()
  local widgets = self:GetWidgets()
  self.tabText = {
    [1] = widgets.tx_date,
    [2] = widgets.tx_weather,
    [3] = widgets.tx_change,
    [4] = widgets.tx_content
  }
  self:ShowEff()
end

function NationItemPage:ShowEff()
  self.tab_Widgets.im_bg:SetActive(false)
  self.tab_Widgets.btn_close.interactable = false
  local dropCfg = configManager.GetDataById("config_item_info", self.itemId)
  if dropCfg.effect_name then
    self.objEff = UIHelper.CreateUIEffect("effects/prefabs/ui/" .. dropCfg.effect_name, self.tab_Widgets.obj_eff.transform)
    self.objEff:AddComponent(UISortEffectComponent.GetClassType())
    self.m_timer = self:CreateTimer(function()
      self:_EffOver()
    end, dropCfg.eff_time, 1, false)
    self:StartTimer(self.m_timer)
  end
end

function NationItemPage:_EffOver()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
    self.m_timer = nil
  end
  if self.obj_eff ~= nil then
    UIHelper.DestroyUIEffect(self.obj_eff)
  end
  self.tab_Widgets.im_bg:SetActive(true)
  SoundManager.Instance:PlayAudio("Effect_eff_piaoliuwu_zimuloop")
  self:_ShowContent()
end

function NationItemPage:_ShowContent()
  local dropCfg = configManager.GetDataById("config_item_info", self.itemId)
  local content = dropCfg.nation_text
  self.num = 1
  if content[self.showNum] then
    local str = UIHelper.GetString(content[self.showNum])
    local len = utf8Helper.SubStringGetTotalIndex(str)
    self.startIndex = 0
    self.endIndex = 0
    self.printTimer = Timer.New(function()
      self:_StartContent(str, #content)
    end, timeInterval / 1000, len, false)
    self.printTimer:Start()
  end
end

function NationItemPage:_StartContent(str, allTextNum)
  local len = utf8Helper.SubStringGetTotalIndex(str)
  self.endIndex = self.endIndex + 1
  local endbyteIndex = utf8Helper.SubStringGetTrueEndIndex(str, self.endIndex)
  local curbyteIndex = utf8Helper.SubStringGetTrueEndIndex(str, self.startIndex)
  self.showText = string.sub(str, 1, endbyteIndex)
  self.startIndex = self.endIndex + 1
  UIHelper.SetText(self.tabText[self.showNum], self.showText)
  if len <= self.num and allTextNum > self.showNum then
    self.num = 1
    self.showNum = self.showNum + 1
    self:_ShowContent()
  elseif allTextNum <= self.showNum and len <= self.num then
    SoundManager.Instance:StopAudio("Effect_eff_piaoliuwu_zimuloop")
    self.isCanClose = true
  else
    self.num = self.num + 1
  end
end

function NationItemPage:_ClickClose()
  if self.isCanClose then
    UIHelper.ClosePage("NationItemPage")
  end
end

function NationItemPage:DoOnHide()
end

function NationItemPage:DoOnClose()
  if self.objEff ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.objEff)
    self.objEff = nil
  end
end

return NationItemPage
