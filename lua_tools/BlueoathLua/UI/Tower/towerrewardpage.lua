local TowerRewardPage = class("UI.Tower.TowerRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TowerRewardPage:DoInit()
end

function TowerRewardPage:DoOnOpen()
  local towerData = Data.towerData:GetData() or {}
  local chapterId = towerData.ChapterId
  self.chapterIdMin = chapterId
  self.chapterId = chapterId
  local widgets = self:GetWidgets()
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterIdMin)
  UIHelper.SetLocText(widgets.tx_recentmode, 1700024, chapterConfig.name)
  self:ShowRewards()
  self:ShowButtons()
end

function TowerRewardPage:ShowButtons()
  local widgets = self:GetWidgets()
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterIdMin)
  widgets.bu_before.gameObject:SetActive(self.chapterId == chapterConfig.next_chapter)
  widgets.bu_next.gameObject:SetActive(self.chapterId == self.chapterIdMin and chapterConfig.next_chapter > 0)
end

function TowerRewardPage:ShowRewards()
  local widgets = self:GetWidgets()
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  UIHelper.SetLocText(widgets.tx_recentmode, 1700024, chapterConfig.name)
  local towerId = chapterConfig.relation_chapter_id
  self.towerId = towerId
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", self.towerId)
  local tbl = {}
  local basic_reward = chapterTowerConfig.basic_reward
  if 0 < basic_reward then
    local sub = {}
    sub.rewardId = basic_reward
    sub.str = UIHelper.GetString(1700026)
    table.insert(tbl, sub)
  end
  local themes = chapterTowerConfig.tower_topic
  local themeId = themes[1]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  local copyList = themeConfig.type == TowerType.Solo and themeConfig.copy_list or themeConfig.area_final_copy
  local num = 0
  for index, value in ipairs(chapterTowerConfig.area_pass_reward) do
    local sub = {}
    sub.rewardId = value
    if themeConfig.type == TowerType.Solo then
      num = num + #copyList[index]
      local str = UIHelper.GetString(1700025)
      sub.str = string.format(str, num)
    else
      local copystr = ""
      local copyListSub = copyList[index]
      for i = 1, #copyListSub do
        local copyId = copyListSub[i]
        local copyConfig = configManager.GetDataById("config_copy_display", copyId)
        if i < #copyListSub then
          copystr = copystr .. copyConfig.copy_index .. ","
        else
          copystr = copystr .. copyConfig.copy_index
        end
      end
      local str = UIHelper.GetString(1703004)
      sub.str = string.format(str, copystr)
    end
    table.insert(tbl, sub)
  end
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.content_reward, #tbl, function(index, tabPart)
    local info = tbl[index]
    local rewardId = info.rewardId
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    tabPart.tx_nextreward.text = info.str
    local paramConfig = configManager.GetDataById("config_parameter", 201).arrValue
    UIHelper.SetImage(tabPart.img_reward, paramConfig[index])
    UIHelper.CreateSubPart(tabPart.reward, tabPart.Content, #rewards, function(indexSub, tabPartSub)
      local reward = rewards[indexSub]
      local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
      UIHelper.SetText(tabPartSub.tx_num, "x" .. reward.Num)
      UIHelper.SetImageByQuality(tabPartSub.img_quality, display.quality)
      UIHelper.SetImage(tabPartSub.img_icon, display.icon)
      UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self.btn_reward, self, reward)
    end)
  end)
end

function TowerRewardPage:btn_reward(go, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

function TowerRewardPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_OK, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_before, self.bu_before, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_next, self.bu_next, self)
end

function TowerRewardPage:btn_close()
  UIHelper.ClosePage("TowerRewardPage")
end

function TowerRewardPage:bu_before()
  self.chapterId = Logic.towerLogic:GetPreChapterId(self.chapterId)
  self:ShowButtons()
  self:ShowRewards()
end

function TowerRewardPage:bu_next()
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  self.chapterId = chapterConfig.next_chapter
  self:ShowButtons()
  self:ShowRewards()
end

return TowerRewardPage
