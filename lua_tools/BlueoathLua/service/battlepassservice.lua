local BattlePassService = class("service.BattlePassService", Service.BaseService)

function BattlePassService:initialize()
  self:_InitHandlers()
end

function BattlePassService:_InitHandlers()
  self:BindEvent("battlepass.GetReward", self._ReceiveGetReward, self)
  self:BindEvent("battlepass.GetAllReward", self._ReceiveGetAllReward, self)
  self:BindEvent("battlepass.RefreshRandomTask", self._ReceiveRefreshRandomTask, self)
  self:BindEvent("battlepass.RecieveTaskReward", self._ReceiveRecieveTaskReward, self)
  self:BindEvent("battlepass.BuyPassType", self._ReceiveBuyPassType, self)
  self:BindEvent("battlepass.BuyPassLevel", self._ReceiveBuyPassLevel, self)
  self:BindEvent("battlepass.UpdateBattlePassInfo", self._ReceiveUpdateBattlePassInfo, self)
end

function BattlePassService:checkErr(name, err, errmsg, callback)
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

function BattlePassService:SendGetReward(arg)
  local data = {}
  data.PassLevel = arg.PassLevel
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSGETREWARDARG)
  self:SendNetEvent("battlepass.GetReward", msg, arg)
end

function BattlePassService:_ReceiveGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSGETALLREWARDRET)
  local rewardids = {}
  for _, rewarddata in ipairs(data.AllPassReward) do
    local cfg = configManager.GetDataById("config_battlepass_level", rewarddata.PassLevel)
    if rewarddata.PassType == BATTLEPASS_TYPE.ADVANCED then
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

function BattlePassService:SendGetAllReward(arg)
  self:SendNetEvent("battlepass.GetAllReward", nil, arg)
end

function BattlePassService:_ReceiveGetAllReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetAllReward", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSGETALLREWARDRET)
  local rewardids = {}
  for _, rewarddata in ipairs(data.AllPassReward) do
    local cfg = configManager.GetDataById("config_battlepass_level", rewarddata.PassLevel)
    if rewarddata.PassType == BATTLEPASS_TYPE.ADVANCED then
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
  self:SendLuaEvent(LuaEvent.BattlePass_RecieveGetAllReward)
end

function BattlePassService:SendRefreshRandomTask(arg)
  local data = {}
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSREFRESHRANDOMTASKARG)
  self:SendNetEvent("battlepass.RefreshRandomTask", msg, arg)
end

function BattlePassService:_ReceiveRefreshRandomTask(ret, state, err, errmsg)
  if self:checkErr("_ReceiveRefreshRandomTask", err, errmsg) then
    return
  end
  self:SendLuaEvent(LuaEvent.BattlePass_RecieveRefreshRandTask, state)
end

function BattlePassService:SendRecieveTaskReward(arg)
  local data = {}
  data.TaskId = arg.TaskId
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSRECIEVETASKREWARDARG)
  arg.LevelBef = Data.battlepassData:GetPassLevel()
  self:SendNetEvent("battlepass.RecieveTaskReward", msg, arg)
end

function BattlePassService:_ReceiveRecieveTaskReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveRecieveTaskReward", err, errmsg) then
    return
  end
  local taskId = state.TaskId
  local bptaskcfg = configManager.GetDataById("config_battlepass_task", taskId)
  local rewards = {}
  local itemreward = {}
  itemreward.Type = GoodsType.CURRENCY
  itemreward.ConfigId = CurrencyType.BATTLEPASSEXP
  itemreward.Num = bptaskcfg.battlepass_exp
  table.insert(rewards, itemreward)
  local callback = function()
    local levelAft = Data.battlepassData:GetPassLevel()
    if levelAft ~= state.LevelBef then
      self:_DotLevel(levelAft)
      self:SendLuaEvent(LuaEvent.BattlePass_RecieveBuyLevel)
    end
  end
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    DontMerge = true,
    callBack = callback
  })
end

function BattlePassService:SendBuyPassType(arg)
  local data = {}
  data.BuyType = arg.BuyType
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSBUYPASSTYPEARG)
  arg.LevelBef = Data.battlepassData:GetPassLevel()
  self:SendNetEvent("battlepass.BuyPassType", msg, arg)
end

function BattlePassService:_ReceiveBuyPassType(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyPassType", err, errmsg) then
    return
  end
  local levelAft = Data.battlepassData:GetPassLevel()
  if levelAft ~= state.LevelBef then
    self:_DotLevel(levelAft)
  end
  self:SendLuaEvent(LuaEvent.BattlePass_RecieveBuyType, state.BuyType)
end

function BattlePassService:SendBuyPassLevel(arg)
  local data = {}
  data.BuyLevel = arg.BuyLevel
  local msg = dataChangeManager:LuaToPb(data, battlepass_pb.TBATTLEPASSBUYPASSLEVELARG)
  arg.LevelBef = Data.battlepassData:GetPassLevel()
  self:SendNetEvent("battlepass.BuyPassLevel", msg, arg)
end

function BattlePassService:_ReceiveBuyPassLevel(ret, state, err, errmsg)
  if self:checkErr("_ReceiveBuyPassLevel", err, errmsg) then
    return
  end
  local levelAft = Data.battlepassData:GetPassLevel()
  if levelAft ~= state.LevelBef then
    self:_DotLevel(levelAft)
  end
  self:SendLuaEvent(LuaEvent.BattlePass_RecieveBuyLevel, state.BuyLevel)
end

function BattlePassService:_ReceiveUpdateBattlePassInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateBattlePassInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, battlepass_pb.TBATTLEPASSINFORET)
  Data.battlepassData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.BattlePass_Update)
end

function BattlePassService:_DotLevel(PassLevel)
  local Type = Data.battlepassData:GetPassType()
  local dotInfo = {
    info = "battlepass_levelup",
    num = PassLevel,
    type = Type
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

return BattlePassService
