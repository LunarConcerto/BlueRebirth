local SetFleetPageCanMove = class("game.Guide.guidebehaviours.SetFleetPageCanMove", GR.requires.BehaviourBase)

function SetFleetPageCanMove:doBehaviour()
  local strParentPage = "FleetPage"
  self.strPageName = "CommonHeroPage"
  self.bCanMove = self.objParam
  self.strPath = "MainRoot/FleetPage/obj_subParent/CommonHeroPage/bottom_bg/scrollRect"
  if UIHelper.IsPageOpen(strParentPage, self.strPageName) then
    self:_SetCanMove()
  else
    eventManager:RegisterEvent(LuaEvent.OpenPage, self._onPageOpen, self)
  end
end

function SetFleetPageCanMove:_onPageOpen(strPageName)
  if strName == self.strPageName then
    self:_SetCanMove()
  end
end

function SetFleetPageCanMove:_SetCanMove()
  eventManager:UnregisterEvent(LuaEvent.OpenPage, self._onPageOpen)
  local tblParam = {}
  tblParam.path = self.strPath
  GR.guideHub:getGuideCachedata():SetFleetCanDrag(self.bCanMove)
  if self.bCanMove then
    tblParam.moveType = 1
  else
    tblParam.moveType = 2
  end
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetScrollRectMoveType, tblParam)
  self:onDone()
end

return SetFleetPageCanMove
