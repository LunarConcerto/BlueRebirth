local AdventureService = class("service.AdventureService", Service.BaseService)
local Socket_net = require("socket_net")

function AdventureService:initialize()
  self:_InitHandlers()
end

function AdventureService:_InitHandlers()
  self:BindEvent("adventure.GetAdventure", self._GetAdventure, self)
  self:BindEvent("adventure.LevelUp", self._LevelUp, self)
  self:BindEvent("adventure.Attack", self._Attack, self)
end

function AdventureService:_GetAdventure(ret, state, err, errmsg)
  if err ~= 0 then
    logError("AdventureService _adventureInfo failed " .. errmsg)
  else
    ret = dataChangeManager:PbToLua(ret, adventure_pb.TADVENTURE)
    Data.adventureData:SetData(ret)
    self:SendLuaEvent(LuaEvent.UpdateAdventureInfo)
  end
end

function AdventureService:SendLevelUp(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("adventure.LevelUp", arg)
end

function AdventureService:_LevelUp(ret, state, err, errmsg)
  if err ~= 0 then
    logError("AdventureService _Receive failed " .. errmsg)
  else
    local numTbl = {}
    local roles = configManager.GetDataById("config_parameter", 284).arrValue
    for index = 1, #roles do
      local roleId = roles[index]
      numTbl[index] = Data.adventureData:GetLevelById(roleId)
    end
    local dotinfo = {
      info = "trpg_girllevel",
      num = numTbl
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    self:SendLuaEvent(LuaEvent.AdventureLevelUp, ret)
  end
end

function AdventureService:SendAttack(arg)
  arg = dataChangeManager:LuaToPb(arg, module_pb.TEMPTYARG)
  self:SendNetEvent("adventure.Attack", arg)
end

function AdventureService:_Attack(ret, state, err, errmsg)
  if err ~= 0 then
    logError("AdventureService _Replacement failed " .. errmsg)
  else
    local dotinfo = {
      info = "trpg_rate",
      num = Data.adventureData:GetIndex()
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    self:SendLuaEvent(LuaEvent.AdventureAttack, ret)
  end
end

return AdventureService
