local BagData = class("data.BagData", Data.BaseData)

function BagData:initialize()
  self:_InitHandlers()
end

function BagData:_InitHandlers()
  self:ResetData()
end

function BagData:ResetData()
  self.bagInfoMap = {}
  self.itemInfoMap = {}
  self.useInfoMap = {}
  self.periodItemMap = {}
  self.oldmap = {}
  self.newmap = {}
end

function BagData:SetData(param)
  if next(param) == nil then
    return
  end
  self.oldmap = clone(self.itemInfoMap)
  if param.bagType == BagType.ITEM_BAG then
    for _, v in ipairs(param.bagInfo) do
      if v.num ~= 0 then
        self.itemInfoMap[v.templateId] = v
      else
        self.itemInfoMap[v.templateId] = nil
      end
    end
    self.newmap = clone(self.itemInfoMap)
    self.useInfoMap = {}
    if next(param.useInfo) ~= nil then
      for _, v in ipairs(param.useInfo) do
        self.useInfoMap[v.templateId] = v.reward
      end
    end
  end
  if param.bagType ~= nil then
    self.bagInfoMap[param.bagType] = param.bagSize
  end
end

function BagData:SetPeriodData(param)
  if param == nil or next(param) == nil then
    return
  end
  for _, v in ipairs(param.periodBagInfo) do
    if v.templateId ~= 0 and createTime ~= 0 then
      self.periodItemMap[v.itemId] = v
    else
      self.periodItemMap[v.itemId] = nil
    end
  end
end

function BagData:GetItemData()
  return SetReadOnlyMeta(self.itemInfoMap)
end

function BagData:GetPeriodItemData()
  return SetReadOnlyMeta(self.periodItemMap)
end

function BagData:GetBagData(bagType)
  return SetReadOnlyMeta(self.bagInfoMap[bagType])
end

function BagData:GetItemById(tId)
  return SetReadOnlyMeta(self:GetItemData()[tId])
end

function BagData:GetItemNum(tid)
  return self:GetItemData()[tid] and self:GetItemData()[tid].num or 0
end

function BagData:UseInfo(tId)
  return SetReadOnlyMeta(self.useInfoMap[tId])
end

function BagData:GetUpdateMap()
  local tmp = {}
  for k, v in pairs(self.newmap) do
    if self.oldmap[k] == nil then
      tmp[k] = v
    end
  end
  return tmp
end

return BagData
