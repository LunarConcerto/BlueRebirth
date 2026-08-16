local FashionData = class("data.FashionData", Data.BaseData)

function FashionData:initialize()
  self:_InitHandlers()
end

function FashionData:_InitHandlers()
  self:ResetData()
end

function FashionData:ResetData()
  self.fashionData = {}
  self.fashionReplaceReward = {}
end

function FashionData:SetData(param)
  if param then
    for k, v in pairs(param.FashionInfo) do
      if not self.fashionData[v.SfId] then
        self.fashionData[v.SfId] = {}
      end
      if v.Fashioning then
        self.fashionData[v.SfId].Fashioning = v.Fashioning
      end
      if v.SfId then
        self.fashionData[v.SfId].SfId = v.SfId
      end
      if v.FashionTid then
        if not self.fashionData[v.SfId].FashionTid then
          self.fashionData[v.SfId].FashionTid = {}
        end
        for p, q in pairs(v.FashionTid) do
          self.fashionData[v.SfId].FashionTid[q] = 1
        end
      end
    end
  end
end

function FashionData:GetFashionData()
  return self.fashionData
end

function FashionData:SetFashionReplaceReward(param)
  self.fashionReplaceReward = param
end

function FashionData:GetFashionReplaceReward()
  return self.fashionReplaceReward
end

return FashionData
