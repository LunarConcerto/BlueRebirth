local PresetFleetService = class("servic.PresetFleetService", Service.BaseService)

function PresetFleetService:initialize()
  self:_InitHandlers()
end

function PresetFleetService:_InitHandlers()
  self:BindEvent("presetfleet.SetPresetFleets", self._SetPresetFleets, self)
  self:BindEvent("presetfleet.PresetFleetsInfo", self._PresetFleetInfo, self)
end

function PresetFleetService:SetPresetFleets(arg)
  arg = dataChangeManager:LuaToPb(arg, presetfleet_pb.TSELFPRESETFLEETS)
  self:SendNetEvent("presetfleet.SetPresetFleets", arg)
end

function PresetFleetService:_SetPresetFleets(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_ChangeNameHero SetPresetFleets Failed : " .. errmsg)
    self:SendLuaEvent(LuaEvent.ChangeFleetNameError, err)
    Logic.presetFleetLogic:ReSetCorr(false)
  else
    self:SendLuaEvent(LuaEvent.ChangeNameSuccess)
    Logic.presetFleetLogic:ReSetCorr(true)
  end
end

function PresetFleetService:_PresetFleetInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" SetPresetFleets Failed : " .. errmsg)
  else
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, presetfleet_pb.TSELFPRESETFLEETS)
    Data.presetFleetData:SetPresetFleetData(info)
    local dataret = Data.presetFleetData:GetPresetFleetData()
    local numret = Data.presetFleetData:GetPresetNameNum()
    Logic.presetFleetLogic:SetFleetNIL(dataret)
    Logic.presetFleetLogic:SetNameNum(numret)
    Logic.presetFleetLogic:ReSetModi()
    self:SendLuaEvent(LuaEvent.PresetFleetInfo)
  end
end

return PresetFleetService
