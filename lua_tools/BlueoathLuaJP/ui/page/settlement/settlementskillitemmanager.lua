local SettlementSkillItemManager = class("UI.Settlement.SettlementSkillItemManager")

function SettlementSkillItemManager:initialize()
  self.myItemMap = {}
  self.enemyItemMap = {}
  self:RegisterEvent()
end

function SettlementSkillItemManager:RegisterEvent()
  eventManager:RegisterEvent(LuaEvent.SettlementPSkillItemEnd, self._OnPskillEnd, self)
  eventManager:RegisterEvent(LuaEvent.SettlementMyPSkillEnd, self._OnMyPskillsEnd, self)
end

function SettlementSkillItemManager:AddItem(comp, index, item)
  if comp == SettlementComp.MY then
    if self.myItemMap[index] then
      table.insert(self.myItemMap[index], item)
    else
      self.myItemMap[index] = {item}
    end
  end
  if comp == SettlementComp.ENEMY then
    if self.enemyItemMap[index] then
      table.insert(self.enemyItemMap[index], item)
    else
      self.enemyItemMap[index] = {item}
    end
  end
end

function SettlementSkillItemManager:ForceEndAllItemAnim()
  for index, items in pairs(self.myItemMap) do
    for _, item in ipairs(items) do
      item:ForceToEnd()
    end
  end
  for index, items in pairs(self.enemyItemMap) do
    for _, item in ipairs(items) do
      item:ForceToEnd()
    end
  end
  eventManager:SendEvent(LuaEvent.SettlementEvaluation)
end

function SettlementSkillItemManager:HaveMyAnim()
  return next(self.myItemMap) ~= nil
end

function SettlementSkillItemManager:HaveEnemyAnim()
  return next(self.enemyItemMap) ~= nil
end

function SettlementSkillItemManager:PlayMyAnim(type)
  if type == SettlementPSkillPlayType.SAMETIME then
    for index, items in pairs(self.myItemMap) do
      if 0 < #items then
        items[1]:Play()
      end
    end
  else
    logError("\233\162\132\231\149\153\231\154\132\229\138\159\232\131\189,\230\156\170\229\174\158\231\142\176")
  end
end

function SettlementSkillItemManager:PlayEnemyAnim(type)
  if type == SettlementPSkillPlayType.SAMETIME then
    for index, items in pairs(self.enemyItemMap) do
      if 0 < #items then
        items[1]:Play()
      end
    end
  else
    logError("\233\162\132\231\149\153\231\154\132\229\138\159\232\131\189,\230\156\170\229\174\158\231\142\176")
  end
end

function SettlementSkillItemManager:_OnPskillEnd(param)
  local index = param.index
  local comp = param.comp
  if comp == SettlementComp.MY then
    if self.myItemMap[index] then
      for _, item in ipairs(self.myItemMap[index]) do
        item:Dispose()
      end
      self.myItemMap[index] = nil
    else
      logError("try to delect a nil settlement pskill item,index:" .. index .. "comp:" .. comp)
    end
    if next(self.myItemMap) == nil then
      eventManager:SendEvent(LuaEvent.SettlementMyPSkillEnd)
    end
  end
  if comp == SettlementComp.ENEMY then
    if self.enemyItemMap[index] then
      for _, item in ipairs(self.enemyItemMap[index]) do
        item:Dispose()
      end
      self.enemyItemMap[index] = nil
    else
      logError("try to delect a nil settlement pskill item,index:" .. index .. "comp:" .. comp)
    end
    if next(self.enemyItemMap) == nil then
      eventManager:SendEvent(LuaEvent.SettlementEvaluation)
    end
  end
end

function SettlementSkillItemManager:_OnMyPskillsEnd()
  if next(self.enemyItemMap) == nil then
    eventManager:SendEvent(LuaEvent.SettlementEvaluation)
  else
    self:PlayEnemyAnim(SettlementPSkillPlayType.SAMETIME)
  end
end

function SettlementSkillItemManager:Dispose()
  for index, items in pairs(self.myItemMap) do
    for _, item in ipairs(items) do
      item:Dispose()
    end
  end
  for index, items in pairs(self.enemyItemMap) do
    for _, item in ipairs(items) do
      item:Dispose()
    end
  end
  self.myItemMap = {}
  self.enemyItemMap = {}
end

return SettlementSkillItemManager
