local HeroRetireTip = class("UI.Dock.HeroRetireTip", LuaUIPage)

function HeroRetireTip:DoInit()
  self.m_tabWidgets = nil
end

function HeroRetireTip:DoOnOpen()
  self.m_selectIds = self:GetParam()
  self:_Refresh()
end

function HeroRetireTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.obj_bg, self._Close, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_close, self._Close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._Ok, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._Cancel, self)
  self:RegisterEvent(LuaEvent.RetireHeros, self._BaseClose, self)
end

function HeroRetireTip:_Refresh()
  self:_ShowShips()
  self:_ShowReward()
end

function HeroRetireTip:_ShowShips()
  local widgets = self:GetWidgets()
  local heroId, heroInfo
  UIHelper.CreateSubPart(widgets.obj_ship, widgets.trans_ship, #self.m_selectIds, function(index, tabPart)
    heroId = self.m_selectIds[index]
    heroInfo = Data.heroData:GetHeroById(heroId)
    ShipCardItem:LoadVerticalCard(heroId, tabPart.cardPart)
    UIHelper.SetText(tabPart.tx_lv, Mathf.ToInt(heroInfo.Lvl))
    UIHelper.SetStar(tabPart.obj_star, tabPart.trans_star, heroInfo.Advance)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_card, self._OnClickShip, self, index)
  end)
end

function HeroRetireTip:_OnClickShip(go, params)
  table.remove(self.m_selectIds, params)
  self:_Refresh()
end

function HeroRetireTip:_ShowReward()
  local widgets = self:GetWidgets()
  local items = Logic.dockLogic:GetHeroRetireReward(self.m_selectIds)
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.trans_reward, #items, function(index, tabPart)
    local num = items[index][3]
    local icon = Logic.shopLogic:GetTable_Index_Info(items[index]).icon_small
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetText(tabPart.tx_num, num)
  end)
end

function HeroRetireTip:_Close()
  eventManager:SendEvent(LuaEvent.CancelHeroRetire, self.m_selectIds)
  self:_BaseClose()
end

function HeroRetireTip:_BaseClose()
  UIHelper.ClosePage("HeroRetireTip")
end

function HeroRetireTip:_Cancel()
  self:_Close()
end

function HeroRetireTip:_Ok()
  if #self.m_selectIds <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(180023))
    return
  end
  local bBreak = false
  local bLevelUp = false
  local bIntensify = false
  local bHighQuality = false
  local bRemould = false
  for i, heroId in ipairs(self.m_selectIds) do
    bBreak = bBreak or Logic.shipLogic:CheckHasBreak(heroId)
    bLevelUp = bLevelUp or Data.heroData:GetHeroById(heroId).Lvl > 1
    bIntensify = bIntensify or Logic.shipLogic:CheckHasIntensify(heroId)
    bHighQuality = bHighQuality or Logic.shipLogic:CheckHighQuality(heroId)
    bRemould = bRemould or Logic.remouldLogic:CkeckHeroRemoulding(heroId)
  end
  if bBreak or bLevelUp or bIntensify or bHighQuality then
    local tblTips = {}
    if bBreak or bIntensify then
      table.insert(tblTips, UIHelper.GetString(110029))
    end
    if bLevelUp then
      table.insert(tblTips, UIHelper.GetString(110028))
    end
    if bHighQuality then
      table.insert(tblTips, UIHelper.GetString(110027))
    end
    if bRemould then
      table.insert(tblTips, UIHelper.GetString(940000003))
    end
    local strTips = string.format(UIHelper.GetString(110026), table.concat(tblTips, ","))
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Logic.dockLogic:SroreHeroEquipInfo(self.m_selectIds)
          Service.heroService:SendRetireHero(self.m_selectIds, false)
        end
      end
    }
    noticeManager:ShowMsgBox(strTips, tabParams)
  else
    Logic.dockLogic:SroreHeroEquipInfo(self.m_selectIds)
    Service.heroService:SendRetireHero(self.m_selectIds, false)
  end
end

function HeroRetireTip:DoOnHide()
end

function HeroRetireTip:DoOnClose()
end

return HeroRetireTip
