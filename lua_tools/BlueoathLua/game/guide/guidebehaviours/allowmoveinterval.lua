local AllowMoveInterval = class("game.Guide.guidebehaviours.AllowMoveInterval", GR.requires.BehaviourBase)

function AllowMoveInterval:doBehaviour()
  self:onDone()
  self.timer = nil
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetFleetCanMove, true)
  GR.guideHub.doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetNpcCanMove, false)
  local ntime = self.objParam
  local nTotalTime = 0
  local funcCB = function()
    nTotalTime = nTotalTime + Time.deltaTime
    if nTotalTime >= ntime then
      GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetFleetCanMove, false)
      GR.guideHub.doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetNpcCanMove, true)
      if self.timer ~= nil then
        self.timer:Stop()
        self.timer = nil
      end
    else
      local curStep = GR.guideManager:getCurStep()
      if curStep ~= nil and (curStep.nId == 1490 or curStep.nId == 1500) then
        if self.timer ~= nil then
          self.timer:Stop()
          self.timer = nil
        end
        GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetFleetCanMove, true)
        GR.guideHub.doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.SetNpcCanMove, true)
      end
    end
  end
  self.timer = Timer.New(funcCB, 0.1, -1)
  self.timer:Start()
end

return AllowMoveInterval
