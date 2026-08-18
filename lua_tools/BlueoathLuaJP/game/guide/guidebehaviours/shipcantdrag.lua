local ShipCantDrag = class("game.Guide.Guidebehaviours.ShipCantDrag", GR.requires.BehaviourBase)

function ShipCantDrag:doBehaviour()
  logError("Script set Ship Cant Drag")
  Logic.fleetLogic:SetShipCantDrag(self.objParam)
  self:onDone()
end

return ShipCantDrag
