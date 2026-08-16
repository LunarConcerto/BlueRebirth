local EmailContent = class("UI.Email.EmailContent", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function EmailContent:DoInit()
  self.m_tabWidgets = nil
  self.m_tabGetObj = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.haveNewMail = false
end

function EmailContent:DoOnOpen()
  self.m_tabEmail = self:GetParam()
  self:_LoadContent(self.m_tabEmail)
  Logic.emailLogic:SetShowDetail(true)
end

function EmailContent:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, self._Close, self)
  self:RegisterEvent(LuaEvent.UpdataMailList, self._FetchItem)
  self:RegisterEvent("fetchMailItem", self._OnGetReward)
end

function EmailContent:_OnGetReward(tabMailList)
  if 0 < #tabMailList then
    Logic.rewardLogic:ShowCommonReward(tabMailList, "EmailPage", nil)
  end
end

function EmailContent:_LoadContent(tabEmail)
  if tabEmail == nil then
    UIHelper.ClosePage("EmailContent")
    return
  end
  local title, content = Logic.emailLogic:ParseEmail(tabEmail)
  UIHelper.SetText(self.m_tabWidgets.txt_title, title)
  UIHelper.SetText(self.m_tabWidgets.txt_content, content)
  self.m_tabWidgets.txt_time.text = "  \230\148\182\228\187\182\230\151\182\233\151\180:" .. Logic.emailLogic:FormatTime(tabEmail.ReceiveTime)
  self.m_tabWidgets.obj_itemBase:SetActive(#tabEmail.Items ~= 0)
  if #tabEmail.Items ~= 0 then
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_access, self.m_tabWidgets.trans_access, #tabEmail.Items, function(nindex, tabPart)
      local num = Mathf.ToInt(tabEmail.Items[nindex].Num)
      UIHelper.SetText(tabPart.Txt_num, "x" .. num)
      local icon = Logic.emailLogic:GetIcon(tabEmail.Items[nindex].Type, tabEmail.Items[nindex].Id)
      local quality = Logic.emailLogic:GetQuality(tabEmail.Items[nindex].Type, tabEmail.Items[nindex].Id)
      UIHelper.SetImage(tabPart.Im_bg, QualityIcon[quality])
      UIHelper.SetImage(tabPart.Im_access, icon)
      table.insert(self.m_tabGetObj, tabPart.obj_get)
      UGUIEventListener.AddButtonOnClick(tabPart.Im_bg, self._ShowItemDetail, self, tabEmail.Items[nindex])
    end)
    if tabEmail.IsGotReawrd ~= 0 or self.haveNewMail then
      for k, v in pairs(self.m_tabGetObj) do
        v:SetActive(true)
      end
      self.m_tabWidgets.txt_get.text = "\229\136\160 \233\153\164"
      UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_get, self._SendDelectMail, self)
    else
      UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_get, self._SendFetchItem, self)
    end
  else
    self.m_tabWidgets.trans_access.gameObject:SetActive(false)
    self.m_tabWidgets.txt_get.text = "\229\136\160 \233\153\164"
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_get, self._SendDelectMail, self)
  end
end

function EmailContent:_ShowItemDetail(go, item)
  Logic.itemLogic:ShowItemInfo(item.Type, item.Id)
end

function EmailContent:_Close()
  UIHelper.ClosePage("EmailContent")
end

function EmailContent:_SendFetchItem()
  local ret = Logic.emailLogic:CanFetchItem(self.m_tabEmail.Mid)
  if ret ~= MailRewardStatus.GetAward then
    return
  end
  Service.emailService:SendfetchItem(self.m_tabEmail.Mid)
end

function EmailContent:_FetchItem()
  local tabMailList = Data.emailData:GetMailList()
  local mailInfo = Logic.emailLogic:GetMailById(tabMailList, self.m_tabEmail.Mid)
  self.haveNewMail = true
  self:_LoadContent(mailInfo)
end

function EmailContent:_SendDelectMail()
  Service.emailService:SendDeleteMail(self.m_tabEmail.Mid)
  UIHelper.ClosePage("EmailContent")
end

function EmailContent:DoOnHide()
end

function EmailContent:DoOnClose()
  Logic.emailLogic:SetShowDetail(false)
end

return EmailContent
