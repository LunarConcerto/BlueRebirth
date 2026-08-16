local ShipTestSelect = class("ui.page.Common.CommonSelect ShipTestSelect")

function ShipTestSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function ShipTestSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\180\172\206\235", self, true, self._SelectCancel)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._SelectConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._SelectCancel, self)
  self.m_page.m_tabSelectShip = tabParams.m_selectedIdList or {}
end

function ShipTestSelect:_SelectConfirm()
  if #self.m_page.m_tabSelectShip == 0 then
    noticeManager:OpenTipPage(self, "\199\235\209\161\212\241\213\189\188\167")
    return
  end
  local heroId = self.m_page.m_tabSelectShip[1]
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local heroTid = 0
  if heroInfo ~= nil then
    heroTid = heroInfo.TemplateId
  end
  if heroTid <= 0 then
    logError("heroTid err", heroTid)
    return
  end
  local cfg = configManager.GetDataById("config_ship_main", heroTid)
  local siCfg = configManager.GetDataById("config_ship_info", cfg.ship_info_id)
  local shipTid = siCfg.sf_id
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.shiptaskService:SendSetCurrentShip({ShipTid = shipTid, HeroTemplateId = heroTid})
        UIHelper.Back()
      end
    end
  }
  local shipshow = Logic.shipLogic:GetShipInfoById(heroTid)
  local msg = UIHelper.GetLocString(7400001, shipshow.ship_name)
  noticeManager:ShowMsgBox(msg, tabParams)
end

function ShipTestSelect:_SelectCancel()
  UIHelper.Back()
end

return ShipTestSelect
