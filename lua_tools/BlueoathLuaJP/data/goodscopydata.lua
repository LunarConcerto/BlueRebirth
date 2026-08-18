local GoodsCopyData = class("data.GoodsCopyData", Data.BaseData)

function GoodsCopyData:initialize()
  self:ResetData()
end

function GoodsCopyData:ResetData()
  self.copyRecordMap = {}
  self.heroMaxDamage = {}
end

function GoodsCopyData:SetData(param)
  if param.InfoList then
    for k, info in pairs(param.InfoList) do
      local record = self.copyRecordMap[info.CopyId]
      if record then
        if info.TodayMaxDamage then
          record.TodayMaxDamage = info.TodayMaxDamage
        end
        if info.Percent then
          record.Percent = info.Percent
        end
        if info.TodayGetGoods then
          record.TodayGetGoods = info.TodayGetGoods
        end
      else
        self.copyRecordMap[info.CopyId] = info
      end
    end
  end
  if param.HeroDamageList then
    for i, heroDamage in ipairs(param.HeroDamageList) do
      self.heroMaxDamage[heroDamage.ShipFleetId] = heroDamage.MaxDamage
    end
  end
end

function GoodsCopyData:GetDataByCopyId(copyId)
  local data = self.copyRecordMap[copyId]
  if not data then
    data = {}
    data.CopyId = copyId
    data.TodayMaxDamage = 0
    data.TodayGetGoods = 0
    self.copyRecordMap[copyId] = data
  end
  return data
end

function GoodsCopyData:GetGoodsCopyDamages()
  local damageData = {}
  local count = 0
  for copyId, data in pairs(self.copyRecordMap) do
    if 0 < copyId then
      count = count + 1
      table.insert(damageData, data)
    end
  end
  return damageData, count
end

function GoodsCopyData:GetGoodsCopyDatas()
  return self.copyRecordMap
end

function GoodsCopyData:GetRankData()
  return self:GetDataByCopyId(0)
end

function GoodsCopyData:GetMaxDamage(shipFleetId)
  return self.heroMaxDamage[shipFleetId] or 0
end

return GoodsCopyData
