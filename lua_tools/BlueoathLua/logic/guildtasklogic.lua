local GuildTaskLogic = class("Logic.GuildTaskLogic")

function GuildTaskLogic:initialize()
end

function GuildTaskLogic:GetTodayConstantRewardList()
  local todayTaskInfo = Data.guildtaskData:GetTodayTaskInfo()
  local todayConstantRewardPool = {}
  for _, taskdata in pairs(todayTaskInfo) do
    local taskId = taskdata.TaskId
    local cfg = configManager.GetDataById("config_task_guild", taskId)
    local count = todayConstantRewardPool[cfg.guild_rewards] or 0
    todayConstantRewardPool[cfg.guild_rewards] = count + taskdata.ProgressSum
    local extracount = todayConstantRewardPool[cfg.extra_reward] or 0
    todayConstantRewardPool[cfg.extra_reward] = extracount + taskdata.ExtraSum
  end
  local map = {}
  for rewardid, count in pairs(todayConstantRewardPool) do
    local items = Logic.rewardLogic:FormatRewardById(rewardid)
    for _, temp in pairs(items) do
      temp.Num = temp.Num * count
      if map[temp.Type] == nil then
        map[temp.Type] = {}
      end
      if map[temp.Type][temp.ConfigId] then
        map[temp.Type][temp.ConfigId].Num = temp.Num + map[temp.Type][temp.ConfigId].Num
      else
        map[temp.Type][temp.ConfigId] = temp
      end
    end
  end
  local ret = {}
  for _, temps in pairs(map) do
    for _, item in pairs(temps) do
      table.insert(ret, item)
    end
  end
  return ret
end

function GuildTaskLogic:GetTodayRandomRewardList()
  local todayRandomRewardInfo = Data.guildtaskData:GetTodayRandomRewardInfo()
  local todayFinishTaskCount = Data.guildtaskData:GetTodayFinishTaskCount()
  local list = {}
  for _, randomRewardData in ipairs(todayRandomRewardInfo) do
    if todayFinishTaskCount >= randomRewardData.EnterNum then
      local rewards = Logic.rewardLogic:FormatRewardById(randomRewardData.RewardId)
      for _, rewarditem in ipairs(rewards) do
        table.insert(list, rewarditem)
      end
    end
  end
  table.sort(list, function(a, b)
    local quality_a = Logic.goodsLogic:GetQuality(a.ConfigId, a.Type)
    local quality_b = Logic.goodsLogic:GetQuality(b.ConfigId, b.Type)
    if quality_a ~= quality_b then
      return quality_a > quality_b
    end
    if a.Type ~= b.Type then
      return a.Type > b.Type
    end
    if a.ConfigId ~= b.ConfigId then
      return a.ConfigId < b.ConfigId
    end
    if a.Num ~= b.Num then
      return a.Num > b.Num
    end
    return false
  end)
  return list
end

function GuildTaskLogic:GetConstantRewardList()
  local constantRewardPool = Data.guildtaskData:GetConstantRewardPool()
  local map = {}
  for _, rewarddata in ipairs(constantRewardPool) do
    local items = Logic.rewardLogic:FormatRewardById(rewarddata.RewardId)
    for _, temp in pairs(items) do
      temp.Num = temp.Num * rewarddata.RewardNum
      if map[temp.Type] == nil then
        map[temp.Type] = {}
      end
      if map[temp.Type][temp.ConfigId] then
        map[temp.Type][temp.ConfigId].Num = temp.Num + map[temp.Type][temp.ConfigId].Num
      else
        map[temp.Type][temp.ConfigId] = temp
      end
    end
  end
  local ret = {}
  for _, temps in pairs(map) do
    for _, item in pairs(temps) do
      table.insert(ret, item)
    end
  end
  table.sort(ret, function(a, b)
    local quality_a = Logic.goodsLogic:GetQuality(a.ConfigId, a.Type)
    local quality_b = Logic.goodsLogic:GetQuality(b.ConfigId, b.Type)
    if quality_a ~= quality_b then
      return quality_a > quality_b
    end
    if a.Type ~= b.Type then
      return a.Type > b.Type
    end
    if a.ConfigId ~= b.ConfigId then
      return a.ConfigId < b.ConfigId
    end
    if a.Num ~= b.Num then
      return a.Num > b.Num
    end
    return false
  end)
  return ret
end

function GuildTaskLogic:GetRandomRewardList()
  local randomRewardPool = Data.guildtaskData:GetRandomRewardPool()
  local list = {}
  for _, randomrewarddata in ipairs(randomRewardPool) do
    if randomrewarddata.GiveUid <= 0 then
      table.insert(list, randomrewarddata)
    end
  end
  table.sort(list, function(a, b)
    local quality_a = Logic.goodsLogic:GetQuality(a.ItemId, a.ItemType)
    local quality_b = Logic.goodsLogic:GetQuality(b.ItemId, b.ItemType)
    if quality_a ~= quality_b then
      return quality_a > quality_b
    end
    if a.ItemType ~= b.ItemType then
      return a.ItemType > b.ItemType
    end
    if a.ItemId ~= b.ItemId then
      return a.ItemId < b.ItemId
    end
    if a.ItemNum ~= b.ItemNum then
      return a.ItemNum > b.ItemNum
    end
    return false
  end)
  return list
end

function GuildTaskLogic:GetRandomRewardResultList()
  local randomRewardPool = Data.guildtaskData:GetRandomRewardPool()
  local list = {}
  for _, randomrewarddata in ipairs(randomRewardPool) do
    if randomrewarddata.GiveUid > 0 then
      table.insert(list, randomrewarddata)
    end
  end
  return list
end

EnumDonateItemType = {Item = 1, Equip = 2}

function GuildTaskLogic:GetDonateItemList(taskId)
  local dilist = {}
  dilist.Type = EnumDonateItemType.Item
  dilist.ItemList = {}
  dilist.EquipList = {}
  local cfg = configManager.GetDataById("config_task_guild", taskId)
  if cfg.type ~= EnumGuildTaskType.Donate then
    logError("err type ", cfg.type)
    return dilist
  end
  local getEquipTab = function()
    local equipBagInfo = Data.equipData:GetEquipData()
    local equipTab = Logic.equipLogic:GetEquipConfig(equipBagInfo, nil)
    local _, tabRes = Logic.equipLogic:EquipBagOverlay(equipTab)
    return tabRes
  end
  local getItemTab = function()
    local tabRes = {}
    local itemData = Data.bagData:GetItemData()
    for _, iteminfo in pairs(itemData) do
      if iteminfo.num > 0 then
        local itemcfg = Logic.bagLogic:GetItemByConfig(iteminfo.templateId)
        if not itemcfg.show_type or itemcfg.show_type == 0 then
          table.insert(tabRes, iteminfo)
        end
      end
    end
    return tabRes
  end
  local donateTaskType = cfg.goal[1]
  if donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Id_Item then
    if cfg.goal[2] == GoodsType.EQUIP then
      dilist.Type = EnumDonateItemType.Equip
      local tabRes = getEquipTab()
      for _, res in ipairs(tabRes) do
        if cfg.goal[3] == res.TemplateId then
          table.insert(dilist.EquipList, res)
        end
      end
    else
      dilist.Type = EnumDonateItemType.Item
      local itemData = getItemTab()
      for _, iteminfo in pairs(itemData) do
        local itemType = Logic.bagLogic:GetItemTypeByTid(iteminfo.templateId)
        if itemType == cfg.goal[2] and iteminfo.templateId == cfg.goal[3] then
          table.insert(dilist.ItemList, iteminfo)
        end
      end
    end
  elseif donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Qual_Item then
    if cfg.goal[2] == GoodsType.EQUIP then
      dilist.Type = EnumDonateItemType.Equip
      local tabRes = getEquipTab()
      for _, res in ipairs(tabRes) do
        local equipConfig = configManager.GetDataById("config_equip", res.TemplateId)
        if cfg.goal[3] == equipConfig.quality then
          table.insert(dilist.EquipList, res)
        end
      end
    else
      dilist.Type = EnumDonateItemType.Item
      local itemData = getItemTab()
      for _, iteminfo in pairs(itemData) do
        local itemcfg = Logic.bagLogic:GetItemByConfig(iteminfo.templateId)
        local itemType = Logic.bagLogic:GetItemTypeByTid(iteminfo.templateId)
        if itemType == cfg.goal[2] and itemcfg.quality == cfg.goal[3] then
          table.insert(dilist.ItemList, iteminfo)
        end
      end
    end
  elseif donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Qual_Equip then
    dilist.Type = EnumDonateItemType.Equip
    local tabRes = getEquipTab()
    for _, res in ipairs(tabRes) do
      local equipConfig = configManager.GetDataById("config_equip", res.TemplateId)
      if cfg.goal[3] == equipConfig.quality and cfg.goal[2] == equipConfig.equip_type_id then
        table.insert(dilist.EquipList, res)
      end
    end
  else
    logError("Undefined donateTaskType", donateTaskType)
    return dilist
  end
  return dilist
end

function GuildTaskLogic:GetDonateItemNum(taskId)
  local dilist = self:GetDonateItemList(taskId)
  local count = 0
  if dilist.Type == EnumDonateItemType.Item then
    for _, iteminfo in ipairs(dilist.ItemList) do
      count = count + iteminfo.num
    end
  else
    for _, equipinfo in ipairs(dilist.EquipList) do
      count = count + equipinfo.Num
    end
  end
  return count
end

function GuildTaskLogic:GetConstantRewardMemGetList()
  local memGetConstInfo = Data.guildtaskData:GetMemberGetConstantReward()
  local ret = {}
  for _, info in pairs(memGetConstInfo) do
    table.insert(ret, info)
  end
  local myUid = Data.userData:GetUserUid()
  table.sort(ret, function(a, b)
    if a.Uid == myUid then
      return true
    end
    if b.Uid == myUid then
      return false
    end
    local post_a = Data.guildData:GetPostByUid(a.Uid)
    local post_b = Data.guildData:GetPostByUid(b.Uid)
    if post_a ~= post_b then
      return post_a < post_b
    end
    if a.User.Level ~= b.User.Level then
      return a.User.Level > b.User.Level
    end
    if a.Uid ~= b.Uid then
      return a.Uid < b.Uid
    end
    return false
  end)
  return ret
end

function GuildTaskLogic:GetCurrentTaskList()
  local list = {}
  local curTasks = Data.guildtaskData:GetCurrentTasks()
  for _, taskinfo in pairs(curTasks) do
    table.insert(list, taskinfo)
  end
  table.sort(list, function(a, b)
    if a.TaskIndex ~= b.TaskIndex then
      return a.TaskIndex < b.TaskIndex
    end
    return false
  end)
  return list
end

function GuildTaskLogic:CheckDonateNotice(donateData)
  local equips = {}
  for _, item in ipairs(donateData.Items) do
    if item.ItemType == GoodsType.EQUIP and item.ItemNum > 0 then
      table.insert(equips, item.SpecialId)
    end
  end
  for _, equipid in ipairs(equips) do
    local intensify = Logic.equipLogic:IsEquipIntensify(equipid)
    if intensify then
      return true
    end
  end
  return false
end

function GuildTaskLogic:ShowGuildTaskFinishReward(taskId, taskIndex, taskNum, isExtra)
  local cfg = configManager.GetDataById("config_task_guild", taskId)
  local rewardids = {}
  for i = 1, taskNum do
    table.insert(rewardids, cfg.guild_rewards)
    if isExtra and cfg.extra_reward > 0 then
      table.insert(rewardids, cfg.extra_reward)
    end
  end
  local rewards = Logic.rewardLogic:FormatRewards(rewardids)
  local extrarewards
  local curTasks = Data.guildtaskData:GetCurrentTasks()
  local taskinfo = curTasks[taskIndex] or {}
  if taskinfo.IsFinished and 0 < taskinfo.IsFinished then
    local todayRandomPoolList = Data.guildtaskData:GetTodayRandomRewardInfo()
    local todayFinishTaskCount = Data.guildtaskData:GetTodayFinishTaskCount()
    local rid = 0
    for _, rewardinfo in ipairs(todayRandomPoolList) do
      if todayFinishTaskCount >= rewardinfo.EnterNum then
        rid = rewardinfo.RewardId
      end
    end
    if 0 < rid then
      extrarewards = Logic.rewardLogic:FormatRewards({rid})
    end
  end
  local rewardType = RewardType.GUILD_CONST_REWARD
  if extrarewards ~= nil then
    rewardType = RewardType.GUILD_RAND_REWARD
  end
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    ExtraRewards = extrarewards,
    RewardType = rewardType,
    Page = "GuildPage",
    DontMerge = true,
    ShowTweenFlag = true
  })
end

return GuildTaskLogic
