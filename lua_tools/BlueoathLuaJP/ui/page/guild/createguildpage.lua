local CreateGuildPage = class("UI.Guild.CreateGuildPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function CreateGuildPage:DoInit()
end

function CreateGuildPage:DoOnOpen()
  self:updateMoto()
end

function CreateGuildPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.btnCloseOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCreate, self.btnCreateOnClick, self)
  self:RegisterEvent(LuaEvent.Update_OurGuildInfo, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.Update_MyGuildInfo, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.MOTO_GUILD_CREATE_SUCCESS, self.updateMoto, self)
end

function CreateGuildPage:DoOnHide()
end

function CreateGuildPage:DoOnClose()
end

function CreateGuildPage:btnCloseOnClick(param)
  UIHelper.ClosePage("CreateGuildPage")
end

function CreateGuildPage:btnCreateOnClick(param)
  local paramRec = Logic.guildLogic:GetGuildParamConfig()
  local needNum = paramRec.guildbuild[2]
  local haveNum = Data.userData:GetCurrency(paramRec.guildbuild[1])
  if needNum > haveNum then
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, paramRec.guildbuild[1])
    return
  end
  local data = {
    name = self.tab_Widgets.inputField.text,
    emblem = self.mBadge
  }
  if data.name == nil or data.name == "" then
    noticeManager:ShowTipById(710042)
    return
  end
  if string.find(data.name, " ") ~= nil then
    noticeManager:ShowTipById(710049)
    return
  end
  Service.guildService:SendCreate(data)
end

function CreateGuildPage:updateMoto()
  logDebug("CreateMoto:updateMoto")
  if Data.guildData:inGuild() then
    logDebug("in guild")
    UIHelper.ClosePage("CreateGuildPage")
    return
  end
  local paramRec = Logic.guildLogic:GetGuildParamConfig()
  local currency = {
    type = GoodsType.CURRENCY,
    id = paramRec.guildbuild[1],
    count = paramRec.guildbuild[2]
  }
  local display = ItemInfoPage.GenDisplayData(currency.type, currency.id)
  UIHelper.SetText(self.tab_Widgets.textNum, currency.count)
  UIHelper.SetImage(self.tab_Widgets.imgCurrncy, display.icon_small)
end

return CreateGuildPage
