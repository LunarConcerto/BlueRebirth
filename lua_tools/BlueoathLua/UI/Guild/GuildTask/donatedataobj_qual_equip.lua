local DonateDataObj_Qual_Equip = class("UI.Guild.GuildTask.DonateDataObj_Qual_Equip", DonateDataObj)
local super = DonateDataObj

function DonateDataObj_Qual_Equip:Init()
  local cfg = self.mCfg
  for i = 1, cfg.goal[4] do
    local item = {}
    item.ItemType = 0
    item.ItemId = 0
    item.ItemNum = 0
    table.insert(self.Items, item)
  end
end

function DonateDataObj_Qual_Equip:GetTxtTips()
  return UIHelper.GetLocString(710075)
end

function DonateDataObj_Qual_Equip:GetMaxDonateTaskNum()
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

return DonateDataObj_Qual_Equip
