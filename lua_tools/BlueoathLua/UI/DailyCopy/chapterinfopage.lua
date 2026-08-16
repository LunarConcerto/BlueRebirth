local ChapterInfoPage = class("UI.DailyCopy.ChapterInfoPage", LuaUIPage)

function ChapterInfoPage:DoInit()
  self.chapterId = 1
end

function ChapterInfoPage:DoOnOpen()
  self:_InitChapter()
  self:_ShowChapter(self.chapterId)
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnGo, function()
    local chapterConfig = configManager.GetDataById("config_daily_chapter", self.chapterId)
    UIHelper.ClosePage("ChapterInfoPage")
    Logic.copyLogic:QuickToChapter(chapterConfig.train_chapter, chapterConfig.train_array_indexid)
  end)
end

function ChapterInfoPage:_InitChapter()
  local widgets = self:GetWidgets()
  local chapterConfig = configManager.GetData("config_daily_chapter")
  local len = #chapterConfig
  widgets.tgGroup:ClearToggles()
  UIHelper.CreateSubPart(widgets.obj, widgets.content, len, function(index, tabPart)
    local chapterInfo = chapterConfig[index]
    UIHelper.SetImage(tabPart.imgIcon, chapterInfo.icon)
    UIHelper.SetText(tabPart.textName, chapterInfo.name)
    widgets.tgGroup:RegisterToggle(tabPart.toggle)
  end)
  widgets.tgGroup:SetActiveToggleIndex(self.chapterId - 1)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroup, self, nil, self._SwitchChapter)
end

function ChapterInfoPage:_SwitchChapter(index)
  self:_ShowChapter(index + 1)
end

function ChapterInfoPage:_ShowChapter(chapterId)
  local widgets = self:GetWidgets()
  local chapterConfig = configManager.GetDataById("config_daily_chapter", chapterId)
  UIHelper.SetText(widgets.textDesc, chapterConfig.desc)
  UIHelper.SetText(widgets.textRecommend, chapterConfig.advice)
  widgets.textTitle.text = chapterConfig.name .. ":"
  self.chapterId = chapterId
end

function ChapterInfoPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnClose, self._btnClose, self)
end

function ChapterInfoPage:_btnClose()
  UIHelper.ClosePage("ChapterInfoPage")
end

return ChapterInfoPage
