local PresetFleetData = class("data.PresetFleetData", Data.BaseData)

function PresetFleetData:initialize()
  self:_InitHandlers()
end

function PresetFleetData:_InitHandlers()
  self:ResetData()
end

function PresetFleetData:ResetData()
  self.m_data = {}
end

function PresetFleetData:SetPresetFleetData(data)
  self.m_data = data
  local dot = self.m_data.redDot
  if dot == 1 then
    Logic.presetFleetLogic:IsnoDotSend()
  end
end

function PresetFleetData:GetPresetFleetData()
  local arrData = self.m_data.presetfleet
  return arrData
end

function PresetFleetData:GetPresetNameNum()
  local num = self.m_data.NameNum
  return num
end

function PresetFleetData:GetRedDotValue()
  local dot = self.m_data.redDot
  return dot
end

return PresetFleetData
