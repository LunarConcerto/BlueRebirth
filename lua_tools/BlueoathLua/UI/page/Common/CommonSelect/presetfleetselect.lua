local PresetFleetSelect = class("ui.page.Common.CommonSelect.PresetFleetSelect")

function PresetFleetSelect:initialize()
  self.m_page = nil
  self.m_widgets = nil
  self.m_tabParams = nil
  self.m_showFleet = true
end

function PresetFleetSelect:Init(page, tabParams)
  self.m_page = page
  self.m_widgets = page.m_tabWidgets
  self.m_tabParams = tabParams
  self.m_page:OpenTopPage("CommonSelectPage", 1, "\232\136\185\229\157\158", self, true, function()
    self:_CrusadeCancel()
  end)
  UGUIEventListener.AddButtonToggleChanged(self.m_widgets.tog_showFleet, self._ShowFleet, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_ok, self._CrusadeConfirm, self)
  UGUIEventListener.AddButtonOnClick(self.m_widgets.btn_cancal, self._CrusadeCancel, self)
  self.m_widgets.obj_crusade:SetActive(true)
  self.m_page.m_tabSelectShip = self.m_tabParams.m_selectedIdList
  if next(self.m_tabParams.m_selectedIdList) ~= nil then
    table.insertto(self.m_page.m_SelectedBack, self.m_page.m_tabSelectShip)
  end
end

function PresetFleetSelect:_ShowFleet(go, isOn)
  local tabTemp
  self.m_showFleet = isOn
  if not isOn then
    tabTemp = Logic.shipLogic:RemoveFleetShip(self.m_page.m_tabSortHero)
  else
    tabTemp = self.m_page.m_heroData
  end
  self.m_page.m_tabSortHero = tabTemp
  self.m_page:_LoadHeroItem(tabTemp)
end

function PresetFleetSelect:_CrusadeConfirm()
  local index = Logic.presetFleetLogic:GetCurIndex()
  local length = #self.m_page.m_tabSelectShip
  if length < 1 then
    Logic.presetFleetLogic:DeleteFleet(index)
    UIHelper.Back()
  else
    Logic.presetFleetLogic:SetPresetHeros(index, self.m_page.m_tabSelectShip)
    UIHelper.Back()
  end
end

function PresetFleetSelect:_CrusadeCancel()
  local index = Logic.presetFleetLogic:GetCurIndex()
  Logic.presetFleetLogic:SetPresetHeros(index, self.m_page.m_SelectedBack)
  UIHelper.Back()
end

function PresetFleetSelect:GetShowFleet()
  return self.m_showFleet
end

function PresetFleetSelect:_CheckTodoHero(index)
  local res = {}
  for _, id in ipairs(self.m_page.m_tabSelectShip) do
    if Logic.assistNewLogic:IsSupportTodo(id, index) then
      table.insert(res, id)
    end
  end
  return res
end

function PresetFleetSelect:_TryRemoveTodoHero(heros)
  local ok
  for _, id in ipairs(heros) do
    ok = Logic.assistNewLogic:RemoveAssistTodoHero(id)
    if not ok then
      logError("remove todo hero failture,heroId:" .. id)
      return false
    end
  end
  return true
end

return PresetFleetSelect
