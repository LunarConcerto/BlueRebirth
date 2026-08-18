local HeadData = class("data.HeadData", Data.BaseData)

function HeadData:initialize()
  self.ShipHeadBuyData = {}
  self.ShipHeadUnlockData = {}
  self.ShipHeadRedDotData = {}
end

function HeadData:SetData(data)
end

function HeadData:SetDefaultRedDot()
  if self.redRecordTab == nil then
    local uid = Data.userData:GetUserUid()
    local redRecord = PlayerPrefs.GetString(uid .. "ShipHeadRedDot")
    self.redRecordTab = string.split(redRecord, ":")
  end
  local profileCfg = Logic.headLogic:GetAllShipCfg()
  for _, v in pairs(profileCfg) do
    if v.shownew ~= nil and v.shownew > 0 and #self.redRecordTab > 0 then
      local show = self:CheckRecordReaDot(v.id)
      if show then
        if self.ShipHeadRedDotData[v.belongshipid] == nil then
          self.ShipHeadRedDotData[v.belongshipid] = {}
        end
        self.ShipHeadRedDotData[v.belongshipid][v.id] = true
      end
    end
  end
end

function HeadData:SetRedRecord()
  if #self.redRecordTab == 0 then
    return
  end
  local str = ""
  for _, v in pairs(self.redRecordTab) do
    if str == nil then
      str = v
    else
      str = str .. ":" .. v
    end
  end
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetString(uid .. "ShipHeadRedDot", str)
end

function HeadData:CheckRecordReaDot(pId)
  for _, v in pairs(self.redRecordTab) do
    if tonumber(v) == pId then
      return false
    end
  end
  return true
end

function HeadData:UpdateShipHeadBuyCount(data)
  self.ShipHeadBuyData[data.ShipFleetId] = data.Count
end

function HeadData:GetHeadBuyCountBySFId(id)
  if self.ShipHeadBuyData[id] == nil then
    return 0
  end
  return self.ShipHeadBuyData[id]
end

function HeadData:UpdateShipHeadBuy(data)
end

function HeadData:UpdateShipHeadSet(data)
end

function HeadData:UpdateShipHeadUnlockedList(data)
  for _, data1 in pairs(data.UnlockedList) do
    for _, v in pairs(data1.ProfileID) do
      self.ShipHeadUnlockData[v] = true
    end
  end
end

function HeadData:GetShipHeadUnlockState(profileID)
  return self.ShipHeadUnlockData[profileID]
end

function HeadData:UpdateShipHeadUnlock(data)
  self.ShipHeadUnlockData[data.ProfileID] = true
  local config = configManager.GetDataById("config_profile", data.ProfileID)
  if self.ShipHeadRedDotData[config.belongshipid] == nil then
    self.ShipHeadRedDotData[config.belongshipid] = {}
  end
  self.ShipHeadRedDotData[config.belongshipid][data.ProfileID] = true
end

function HeadData:GetRedDot()
  for _, shipData in pairs(self.ShipHeadRedDotData) do
    for _, v in pairs(shipData) do
      if v == true then
        return true
      end
    end
  end
end

function HeadData:GetRedDotBySFId(sfId)
  if self.ShipHeadRedDotData[sfId] == nil then
    return false
  end
  return next(self.ShipHeadRedDotData[sfId])
end

function HeadData:GetRedDotBySFIdAndPId(sfId, pId)
  if self.ShipHeadRedDotData[sfId] == nil then
    return false
  end
  return self.ShipHeadRedDotData[sfId][pId]
end

function HeadData:DetailRedDotBySFIdAndPId(sfId, pId)
  if self.ShipHeadRedDotData[sfId] == nil then
    return
  end
  self.ShipHeadRedDotData[sfId][pId] = nil
end

function HeadData:DetailRedDotRecord(pId)
  local str = tostring(pId)
  for _, v in pairs(self.redRecordTab) do
    if str == v then
      return
    end
  end
  self.redRecordTab[#self.redRecordTab + 1] = str
end

function HeadData:GetSortHeadList(shipHeadCfg)
  table.sort(shipHeadCfg, function(data1, data2)
    local unlock1 = self.ShipHeadUnlockData[data1.id]
    local unlock2 = self.ShipHeadUnlockData[data2.id]
    if unlock1 ~= unlock2 then
      return unlock1
    end
    if data1.type ~= data2.type then
      return data1.type < data2.type
    end
    return data1.id < data2.type
  end)
  return shipHeadCfg
end

return HeadData
