local TowerThemePage = class("UI.Tower.TowerThemePage", LuaUIPage)

function TowerThemePage:DoInit()
  local towerData = Data.towerData:GetData() or {}
  self.chapterId = towerData.ChapterId
  self.themeIndex = towerData.TopicIndex
  self.index = 1
end

function TowerThemePage:DoOnOpen()
  local widgets = self:GetWidgets()
  self:OpenTopPage("TowerThemePage", 1, "\228\184\187\233\162\152", self, true)
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  self:InitData()
  UIHelper.CreateSubPart(widgets.label, widgets.Content, #self.data, function(index, tabPart)
    local sub = self.data[index]
    local themeIndex = Logic.towerLogic:FormatThemeIndex(sub.themeIndex, #chapterTowerConfig.tower_topic)
    local themeId = chapterTowerConfig.tower_topic[themeIndex]
    local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
    tabPart.toggle.isOn = index == self.index
    widgets.tgGroup:RegisterToggle(tabPart.toggle)
    UIHelper.SetText(tabPart.name, themeConfig.name)
    UIHelper.SetText(tabPart.des, sub.str)
    UIHelper.SetText(tabPart.name_select, themeConfig.name)
    UIHelper.SetText(tabPart.des_select, sub.str)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroup, self, nil, self._SwitchTheme)
  if self.themeIndex > 0 and #chapterTowerConfig.tower_topic > 2 then
    self:_SwitchTheme(1)
  else
    self:_SwitchTheme(0)
  end
end

function TowerThemePage:_SwitchTheme(index)
  local widgets = self:GetWidgets()
  local themeIndex = self.data[index + 1].themeIndex
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local themeIndex = Logic.towerLogic:FormatThemeIndex(themeIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  local themeInfo = themeConfig.features_list
  UIHelper.SetText(widgets.tx_title, themeConfig.name)
  UIHelper.SetLocText(widgets.tx_desc, 1700059, themeConfig.name)
  UIHelper.CreateSubPart(widgets.bu_theme, widgets.ContentTheme, #themeInfo, function(index, tabPart)
    local sub = themeInfo[index]
    UIHelper.SetText(tabPart.tx_name, sub[1])
    UIHelper.SetImage(tabPart.icon, sub[2])
    UGUIEventListener.AddButtonOnClick(tabPart.bu_theme, self.bu_theme, self, sub)
  end)
end

function TowerThemePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
end

function TowerThemePage:bu_theme(go, content)
  UIHelper.OpenPage("TowerThemeDetailPage", content)
end

function TowerThemePage:InitData()
  self.data = {}
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  local len = #chapterTowerConfig.tower_topic
  if self.themeIndex > 0 and 2 < len then
    local sub = {}
    sub.themeIndex = self.themeIndex - 1
    sub.str = UIHelper.GetString(1700028)
    table.insert(self.data, sub)
    self.index = self.index + 1
  end
  local subNow = {}
  subNow.themeIndex = self.themeIndex
  subNow.str = UIHelper.GetString(1700029)
  table.insert(self.data, subNow)
  local subNext = {}
  subNext.themeIndex = self.themeIndex + 1
  subNext.str = UIHelper.GetString(1700030)
  table.insert(self.data, subNext)
  if 2 < len then
    local subNextNext = {}
    subNextNext.themeIndex = self.themeIndex + 2
    subNextNext.str = UIHelper.GetString(1700031)
    table.insert(self.data, subNextNext)
  end
end

return TowerThemePage
