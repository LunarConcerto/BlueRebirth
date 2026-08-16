local ManageGuildPage = class("UI.Guild.ManageGuildPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ManageGuildPage:DoInit()
end

function ManageGuildPage:DoOnOpen()
  local ourGuild = Data.guildData:getOurGuildInfo()
  local enounce = ourGuild:getEnounce()
  self.tab_Widgets.inputNote.text = enounce or ""
  local cfg = Logic.guildLogic:GetGuildParamConfig()
  local publicityCost = cfg.publicitycost
  if #publicityCost < 3 then
    self.tab_Widgets.objPublicityCost:SetActive(false)
  else
    self.tab_Widgets.objPublicityCost:SetActive(true)
    local display = ItemInfoPage.GenDisplayData(publicityCost[1], publicityCost[2])
    UIHelper.SetText(self.tab_Widgets.txtPublicityCurrencyNum, publicityCost[3])
    UIHelper.SetImage(self.tab_Widgets.imgPublicityCurrncy, display.icon)
  end
end

function ManageGuildPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.btnCloseOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnConfirm, self.btnConfirmOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnPublicity, self.btnPublicityOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnDismiss, self.btnDismissOnClick, self)
end

function ManageGuildPage:DoOnHide()
end

function ManageGuildPage:DoOnClose()
end

function ManageGuildPage:btnCloseOnClick()
  UIHelper.ClosePage("ManageGuildPage")
end

function ManageGuildPage:btnConfirmOnClick()
  local enounce = self.tab_Widgets.inputNote.text
  local cfg = Logic.guildLogic:GetGuildParamConfig()
  local maxnum = cfg.notewordnum
  local curnum = utf8Helper.SubStringGetTotalIndex(enounce)
  if maxnum < curnum then
    noticeManager:ShowTipById(710066, maxnum, curnum)
    return
  end
  local ourGuild = Data.guildData:getOurGuildInfo()
  local menounce = ourGuild:getEnounce()
  if enounce ~= menounce then
    Service.guildService:SendModify({
      Enounce = enounce,
      succ_callbackfunc = function()
        noticeManager:ShowTipById(710057)
        UIHelper.ClosePage("ManageGuildPage")
      end
    })
  else
    UIHelper.ClosePage("ManageGuildPage")
  end
end

function ManageGuildPage:btnPublicityOnClick()
  local iscan, info = Data.guildData:CanPublicity()
  if not iscan then
    noticeManager:ShowTipById(710058, info)
    return
  end
  Service.guildService:SendPublicity()
end

function ManageGuildPage:CheckBossActivity()
  local res = false
  if Logic.bossCopyLogic:IsInBossBattleStage() then
    noticeManager:ShowTipById(4300030)
    res = true
  end
  return res
end

function ManageGuildPage:btnDismissOnClick()
  if self:CheckBossActivity() then
    return
  end
  local ourGuildData = Data.guildData:getOurGuildInfo()
  local memberNum = ourGuildData:getMemberNum()
  if 1 < memberNum then
    noticeManager:ShowTipById(710017)
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.guildService:SendDismiss()
      else
      end
      UIHelper.ClosePage("ManageGuildPage")
    end
  }
  noticeManager:ShowMsgBox(710004, tabParams)
end

return ManageGuildPage
