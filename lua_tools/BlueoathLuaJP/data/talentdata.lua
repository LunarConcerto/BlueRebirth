local TalentData = class("data.TalentData", Data.BaseData)

function TalentData:initialize()
  self.talentActiveData = {}
  self.subTalentData = {}
  self.shipAttrData = {}
  self.shipLvData = {}
end

function TalentData:UpdateTalentTreeListData(data)
  if data == nil then
    return
  end
  if data.TalentList then
    self.talentActiveData = {}
    self.subTalentData = {}
    for _, v in pairs(data.TalentList) do
      self.subTalentData[v.TalentId] = v
      local talentCfg = configManager.GetDataById("config_talent", v.TalentId)
      local mainTalentId = talentCfg.belongtalent
      if mainTalentId == 0 then
        mainTalentId = v.TalentId
      end
      self.talentActiveData[mainTalentId] = v.TalentId
    end
  end
end

function TalentData:UpdateTalentChange(data)
  if data.TalentDataList then
    for _, v in pairs(data.TalentDataList) do
      self:UpdateSelectTalent(v)
    end
    eventManager:SendEvent(LuaEvent.UpdateTalentChange)
  end
end

function TalentData:UpdateSelectTalent(data)
  local talentCfg = configManager.GetDataById("config_talent", data.TalentId)
  local mainTalentId = talentCfg.belongtalent
  if mainTalentId == 0 then
    mainTalentId = data.TalentId
  end
  local curTalentId = self.talentActiveData[mainTalentId]
  if curTalentId then
    self.subTalentData[curTalentId] = nil
  end
  self.subTalentData[data.TalentId] = data
  self.talentActiveData[mainTalentId] = data.TalentId
end

function TalentData:UpdateTalentData(data)
  if data.TalentData then
    self:UpdateSelectTalent(data.TalentData)
  end
end

function TalentData:GetCurSubTalentId(mainTalentId)
  local id = self.talentActiveData[mainTalentId]
  if id then
    local data = self.subTalentData[id]
    if data.IsOperate == 0 then
      local previousId = Logic.talentLogic:GetPreviousTalentId(id)
      return previousId
    else
      return id
    end
  else
    logError("TalentData:GetCurSubTalent \230\156\141\229\138\161\229\153\168\231\188\186\229\176\145mainTalentId[%d]\231\154\132\228\191\161\230\129\175", mainTalentId)
    return 0
  end
end

function TalentData:GetCurTalentBySubTalentId(subTalentId)
  return self.subTalentData[subTalentId]
end

function TalentData:UpdateShipTypeAttrData(data)
  if data then
    for _, v in pairs(data.AttrDataList) do
      if not self.shipAttrData[data.ShipType] then
        self.shipAttrData[data.ShipType] = {}
      end
      local propCfg = configManager.GetDataById("config_prop", v.AttrId)
      local s = 1
      if propCfg.prop_value_type == 0 then
        s = 0.01
      end
      self.shipAttrData[data.ShipType][v.AttrId] = v.Value * s
    end
  end
end

function TalentData:UpdateEffectDataLevelUp(data)
  if data then
    self.shipLvData[data.ShipType] = data.LevelUp
  end
end

function TalentData:UpdateEffectDataAll(data)
  if data == nil then
    return
  end
  if data.AttrList then
    for _, v in pairs(data.AttrList) do
      self:UpdateShipTypeAttrData(v)
    end
  end
  if data.LevelUpList then
    for _, v in pairs(data.LevelUpList) do
      self:UpdateEffectDataLevelUp(v)
    end
  end
end

function TalentData:GetTalentAttrByType(shipType)
  return self.shipAttrData[shipType]
end

function TalentData:GetTalentAttrBySMId(sm_id)
  local shipConfig = configManager.GetDataById("config_ship_main", sm_id)
  local shipInfoCfg = configManager.GetDataById("config_ship_info", shipConfig.ship_info_id)
  local shipType = shipInfoCfg.ship_type
  local talentAttr = self:GetTalentAttrByType(shipType)
  if talentAttr then
    return talentAttr
  end
  return {}
end

function TalentData:GetTalentLvByType(shipType)
  return self.shipLvData[shipType] or 0
end

return TalentData
