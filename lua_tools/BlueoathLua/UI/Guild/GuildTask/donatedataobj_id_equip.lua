local DonateDataObj_Id_Equip = class("UI.Guild.GuildTask.DonateDataObj_Id_Equip", DonateDataObj)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local super = DonateDataObj

function DonateDataObj_Id_Equip:Init()
  local cfg = self.mCfg
  for i = 1, cfg.goal[4] do
    local item = {}
    item.ItemType = cfg.goal[2]
    item.ItemId = cfg.goal[3]
    item.ItemNum = 0
    table.insert(self.Items, item)
  end
end

function DonateDataObj_Id_Equip:GetTxtTips()
  local cfg = self.mCfg
  local display = ItemInfoPage.GenDisplayData(cfg.goal[2], cfg.goal[3])
  return UIHelper.GetLocString(710070, cfg.goal[4] .. " " .. display.name)
end

function DonateDataObj_Id_Equip:GetMaxDonateTaskNum()
  local cfg = self.mCfg
  local maxNum = 1
  local itemNum = cfg.goal[4]
  local havedonatenum = Logic.guildtaskLogic:GetDonateItemNum(self.TaskId)
  maxNum = math.floor(havedonatenum / itemNum)
  local parentMaxNum = super.GetMaxDonateTaskNum(self)
  if maxNum > parentMaxNum then
    maxNum = parentMaxNum
  end
  return maxNum
end

return DonateDataObj_Id_Equip
