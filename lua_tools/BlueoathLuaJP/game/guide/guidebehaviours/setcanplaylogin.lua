local SetCanPlayLogin = class("game.Guide.guidebehaviours.SetCanPlayLogin", GR.requires.BehaviourBase)

function SetCanPlayLogin:doBehaviour()
  self.bCanPlayLogin = self.objParam
  local objStageMain = stageMgr:GetStageObj(EStageType.eStageMain)
  if objStageMain == nil then
    self:onDone()
    logError("objStageMain is nil return")
    return
  end
  local states = objStageMain.states
  if states == nil then
    self:onDone()
    logError("states is nil return")
    return
  end
  local objState = states.mStateMap[HomeStateID.MAIN]
  if objState == nil then
    self:onDone()
    logError("HomeStateID.MAIN is nil return")
    return
  end
  objState:setCanPlayLogin(self.bCanPlayLogin)
  self:onDone()
end

return SetCanPlayLogin
