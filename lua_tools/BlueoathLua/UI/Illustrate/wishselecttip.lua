local WishSelectTip = class("UI.Illustrate.WishSelectTip", LuaUIPage)
local WishSelectHeroItem = require("ui.page.Illustrate.WishSelectHeroItem")

function WishSelectTip:DoInit()
end

function WishSelectTip:DoOnOpen()
  self.m_herolist = Data.wishData:GetSelectHeroList()
  if self.m_herolist == nil or next(self.m_herolist) == nil then
    noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\232\174\184\230\132\191\232\139\177\233\155\132")
  else
    self:_ShowSelectHero(self.m_herolist)
    local widgets = self:GetWidgets()
    local currPos = widgets.trans_item.anchoredPosition
    widgets.trans_item.anchoredPosition = Vector3.New(currPos.x, 0, currPos.z)
  end
  SoundManager.Instance:PlayMusic("Lower_music_volume")
end

function WishSelectTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._Cancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._Confirm, self)
end

function WishSelectTip:_ShowSelectHero(herolist)
  local widgets = self:GetWidgets()
  local sr, ssr = Logic.wishLogic:GetBanHeroNum()
  UIHelper.SetLocText(widgets.tx_numstr, 951007, sr .. " " .. UIHelper.GetLocString(951008, ssr))
  UIHelper.SetLocText(widgets.tx_tip, 951014)
  local srTime, isLimitSR = Logic.wishLogic:GetHeroChargeTimeByQuality(ShipQuality.SR)
  local ssrTime, isLimitSSR = Logic.wishLogic:GetHeroChargeTimeByQuality(ShipQuality.SSR)
  local limitStr = isLimitSR and UIHelper.GetString(951032) or ""
  UIHelper.SetText(widgets.tx_desstr, UIHelper.GetLocString(951030) .. time.getTimeStringFontDynamic(srTime) .. limitStr)
  limitStr = isLimitSSR and UIHelper.GetString(951032) or ""
  UIHelper.SetText(widgets.tx_desstr_ssr, UIHelper.GetLocString(951031) .. time.getTimeStringFontDynamic(ssrTime) .. limitStr)
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #herolist, function(index, tabPart)
    WishSelectHeroItem:Init(self, herolist[index], tabPart, false, nil)
  end)
end

function WishSelectTip:_Cancel()
  UIHelper.ClosePage("WishSelectTip")
end

function WishSelectTip:_Confirm()
  local param = self:_dealParam(self.m_herolist)
  if #param <= 0 then
    noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\232\174\184\230\132\191\232\139\177\233\155\132")
    return
  end
  param = Logic.wishLogic:FilterCanWish(param)
  Service.illustrateService:SendVowHero(param)
  local dotinfo = {
    info = "ui_vow_confirm"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  UIHelper.ClosePage("WishSelectTip")
end

function WishSelectTip:_dealParam(herolist)
  local res = {}
  for i, info in ipairs(herolist) do
    res[i] = info.IllustrateId
  end
  return res
end

function WishSelectTip:DoOnHide()
end

function WishSelectTip:DoOnClose()
  SoundManager.Instance:PlayMusic("Reset_bus_volume_all")
end

return WishSelectTip
