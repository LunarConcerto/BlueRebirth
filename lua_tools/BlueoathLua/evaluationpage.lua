EvaluationPage = class("UI.Settlement.EvaluationPage", LuaUIPage)

function EvaluationPage:DoInit()
end

function EvaluationPage:DoOnOpen()
  local widget = self:GetWidgets()
  self:SetEvaluation()
  local timer = self:CreateTimer(function()
    eventManager:SendEvent(LuaEvent.EvaluationEnd, nil)
    UIHelper.ClosePage("EvaluationPage")
  end, 2.15, 1)
  timer:Start()
end

function EvaluationPage:DoOnHide()
end

function EvaluationPage:DoOnClose()
end

function EvaluationPage:SetEvaluation()
  local params = self.param
  local copyInfo = params.copyInfo
  local isTrain = Logic.copyLogic:IsTrainCopy(copyInfo.id)
  local grade = params.grade
  if isTrain then
    self:TrainResult(grade)
  else
    self:NormalResult(grade)
  end
  if grade ~= EvaGradeType.F then
    vivoSDKInterface:sendGameWin(1)
  else
    vivoSDKInterface:sendGameWin(0)
  end
end

function EvaluationPage:NormalResult(evaluation)
  local widget = self:GetWidgets()
  widget.obj_failture:SetActive(evaluation == EvaGradeType.F)
  local params = self.param
  if params.nenemy > 1 and params.hasBattleGuard == false then
    widget.obj_success_m:SetActive(evaluation ~= EvaGradeType.F)
    widget.obj_success:SetActive(false)
  else
    widget.obj_success:SetActive(evaluation ~= EvaGradeType.F)
    widget.obj_success_m:SetActive(false)
  end
  if evaluation == EvaGradeType.A or evaluation == EvaGradeType.B then
    SoundManager.Instance:PlayMusic("Win_A")
  elseif evaluation == EvaGradeType.C or evaluation == EvaGradeType.D or evaluation == EvaGradeType.E then
    SoundManager.Instance:PlayMusic("Win_B")
  elseif evaluation == EvaGradeType.S or evaluation == EvaGradeType.SS then
    SoundManager.Instance:PlayMusic("Win_S")
  elseif evaluation == EvaGradeType.F then
    SoundManager.Instance:PlayMusic("Lose")
  end
  if evaluation == EvaGradeType.F then
  else
    SoundManager.Instance:PlayAudio("Effect_battle_success")
  end
end

function EvaluationPage:TrainResult(evaluation)
  local widget = self:GetWidgets()
  local isWin = evaluation <= EvaGradeType.B
  local params = self.param
  if params.nenemy > 1 then
    widget.obj_success_m:SetActive(evaluation ~= EvaGradeType.F)
    widget.obj_success:SetActive(false)
    widget.obj_success:SetActive(false)
  else
    widget.obj_success:SetActive(isWin)
    widget.obj_success_m:SetActive(false)
  end
  widget.obj_failture:SetActive(not isWin)
  if isWin then
    SoundManager.Instance:PlayAudio("Effect_battle_success")
    SoundManager.Instance:PlayMusic("Win_S")
  else
    SoundManager.Instance:PlayMusic("Lose")
  end
end

return EvaluationPage
