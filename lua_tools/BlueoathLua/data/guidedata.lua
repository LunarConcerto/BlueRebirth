local GuideData = class("data.GuideData", Data.BaseData)

function GuideData:initialize()
  self:ResetData()
end

function GuideData:ResetData()
  self.funcIdList = {}
  self.plotIdList = {}
  self.setting = {}
  self.m_setmap = {}
  self.guideEvent = {}
end

function GuideData:SetGuideData(param)
  for i = 1, #param.FuncList do
    self.funcIdList[tonumber(param.FuncList[i])] = 1
  end
  for i = 1, #param.PlotList do
    self.plotIdList[tonumber(param.PlotList[i])] = 1
  end
  self:SetSetting(param.Setting)
  self:_SetGuideEventData(param.Event)
end

function GuideData:SetSetting(sets)
  if sets and 0 < #sets then
    for _, v in ipairs(sets) do
      self.m_setmap[v.Key] = v.Value
    end
  end
end

function GuideData:_SetGuideEventData(tblEvent)
  for nIndex, tblValue in pairs(tblEvent) do
    local nType = tblValue.Key
    local objParam = tblValue.Value
    self.guideEvent[nType] = objParam
  end
end

function GuideData:FuncIsOpen(funcId)
  return self.funcIdList[tonumber(funcId)] ~= nil
end

function GuideData:SetFuncId(funcId)
  self.funcIdList[funcId] = 1
end

function GuideData:PlotIsGot(plotId)
  return self.plotIdList[plotId] ~= nil
end

function GuideData:SetPlotId(plotId)
  self.plotIdList[plotId] = 1
end

function GuideData:GetGuideEvent()
  return self.guideEvent
end

function GuideData:GetSettingByKey(key)
  return self.m_setmap[key]
end

return GuideData
