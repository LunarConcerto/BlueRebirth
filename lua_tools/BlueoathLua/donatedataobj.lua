DonateDataObj = class("UI.Guild.GuildTask.DonateDataObj")

function DonateDataObj:initialize(taskdata)
  self.mTaskData = taskdata
  self.TaskIndex = taskdata.TaskIndex
  self.TaskId = taskdata.TaskId
  self.Items = {}
  self.TaskNum = 1
  local taskId = taskdata.TaskId
  local cfg = configManager.GetDataById("config_task_guild", taskId)
  if cfg.type ~= EnumGuildTaskType.Donate then
    logError("err type ", cfg.type)
    return
  end
  self.mCfg = cfg
end

function DonateDataObj:Init()
end

function DonateDataObj:CheckTaskNum(taskNum)
  if taskNum < 1 then
    logError("taskNum err", taskNum)
    return false
  end
  return true
end

function DonateDataObj:SetTaskNum(taskNum)
  if not self:CheckTaskNum(taskNum) then
    return
  end
  local cfg = self.mCfg
  local itemcount = cfg.goal[4] * taskNum
  if itemcount == #self.Items then
    return
  end
  local items = {}
  for i = 1, itemcount do
    local item = self.Items[i]
    if item == nil then
      item = {}
      item.ItemType = cfg.goal[2]
      item.ItemId = cfg.goal[3]
      item.ItemNum = 0
    end
    table.insert(items, item)
  end
  self.Items = items
  self.TaskNum = taskNum
end

function DonateDataObj:GetTarDonateNum()
  local cfg = self.mCfg
  local tarnum = cfg.goal[4] * self.TaskNum
  return tarnum
end

function DonateDataObj:GetTxtTips()
end

function DonateDataObj:CheckHaveNum()
  local cfg = self.mCfg
  local donateTaskType = cfg.goal[1]
  if donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Id_Item then
    local itemType = cfg.goal[2]
    local itemId = cfg.goal[3]
    local itemNum = cfg.goal[4]
    local havenum = self:GetHaveNum(itemType, itemId)
    if itemNum > havenum then
      noticeManager:ShowTipById(710079)
      globalNoitceManager:ShowItemInfoPage(itemType, itemId)
      return false
    end
  end
  local havedonatenum = Logic.guildtaskLogic:GetDonateItemNum(self.mTaskData.TaskId)
  if havedonatenum < cfg.goal[4] then
    noticeManager:ShowTipById(710079)
    if 2 <= #cfg.drop_show_id then
      globalNoitceManager:ShowItemInfoPage(cfg.drop_show_id[1], cfg.drop_show_id[2])
    end
    return false
  end
  return true
end

function DonateDataObj:GetHaveNum(itemTyp, itemId)
  local havenum = 0
  if itemTyp == GoodsType.EQUIP then
    havenum = self:GetEquipCanCostNum(itemId)
  elseif itemTyp == GoodsType.ITEM then
    havenum = Logic.bagLogic:GetBagItemNum(itemId)
  elseif itemTyp == GoodsType.REWARD_SHIPLEVELUP_ITEM then
    havenum = Logic.bagLogic:GetBagItemNum(itemId)
  elseif itemTyp == GoodsType.SHIP then
    havenum = Data.heroData:GetHeroCountByTemplateId(itemId)
  elseif itemTyp == GoodsType.CURRENCY then
    havenum = Data.userData:GetCurrency(itemId)
  elseif itemTyp == GoodsType.EQUIP_ENHANCE_ITEM then
    havenum = Logic.bagLogic:GetBagItemNum(itemId)
  else
    havenum = Logic.bagLogic:GetBagItemNum(itemId)
    logError("undefined type ", itemTyp)
  end
  return havenum
end

function DonateDataObj:GetEquipCanCostNum(templateId)
  local equips = Data.equipData:GetEquipsByTid(templateId)
  local Condition = function(equip)
    local heroId = Data.equipData:GetEquipHero(equip.EquipId, fleetType)
    return heroId == 0
  end
  local count = 0
  for _, equip in pairs(equips) do
    if Condition(equip) then
      count = count + 1
    end
  end
  return count
end

function DonateDataObj:GetMaxDonateTaskNum()
  local cfg = self.mCfg
  local maxNum = 1
  local canDo = cfg.max_player_goal_num - self.mTaskData.Progress
  maxNum = canDo
  local postCfg = Logic.guildLogic:GetUserPostConfig()
  local todayfinishnum = Data.guildtaskData:GetUserTodayFinishTaskStepCount()
  if todayfinishnum + canDo > postCfg.guildtask_finish_num then
    canDo = postCfg.guildtask_finish_num - todayfinishnum
  end
  if maxNum > canDo then
    maxNum = canDo
  elseif maxNum < 1 then
    maxNum = 1
  end
  return maxNum
end

function DonateDataObj.Create(taskdata)
  local taskId = taskdata.TaskId
  local cfg = configManager.GetDataById("config_task_guild", taskId)
  if cfg.type ~= EnumGuildTaskType.Donate then
    logError("err type ", cfg.type)
    return
  end
  local obj
  local donateTaskType = cfg.goal[1]
  if donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Id_Item then
    if cfg.goal[2] == GoodsType.EQUIP then
      obj = require("ui.page.Guild.GuildTask.DonateDataObj_Id_Equip"):new(taskdata)
    else
      obj = require("ui.page.Guild.GuildTask.DonateDataObj_Id_Item"):new(taskdata)
    end
  elseif donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Qual_Item then
    obj = require("ui.page.Guild.GuildTask.DonateDataObj_Qual_Item"):new(taskdata)
  elseif donateTaskType == EnumGuildTaskDonateType.DonateTaskType_Num_Qual_Equip then
    obj = require("ui.page.Guild.GuildTask.DonateDataObj_Qual_Equip"):new(taskdata)
  else
    logError("Undefined donateTaskType", donateTaskType)
  end
  obj:Init()
  return obj
end

return DonateDataObj
