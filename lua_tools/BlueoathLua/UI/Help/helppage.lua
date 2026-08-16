local HelpPage = class("UI.Help.HelpPage", LuaUIPage)

function HelpPage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabParams = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function HelpPage:DoOnOpen()
  self:_LoadContent(self:GetParam())
end

function HelpPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, self._CliskClose, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, self._CliskClose, self)
end

function HelpPage:_LoadContent(param)
  local id = param.content
  local title = param.title or "\229\184\174\229\138\169\228\191\161\230\129\175"
  local openType = param.openType or OpenSharePage.Other
  if type(id) == "number" then
    local content = UIHelper.GetString(id)
    self.m_tabWidgets.txt_content.text = content
    self.m_tabWidgets.txt_ssrContent.text = content
  else
    UIHelper.SetText(self.m_tabWidgets.txt_content, id)
    UIHelper.SetText(self.m_tabWidgets.txt_ssrContent, id)
  end
  UIHelper.SetText(self.m_tabWidgets.txt_title, title)
  self.m_tabWidgets.obj_commom:SetActive(openType == OpenSharePage.Other)
  self.m_tabWidgets.obj_bgSSR:SetActive(openType == OpenSharePage.ActSSR)
end

function HelpPage:_CliskClose()
  UIHelper.ClosePage("HelpPage")
end

return HelpPage
