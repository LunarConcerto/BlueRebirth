local PlayAudio = class("game.Guide.guidebehaviours.PlayAudio", GR.requires.BehaviourBase)

function PlayAudio:doBehaviour()
  local nCurStage = stageMgr:GetCurStageType()
  if nCurStage ~= EStageType.eStageLogin then
    self:doImp()
  else
    eventManager:RegisterEvent(LuaEvent.LoadingTranslateClose, self.doImp, self)
  end
end

function PlayAudio:doImp(nNextState)
  if nNextState == EStageType.eStageLogin then
    return
  end
  eventManager:UnregisterEvent(LuaEvent.LoadingTranslateClose, self.doImp)
  local tblParam = self.objParam
  local strAudioName = tblParam[1]
  local bPlay = tblParam[2]
  if bPlay then
    SoundManager.Instance:PlayAudio(strAudioName)
  else
    SoundManager.Instance:StopAudio(strAudioName)
  end
  self:onDone()
end

return PlayAudio
