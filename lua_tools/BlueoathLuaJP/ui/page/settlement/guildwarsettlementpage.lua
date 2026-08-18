GuildWarSettlementPage = class("UI.Settlement.GuildWarSettlementPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local achieve = {
  BattleFinish = {
    Txt = UIHelper.GetString(810008)
  },
  BattleDamage = {
    Txt = UIHelper.GetString(810009),
    Per = 0
  },
  KillBoss = {
    Txt = UIHelper.GetString(810010)
  },
  NormalAward = {
    Txt = UIHelper.GetString(810011)
  }
}

function GuildWarSettlementPage:DoInit()
end

function GuildWarSettlementPage:DoOnOpen()
  self.widgets = self:GetWidgets()
  local param = self.param
  self:LoadInfo()
end

function GuildWarSettlementPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_skip, function()
    UIHelper.ClosePage("GuildWarSettlementPage")
    if self.param.Page == "SettlementLogic" then
      Logic.settlementLogic.m_flowCtrl(Logic.settlementLogic.Input.Next)
    end
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_mask, function()
    UIHelper.ClosePage("GuildWarSettlementPage")
    if self.param.Page == "SettlementLogic" then
      Logic.settlementLogic.m_flowCtrl(Logic.settlementLogic.Input.Next)
    end
  end, self)
end

function GuildWarSettlementPage:LoadInfo()
  self:LoadBaseInfo()
  self:LoadDamageInfo()
  self:LoadRewardInfo()
end

function GuildWarSettlementPage:LoadBaseInfo()
  local config = configManager.GetDataById("config_guildwar_base_info", self.param.BaseID)
  UIHelper.SetText(self.widgets.tx_base, config.desc)
  local StageName = {
    [1] = "\226\133\160",
    [2] = "\226\133\161",
    [3] = "\226\133\162",
    [4] = "\226\133\163",
    [5] = "\226\133\164",
    [6] = "\226\133\165"
  }
  local stage = string.format(UIHelper.GetString(810001), StageName[self.param.StageID])
  local section = string.format(UIHelper.GetString(810002), self.param.SectionID)
  UIHelper.SetText(self.tab_Widgets.tx_stage, stage)
  UIHelper.SetText(self.tab_Widgets.tx_lap, section)
  UIHelper.SetText(self.tab_Widgets.tx_level, self.param.StageLevel)
end

function GuildWarSettlementPage:LoadDamageInfo()
  UIHelper.SetText(self.widgets.tx_damage_num, self.param.RealDamage)
  UIHelper.SetText(self.widgets.tx_damage_rate, self.param.DamagePercent / 100)
  UIHelper.SetText(self.widgets.tx_jf_num, self.param.Points)
end

function GuildWarSettlementPage:_SameItemMerge(rewards)
  local mergeItemInfo = {}
  for k, v in pairs(rewards) do
    local isHave = self:_IsHaveItem(mergeItemInfo, v.Type, v.ConfigId, v.Num)
    if isHave == false then
      table.insert(mergeItemInfo, v)
    end
  end
  return mergeItemInfo
end

function GuildWarSettlementPage:_IsHaveItem(mergeItemInfo, type, tid, num)
  for k, v in pairs(mergeItemInfo) do
    if v.ConfigId == tid and v.Type == type and not self.dontMerge then
      v.Num = v.Num + num
      return true
    end
  end
  return false
end

function GuildWarSettlementPage:LoadRewardInfo()
  if next(self.param.NormalReward) ~= nil then
    for i = 1, #self.param.NormalReward do
      table.insert(self.param.RewardList, self.param.NormalReward[i])
    end
  end
  self.widgets.obj_reward:SetActive(next(self.param.RewardList) ~= nil)
  if next(self.param.RewardList) ~= nil then
    self.param.RewardList = self:_SameItemMerge(self.param.RewardList)
  end
  self:LoadAchieveInfo()
  UIHelper.CreateSubPart(self.widgets.obj_item, self.widgets.trs_reward, #self.param.RewardList, function(index, tabPart)
    local itemType = self.param.RewardList[index].Type
    local configInfo = self:_GetRewardConf(itemType, self.param.RewardList[index].ConfigId)
    local name = configInfo.name
    local quality = configInfo.quality
    local icon = configInfo.icon
    UIHelper.SetImage(tabPart.img_icon, icon)
    UIHelper.SetImage(tabPart.img_frame, QualityIcon[quality])
    UIHelper.SetText(tabPart.txt_num, "x" .. math.tointeger(self.param.RewardList[index].Num))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      local award = self.param.RewardList[index]
      SoundManager.Instance:PlayMusic("UI_Button_CrusadeSuccessPage_0001")
      local itemType = award.Type
      if award.ConfigId == 80240 or award.ConfigId == 80247 or award.ConfigId == 80248 or award.ConfigId == 80249 or award.ConfigId == 80250 then
        itemType = 8
      end
      if itemType == GoodsType.EQUIP then
        UIHelper.OpenPage("ShowEquipPage", {
          templateId = award.ConfigId,
          showEquipType = ShowEquipType.Simple,
          showDrop = false
        })
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemType, award.ConfigId))
      end
    end, self)
  end)
end

function GuildWarSettlementPage:LoadAchieveInfo()
  local achieves = {}
  table.insert(achieves, achieve.BattleFinish)
  if self.param.RealDamage > 0 then
    table.insert(achieves, achieve.BattleDamage)
  end
  if self.param.ResultCode == 3 then
    table.insert(achieves, achieve.KillBoss)
  elseif self.param.ResultCode == 1 then
    noticeManager:ShowTip(UIHelper.GetString(810045))
  end
  table.insert(achieves, achieve.NormalAward)
  UIHelper.CreateSubPart(self.widgets.obj_text, self.widgets.trs_achieve, #achieves, function(index, tabpart)
    local tex = string.format(achieves[index].Txt, self.param.DamagePercent / 100 .. "%")
    UIHelper.SetText(tabpart.Text, tex)
  end)
end

function GuildWarSettlementPage:_GetRewardConf(typeId, confId)
  local table_idnex_Info = configManager.GetDataById("config_table_index", typeId)
  local configInfo = configManager.GetDataById(table_idnex_Info.file_name, confId)
  return configInfo
end

function GuildWarSettlementPage:_ShowItemInfo(go, award)
  SoundManager.Instance:PlayMusic("UI_Button_CrusadeSuccessPage_0001")
  local itemType = award.Type
  if award.ConfigId == 80240 or award.ConfigId == 80247 or award.ConfigId == 80248 or award.ConfigId == 80249 or award.ConfigId == 80250 then
    itemType = 8
  end
  if itemType == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemType, award.ConfigId))
  end
end

function GuildWarSettlementPage:DoOnHide()
end

return GuildWarSettlementPage
