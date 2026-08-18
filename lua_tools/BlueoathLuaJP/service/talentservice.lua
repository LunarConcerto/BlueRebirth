local TalentService = class("service.TalentService", Service.BaseService)

function TalentService:initialize()
  self:InitHandlers()
end

function TalentService:InitHandlers()
  self:BindEvent("talentTree.TalentTreeAllList", self.UpdateTalentTreeAllList, self)
  self:BindEvent("talentTree.TalentChange", self.UpdateTalentChange, self)
  self:BindEvent("talentTree.GetTalentData", self.UpdateGetTalentData, self)
  self:BindEvent("talentTree.UnLockTalent", self.UnLockTalent, self)
  self:BindEvent("talentTree.UpgradeTalent", self.UpgradeTalent, self)
  self:BindEvent("talentTree.EffectDataAttr", self.UpdateShipTypeAttrData, self)
  self:BindEvent("talentTree.EffectDataLevelUp", self.UpdateEffectDataLevelUp, self)
  self:BindEvent("talentTree.EffectDataAll", self.UpdateEffectDataAll, self)
end

function TalentService:UpdateTalentTreeAllList(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:GetTalentTreeAllList error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TTALENTTREEALLLIST)
    Data.talentData:UpdateTalentTreeListData(data)
  end
end

function TalentService:UpdateTalentChange(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateTalentChange error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TTALENTCHANGE)
    Data.talentData:UpdateTalentChange(data)
  end
end

function TalentService:SendGetTalentData(talentId)
  local arg = {TalentId = talentId}
  arg = dataChangeManager:LuaToPb(arg, talenttree_pb.TGETTALENTDATAARG)
  self:SendNetEvent("talentTree.GetTalentData", arg)
end

function TalentService:UpdateGetTalentData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateGetTalentData error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TGETTALENTDATARET)
    Data.talentData:UpdateTalentData(data)
  end
end

function TalentService:SendUnLockTalent(talentId)
  local msg = {TalentId = talentId}
  local arg = dataChangeManager:LuaToPb(msg, talenttree_pb.TUNLOCKTALENTARG)
  self:SendNetEvent("talentTree.UnLockTalent", arg, msg)
end

function TalentService:UnLockTalent(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateGetTalentData error[%d]", err)
  else
    state.Type = 0
    self:SendLuaEvent(LuaEvent.UpdateTalentSuccess, state)
  end
end

function TalentService:SendUpgradeTalent(talentId)
  local msg = {TalentId = talentId}
  local arg = dataChangeManager:LuaToPb(msg, talenttree_pb.TUPGRADETALENTARG)
  self:SendNetEvent("talentTree.UpgradeTalent", arg, msg)
end

function TalentService:UpgradeTalent(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateGetTalentData error[%d]", err)
  else
    state.Type = 1
    self:SendLuaEvent(LuaEvent.UpdateTalentSuccess, state)
  end
end

function TalentService:UpdateShipTypeAttrData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateShipTypeAttrData error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TSHIPTYPEATTRDATA)
    Data.talentData:UpdateShipTypeAttrData(data)
  end
end

function TalentService:UpdateEffectDataLevelUp(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateEffectDataLevelUp error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TSHIPTYPELEVELUPDATA)
    Data.talentData:UpdateEffectDataLevelUp(data)
  end
end

function TalentService:UpdateEffectDataAll(ret, state, err, errmsg)
  if err ~= 0 then
    logError("TalentService:UpdateEffectDataAll error[%d]", err)
  else
    local data = dataChangeManager:PbToLua(ret, talenttree_pb.TTALENTEFFECTDATA)
    Data.talentData:UpdateEffectDataAll(data)
  end
end

return TalentService
