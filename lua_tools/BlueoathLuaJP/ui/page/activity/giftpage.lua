local GiftPage = class("UI.Activity.GiftPage", LuaUIPage)

function GiftPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function GiftPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_giftCommit, self._GiftCommit, self)
end

function GiftPage:DoOnOpen()
end

function GiftPage:_GiftCommit()
  local input = self.m_tabWidgets.giftInput.text
  if input == "" then
    noticeManager:ShowTip(UIHelper.GetString(330009))
    return
  end
  local useSDK = platformManager:useSDK()
  if useSDK then
    platformManager:getGiftCard(input, function(result)
      self:_GiftCallBack(result)
    end)
  end
end

function GiftPage:_GiftCallBack(result)
  if result then
    noticeManager:ShowTip(result.msg)
  end
end

function GiftPage:DoOnClose()
end

return GiftPage
