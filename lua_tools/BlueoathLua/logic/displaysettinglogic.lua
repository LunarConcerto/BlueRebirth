local DisplaySettingLogic = class("logic.DisplaySettingLogic")

function DisplaySettingLogic:initialize()
  eventManager:RegisterEvent(LuaEvent.UpdateGMAnswer, self._UpdateGMAnswer, self)
end

function DisplaySettingLogic:HaveNewAnswer()
  return self.haveAnswer
end

function DisplaySettingLogic:_UpdateGMAnswer(state)
  self:SetAnswerState(state)
end

function DisplaySettingLogic:SetAnswerState(state)
  self.haveAnswer = state
  eventManager:SendEvent(LuaEvent.RedDotGMAnswerUpdate)
end

return DisplaySettingLogic
