local ChatSetPage = class("UI.Chat.ChatSetPage", LuaUIPage)

function ChatSetPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabVoiceSet = {}
  self.m_tabChatSet = {}
end

function ChatSetPage:DoOnOpen()
  local tabConfig = Logic.chatLogic:GetChatSetConfig()
  self:_DealConfig(tabConfig)
  self:_ShowChatSet()
end

function ChatSetPage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._ClosePage, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_block, self._TogReceiveBlock, self)
end

function ChatSetPage:_ShowChatSet()
  local widgets = self.m_tabWidgets
  self:_LoadSet(widgets.obj_Play, widgets.trans_Play, self.m_tabVoiceSet)
  self:_LoadSet(widgets.obj_Chat, widgets.trans_Chat, self.m_tabChatSet)
end

function ChatSetPage:_DealConfig(tabConfig)
  for k, v in pairs(tabConfig) do
    if v.belong == 2 then
      table.insert(self.m_tabVoiceSet, v)
    end
    if v.belong == 3 then
      table.insert(self.m_tabChatSet, v)
    end
  end
end

function ChatSetPage:_LoadSet(obj, trans, tabData)
  UIHelper.CreateSubPart(obj, trans, #tabData, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_name, tabData[index].name)
    local value = Logic.chatLogic:GetChatSet(tabData[index].key)
    if value == 0 then
      value = tabData[index].value
      Logic.chatLogic:SetChatSet(tabData[index].key, value)
    end
    tabPart.tog_Item.isOn = value == 2
    UGUIEventListener.AddButtonToggleChanged(tabPart.tog_Item, self._onTogChange, self, tabData[index].id)
  end)
end

function ChatSetPage:_onTogChange(go, isOn, id)
  local value = isOn and 2 or 1
  local config = Logic.chatLogic:GetChatSetConfigById(id)
  Logic.chatLogic:SetChatSet(config.key, value)
end

function ChatSetPage:_AutoPlayIn3G4G(go, isOn)
  if isOn then
    logError("3G/4G\232\135\170\229\138\168\230\146\173\230\148\190")
  else
    logError("3G/4G\229\143\150\230\182\136\232\135\170\229\138\168\230\146\173\230\148\190")
  end
end

function ChatSetPage:_ClosePage()
  eventManager:SendEvent(LuaEvent.UpdataChatInfo)
  UIHelper.ClosePage("ChatSetPage")
end

function ChatSetPage:_TogReceiveBlock(go, isOn)
  Data.chatData:SetBlockTog(isOn)
end

function ChatSetPage:DoOnHide()
end

function ChatSetPage:DoOnClose()
end

return ChatSetPage
