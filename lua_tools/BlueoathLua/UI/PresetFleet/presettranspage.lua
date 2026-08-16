local PresetTransPage = class("UI.PresetFleet.PresetTransPage")

function PresetTransPage:Init(page, fleetType)
  self.page = page
  self.fleetType = fleetType
  self.fleetSave = false
end

function PresetTransPage:OnDrag(tabPart, shipInfo, clickIndex)
  if self.page.m_popObj ~= nil then
    GameObject.Destroy(self.page.m_popObj)
    if self.btnDrag ~= nil then
      UGUIEventListener.ClearDragListener(self.btnDrag)
      self.btnDrag = nil
    end
  end
  if npcAssistFleetMgr:IsNpcHeroId(shipInfo.HeroId) then
    noticeManager:OpenTipPage(self.page, 921001)
    return
  end
  self.page.m_popObj = nil
  self.page.m_popShip = shipInfo
  self.page.m_clickPos = clickIndex
  self.page.m_tabWidgets.obj_float:SetActive(true)
  self.page.m_popObj = UIHelper.CreateGameObject(tabPart.gameObject, self.page.m_tabWidgets.obj_float.transform)
  self.page.m_tabWidgets.obj_float.transform.position = tabPart.obj_hero.transform.position
  self.page.m_popObj.transform.pivot = Vector2.New(0.5, 0.5)
  self.page.m_popObj.transform.position = Vector3.New(tabPart.objSelf.transform.position.x - 10, tabPart.objSelf.transform.position.y - 10, 0)
  self:AddCardDrag(tabPart.objCopy, self.page.m_popObj.transform)
  self.btnDrag = tabPart.objCopy
end

function PresetTransPage:AddCardDrag(objDrag, dragTran)
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
    UGUIEventListener.ClearDragListener(objDrag)
    local camera = eventData.pressEventCamera
    local dragPos = eventData.position
    self:_UpdateFleet(dragPos, camera)
    self.btnDrag = nil
  end, nil, nil)
  self.page.isClickCard = true
end

function PresetTransPage:_DragCard(objPos, camera)
  self.page.isClickCard = false
  local widgets = self.page:GetWidgets()
  local pos = self:GetFleetPos(objPos, camera)
  if widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
    self.page.lastPos = pos
  end
end

function PresetTransPage:GetFleetPos(objPos, camera)
  for i, v in ipairs(self.page.m_rectTranArr) do
    if v:RectangleContainsScreenPoint(objPos, camera) then
      return i
    end
  end
  return nil
end

function PresetTransPage:_UpdateFleet(objPos, camera)
  if self.page.m_popObj ~= nil then
    self:_SetFleetPos(objPos, camera)
    GameObject.Destroy(self.page.m_popObj)
    self.page.m_tabWidgets.obj_float:SetActive(false)
    self.page.m_popObj = nil
  end
end

function PresetTransPage:_SetFleetPos(objPos, camera)
  local widgets = self.page:GetWidgets()
  local heroInfo = self.page.m_tabFleetData[self.page.nToggleIndex].heroInfo
  if not widgets.rectTran_dragArea:RectangleContainsScreenPoint(objPos, camera) then
    return
  else
    self.page.curPos = self:GetFleetPos(objPos, camera)
    self:SetPosShip()
  end
end

function PresetTransPage:SetPosShip()
  local heroInfo = self.page.m_tabFleetData[self.page.nToggleIndex].heroInfo
  if heroInfo[self.page.curPos] ~= nil then
    self.page.m_bNeedSave = true
    local befShip = heroInfo[self.page.curPos]
    if npcAssistFleetMgr:IsNpcHeroId(befShip) then
      noticeManager:OpenTipPage(self.page, 921001)
      return
    end
    heroInfo[self.page.curPos] = self.page.m_popShip.HeroId
    heroInfo[self.page.m_clickPos] = befShip
    SoundManager.Instance:PlayAudio("UI_Tween_FleetPage_0006")
  else
    noticeManager:OpenTipPage(self.page, 921002)
  end
  self.page:_CreateFleetInfo(self.page.nToggleIndex)
end

function PresetTransPage:ClickCard()
  if self.page.isClickCard then
    if self.page.m_popObj ~= nil then
      GameObject.Destroy(self.page.m_popObj)
      self.page.m_popObj = nil
    end
    self.page.m_tabWidgets.obj_left:SetActive(false)
    self.page.m_tabWidgets.obj_right:SetActive(false)
    Logic.fleetLogic:SetSelectTog(self.page.nToggleIndex)
    self:SaveFleetData()
    local param = {
      fleetType = self.fleetType,
      copyInfo = {
        copyId = self.page.nCopyId,
        chapterId = self.page.nChapterId,
        exercises = self.page.m_battleMode,
        copyImp = self.page.copyImp
      }
    }
    if Logic.towerLogic:IsTowerType(self.fleetType) then
      param.subType = FleetSubType.Tower
    else
      param.isLevelOpen = true
    end
    self.page:CloseTopPage()
    UIHelper.OpenPage("FleetPage", param)
  end
  self.page.isClickCard = true
end

function PresetTransPage:OnFleetClose()
  self.page:OpenTopPage("LevelDetailsPage", 1, "\229\133\179\229\141\161\232\175\166\230\131\133", self, true)
  self.page.m_tabWidgets.obj_left:SetActive(true)
  self.page.m_tabWidgets.obj_right:SetActive(true)
  if not self.fleetSave then
    self.page:_InitNpcAssist()
    self.page.copyImp:CreateFleet()
  end
end

function LevelFleetPage:OnFleetChange()
  local data = Data.fleetData:GetFleetData(self.fleetType)
  self.page.m_tabFleetData = clone(data)
  self.page:_InitNpcAssist()
  self.page.copyImp:CreateFleet()
  self.fleetSave = false
end

function PresetTransPage:SaveFleetData()
  local chapterId = self.page.nChapterId
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  if chapterConfig.class_type == ChapterType.PlotCopy or not self.page.m_bNeedSave then
    return
  end
  local tacticsTab = {
    tactics = self.page.m_tabFleetData
  }
  Service.fleetService:SendSetFleet(tacticsTab)
  self.page.m_bNeedSave = false
end

function PresetTransPage:SetSaveSign()
  self.fleetSave = true
end

return PresetTransPage
