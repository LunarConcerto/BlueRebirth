local EquipActivityLogic = class("logic.EquipActivityLogic")

function EquipActivityLogic:initialize()
end

function EquipActivityLogic:IsCanGetReward(equipId, equipTid)
  if equipId <= 0 then
    return false
  end
  local equipCfg = configManager.GetDataById("config_equip", equipTid)
  local power = Data.equipactivityData:GetPowerPointByEquipId(equipId)
  local isReward = Data.equipactivityData:GetIsRewardByEquipId(equipId)
  if isReward <= 0 and power >= equipCfg.max_energy then
    return true
  end
  return false
end

function EquipActivityLogic:CheckAndSendGetReward(equipId)
  local equipTid = Logic.equipLogic:GetEquipTidByEquipId(equipId)
  local equipCfg = configManager.GetDataById("config_equip", equipTid)
  local rewardConf = configManager.GetDataById("config_rewards", equipCfg.reward)
  local rewards = rewardConf.rewards
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local isOwn = false
  for i, reward in pairs(rewards) do
    if reward[1] == GoodsType.INTERACTION_BAG_ITEM and ownedItem[reward[2]] then
      isOwn = true
    end
  end
  if isOwn then
    noticeManager:ShowTip(UIHelper.GetString(7600007))
    return
  end
  Service.equipactivityService:SendGetReward({EquipId = equipId})
end

return EquipActivityLogic
