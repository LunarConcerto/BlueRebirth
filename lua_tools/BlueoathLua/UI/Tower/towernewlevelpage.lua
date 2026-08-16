local TowerNewLevelPage = class("UI.Tower.TowerNewLevelPage", LuaUIPage)

function TowerNewLevelPage:DoInit()
end

function TowerNewLevelPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local towerData = Data.towerData:GetData()
  local chapterId = towerData.ChapterId
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", chapterConfig.relation_chapter_id)
  local towerTopicConfig = configManager.GetDataById("config_tower_topic", chapterTowerConfig.tower_topic[1])
  local sum = Logic.towerLogic:GetCopyNumByTheme(towerTopicConfig)
  local chapterPre = Logic.towerLogic:GetPreChapterId(chapterId)
  local chapterConfigPre = configManager.GetDataById("config_chapter", chapterPre)
  local chapterTowerConfigPre = configManager.GetDataById("config_chapter_tower", chapterConfigPre.relation_chapter_id)
  local towerTopicConfigPre = configManager.GetDataById("config_tower_topic", chapterTowerConfigPre.tower_topic[1])
  local sumPre = Logic.towerLogic:GetCopyNumByTheme(towerTopicConfigPre)
  local data = {}
  local subLevel = {}
  subLevel.des = UIHelper.GetString(1700039)
  subLevel.pre = chapterConfigPre.name
  subLevel.now = chapterConfig.name
  table.insert(data, subLevel)
  if chapterTowerConfig.reset_period ~= chapterTowerConfigPre.reset_period then
    local subPeriod = {}
    subPeriod.des = UIHelper.GetString(1700040)
    subPeriod.pre = string.format(UIHelper.GetString(1700045), Logic.mathLogic:FormatNumber(chapterTowerConfigPre.reset_period / 86400))
    subPeriod.now = string.format(UIHelper.GetString(1700045), Logic.mathLogic:FormatNumber(chapterTowerConfig.reset_period / 86400))
    table.insert(data, subPeriod)
  end
  if sum ~= sumPre then
    local subSum = {}
    subSum.des = UIHelper.GetString(1700041)
    subSum.pre = string.format(UIHelper.GetString(1700046), sumPre)
    subSum.now = string.format(UIHelper.GetString(1700046), sum)
    table.insert(data, subSum)
  end
  if chapterTowerConfigPre.daily_battle_time ~= chapterTowerConfig.daily_battle_time then
    local subTimes = {}
    subTimes.des = UIHelper.GetString(1700043)
    subTimes.pre = string.format(UIHelper.GetString(1700047), chapterTowerConfigPre.daily_battle_time)
    subTimes.now = string.format(UIHelper.GetString(1700047), chapterTowerConfig.daily_battle_time)
    table.insert(data, subTimes)
  end
  if chapterTowerConfigPre.battle_point_default ~= chapterTowerConfig.battle_point_default then
    local subPoint = {}
    subPoint.des = UIHelper.GetString(1700042)
    subPoint.pre = string.format(UIHelper.GetString(1700051), chapterTowerConfigPre.battle_point_default)
    subPoint.now = string.format(UIHelper.GetString(1700051), chapterTowerConfig.battle_point_default)
    table.insert(data, subPoint)
  end
  if chapterTowerConfigPre.battle_point_cost ~= chapterTowerConfig.battle_point_cost then
    local subTimes = {}
    subTimes.des = UIHelper.GetString(1700050)
    subTimes.pre = string.format(UIHelper.GetString(1700051), chapterTowerConfigPre.battle_point_cost)
    subTimes.now = string.format(UIHelper.GetString(1700051), chapterTowerConfig.battle_point_cost)
    table.insert(data, subTimes)
  end
  UIHelper.CreateSubPart(widgets.template, widgets.Content, #data, function(index, tabPart)
    local subData = data[index]
    tabPart.tx_desc.text = subData.des
    tabPart.tx_pre.text = subData.pre
    tabPart.tx_now.text = subData.now
  end)
end

function TowerNewLevelPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self.btn_close, self)
end

function TowerNewLevelPage:btn_close()
  UIHelper.ClosePage("TowerNewLevelPage")
end

function TowerNewLevelPage:DoOnClose()
  local towerData = Data.towerData:GetData()
  local chapterId = towerData.ChapterId
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", chapterConfig.relation_chapter_id)
  local chapterPre = Logic.towerLogic:GetPreChapterId(chapterId)
  local chapterConfigPre = configManager.GetDataById("config_chapter", chapterPre)
  local chapterTowerConfigPre = configManager.GetDataById("config_chapter_tower", chapterConfigPre.relation_chapter_id)
  if #chapterTowerConfig.tower_topic > 1 and #chapterTowerConfigPre.tower_topic <= 1 then
    Logic.towerLogic:ShowTowerTheme()
  end
end

return TowerNewLevelPage
