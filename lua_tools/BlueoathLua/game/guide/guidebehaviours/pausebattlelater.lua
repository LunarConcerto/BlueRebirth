local PauseBattleLater = class("game.Guide.Guidebehaviours.PauseBattleLater", GR.requires.BehaviourBase)

function PauseBattleLater:onInit()
  self.waitFrame = 3
  self.mFrameTimer = nil
end

function PauseBattleLater:doBehaviour()
  local funcCB = function()
    self:PauseGame()
  end
  if self.mFrameTimer ~= nil then
    self.mFrameTimer:Stop()
    self.mFrameTimer = nil
  end
  self.mFrameTimer = FrameTimer.New(funcCB, 5, 1)
  self.mFrameTimer:Start()
  self:onDone()
end

function PauseBattleLater:PauseGame()
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.PAUSE_BATTLE, true)
  self.mFrameTimer:Stop()
end

return PauseBattleLater
