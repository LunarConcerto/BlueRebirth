local BuildingSelect = class("ui.page.Common.CommonSelect.BuildingSelect")

function BuildingSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
end

function BuildingSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, function()
    self:_BuildingCancel()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_rmd, self._BuildingRmd, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._BuildingConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._BuildingCancel, self)
  local dotinfo = {
    info = "ui_shipyard",
    type = "building_shipyard"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self.m_page.m_tabSelectShip = self.m_tabParams.m_selectedIdList
  if next(self.m_tabParams.m_selectedIdList) ~= nil then
    table.insertto(self.m_page.m_SelectedBack, self.m_page.m_tabSelectShip)
  end
  self.m_widgets.obj_building:SetActive(true)
  self.m_widgets.obj_sort:SetActive(false)
end

function BuildingSelect:_BuildingRmd(go, param)
  local buildId = self.m_tabParams.m_buildingInfo.Id
  local orginHero = self.m_page.m_tabSortHero
  local rmd = Logic.buildingLogic:AutoRmdHero(orginHero, buildId)
  if 0 < #rmd then
    for _, heroId in ipairs(rmd) do
      table.insert(self.m_page.m_tabSelectShip, heroId)
    end
    self.m_page:_LoadHeroItem(orginHero)
    self.m_page:_ShowSelectNum()
  end
end

function BuildingSelect:_BuildingConfirm()
  local ok, msg = Logic.buildingLogic:CheckAndSendBuildHero(self.m_page.m_tabSelectShip, self.m_page:_GetBuildingData())
  logError(msg)
  if ok then
    UIHelper.Back()
  else
    noticeManager:ShowTip(msg)
  end
end

function BuildingSelect:_BuildingCancel()
  UIHelper.Back()
end

return BuildingSelect
