local DonateDataObj_Id_Item = class("UI.Guild.GuildTask.DonateDataObj_Id_Item", DonateDataObj)
local super = DonateDataObj
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function DonateDataObj_Id_Item:Init()
  local cfg = self.mCfg
  local item = {}
  item.ItemType = cfg.goal[2]
  item.ItemId = cfg.goal[3]
  item.ItemNum = cfg.goal[4]
  table.insert(self.Items, item)
end

function DonateDataObj_Id_Item:SetTaskNum(taskNum)
  if not self:CheckTaskNum(taskNum) then
    return
  end
  local cfg = self.mCfg
  self.Items[1].ItemNum = cfg.goal[4] * taskNum
  self.TaskNum = taskNum
end

function DonateDataObj_Id_Item:GetTxtTips()
  local cfg = self.mCfg
  local display = ItemInfoPage.GenDisplayData(cfg.goal[2], cfg.goal[3])
  return UIHelper.GetLocString(710070, cfg.goal[4] .. " " .. display.name)
end

function DonateDataObj_Id_Item:GetMaxDonateTaskNum()
  local cfg = self.mCfg
  local maxNum = 1
  local itemType = cfg.goal[2]
  local itemId = cfg.goal[3]
  local itemNum = cfg.goal[4]
  local havenum = self:GetHaveNum(itemType, itemId)
  maxNum = math.floor(havenum / itemNum)
  local parentMaxNum = super.GetMaxDonateTaskNum(self)
  if maxNum > parentMaxNum then
    maxNum = parentMaxNum
  end
  return maxNum
end

return DonateDataObj_Id_Item
