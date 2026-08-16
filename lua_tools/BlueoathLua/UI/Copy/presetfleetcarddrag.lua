local PresetFleetCardDrag = class("UI.Copy.PresetFleetCardDrag")

function PresetFleetCardDrag:Init(page, fleetType)
  self.page = page
  self.fleetType = fleetType
  self.fleetSave = false
end

function PresetFleetCardDrag:OnDrag(tabPart, shipInfo, clickIndex, fleetType, fleetIndex, page, originObj)
  self.page = page
  if self.page.m_popObj ~= nil then
    GameObject.Destroy(self.page.m_popObj)
    if self.btnDrag ~= nil then
      UGUIEventListener.ClearDragListener(self.btnDrag)
      self.btnDrag = nil
    end
  end
  self.page.m_popObj = nil
  self.page.m_popShip = shipInfo
  self.page.m_clickPos = clickIndex
  self.m_fleetType = fleetType
  self.m_fleetIndex = fleetIndex
  self.page.m_widgets.obj_float:SetActive(true)
  self.page.m_popObj = UIHelper.CreateGameObject(tabPart.gameObject, self.page.m_widgets.obj_float.transform)
  self.page.m_widgets.obj_float.transform.position = tabPart.obj_hero.transform.position
  self.page.m_popObj.transform.pivot = Vector2.New(0.5, 0.5)
  self.page.m_popObj.transform.position = Vector3.New(tabPart.objSelf.transform.position.x - 10, tabPart.objSelf.transform.position.y - 10, 0)
  CSUIHelper.SetParent(originObj.transform, self.page.pageWidgets.obj_outDrag.gameObject.transform)
  self:AddCardDrag(originObj, self.page.m_popObj.transform)
  self.btnDrag = tabPart.objCopy
end

function PresetFleetCardDrag:AddCardDrag(objDrag, dragTran)
  UGUIEventListener.AddOnDrag(objDrag, function(go, eventData)
    if self.page.m_popObj == nil then
      return
    end
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local worldPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    dragTran.position = worldPos
    self:_DragCard(dragPos, camera)
  end, nil, nil)
  UGUIEventListener.AddOnEndDrag(objDrag, function(go, eventData)
    local camera = eventData.pressEventCamera
    local dragPos = eventData.position
    self:_UpdateFleet(dragPos, camera)
    self.btnDrag = nil
  end, nil, nil)
  self.page.isClickCard = true
end

function PresetFleetCardDrag:_DragCard(objPos, camera)
  self.page.isClickCard = false
  local widgets = self.page:GetWidgets()
  local pos = self:GetFleetPos(objPos, camera)
  if widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
    self.page.lastPos = pos
  end
end

function PresetFleetCardDrag:GetFleetPos(objPos, camera)
  for i, v in ipairs(self.page.m_rectTranArr) do
    if v:RectangleContainsScreenPoint(objPos, camera) then
      return i
    end
  end
  return nil
end

function PresetFleetCardDrag:_UpdateFleet(objPos, camera)
  if self.page.m_popObj ~= nil then
    GameObject.Destroy(self.page.m_popObj)
    self.page.m_widgets.obj_float:SetActive(false)
    self.page.m_popObj = nil
  end
  self:_SetFleetPos(objPos, camera)
end

function PresetFleetCardDrag:_SetFleetPos(objPos, camera)
  local widgets = self.page:GetWidgets()
  if not widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
    self:_ChangeShipEnd()
    return
  else
    self.page.curPos = self:GetFleetPos(objPos, camera)
    self:SetPosShip()
  end
end

function PresetFleetCardDrag:SetPosShip()
  local heroInfo = Logic.presetFleetLogic:GetDataByIndex(self.m_fleetIndex).heroList
  if heroInfo[self.page.curPos] ~= nil and self.page.m_popShip then
    self.page.m_bNeedSave = true
    local befShip = heroInfo[self.page.curPos]
    heroInfo[self.page.curPos] = self.page.m_popShip.HeroId
    heroInfo[self.page.m_clickPos] = befShip
    SoundManager.Instance:PlayAudio("UI_Tween_FleetPage_0006")
  else
  end
  Logic.presetFleetLogic:SetPresetHeros(self.m_fleetIndex, heroInfo)
  self:_ChangeShipEnd()
end

function PresetFleetCardDrag:ClickCard(index, herosData, isClickCard)
  if isClickCard then
    if self.page.m_popObj ~= nil then
      GameObject.Destroy(self.page.m_popObj)
      self.page.m_popObj = nil
    end
    local param = {m_index = index, m_data = herosData}
    self.page:_OnClickHero(param)
  end
  self.page.isClickCard = true
end

function PresetFleetCardDrag:_ChangeShipEnd()
  for i = 0, self.page.pageWidgets.obj_outDrag.transform.childCount - 1 do
    local child = self.page.pageWidgets.obj_outDrag.transform:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
end

function PresetFleetCardDrag:SaveFleetData()
  self.page.m_bNeedSave = false
end

return PresetFleetCardDrag
