local TalentLogic = class("logic.TalentLogic")

function TalentLogic:initialize()
  self:ResetTalentSequence()
end

function TalentLogic:ResetTalentSequence()
  self.subMainTalents = {}
  local talentMainCfgs = configManager.GetData("config_talentmain")
  for _, mainCfg in pairs(talentMainCfgs) do
    for _, talentId in pairs(mainCfg.talentlist) do
      if self.subMainTalents[talentId] == nil then
        self.subMainTalents[talentId] = {}
      end
      local nextId = self:GetNextTalentById(talentId, talentId)
      while 0 < nextId do
        table.insert(self.subMainTalents[talentId], nextId)
        nextId = self:GetNextTalentById(nextId, talentId)
      end
    end
  end
  self.previousTalentId = {}
  local talentCfgs = configManager.GetData("config_talent")
  for _, v in pairs(talentCfgs) do
    if v.nexttalent ~= 0 then
      self.previousTalentId[v.nexttalent] = v.id
    end
  end
end

function TalentLogic:GetNextTalentById(talentId, mainTalentId)
  local talentCfg = configManager.GetDataById("config_talent", talentId)
  if talentCfg.belongtalent ~= 0 and talentCfg.belongtalent ~= mainTalentId then
    logError("\231\173\150\229\136\146 config_talent\232\161\168 talentId[%d] belongtalent[%d] Error", talentId, mainTalentId)
  end
  return talentCfg.nexttalent
end

function TalentLogic:GetSubTalentsByMainId(talentId)
  return self.subMainTalents[talentId]
end

function TalentLogic:GetSubTalentMainId(talentId)
  local talentCfg = configManager.GetDataById("config_talent", talentId)
  return talentCfg.belongtalent
end

function TalentLogic:GetSubTalentLv(talentId)
  local lv = 1
  local mainId = self:GetSubTalentMainId(talentId)
  if self.subMainTalents[mainId] == nil or next(self.subMainTalents[mainId]) == nil then
    return lv
  end
  for k, v in pairs(self.subMainTalents[mainId]) do
    if v == talentId then
      lv = k + 1
      break
    end
  end
  return lv
end

function TalentLogic:GetMainTalentMaxLv(mainTalentId)
  if self.subMainTalents[mainTalentId] then
    return #self.subMainTalents[mainTalentId] + 1
  end
  return 1
end

function TalentLogic:GetPreviousTalentId(id)
  if self.previousTalentId[id] then
    return self.previousTalentId[id]
  end
  return id
end

return TalentLogic
