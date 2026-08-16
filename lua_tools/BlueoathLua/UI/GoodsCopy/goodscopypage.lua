local GoodsCopyPage = class("UI.GoodsCopy.GoodsCopyPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GoodsCopyPage:DoInit()
end

function GoodsCopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OnBtnHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_go, self._OnBtnGo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_activity, self._ToTestShip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_damage, self._ToDamagePage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_select, self._OnBtnSelect, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bg, self._CloseSelect, self)
end

function GoodsCopyPage:DoOnOpen()
  local widgets = self.tab_Widgets
  self:OpenTopPage("GoodsCopyPage", 1, UIHelper.GetString(520002), self, true)
  local chapterId = configManager.GetDataById("config_parameter", 174).value
  local copyId = Logic.goodsCopyLogic:GetCurCopyId()
  local data = Data.goodsCopyData:GetRankData()
  self.chapterId = chapterId
  self:SelectCopy(copyId)
  self.showSelectCopy = false
  widgets.trans_arrow.localScale = Vector3.New(1, -1, 1)
  widgets.obj_select:SetActive(false)
  UIHelper.SetText(widgets.txt_damage, math.floor(data.TodayMaxDamage))
  UIHelper.SetText(widgets.txt_today_reward, math.floor(data.TodayGetGoods))
  if data.Percent and data.Percent ~= -1 then
    UIHelper.SetText(widgets.txt_rank_none, "")
    UIHelper.SetText(widgets.txt_rank, string.format("%.2f%%", data.Percent / 100))
    self:SetArrowPos(data.Percent)
    local curCfg, nextCfg = Logic.goodsCopyLogic:GetCfgByRank(data.Percent)
    local rewardRec = configManager.GetDataById("config_rewards", curCfg.reward)
    local rewards = Logic.rewardLogic:FormatReward(rewardRec.rewards)
    UIHelper.CreateSubPart(widgets.list_item1, widgets.list_content1, #rewards, function(nIndex, luaPart)
      self:FillRewardItem(luaPart, rewards[nIndex])
    end)
    if nextCfg then
      UIHelper.SetText(widgets.txt_next_rank_reward, string.format("%.2f%%-%.2f%%", nextCfg.p1 / 100, nextCfg.p2 / 100))
    else
      nextCfg = curCfg
      widgets.txt_max:SetActive(true)
      widgets.txt_next_rank_reward.gameObject:SetActive(false)
    end
    rewardRec = configManager.GetDataById("config_rewards", nextCfg.reward)
    rewards = Logic.rewardLogic:FormatReward(rewardRec.rewards)
    UIHelper.CreateSubPart(widgets.list_item2, widgets.list_content2, #rewards, function(nIndex, luaPart)
      self:FillRewardItem(luaPart, rewards[nIndex])
    end)
  else
    self.tab_Widgets.obj_rank_pointer.gameObject:SetActive(false)
    UIHelper.SetLocText(self.tab_Widgets.txt_rank_none, 510002)
    widgets.obj_list1:SetActive(false)
    widgets.txt_none1.gameObject:SetActive(true)
    local _, nextCfg = Logic.goodsCopyLogic:GetCfgByRank(data.Percent)
    UIHelper.SetText(widgets.txt_next_rank_reward, string.format("%.2f%%-%.2f%%", nextCfg.p1 / 100, nextCfg.p2 / 100))
    local rewardRec = configManager.GetDataById("config_rewards", nextCfg.reward)
    local rewards = Logic.rewardLogic:FormatReward(rewardRec.rewards)
    UIHelper.CreateSubPart(widgets.list_item2, widgets.list_content2, #rewards, function(nIndex, luaPart)
      self:FillRewardItem(luaPart, rewards[nIndex])
    end)
  end
  self:InitActivity()
  self:InitSelectCopy()
end

function GoodsCopyPage:InitActivity()
  local inActivity = Logic.activityLogic:CheckOpenActivityByType(ActivityType.TestShip)
  self.tab_Widgets.btn_activity.gameObject:SetActive(inActivity)
end

function GoodsCopyPage:SelectCopy(copyId)
  self.copyId = copyId
  local copyBattleCfg = configManager.GetDataById("config_goods_battle", copyId)
  UIHelper.SetText(self.tab_Widgets.txt_copy, copyBattleCfg.name)
  UIHelper.SetText(self.tab_Widgets.txt_buff, copyBattleCfg.buff_name)
end

function GoodsCopyPage:InitSelectCopy()
  local widgets = self:GetWidgets()
  local copyIds = Logic.goodsCopyLogic:GetGoodsCopyIdList()
  UIHelper.CreateSubPart(widgets.obj_copyitem, widgets.trans_copylist, #copyIds, function(index, tabPart)
    local copyId = copyIds[index]
    local copyCfg = configManager.GetDataById("config_copy_display", copyId)
    local copyBattleCfg = configManager.GetDataById("config_goods_battle", copyId)
    UIHelper.SetText(tabPart.txt_name, copyBattleCfg.name)
    tabPart.obj_type:SetActive(copyBattleCfg.type_icon ~= "")
    if copyBattleCfg.type_icon ~= "" then
      UIHelper.SetImage(tabPart.im_shiptype, copyBattleCfg.type_icon)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn, self._OnCopySelect, self, copyId)
  end)
end

function GoodsCopyPage:FillRewardItem(luaPart, rewardInfo)
  local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo)
  UIHelper.SetImage(luaPart.icon, tabReward.texIcon)
  UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
  UIHelper.SetText(luaPart.tx_num, rewardInfo.Num)
  UGUIEventListener.AddButtonOnClick(luaPart.obj_reward, self._ShowRewardInfo, self, rewardInfo)
end

function GoodsCopyPage:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function GoodsCopyPage:SetArrowPos(percent)
  local leftX = self.tab_Widgets.trans_rank_left.position.x
  local rightX = self.tab_Widgets.trans_rank_right.position.x
  local arrowX = (10000 - percent) / 10000.0 * (rightX - leftX) + leftX
  local oldPos = self.tab_Widgets.obj_rank_pointer.position
  self.tab_Widgets.obj_rank_pointer.position = Vector3.New(arrowX, oldPos.y, oldPos.z)
end

function GoodsCopyPage:_OnBtnHelp()
  UIHelper.OpenPage("GoodsCopyRewardPage")
end

function GoodsCopyPage:_OnBtnGo()
  if not Logic.fleetLogic:IsHasFleet() then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  local serverData = Data.copyData:GetGoodsCopyData()
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = serverData[self.copyId],
    chapterId = self.chapterId,
    IsRunningFight = false,
    copyId = self.copyId
  }
  Logic.copyLogic:SetEnterLevelInfo(true)
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function GoodsCopyPage:_ToTestShip()
  local activities = Logic.activityLogic:GetOpenActivityByType(ActivityType.TestShip)
  if activities[1] then
    UIHelper.OpenPage("ActivityPage", {
      activityId = activities[1].id
    })
  end
end

function GoodsCopyPage:_ToDamagePage()
  UIHelper.OpenPage("GoodsDamagePage")
end

function GoodsCopyPage:_OnBtnSelect()
  local widgets = self:GetWidgets()
  self.showSelectCopy = not self.showSelectCopy
  widgets.obj_select:SetActive(self.showSelectCopy)
  widgets.trans_arrow.localScale = Vector3.New(1, self.showSelectCopy and 1 or -1, 1)
end

function GoodsCopyPage:_CloseSelect()
  local widgets = self:GetWidgets()
  widgets.obj_select:SetActive(false)
  widgets.trans_arrow.localScale = Vector3.New(1, -1, 1)
  self.showSelectCopy = false
end

function GoodsCopyPage:_OnCopySelect(go, copyId)
  Logic.goodsCopyLogic:SetGoodsCopyId(copyId)
  self:SelectCopy(copyId)
  self:_CloseSelect()
end

function GoodsCopyPage:DoOnHide()
end

return GoodsCopyPage
