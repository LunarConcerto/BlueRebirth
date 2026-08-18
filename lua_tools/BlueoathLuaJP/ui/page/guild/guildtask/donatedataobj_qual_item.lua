local DonateDataObj_Qual_Item = class("UI.Guild.GuildTask.DonateDataObj_Qual_Item", DonateDataObj)
local super = DonateDataObj

function DonateDataObj_Qual_Item:Init()
  local cfg = self.mCfg
  for i = 1, cfg.goal[4] do
    local item = {}
    item.ItemType = 0
    item.ItemId = 0
    item.ItemNum = 0
    table.insert(self.Items, item)
  end
end

function DonateDataObj_Qual_Item:SetTaskNum(taskNum)
  if not self:CheckTaskNum(taskNum) then
    return
  end
  local cfg = self.mCfg
  local itemcount = cfg.goal[4] * taskNum
  local itemscount = 0
  for _, item in ipairs(self.Items) do
    if 0 >= item.ItemNum then
      itemscount = itemscount + 1
    else
      itemscount = itemscount + item.ItemNum
    end
  end
  if itemcount == itemscount then
    return
  end
  local itemnum = 0
  local items = {}
  for i = 1, itemcount do
    if itemcount <= itemnum then
      break
    end
    local item = self.Items[i]
    if item == nil then
      item = {}
      item.ItemType = cfg.goal[2]
      item.ItemId = cfg.goal[3]
      item.ItemNum = 0
      itemnum = itemnum + 1
    else
      if itemcount < itemnum + item.ItemNum then
        item.ItemNum = itemcount - itemnum
      end
      itemnum = itemnum + item.ItemNum
    end
    table.insert(items, item)
  end
  self.Items = items
  self.TaskNum = taskNum
end

function DonateDataObj_Qual_Item:GetTxtTips()
  return UIHelper.GetLocString(710075)
end

function DonateDataObj_Qual_Item:GetMaxDonateTaskNum()
  local cfg = self.mCfg
  local maxNum = 1
  local itemNum = cfg.goal[4]
  local havedonatenum = Logic.guildtaskLogic:GetDonateItemNum(self.mTaskData.TaskId)
  maxNum = math.floor(havedonatenum / itemNum)
  local parentMaxNum = super.GetMaxDonateTaskNum(self)
  if maxNum > parentMaxNum then
    maxNum = parentMaxNum
  end
  return maxNum
end

return DonateDataObj_Qual_Item
