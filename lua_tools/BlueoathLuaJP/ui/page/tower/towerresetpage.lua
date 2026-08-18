local TowerResetPage = class("UI.Tower.TowerResetPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TowerResetPage:DoInit()
end

function TowerResetPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local array = configManager.GetDataById("config_parameter", 219).arrValue
  local typ = array[1]
  local id = array[2]
  local num_consume = array[3]
  local display = ItemInfoPage.GenDisplayData(typ, id)
  local num_possess = Logic.bagLogic:GetBagItemNum(id)
  widgets.textNum.text = num_possess .. "/" .. num_consume
  UIHelper.SetImage(widgets.imgIcon, display.icon_small)
  UGUIEventListener.AddButtonOnClick(widgets.btnIcon, self.btnIcon, self, array)
end

function TowerResetPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.btn_ok, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.btn_close, self)
end

function TowerResetPage:btnIcon(go, array)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(array[1], array[2], true))
end

function TowerResetPage:btn_close()
  UIHelper.ClosePage("TowerResetPage")
end

function TowerResetPage:btn_ok()
  local array = configManager.GetDataById("config_parameter", 219).arrValue
  local typ = array[1]
  local id = array[2]
  local num_consume = array[3]
  local num_possess = Logic.bagLogic:GetBagItemNum(id)
  if num_consume <= num_possess then
    Service.towerService:SendReset()
    UIHelper.ClosePage("TowerResetPage")
  else
    local name = Logic.goodsLogic:GetName(id, typ)
    noticeManager:ShowTipById(440002, name)
    globalNoitceManager:ShowItemInfoPage(typ, id)
  end
end

function TowerResetPage:DoOnClose()
  local params = self:GetParam() or {}
  if params.callback then
    params.callback()
  end
end

return TowerResetPage
