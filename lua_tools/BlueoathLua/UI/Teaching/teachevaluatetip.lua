local TeachEvaluateTip = class("UI.Teaching.TeachEvaluateTip", LuaUIPage)

function TeachEvaluateTip:DoInit()
  self.selectStar = 0
  self.teacherInfo = {}
  self.taskConf = {}
end

function TeachEvaluateTip:DoOnOpen()
  local param = self:GetParam()
  self.teacherInfo = param.teacherInfo[1]
  self.taskConf = param.taskConf
  self:_SetHintInfo()
  self.starOnTab = {
    self.tab_Widgets.obj_staron1,
    self.tab_Widgets.obj_staron2,
    self.tab_Widgets.obj_staron3
  }
  local defaultStarOn = Logic.teachingLogic:GetDefaultEvaluateStar()
  self:_ClickStar(nil, defaultStarOn)
  self.tab_Widgets.input_eva.characterLimit = Logic.teachingLogic:GetEvaUp()
end

function TeachEvaluateTip:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseTip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_mask, self._CloseTip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._SendEvaInfo, self)
  local starBtnTab = {
    self.tab_Widgets.btn_star1,
    self.tab_Widgets.btn_star2,
    self.tab_Widgets.btn_star3
  }
  for i, v in ipairs(starBtnTab) do
    UGUIEventListener.AddButtonOnClick(v, self._ClickStar, self, i)
  end
  self:RegisterEvent(LuaEvent.TeachingAppraise, self._EvalationSucceed, self)
  self:RegisterEvent(LuaEvent.TeachingAppraiseErr, self._EvalationFail, self)
end

function TeachEvaluateTip:_SetHintInfo()
  self.tab_Widgets.tx_evaContent.text = string.format(UIHelper.GetString(2200003), self.taskConf.title, Logic.teachingLogic:DisposeUname(self.teacherInfo.UserInfo.Uname))
end

function TeachEvaluateTip:_ClickStar(obj, index)
  self.selectStar = index
  for i, v in ipairs(self.starOnTab) do
    if i <= index then
      v:SetActive(true)
    else
      v:SetActive(false)
    end
  end
  local str = UIHelper.GetString(Logic.teachingLogic:GetStarEvaId(index))
  self.tab_Widgets.tx_eva.text = str
end

function TeachEvaluateTip:_CloseTip()
  UIHelper.ClosePage(self:GetName())
end

function TeachEvaluateTip:_SendEvaInfo()
  local str = ""
  if self.tab_Widgets.input_eva.text == "" then
    str = "\232\176\162\232\176\162\229\175\188\229\184\136\231\154\132\230\130\137\229\191\131\230\140\135\229\175\188\239\188\129"
  else
    str = self.tab_Widgets.input_eva.text
  end
  local sendSucceed, tips = Logic.teachingLogic:CheckEvalation(self.teacherInfo.Uid, self.selectStar, str)
  if not sendSucceed then
    noticeManager:ShowTip(tips)
  end
end

function TeachEvaluateTip:_EvalationSucceed()
  noticeManager:ShowTip("\232\175\132\228\187\183\229\183\178\229\143\145\233\128\129")
  UIHelper.ClosePage(self:GetName())
end

function TeachEvaluateTip:_EvalationFail(param)
  if param == ErrorCode.ErrChatMask then
    noticeManager:ShowTip(UIHelper.GetString(220003))
  else
    logError("Teaching.AppraiseRet Error:", param)
  end
end

function TeachEvaluateTip:DoOnHide()
end

function TeachEvaluateTip:DoOnClose()
end

return TeachEvaluateTip
