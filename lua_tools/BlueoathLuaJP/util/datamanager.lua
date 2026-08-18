local DataManager = class("util.DataManager")

function DataManager:initialize()
end

function DataManager:ResetAllData()
  for k, v in pairs(Data) do
    if type(v) == "table" and v.ResetData then
      v:ResetData()
    end
  end
  for k, v in pairs(Logic) do
    if type(v) == "table" and v.ResetData then
      v:ResetData()
    end
  end
end

return DataManager
