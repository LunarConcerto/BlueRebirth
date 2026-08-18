local SetShipSortDefault = class("game.Guide.guidebehaviours.SetShipSortDefault", GR.requires.BehaviourBase)

function SetShipSortDefault:doBehaviour()
  local tblParam = {
    false,
    true,
    {
      {},
      1
    }
  }
  Logic.selectedShipPageLogic:SetSelectedData(tblParam)
  self:onDone()
end

return SetShipSortDefault
