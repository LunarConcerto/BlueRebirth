local WishAdvanceDetailPage = class("UI.Illustrate.WishAdvanceDetailPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local WishSelectHeroItem = require("ui.page.Illustrate.WishSelectHeroItem")
local SHOWITEMNUM = 8
local maskHideImgMap = {
  [true] = "uipic_ui_vow_fo_jiasu",
  [false] = "uipic_ui_vow_fo_xuyuan"
}

function WishAdvanceDetailPage:DoInit()
  self.m_tabTips = {}
end

function WishAdvanceDetailPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._CloseSelf, self)
  UGUIEventListener.AddOnEndDrag(widgets.sv_heros, self._SetAdvanceTips, self)
  self:RegisterEvent(LuaEvent.GetWishReward, self._OpenGetHeroPage, self)
end

function WishAdvanceDetailPage:DoOnOpen()
  self.m_param = self:GetParam()
  self:_Refresh()
end

function WishAdvanceDetailPage:_Refresh()
  local heros = self.m_param
  local widgets = self:GetWidgets()
  widgets.sv_ctrler.Total = #heros
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #heros, function(index, tabPart)
    local id = heros[index]
    local quality, icon, name, ti
    quality = Logic.illustrateLogic:GetQuality(id)
    icon = Logic.illustrateLogic:GetCommonIcon(id)
    name = Logic.illustrateLogic:GetName(id)
    ti, duration = Logic.illustrateLogic:GetAdvanceTime(id)
    UIHelper.SetImage(tabPart.im_quality, GirlEquipQualityBgTexture[quality])
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetText(tabPart.tx_name, name)
    local str = string.format(UIHelper.GetString(951056), ti)
    UIHelper.SetText(tabPart.tx_time, str)
    self:_timeTick(duration, tabPart.tx_time)
  end)
  local tag = 1
  local num = widgets.sv_ctrler.PageNum
  UIHelper.CreateSubPart(widgets.obj_tips, widgets.trans_tips, num, function(index, tabPart)
    tabPart.obj_tips:SetActive(tag == index)
    self.m_tabTips[index] = tabPart.obj_tips
  end)
  LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_heros)
end

function WishAdvanceDetailPage:_timeTick(duration, text)
  local timer = self:CreateTimer(function()
    duration = duration - 1
    local str = string.format(UIHelper.GetString(951056), time.getTimeStringFontDynamic(duration))
    UIHelper.SetText(text, str)
    if duration <= 0 then
      eventManager:SendEvent(LuaEvent.UpdateWish)
    end
  end, 1, duration, false)
  self:StartTimer(timer)
end

function WishAdvanceDetailPage:_CloseSelf()
  UIHelper.ClosePage("WishAdvanceDetailPage")
end

function WishAdvanceDetailPage:_SetAdvanceTips()
  local widgets = self:GetWidgets()
  local intervalIndex = widgets.sv_ctrler.CurPage
  for k, v in pairs(self.m_tabTips) do
    v:SetActive(k == intervalIndex)
  end
end

function WishAdvanceDetailPage:DoOnHide()
end

function WishAdvanceDetailPage:DoOnClose()
end

return WishAdvanceDetailPage
