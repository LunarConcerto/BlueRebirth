local SetBagSortAll = class("game.Guide.guidebehaviours.SetBagSortAll", GR.requires.BehaviourBase)

function SetBagSortAll:doBehaviour()
  Logic.bagLogic:SetSceenIndex(0)
  self:onDone()
end

return SetBagSortAll
