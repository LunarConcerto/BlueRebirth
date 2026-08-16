local ShipMaxLevelupPage = class("UI.Hero.ShipMaxLevelupPage", LuaUIPage)
local CommonItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local heroDev = Logic.developLogic

function ShipMaxLevelupPage:DoInit()
  self.m_heroId = 0
  self.m_cid = 0
  self.m_firstlack = nil
end

function ShipMaxLevelupPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._OnCancel, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnCancel, self)
  self:RegisterEvent(LuaEvent.HERO_LvFurtherOk, self._OnCancel, self)
end

function ShipMaxLevelupPage:DoOnOpen()
  local param = self:GetParam()
  self.m_heroId = param.heroId
  self.m_cid = param.cid
  self:_Refresh()
end

function ShipMaxLevelupPage:_Refresh()
  self:_ShowLv()
  self:_ShowCost()
end

function ShipMaxLevelupPage:_ShowLv()
  local cid = self.m_cid
  local config = heroDev:GetLHeroFurtherConfig(cid)
  if config then
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.tx_lvnow, "Lv." .. config.initial_level)
    UIHelper.SetText(widgets.tx_lvthen, "Lv." .. config.max_level)
  else
    logError("get hero further config error,id:" .. cid)
  end
end

function ShipMaxLevelupPage:_ShowCost()
  local heroId = self.m_heroId
  local cid = self.m_cid
  self.m_firstlack = nil
  local cost, enough, tid
  local ok, hero = Data.heroData:VerifyHero(heroId)
  if ok then
    tid = hero.TemplateId
  else
    logError("get hero data err,heroId:" .. heroId)
    return
  end
  local costs = heroDev:GetLFurtherCost(tid, cid)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #costs, function(index, tabPart)
    cost, enough = heroDev:FormatLFurtherCost(costs[index])
    local item = CommonItem:new()
    item:Init(index, cost, tabPart)
    if enough then
      UIHelper.SetText(tabPart.txt_num, cost.Num)
    else
      UIHelper.SetTextColor(tabPart.txt_num, cost.Num, "FF0000")
      if self.m_firstlack == nil then
        self.m_firstlack = cost
      end
    end
    UGUIEventListener.AddButtonOnClick(tabPart.img_frame, self._ShowItemDetail, self, cost)
  end)
end

function ShipMaxLevelupPage:_ShowItemDetail(go, cost)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(cost.Type, cost.ConfigId))
end

function ShipMaxLevelupPage:_OnOk()
  local ok, msg = heroDev:CheckLFurther(self.m_heroId, self.m_cid)
  if ok then
    Service.heroService:_SendHeroLFurther(self.m_heroId)
  else
    self:_FurtherFailProcess(msg)
  end
end

function ShipMaxLevelupPage:_FurtherFailProcess(msg)
  if msg == UIHelper.GetString(180004) then
    UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
  elseif type(msg) == "table" then
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(msg[1], msg[2], true))
  else
    noticeManager:ShowTip(msg)
  end
end

function ShipMaxLevelupPage:_OnCancel()
  self:_CloseSelf()
end

function ShipMaxLevelupPage:_CloseSelf()
  UIHelper.ClosePage("ShipMaxLevelupPage")
end

function ShipMaxLevelupPage:DoOnHide()
end

function ShipMaxLevelupPage:DoOnClose()
end

return ShipMaxLevelupPage
