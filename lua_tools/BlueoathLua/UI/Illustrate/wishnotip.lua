local WishNoTip = class("UI.Illustrate.WishNoTip", LuaUIPage)
local WishSelectHeroItem = require("ui.page.Illustrate.WishSelectHeroItem")

function WishNoTip:DoInit()
end

function WishNoTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_close, self._CloseSelf, self)
end

function WishNoTip:DoOnOpen()
  self:_Refresh()
end

function WishNoTip:_Refresh()
  local widgets = self:GetWidgets()
  local ids = Logic.wishLogic:GetAllNoHeros()
  UIHelper.CreateSubPart(widgets.obj_hero, widgets.trans_hero, #ids, function(index, tabPart)
    local data = Data.wishData:GetNoShipById(ids[index])
    if data then
      local item = WishSelectHeroItem:new()
      item:Init(self, data, tabPart, false, nil, index)
    end
  end)
end

function WishNoTip:_ShowShips()
end

function WishNoTip:_CloseSelf()
  UIHelper.ClosePage("WishNoTip")
end

function WishNoTip:DoOnHide()
end

function WishNoTip:DoOnClose()
end

return WishNoTip
