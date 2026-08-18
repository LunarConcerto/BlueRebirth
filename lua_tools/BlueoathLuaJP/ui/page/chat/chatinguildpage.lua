local super = require("ui.page.Chat.ChatPage")
local ChatInGuildPage = class("UI.Chat.ChatInGuildPage", super)

function ChatInGuildPage:DoOnOpen()
  Data.chatData:SetChatChannel(ChatChannel.Guild)
  super.DoOnOpen(self)
  self.tab_Widgets.objTag:SetActive(false)
  self.tab_Widgets.objImgBg:SetActive(false)
  self.tab_Widgets.objImgMask:SetActive(false)
  self.tab_Widgets.objBtnClose:SetActive(false)
end

function ChatInGuildPage:_FillMsgItem(index, luaPart, tabChatList, channelType)
  super._FillMsgItem(self, index, luaPart, tabChatList, channelType)
  UGUIEventListener.ClearButtonEventListener(luaPart.im_otherHead.gameObject)
end

return ChatInGuildPage
