local EquipActivityService = class("service.EquipActivityService", Service.BaseService)

function EquipActivityService:initialize()
  self:_InitHandlers()
end

function EquipActivityService:_InitHandlers()
  self:BindEvent("equipactivity.GetReward", self._ReceiveGetReward, self)
  self:BindEvent("equipactivity.UpdateEquipActivityInfo", self._ReceiveUpdateEquipActivityInfo, self)
end

function EquipActivityService:checkErr(name, err, errmsg, callback)
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

function EquipActivityService:SendGetReward(arg)
  local data = {}
  data.EquipId = arg.EquipId
  local msg = dataChangeManager:LuaToPb(data, equipactivity_pb.TEQUIPACTIVITYGETREWARDARG)
  self:SendNetEvent("equipactivity.GetReward", msg, arg)
end

function EquipActivityService:_ReceiveGetReward(ret, state, err, errmsg)
  if self:checkErr("_ReceiveGetReward", err, errmsg) then
    return
  end
  local eaInfo = Data.equipactivityData:GetInfoByEquipId(state.EquipId)
  local equipCfg = configManager.GetDataById("config_equip", eaInfo.TemplateId)
  local rewards = Logic.rewardLogic:FormatRewards({
    equipCfg.reward
  })
  UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards, DontMerge = true})
end

function EquipActivityService:_ReceiveUpdateEquipActivityInfo(ret, state, err, errmsg)
  if self:checkErr("_ReceiveUpdateEquipActivityInfo", err, errmsg) then
    return
  end
  local data = dataChangeManager:PbToLua(ret, equipactivity_pb.TEQUIPACTIVITYINFO)
  Data.equipactivityData:UpdateData(data)
  self:SendLuaEvent(LuaEvent.AEQUIP_RefreshData)
end

return EquipActivityService
