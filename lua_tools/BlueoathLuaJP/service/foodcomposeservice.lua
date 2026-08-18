local FoodComposeService = class("servic.FoodComposeService", Service.BaseService)

function FoodComposeService:initialize()
  self:_InitHandlers()
end

function FoodComposeService:_InitHandlers()
  self:BindEvent("foodCompose.GetFoodCompose", self._GetFoodCompose, self)
  self:BindEvent("foodCompose.FoodCompose", self._FoodComposeRet, self)
end

function FoodComposeService:_GetFoodCompose(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetFoodComposeData failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, foodCompose_pb.TFOODCOMPOSEINFORET)
    Data.foodComposeData:SetData(info)
    self:SendLuaEvent(LuaEvent.GetFoodComposeMsg)
  end
end

function FoodComposeService:_FoodComposeRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_GetFoodComposeRet failed " .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, foodCompose_pb.TFOODCOMPOSERET)
    self:SendLuaEvent(LuaEvent.FoodComposeRewardRet, info)
  end
end

function FoodComposeService:SendGetFoodComposeData(arg)
  self:SendNetEvent("foodCompose.GetFoodComposeData")
end

function FoodComposeService:SendFoodCompose(arg, state)
  arg = dataChangeManager:LuaToPb(arg, foodCompose_pb.TFOODCOMPOSEARG)
  self:SendNetEvent("foodCompose.FoodCompose", arg, state)
end

return FoodComposeService
