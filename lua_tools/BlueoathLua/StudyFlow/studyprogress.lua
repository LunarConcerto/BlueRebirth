local StudyProgress = class("StudyFlow")

function StudyProgress:initialize()
end

function StudyProgress:SetData(data, part)
  self.m_data = data
  self.m_part = part
  UGUIEventListener.AddButtonOnClick(part.btn_cancel, self.OnClickCancel, self)
  UGUIEventListener.AddButtonOnClick(part.btn_speedup, self.OnClickSpeedUp, self)
end

function StudyProgress:OnClose()
  if self.m_timer and self.m_timer.running then
    self.m_timer:Stop()
  end
end

function StudyProgress:OnClickSpeedUp(go)
  local textbookArr = Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
  if #textbookArr == 0 then
    noticeManager:ShowMsgBox(UIHelper.GetString(160012))
    return false
  end
  UIHelper.OpenPage("SkillSpeedUpPage", self.m_data)
end

function StudyProgress:OnClickCancel(go)
  local heroId = self.m_data.heroId
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.CancelStudy, heroId)
end

function StudyProgress:Display()
  self:SetSkillName()
  self:SetSkillDesc()
  self:SetSkillIcon()
  self:SetHeroIcon()
  local leftTime = self.m_data.finishTime - time.getSvrTime()
  self:CreateCountDown(leftTime)
  self:SetLv()
  self:SetExp()
end

function StudyProgress:SetSkillName()
  local displayInfo = self.m_data
  local part = self.m_part
  local color = TalentColor[displayInfo.pskillType]
  UIHelper.SetTextColor(part.txt_skillName, displayInfo.pskillName, color)
end

function StudyProgress:SetSkillDesc()
  local displayInfo = self.m_data
  local part = self.m_part
  UIHelper.SetText(part.txt_skillDesc, displayInfo.pskillDesc)
end

function StudyProgress:SetSkillIcon()
  local displayInfo = self.m_data
  local part = self.m_part
  UIHelper.SetImage(part.img_skillIcon, displayInfo.pskillIcon)
end

function StudyProgress:SetHeroIcon()
  local displayInfo = self.m_data
  local part = self.m_part
  ShipCardItem:LoadVerticalCard(displayInfo.heroId, part.part_card)
end

function StudyProgress:SetLeftTime()
  local displayInfo = self.m_data
  local part = self.m_part
  local left = displayInfo.finishTime - time.getSvrTime()
  if left < 0 then
    eventManager:SendEvent(LuaEvent.FinishStudyCheck, self.m_data.heroId)
    if self.m_timer and self.m_timer.running then
      self.m_timer:Stop()
    end
  end
  left = 0 < left and left or 0
  local strLeftTime = UIHelper.GetCountDownStr(left)
  if 0 <= left then
    part.txt_leftTime.gameObject:SetActive(true)
    part.txt_leftTimeValue.gameObject:SetActive(true)
    UIHelper.SetText(part.txt_leftTimeValue, strLeftTime)
  else
    part.txt_leftTime.gameObject:SetActive(false)
    part.txt_leftTimeValue.gameObject:SetActive(false)
  end
end

function StudyProgress:SetLv()
  local displayInfo = self.m_data
  local part = self.m_part
  UIHelper.SetText(part.txt_skillLv, displayInfo.pskillLv)
end

function StudyProgress:SetExp()
  local displayInfo = self.m_data
  local part = self.m_part
  local currentExp = Mathf.ToInt(displayInfo.curExp - displayInfo.lastLvExp)
  local maxExp = displayInfo.nextLvExp - displayInfo.lastLvExp
  local strExp = string.format("%s/%s", currentExp, maxExp)
  UIHelper.SetText(part.txt_skillExp, strExp)
  part.sld_exp.value = currentExp / maxExp
end

function StudyProgress:CreateCountDown(leftTime)
  self.m_timer = self.m_timer or Timer.New()
  local timer = self.m_timer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:SetLeftTime()
  end, 1, -1)
  timer:Start()
  self:SetLeftTime()
end

function StudyProgress:GenExpAddSeq(ret)
  local displayInfo = self.m_data
  local part = self.m_part
  local expBefore, expAfter = ret.ExpBefore, ret.ExpAfter
  local beforeLv = Logic.shipLogic:GetPSkillLvByExp(expBefore)
  local afterLv = Logic.shipLogic:GetPSkillLvByExp(expAfter)
  local time = Logic.studyLogic:GetEndTweenTime()
  local exp = expAfter - expBefore
  local shipName = displayInfo.shipName
  local shipQuality = displayInfo.shipQuality
  local skillName = displayInfo.pskillName
  local skillQuality = Logic.shipLogic:GetPSkillType(displayInfo.pskillId)
  local skillColor = TalentColor[skillQuality]
  local shipColor = ShipQualityColor[shipQuality]
  if beforeLv > afterLv then
    logError("pskill study fatal:beforeLv greater then afterLv,hero:" .. shipName .. "pskill" .. skillName .. "beforeLv:" .. beforeLv .. "afterLv:" .. afterLv)
    return false, nil
  end
  local seq = UISequence.NewSequence(part.sld_exp.gameObject, true)
  local max, from, to, fromExp, toExp, lastTotalExp, nextTotalExp = 0, 0, 0, 0, 0, 0, 0
  for i = beforeLv, afterLv do
    max = configManager.GetDataById("config_ship_talent_upgrade_exp", i).exp
    lastTotalExp = Logic.shipLogic:GetTotalExpByPSkillLv(i - 1)
    fromExp = Mathf.Max(lastTotalExp, expBefore)
    nextTotalExp = Logic.shipLogic:GetTotalExpByPSkillLv(i)
    endExp = Mathf.Min(nextTotalExp, expAfter)
    from = (fromExp - lastTotalExp) / max
    to = (endExp - lastTotalExp) / max
    seq:Append(part.sld_exp:TweenValue(from, to, time))
  end
  seq:AppendCallback(function()
    local showtip = Logic.studyLogic:CheckStudyGoOnTip()
    if not showtip then
      Logic.studyLogic:SetSendEnd(true)
      eventManager:SendEvent(LuaEvent.StudyEndTweenFinish, displayInfo.heroId)
      return
    end
    local str = ""
    if beforeLv < afterLv then
      str = string.format(UIHelper.GetString(160010), UIHelper.SetColor(shipName, shipColor), UIHelper.SetColor(skillName, skillColor), Mathf.ToInt(exp), beforeLv, afterLv)
    else
      str = string.format(UIHelper.GetString(160019), UIHelper.SetColor(shipName, shipColor), UIHelper.SetColor(skillName, skillColor), Mathf.ToInt(exp))
    end
    local contentTg = UIHelper.GetString(931002)
    local tgIsON = false
    local playerPrefsKey = PlayerPrefsKey.StudyGoOn
    if playerPrefsKey then
      tgIsON = PlayerPrefs.GetBool(playerPrefsKey, false)
    end
    local callBackConfirm = function(isOn)
      local playerPrefsKey = PlayerPrefsKey.StudyGoOn
      if playerPrefsKey then
        PlayerPrefs.SetBool(playerPrefsKey, isOn)
        PlayerPrefs.SetInt(playerPrefsKey .. "Time", os.time())
      end
      local textbookArr = Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE)
      if #textbookArr < 1 then
        noticeManager:ShowTip("\230\151\160\229\143\175\231\148\168\230\149\153\230\157\144")
        return
      end
      local flow = Logic.studyLogic:GetStudyFlow()
      flow:Input(flow.InputType.ContinueLearn, ret)
      eventManager:RegisterEvent(LuaEvent.StudyGoOnSelectBookCancel, function()
        Logic.studyLogic:SetSendEnd(true)
        eventManager:SendEvent(LuaEvent.StudyEndTweenFinish, displayInfo.heroId)
      end)
      UIHelper.OpenPage("SelectTextbookPage", SelectTextbookPage.GenDisplayData(textbookArr, ret.PSkillId))
    end
    local callBackCancel = function()
      Logic.studyLogic:SetSendEnd(true)
      eventManager:SendEvent(LuaEvent.StudyEndTweenFinish, displayInfo.heroId)
    end
    noticeManager:ShowSuperNotice(str, contentTg, true, tgIsON, callBackConfirm, callBackCancel)
  end)
  return seq ~= nil, seq
end

return StudyProgress
