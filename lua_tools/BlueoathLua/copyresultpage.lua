CopyResultPage = class("UI.Settlement.CopyResultPage", LuaUIPage)

function CopyResultPage:DoInit()
  self.m_copyRet = nil
end

function CopyResultPage:DoOnOpen()
  Service.cacheDataService:ClearLocalCacheId()
  local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
  local widget = self:GetWidgets()
  local param = self.param
  local copyPassRet = Logic.settlementLogic:GetCopyPassRet()
  self.m_copyRet = copyPassRet
  if copyPassRet and copyPassRet.Grade then
    param.bSuccess = copyPassRet.Grade < EvaGradeType.F
    Logic.settlementLogic:SetCopyPassRet(nil)
  end
  widget.obj_rootSuccess:SetActive(param.bSuccess)
  widget.obj_rootFail:SetActive(not param.bSuccess)
  local obj_root = widget.obj_root
  local clip = obj_root:GetComponentInChildren(UnityEngine_Animation.GetClassType()).clip
  local extraT = 1.5
  local chapter = Logic.copyLogic:GetCopyChapter(copyInfo.CopyId)
  local hideBeStrong = chapter and (chapter.class_type == ChapterType.Train or chapter.class_type == ChapterType.TrainAdvance) or false
  if param.bSuccess then
    if self:_CanAutoExe() then
      self.m_closeCo = self:CreateTimer(function()
        self:_SuccessCB()
      end, clip.length + extraT, 1, false)
      self:StartTimer(self.m_closeCo)
    end
  elseif not hideBeStrong then
    UIHelper.OpenPage("BeStrongPage", {
      onClose = function()
        UIHelper.ClosePage(self:GetName())
        param.callback()
        param.callback = nil
      end,
      fleetType = chapter.tactic_type
    })
    eventManager:SendEvent(LuaEvent.BattleFail, copyInfo.CopyId)
  else
    self.tab_Widgets.btnLeave.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnLeave, self.OnBtnLeaveClicked, self)
    self.tab_Widgets.btnAgain.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAgain, self.OnBtnAgainClicked, self)
  end
  eventManager:SendEvent(LuaEvent.ExistBattleManual)
  self:_ShowAEquipPoinTip()
end

function CopyResultPage:OnBtnLeaveClicked()
  local param = self.param
  UIHelper.ClosePage(self:GetName())
  param.callback()
end

function CopyResultPage:OnBtnAgainClicked()
  prepareBattleMgr:RestartBattle()
end

function CopyResultPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.obj_activitytips, self._ShowAEquipPointReward, self)
  UGUIEventListener.AddButtonOnClick(widgets.obj_mask, self._SuccessCB, self)
  self:RegisterEvent(LuaEvent.AEQUIP_RefreshData, self._ShowAEquipPoinTip, self)
end

function CopyResultPage:_SuccessCB()
  if self then
    local copyInfo = Logic.copyLogic:GetAttackCopyInfo()
    local param = self.param
    local copyPassRet = self.m_copyRet
    local chaseCheck = false
    local chapter = Logic.copyLogic:GetCopyChapter(copyInfo.CopyId)
    local hideBeStrong = chapter and (chapter.class_type == ChapterType.Train or chapter.class_type == ChapterType.TrainAdvance) or false
    local isStarTrain = hideBeStrong
    local isGoodsCopy = chapter and chapter.class_type == ChapterType.GoodsCopy or false
    local isWalkDog = chapter and chapter.class_type == ChapterType.WalkDog or false
    local isEquipTest = chapter and chapter.class_type == ChapterType.EquipTestCopy or false
    local isEquipNewTest = chapter and chapter.class_type == ChapterType.EquipNewTestCopy or false
    local isSecretCopy = chapter and chapter.class_type == ChapterType.ActivitySecretCopy or false
    local isActivityBoss = chapter and chapter.class_type == ChapterType.BossCopy or false
    UIHelper.ClosePage("CopyResultPage")
    if copyInfo.CopyId ~= nil then
      chaseCheck = Data.copyData:IsFirstOpenRunById(copyInfo.CopyId)
    end
    if chaseCheck then
      UIHelper.OpenPage("ChaseTipPage", param)
    elseif isStarTrain then
      UIHelper.OpenPage("TrainStarPage", {
        copyId = copyInfo.CopyId,
        callback = param.callback,
        starLevel = copyPassRet.StarLv,
        passTime = copyPassRet.PassTime,
        evaluate = copyPassRet.Evaluate
      })
    elseif isGoodsCopy then
      UIHelper.OpenPage("GoodsCopyResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback
      })
    elseif isWalkDog then
      UIHelper.OpenPage("ActivityBattleResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback
      })
    elseif isEquipTest then
      UIHelper.OpenPage("EquipTestResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback
      })
    elseif isEquipNewTest then
      UIHelper.OpenPage("EquipTestResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback
      })
    elseif isSecretCopy then
      UIHelper.OpenPage("ActivityBattleCopyResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback
      })
    elseif isActivityBoss then
      UIHelper.OpenPage("ActivityBattleCopyResultPage", {
        result = copyPassRet.ExReward,
        callback = param.callback,
        isActivityBoss = true
      })
    else
      local ok, value = Logic.settlementLogic:GetActivityParam()
      if ok then
        value.callback = param.callback
        UIHelper.OpenPage("AcRewardPage", value)
      else
        param.callback()
        param.callback = nil
      end
    end
  end
end

function CopyResultPage:_CanAutoExe()
  return Logic.settlementLogic:ShowAEquipPointTip() == 0
end

function CopyResultPage:_ShowAEquipPoinTip()
  local total = Logic.settlementLogic:ShowAEquipPointTip()
  local widgets = self:GetWidgets()
  widgets.obj_activitytips:SetActive(0 < total)
  UIHelper.SetText(widgets.tx_activitytips, string.format(UIHelper.GetString(7600000), total))
end

function CopyResultPage:_ShowAEquipPointReward()
  UIHelper.OpenPage("ActivityGetEnergyPage")
end

function CopyResultPage:DoOnHide()
end

function CopyResultPage:DoOnClose()
  self.m_closeCo = nil
end

return CopyResultPage
