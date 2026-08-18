local BattlePassActivityService = class("service.BattlePassActivityService", Service.BaseService)

function BattlePassActivityService:initialize()
  self:_InitHandlers()
end

function BattlePassActivityService:_InitHandlers()
  self:BindEvent("activitybattlepass.GetReward", self._ReceiveGetReward, self)
  self:BindEvent("activitybattlepass.GetAllReward", self._ReceiveGetAllReward, self)
  self:BindEvent("activitybattlepass.RefreshRandomTask", self._ReceiveRefreshRandomTask, self)
  self:BindEvent("activitybattlepass.RecieveTaskReward", self._ReceiveRecieveTaskReward, self)
  self:BindEvent("activitybattlepass.BuyPassType", self._ReceiveBuyPassType, self)
  self:BindEvent("activitybattlepass.BuyPassLevel", self._ReceiveBuyPassLevel, self)
  self:BindEvent("activitybattlepass.UpdateBattlePassInfo", self._ReceiveUpdateBattlePassInfo, self)
end

function BattlePassActivityService:checkErr(name, err, errmsg, callback)
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

function BattlePassActivityService:SendGetReward(arg)
  local data = {}
  data.PassLevel = arg.PassLevel
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSGETREWARDARG)
  self:SendNetEvent("activitybattlepass.GetReward", msg, arg)
end

function BattlePassActivityService:_ReceiveGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSGETALLREWARDRET)
  local rewardids = {}
  for _, rewarddata in ipairs(data.AllPassReward) do
    local cfg = configManager.GetDataById("config_battlepass_level_activity", rewarddata.PassLevel)
    if rewarddata.PassType == BATTLEPASSACTIVITY_TYPE.ADVANCED then
      if cfg.pay_level_reward > 0 then
        table.insert(rewardids, cfg.pay_level_reward)
      end
    elseif 0 < cfg.free_level_reward then
      table.insert(rewardids, cfg.free_level_reward)
    end
  end
  local rewards = Logic.rewardLogic:FormatRewards(rewardids)
  Logic.rewardLogic:ShowCommonReward(rewards)
end

function BattlePassActivityService:SendGetAllReward(arg)
  self:SendNetEvent("activitybattlepass.GetAllReward", nil, arg)
end

function BattlePassActivityService:_ReceiveGetAllReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetAllReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSGETALLREWARDRET)
  local rewardids = {}
  for _, rewarddata in ipairs(data.AllPassReward) do
    local cfg = configManager.GetDataById("config_battlepass_level_activity", rewarddata.PassLevel)
    if rewarddata.PassType == BATTLEPASSACTIVITY_TYPE.ADVANCED then
      if cfg.pay_level_reward > 0 then
        table.insert(rewardids, cfg.pay_level_reward)
      end
    elseif 0 < cfg.free_level_reward then
      table.insert(rewardids, cfg.free_level_reward)
    end
  end
  if 0 < #rewardids then
    local rewards = Logic.rewardLogic:FormatRewards(rewardids)
    Logic.rewardLogic:ShowCommonReward(rewards)
  end
  self:SendLuaEvent(LuaEvent.BattlePassActivity_RecieveGetAllReward)
end

function BattlePassActivityService:SendRefreshRandomTask(arg)
  local data = {}
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSREFRESHRANDOMTASKARG)
  self:SendNetEvent("activitybattlepass.RefreshRandomTask", msg, arg)
end

function BattlePassActivityService:_ReceiveRefreshRandomTask(ret, state, err, errmsg)
  if self:checkErr("_ReceiveRefreshRandomTask", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.BattlePassActivity_RecieveRefreshRandTask, state)
end

function BattlePassActivityService:SendRecieveTaskReward(arg)
  local data = {}
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSRECIEVETASKREWARDARG)
  arg.LevelBef = Data.battlepassactivityData:GetPassLevel()
  self:SendNetEvent("activitybattlepass.RecieveTaskReward", msg, arg)
end

function BattlePassActivityService:_ReceiveRecieveTaskReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveRecieveTaskReward", err, errmsg) then
    return
  end
  local taskId = state.TaskId
  local bptaskcfg = configManager.GetDataById("config_battlepass_task_activity", taskId)
  local rewards = {}
  local itemreward = {}
  itemreward.Type = GoodsType.CURRENCY
  itemreward.ConfigId = CurrencyType.ACTIVITYBATTLEPASSEXP
  itemreward.Num = bptaskcfg.battlepass_exp
  table.insert(rewards, itemreward)
  
  local function callback()
    local levelAft = Data.battlepassactivityData:GetPassLevel()
    if levelAft ~= state.LevelBef then
      self:_DotLevel(levelAft)
      self:SendLuaEvent(LuaEvent.BattlePassActivity_RecieveBuyLevel)
    end
  end
  
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    DontMerge = true,
    callBack = callback
  })
end

function BattlePassActivityService:SendBuyPassType(arg)
  local data = {}
  data.BuyType = arg.BuyType
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSBUYPASSTYPEARG)
  arg.LevelBef = Data.battlepassactivityData:GetPassLevel()
  self:SendNetEvent("activitybattlepass.BuyPassType", msg, arg)
end

function BattlePassActivityService:_ReceiveBuyPassType(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyPassType", err, errmsg) then
    return
  end
  local levelAft = Data.battlepassactivityData:GetPassLevel()
  if levelAft ~= state.LevelBef then
    self:_DotLevel(levelAft)
  end
  self:SendLuaEvent(LuaEvent.BattlePassActivity_RecieveBuyType, state.BuyType)
end

function BattlePassActivityService:SendBuyPassLevel(arg)
  local data = {}
  data.BuyLevel = arg.BuyLevel
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSBUYPASSLEVELARG)
  arg.LevelBef = Data.battlepassactivityData:GetPassLevel()
  self:SendNetEvent("activitybattlepass.BuyPassLevel", msg, arg)
end

function BattlePassActivityService:_ReceiveBuyPassLevel(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyPassLevel", err, errmsg) then
    return
  end
  local levelAft = Data.battlepassactivityData:GetPassLevel()
  if levelAft ~= state.LevelBef then
    self:_DotLevel(levelAft)
  end
  self:SendLuaEvent(LuaEvent.BattlePassActivity_RecieveBuyLevel, state.BuyLevel)
end

function BattlePassActivityService:_ReceiveUpdateBattlePassInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateBattlePassActivityInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSINFORET)
  Data.battlepassactivityData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.BattlePassActivity_Update)
end

function BattlePassActivityService:_DotLevel(PassLevel)
  local Type = Data.battlepassactivityData:GetPassType()
  local dotInfo = {
    info = "battlepassactivity_levelup",
    num = PassLevel,
    type = Type
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

return BattlePassActivityService
