local EmailPage = class("UI.Email.EmailPage", LuaUIPage)
MAXMAILNUM = 100
local getType = {
  getAward = 0,
  bagFull = 1,
  notAward = 2
}

function EmailPage:DoInit()
  self.m_tabWidgets = nil
  self.m_selectMid = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function EmailPage:DoOnOpen()
  local full, num = Logic.emailLogic:IsMailFull()
  if full then
    local content = string.format(UIHelper.GetString(150001), Mathf.ToInt(num))
    noticeManager:ShowMsgBox(content)
    Logic.emailLogic:SetFullTag(false)
  end
  if Data.emailData:GetUpdataTog() then
    Service.emailService:SendGetMailList()
    Data.emailData:SetUpdataTog(false)
  else
    self:_UpdataMailList()
  end
  self:OpenTopPage("EmailPage", 1, "\233\130\174\228\187\182", self, true)
  local dotinfo = {info = "ui_mail"}
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function EmailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_delect, self._SendDelectAllEmail, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_get, self._SendFetchAllItem, self)
  self:RegisterEvent("openMail", self._OpenMail)
  self:RegisterEvent(LuaEvent.UpdataMailList, self._UpdataMailList)
  self:RegisterEvent("fetchMailItem", self._OnGetReward)
end

function EmailPage:_UpdataMailList()
  local tabMailList = Logic.emailLogic:GetActiveMailList()
  if tabMailList ~= nil then
    tabMailList = Logic.emailLogic:SortEmail(tabMailList)
    self.m_tabWidgets.txt_num.text = #tabMailList > MAXMAILNUM and MAXMAILNUM or #tabMailList
    UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_emailsv, self.m_tabWidgets.obj_email, #tabMailList, function(tabPart)
      local tabTemp = {}
      for k, v in pairs(tabPart) do
        tabTemp[tonumber(k)] = v
      end
      for index, luaPart in pairs(tabTemp) do
        local title, content = Logic.emailLogic:ParseEmail(tabMailList[index])
        UIHelper.SetText(luaPart.Txt_title, title)
        UIHelper.SetText(luaPart.Txt_content, Logic.emailLogic:Introduce(content, 20))
        luaPart.Im_new:SetActive(tabMailList[index].ReadTime == 0 and tabMailList[index].IsGotReawrd == 0)
        UGUIEventListener.AddButtonOnClick(luaPart.obj_email, self._SendOpenMail, self, tabMailList[index])
        luaPart.obj_item:SetActive(#tabMailList[index].Items ~= 0)
        luaPart.Im_access.gameObject:SetActive(#tabMailList[index].Items ~= 0)
        luaPart.obj_getbtn:SetActive(false)
        if #tabMailList[index].Items ~= 0 then
          local icon = Logic.emailLogic:GetIcon(tabMailList[index].Items[1].Type, tabMailList[index].Items[1].Id)
          local quality = Logic.emailLogic:GetQuality(tabMailList[index].Items[1].Type, tabMailList[index].Items[1].Id)
          UIHelper.SetImage(luaPart.Im_bg, QualityIcon[quality])
          UIHelper.SetImage(luaPart.Im_access, icon)
          luaPart.Txt_itemnum.text = tabMailList[index].Items[1].Num
          luaPart.obj_delectbtn:SetActive(tabMailList[index].IsGotReawrd ~= 0)
          luaPart.obj_getbtn:SetActive(tabMailList[index].IsGotReawrd == 0)
          luaPart.obj_get:SetActive(tabMailList[index].IsGotReawrd ~= 0)
          if tabMailList[index].IsGotReawrd == 0 then
            luaPart.Txt_other.text = "\230\148\182\229\143\150"
            UGUIEventListener.AddButtonOnClick(luaPart.Btn_other, self._SendFetchItem, self, tabMailList[index].Mid)
          else
            luaPart.Txt_other.text = "\229\136\160\233\153\164"
            UGUIEventListener.AddButtonOnClick(luaPart.Btn_other, self._SendDeleteMail, self, tabMailList[index].Mid)
          end
          luaPart.im_read.gameObject:SetActive(false)
        else
          UIHelper.SetImage(luaPart.Im_bg, "uipic_ui_mail_bg_neirongdi_04")
          luaPart.Txt_other.text = "\229\136\160\233\153\164"
          luaPart.obj_delectbtn:SetActive(true)
          UGUIEventListener.AddButtonOnClick(luaPart.Btn_other, self._SendDeleteMail, self, tabMailList[index].Mid)
          luaPart.im_read.gameObject:SetActive(true)
          if tabMailList[index].ReadTime ~= 0 then
            UIHelper.SetImage(luaPart.im_read, "uipic_ui_mail_im_youjianyidu")
          else
            UIHelper.SetImage(luaPart.im_read, "uipic_ui_mail_im_youjian")
          end
        end
        local mailData = tabMailList[index]
        if mailData.DeleteTime ~= 0 then
          local timeTxt = Logic.buildShipLogic:GetFormatSurplusTime(mailData.DeleteTime)
          luaPart.Txt_countdown_time.text = timeTxt
          luaPart.obj_countdown_root:SetActive(true)
        else
          luaPart.obj_countdown_root:SetActive(false)
        end
      end
    end)
  else
    noticeManager:ShowMsgBox("\229\189\147\229\137\141\230\151\160\233\130\174\228\187\182")
  end
end

function EmailPage:_SendOpenMail(go, mailInfo)
  if mailInfo.ReadTime ~= 0 then
    UIHelper.OpenPage("EmailContent", mailInfo)
    self:_UpdataMailList()
  else
    self.m_selectMid = mailInfo.Mid
    Service.emailService:SendOpenMail(mailInfo.Mid)
  end
end

function EmailPage:_SendDeleteMail(go, mid)
  Service.emailService:SendDeleteMail(mid)
end

function EmailPage:_SendDelectAllEmail()
  Service.emailService:SendDeleteAllMail()
end

function EmailPage:_SendFetchItem(go, mid)
  local ret = Logic.emailLogic:CanFetchItem(mid)
  if ret ~= MailRewardStatus.GetAward then
    return
  end
  Service.emailService:SendfetchItem(mid)
end

function EmailPage:_SendFetchAllItem()
  local ret = Logic.emailLogic:CanFetchItem()
  if ret ~= MailRewardStatus.GetAward then
    if ret == MailRewardStatus.NotAward then
      noticeManager:OpenTipPage(self, 150004)
    end
    return
  end
  Service.emailService:SendfetchAllItems()
end

function EmailPage:_OpenMail(tabMailList)
  if self.m_selectMid == nil then
    return
  end
  local mailInfo = Logic.emailLogic:GetMailById(tabMailList.list, self.m_selectMid)
  if mailInfo == nil then
    return
  end
  UIHelper.OpenPage("EmailContent", mailInfo)
  self:_UpdataMailList()
  self.m_selectMid = nil
end

function EmailPage:_OnGetReward(tabMailList)
  if 0 < #tabMailList then
    local detail = Logic.emailLogic:GetShowDetail()
    if detail then
      return
    end
    Logic.rewardLogic:ShowCommonReward(tabMailList, "EmailPage", nil)
  end
end

function EmailPage:DoOnHide()
end

function EmailPage:DoOnClose()
end

return EmailPage
