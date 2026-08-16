local DailyCopyPage = class("UI.DailyCopy.DailyCopyPage", LuaUIPage)

function DailyCopyPage:DoInit()
  self.copyInfo = configManager.GetData("config_daily_chapter")
end

function DailyCopyPage:DoOnOpen()
  Service.dailyCopyService:SendGetData()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = "\230\175\143\230\151\165"})
  self:_Retention()
  self:_InitInfo()
end

function DailyCopyPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_instruction, self.btn_instruction, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_chapter, self.btn_chapter, self)
  self:RegisterEvent(LuaEvent.UpdateDailyCopy, self._refresh, self)
end

function DailyCopyPage:_Retention()
  local dotUIInfo = {
    info = "ui_copy_daily"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function DailyCopyPage:_refresh()
  for id, tabPart in pairs(self.dailyCopyPart) do
    local dailyGroupInfo = configManager.GetDataById("config_daily_group", id)
    local rewardTotalTimes = Logic.dailyCopyLogic:GetRewardTotalTimes(dailyGroupInfo)
    local rewardTimesLeft = Logic.dailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo)
    UIHelper.SetLocText(tabPart.txt_times, 410018, rewardTimesLeft)
    tabPart.txt_times.gameObject:SetActive(0 < rewardTimesLeft)
    tabPart.textTimeTitle:SetActive(0 < rewardTimesLeft)
  end
end

function DailyCopyPage:_InitInfo()
  local openCopyTab = configManager.GetData("config_daily_group")
  self.dailyCopyPart = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyItem, self.tab_Widgets.trans_copys, #openCopyTab, function(nIndex, tabPart)
    local copyInfo = openCopyTab[nIndex]
    self:_CreateCopyItem(copyInfo, tabPart)
  end)
end

function DailyCopyPage:_CreateCopyItem(copyInfo, tabPart)
  tabPart.obj_copy:SetActive(true)
  tabPart.btn_copy.interactable = true
  UIHelper.SetImage(tabPart.img_drop, copyInfo.drop_icon)
  UIHelper.SetImage(tabPart.img_detail, copyInfo.title_icon)
  local chapterIndex = Logic.dailyCopyLogic:GetDailyChapterIndex(copyInfo)
  tabPart.txt_opentime.text = copyInfo.is_available_show[chapterIndex]
  self.dailyCopyPart[copyInfo.id] = tabPart
  local rewardTimesLeft = Logic.dailyCopyLogic:GetRewardTimesLeft(copyInfo)
  UIHelper.SetLocText(tabPart.txt_times, 410018, rewardTimesLeft)
  tabPart.txt_times.gameObject:SetActive(0 < rewardTimesLeft)
  tabPart.textTimeTitle:SetActive(0 < rewardTimesLeft)
  local chapterInfo = Logic.dailyCopyLogic:GetDailyChapterInfo(copyInfo)
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(chapterInfo.id)
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local chapterData = Logic.dailyCopyLogic:GetPassCopy(chapterId) or {}
  local index = 0 < #chapterData and #chapterData or 1
  local copyId = chapterConfig.level_list[index]
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  tabPart.txt_dropinfo.text = copyConfig.name
  tabPart.text_dropinfo.text = copyInfo.copy_dropinfo
  UIHelper.SetImage(tabPart.img_copy, copyInfo.icon)
  local result = Logic.dailyCopyLogic:CheckDailyCopyPeriod(copyInfo, false)
  tabPart.imgLock.gameObject:SetActive(not result)
  UIHelper.SetImage(tabPart.imgLock, copyInfo.lock_bg)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_copy.gameObject, function()
    self:_OnClickCopyBtn(tabPart, copyInfo)
  end)
end

function DailyCopyPage:_OnClickCopyBtn(tabPart, dailyGroupInfo)
  if not Logic.dailyCopyLogic:CheckDailyCopyPeriod(dailyGroupInfo, true) then
    return
  end
  UIHelper.OpenPage("DailyCopyDetailPage", {
    dailyGroupId = dailyGroupInfo.id
  })
end

function DailyCopyPage:_GetOpenCopy()
  local weekDay = time.getWeekday()
  local openCopyTab = {}
  for _, info in ipairs(self.copyInfo) do
    if table.containV(info.is_available, weekDay) then
      table.insert(openCopyTab, info)
    end
  end
  return openCopyTab
end

function DailyCopyPage:_WeekNum2Str(weeks)
  if #weeks == 7 then
    return UIHelper.GetString(410008)
  end
  local str = ""
  for i = 1, #weeks do
    str = str .. WeekStr[weeks[i]]
    if i < #weeks then
      str = str .. ","
    end
  end
  return string.format(UIHelper.GetString(410006), str)
end

function DailyCopyPage:DoOnHide()
end

function DailyCopyPage:DoOnClose()
end

function DailyCopyPage:btn_chapter()
  UIHelper.OpenPage("ChapterInfoPage")
end

function DailyCopyPage:btn_instruction()
  UIHelper.OpenPage("InstructionPage")
end

return DailyCopyPage
