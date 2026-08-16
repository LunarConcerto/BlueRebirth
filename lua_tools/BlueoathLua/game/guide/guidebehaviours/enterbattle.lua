local EnterBattle = class("game.Guide.guidebehaviours.EnterBattle", GR.requires.BehaviourBase)

function EnterBattle:doBehaviour()
  stageMgr:Goto(EStageType.eStageSimpleBattle, self.objParam)
  self:onDone()
end

return EnterBattle
