SettlementSkillItem = class("UI.Settlement.SettlementSkillItem")
local pskillEffPath = "effects/prefabs/ui/eff_ui_recover_blood"
local bufType = {HPTween = 3}

function SettlementSkillItem:initialize()
  self.index = 0
  self.m_data = nil
  self.m_widgets = nil
  self.m_effObj = nil
  self.m_haveBuf = false
  self.m_BufFunc = nil
  self.m_hpSeq = nil
  self.m_nextItem = nil
  self.m_bufTypeShowMap = {
    [bufType.HPTween] = self._genHPTween
  }
  self.m_timer = nil
end

function SettlementSkillItem:Init(index, widgets, data, nextitem)
  self:OnInit(index, widgets, data)
end

function SettlementSkillItem:OnInit(index, widgets, data, nextitem)
  self.m_index = index
  self.m_data = data
  self.m_widgets = widgets
  self:_GenEff()
  self.m_haveBuf, self.m_BufFunc = self:_GenBuf(bufType.HPTween)
  self.m_nextItem = nextitem
end

function SettlementSkillItem:_GenEff()
  self.m_effObj = UIHelper.CreateUIEffect(pskillEffPath, self.m_widgets.trans_skillEffBase)
  local name = Logic.settlementLogic:GetSkillName(self.m_data.pskillId)
  local transName = UIHelper.TryFindChildTransform(self.m_effObj.transform, "ui_NewBattlePage_fo_skillname_01")
  if transName ~= nil then
    UIHelper.SetTexture(name, transName.gameObject, self.m_effObj)
  else
    logError("can't find eff name obj,index:" .. self.m_index .. "pskillId:" .. self.m_data.pskillId)
  end
  local icon = Logic.settlementLogic:GetSkillHeroIcon(self.m_data.ss_id)
  local transIcon = UIHelper.TryFindChildTransform(self.m_effObj.transform, "di_hou_jiaoseskill")
  if transIcon ~= nil then
    UIHelper.SetTexture(icon, transIcon.gameObject, self.m_effObj)
  else
    logError("can't find eff name obj,index:" .. self.m_index .. "pskillId:" .. self.m_data.pskillId)
  end
  self.m_effObj:SetActive(false)
  self:_SetOtherWidgets(false)
end

function SettlementSkillItem:_SetOtherWidgets(isOn)
  self.m_widgets.obj_type:SetActive(isOn)
  self.m_widgets.img_status.gameObject:SetActive(self.m_data.showState and isOn)
end

function SettlementSkillItem:_GenBuf(type)
  local ok = false
  local seq
  if self.m_bufTypeShowMap[type] then
    ok, seq = self.m_bufTypeShowMap[type](self)
    return ok, function()
      seq:Play(true)
    end
  end
  return ok, nil
end

function SettlementSkillItem:_genHPTween()
  if self.m_data.hpStart and self.m_data.hpEnd then
    self.m_widgets.tween_hp.duration = self:_getHpTweenTime()
    self.m_widgets.tween_hp.from = self.m_data.hpStart
    self.m_widgets.tween_hp.to = self.m_data.hpEnd
    local seq = UISequence.NewSequence(self.m_widgets.tween_hp.gameObject, true)
    seq:Append(self.m_widgets.tween_hp)
    seq:AppendCallback(function()
      if self.m_nextItem then
        self.m_nextItem:Play()
      else
        self:_SetOtherWidgets(true)
        eventManager:SendEvent(LuaEvent.SettlementPSkillItemEnd, {
          index = self.m_index,
          comp = self.m_data.comp
        })
      end
    end)
    self.m_hpSeq = seq
    return IsNil(seq), seq
  else
    return false, nil
  end
end

function SettlementSkillItem:_getHpTweenTime()
  return 1
end

function SettlementSkillItem:Play()
  self.m_effObj:SetActive(true)
  local duration = Logic.settlementLogic:GetSkillBaseTime(self.m_data.pskillId)
  local timer = Timer.New(function()
    self.m_effObj:SetActive(false)
    if self.m_haveBuf and self.m_BufFunc then
      self.m_BufFunc()
    elseif self.m_nextItem then
      self.m_nextItem:Play()
    else
      self:_SetOtherWidgets(true)
      eventManager:SendEvent(LuaEvent.SettlementPSkillItemEnd, {
        index = self.m_index,
        comp = self.m_data.comp
      })
    end
  end, duration, 1, false)
  timer:Start()
  self.m_timer = timer
end

function SettlementSkillItem:ForceToEnd()
  self.m_effObj:SetActive(false)
  if self.m_hpSeq then
    self.m_hpSeq:ResetToEnd()
  end
  if self.m_nextItem then
    self.m_nextItem:ForceToEnd()
  end
end

function SettlementSkillItem:Dispose()
  UIHelper.DestroyUIEffect(self.m_effObj)
  if self.m_timer then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

return SettlementSkillItem
