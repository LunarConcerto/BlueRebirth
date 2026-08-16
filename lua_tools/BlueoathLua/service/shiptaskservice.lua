local ShipTaskService = class("service.ShipTaskService", Service.BaseService)

function ShipTaskService:initialize()
  self:_InitHandlers()
end

function ShipTaskService:_InitHandlers()
  self:BindEvent("shiptask.GetShipTaskReward", self._ReceiveGetShipTaskReward, self)
  self:BindEvent("shiptask.GetAchievementReward", self._ReceiveGetAchievementReward, self)
  self:BindEvent("shiptask.SetCurrentShip", self._ReceiveSetCurrentShip, self)
  self:BindEvent("shiptask.UpdateShipTaskInfo", self._ReceiveUpdateShipTaskInfo, self)
  self:BindEvent("shiptask.UpdateShipTaskActivityInfo", self._ReceiveUpdateShipTaskActivityInfo, self)
  self:BindEvent("shiptask.UpdateAllShipTaskInfo", self._ReceiveAllShipInfo, self)
end

function ShipTaskService:checkErr(name, err, errmsg, callback)
  logDebug("on ", name, err, errmsg)
  if err ~= 0 then
    if 0 < err then
      local str = UIHelper.GetString(err)
      noticeManager:ShowTip(str)
    end
    if err < 0 then
      logError(name .. " error", tostring(errmsg))
      return true
    end
    if callback ~= nil then
      callback()
    end
    return true
  end
  return false
end

function ShipTaskService:SendGetShipTaskReward(arg)
  local data = {}
  data.ShipTid = arg.ShipTid
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, shiptask_pb.TSTSHIPTASKARG)
  self:SendNetEvent("shiptask.GetShipTaskReward", msg, arg)
end

function ShipTaskService:_ReceiveGetShipTaskReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetShipTaskReward", err, errmsg) then
    return
  end
  local cfg = configManager.GetDataById("config_testship_task", state.TaskId)
  noticeManager:ShowTip("\232\142\183\229\190\151\231\137\185\232\174\173\231\130\185\230\149\176" .. cfg.test_point .. "\231\130\185")
end

function ShipTaskService:GetAllInfo()
  self:SendNetEvent("shiptask.GetAllShipData")
end

function ShipTaskService:_ReceiveAllShipInfo(ret, state, err, errmsg)
  if err == 0 then
    local info = dataChangeManager:PbToLua(ret, shiptask_pb.TALLSHIPTASKINFORET)
    Data.shiptaskData:SetAchieveData(info)
  else
    logError("_ReceiveAllShipInfo error")
  end
end

function ShipTaskService:SendGetAchievementReward(arg)
  local data = {}
  data.ShipTid = arg.ShipTid
  data.STAid = arg.STAid
  local msg = dataChangeManager:LuaToPb(data, shiptask_pb.TSTACHIEVEMENTREWARDARG)
  self:SendNetEvent("shiptask.GetAchievementReward", msg, arg)
end

function ShipTaskService:_ReceiveGetAchievementReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetAchievementReward", err, errmsg) then
    return
  end
  local cfg = configManager.GetDataById("config_testship_reward", state.STAid)
  local rewards = Logic.rewardLogic:FormatRewardById(cfg.reward)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    Page = "GuildPage",
    DontMerge = true
  })
end

function ShipTaskService:SendSetCurrentShip(arg)
  local data = {}
  data.ShipTid = arg.ShipTid
  data.HeroTemplateId = arg.HeroTemplateId
  local msg = dataChangeManager:LuaToPb(data, shiptask_pb.TSTSHIPARG)
  self:SendNetEvent("shiptask.SetCurrentShip", msg, arg)
end

function ShipTaskService:_ReceiveSetCurrentShip(ret, state, err, errmsg)
  if self:checkErr("_ReceiveSetCurrentShip", err, errmsg) then
    return
  end
end

function ShipTaskService:_ReceiveUpdateShipTaskInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateShipTaskInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, shiptask_pb.TSHIPTASKINFORET)
  Data.shiptaskData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.ShipTask_RefreshData)
  self:GetAllInfo()
end

function ShipTaskService:_ReceiveUpdateShipTaskActivityInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateShipTaskActivityInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, shiptask_pb.TSHIPTASKACTIVITYINFORET)
  Data.shiptaskData:UpdateActivityData(data)
  self:SendLuaEvent(LuaEvent.ShipTask_RefreshData)
end

return ShipTaskService
