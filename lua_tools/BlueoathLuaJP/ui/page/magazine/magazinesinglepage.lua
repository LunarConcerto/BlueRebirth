local MagazineSinglePage = class("UI.Magazine.MagazineSinglePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BookFlip = require("UI.page.Home.HomeBookFlip"):new()

function MagazineSinglePage:DoInit()
  self.index = 2
  self.indexLeft = 2
  self.indexRight = 3
  self.isJapan = configManager.GetDataById("config_parameter", 360).value == 0
  BookFlip:Init()
end

function MagazineSinglePage:initPageId()
  if self.isJapan then
    if self.index > 3 then
      if math.fmod(self.index, 2) == 1 then
        self.indexLeft = self.index
        self.indexRight = self.index - 1
      else
        self.indexLeft = self.index + 1
        self.indexRight = self.index
      end
    else
      self.indexLeft = 3
      self.indexRight = 2
    end
  elseif self.index > 3 then
    if math.fmod(self.index, 2) == 1 then
      self.indexLeft = self.index - 1
      self.indexRight = self.index
    else
      self.indexLeft = self.index
      self.indexRight = self.index + 1
    end
  else
    self.indexLeft = 2
    self.indexRight = 3
  end
end

function MagazineSinglePage:DoOnOpen()
  local params = self:GetParam()
  self.magazineId = params.magazineId
  self.magazineConfig = configManager.GetDataById("config_magazine_info", self.magazineId)
  self.page_id_list = clone(self.magazineConfig.page_id)
  table.insert(self.page_id_list, 1, 0)
  if self.magazineConfig.special ~= MagazineSpecial.Special then
    table.insert(self.page_id_list, 1, -1)
    table.insert(self.page_id_list, 1, -2)
  end
  self.page2index = {}
  for i, v in ipairs(self.page_id_list) do
    self.page2index[v] = i
  end
  self.page_id_list_ = {}
  for i, v in ipairs(self.magazineConfig.page_id) do
    local magazinePageConfig = configManager.GetDataById("config_magazine_page", v)
    if magazinePageConfig.page_type == 0 then
      table.insert(self.page_id_list_, v)
    end
  end
  local pageId = params.pageId or -1
  if self.magazineConfig.special == MagazineSpecial.Special then
    pageId = params.pageId or self.page_id_list[2]
  end
  self.index = self.page2index[pageId]
  BookFlip:SetTextures(self.magazineConfig.pagedown_id)
  self:_BookFlip()
end

function MagazineSinglePage:Refresh()
  self:ShowContent()
end

function MagazineSinglePage:ShowContent()
  self:initPageId()
  local widgets = self:GetWidgets()
  widgets.obj_rewards:SetActive(self.magazineConfig.special ~= MagazineSpecial.Special)
  widgets.btn_bookmark.gameObject:SetActive(self.magazineConfig.special ~= MagazineSpecial.Special)
  local contents_left = self.magazineConfig.contents_left
  UIHelper.CreateSubPart(widgets.btn_title_1, widgets.content_title_1, #contents_left, function(index, tabPart)
    local magazinePageId = contents_left[index]
    local magazinePageConfig = configManager.GetDataById("config_magazine_page", magazinePageId)
    UIHelper.SetText(tabPart.tx_title, magazinePageConfig.contents_desc)
    UIHelper.SetImage(tabPart.im_title, magazinePageConfig.contents_image)
    UGUIEventListener.AddButtonOnClick(tabPart.btn, function()
      self.index = self.page2index[magazinePageId]
      self:_BookFlip()
    end)
  end)
  local contents_right = self.magazineConfig.contents_right
  UIHelper.CreateSubPart(widgets.btn_title_2, widgets.content_title_2, #contents_right, function(index, tabPart)
    local magazinePageId = contents_right[index]
    local magazinePageConfig = configManager.GetDataById("config_magazine_page", magazinePageId)
    UIHelper.SetText(tabPart.tx_title, magazinePageConfig.contents_desc)
    UIHelper.SetImage(tabPart.im_title, magazinePageConfig.contents_image)
    UGUIEventListener.AddButtonOnClick(tabPart.btn, function()
      self.index = self.page2index[magazinePageId]
      self:_BookFlip()
    end)
  end)
  local itemInfo = configManager.GetDataById("config_parameter", 365).arrValue
  local sum = Logic.rewardLogic:GetPossessNum(itemInfo[1], itemInfo[2])
  UIHelper.SetLocText(widgets.tx_left, 4000032, sum)
  local state = Logic.magazineLogic:GetMagazineState(self.magazineId)
  widgets.btn_bookmark.gameObject:SetActive(state == MagazineState.Lock and self.magazineConfig.special ~= MagazineSpecial.Special)
  widgets.im_mask:SetActive(state == MagazineState.Lock and self.magazineConfig.special ~= MagazineSpecial.Special)
  self:ShowPageLeft()
  self:ShowPageRight()
  self:ShowButton()
  if self.magazineConfig.special ~= MagazineSpecial.Special then
    self:ShowBoxReward()
  end
end

function MagazineSinglePage:ShowPageLeft()
  local widgets = self:GetWidgets()
  local pageIdLeft = self.page_id_list[self.indexLeft] or 0
  if pageIdLeft <= 0 then
    return
  end
  local magazinePageConfig = configManager.GetDataById("config_magazine_page", pageIdLeft)
  UIHelper.SetImage(widgets.im_page_1, magazinePageConfig.image)
  local taskList = magazinePageConfig.task_id
  widgets.content_task_1.gameObject:SetActive(0 < #taskList)
  widgets.im_taskbg1:SetActive(0 < #taskList)
  UIHelper.CreateSubPart(widgets.tx_task_1, widgets.content_task_1, #taskList, function(index, tabPart)
    local taskId = taskList[index]
    local taskData = Data.taskData:GetTaskDataById(taskId, TaskType.Magazine)
    local taskConfig = configManager.GetDataById("config_task_magazine", taskId)
    UIHelper.SetText(tabPart.tx_task, taskConfig.desc)
    local max = Logic.taskLogic:GetTotalCount(taskId, TaskType.Magazine)
    local cur = Logic.taskLogic:GetCurCount(taskData, max)
    local reward = Logic.rewardLogic:FormatRewardById(taskConfig.rewards)
    local num = reward[1].Num
    local state = Logic.taskLogic:GetTaskFinishState(taskId, TaskType.Magazine)
    UIHelper.CreateSubPart(tabPart.star, tabPart.content_star, num, function(indexSub, tabPartSub)
      tabPartSub.star_on:SetActive(state ~= TaskState.TODO)
    end)
    UIHelper.SetTextColorByBool(tabPart.tx_progress, cur .. "/" .. max, 111, 110, state ~= TaskState.TODO)
  end)
  self.tab_Widgets.btn_enlarge1.gameObject:SetActive(magazinePageConfig.button_show == 1)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_enlarge1, function()
    if magazinePageConfig.page_type == 0 then
      widgets.obj_large:SetActive(true)
      self.largePageId = magazinePageConfig.id
      self:SetLargeIndex()
      self:ShowLargeImage()
    else
      widgets.obj_large2:SetActive(true)
      UIHelper.SetImage(widgets.im_large2, magazinePageConfig.image_big)
    end
  end)
end

function MagazineSinglePage:ShowPageRight()
  local widgets = self:GetWidgets()
  local pageIdRight = self.page_id_list[self.indexRight] or 0
  if pageIdRight <= 0 then
    return
  end
  local magazinePageConfig = configManager.GetDataById("config_magazine_page", pageIdRight)
  UIHelper.SetImage(widgets.im_page_2, magazinePageConfig.image)
  local taskList = magazinePageConfig.task_id
  widgets.content_task_2.gameObject:SetActive(0 < #taskList)
  widgets.im_taskbg2:SetActive(0 < #taskList)
  UIHelper.CreateSubPart(widgets.tx_task_2, widgets.content_task_2, #taskList, function(index, tabPart)
    local taskId = taskList[index]
    local taskData = Data.taskData:GetTaskDataById(taskId, TaskType.Magazine)
    local taskConfig = configManager.GetDataById("config_task_magazine", taskId)
    UIHelper.SetText(tabPart.tx_task, taskConfig.desc)
    local max = Logic.taskLogic:GetTotalCount(taskId, TaskType.Magazine)
    local cur = Logic.taskLogic:GetCurCount(taskData, max)
    local reward = Logic.rewardLogic:FormatRewardById(taskConfig.rewards)
    local num = reward[1].Num
    local state = Logic.taskLogic:GetTaskFinishState(taskId, TaskType.Magazine)
    UIHelper.CreateSubPart(tabPart.star, tabPart.content_star, num, function(indexSub, tabPartSub)
      tabPartSub.star_on:SetActive(state ~= TaskState.TODO)
    end)
    UIHelper.SetTextColorByBool(tabPart.tx_progress, cur .. "/" .. max, 111, 110, state ~= TaskState.TODO)
  end)
  self.tab_Widgets.btn_enlarge2.gameObject:SetActive(magazinePageConfig.button_show == 1)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_enlarge2, function()
    if magazinePageConfig.page_type == 0 then
      widgets.obj_large:SetActive(true)
      self.largePageId = magazinePageConfig.id
      self:SetLargeIndex()
      self:ShowLargeImage()
    else
      widgets.obj_large2:SetActive(true)
      UIHelper.SetImage(widgets.im_large2, magazinePageConfig.image_big)
    end
  end)
end

function MagazineSinglePage:ShowBoxReward()
  local widgets = self:GetWidgets()
  local config = self.magazineConfig
  local conditionList = config.condition
  local rewardList = config.rewards
  local item = config.item
  local num = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
  local numMax = conditionList[#conditionList]
  UIHelper.CreateSubPart(widgets.TemplateBox, widgets.ContentBox, #conditionList, function(index, tabPart)
    local condition = conditionList[index]
    UIHelper.SetText(tabPart.num, condition)
    local isFetch = Data.magazineData:GetFetchRewardTime(config.id, index) > 0
    tabPart.icon_open:SetActive(isFetch)
    tabPart.icon_able:SetActive(condition <= num and not isFetch)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      local condition = conditionList[index]
      local num = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
      local isFetch = Data.magazineData:GetFetchRewardTime(config.id, index) > 0
      if condition <= num and not isFetch then
      else
        local isOpen = PeriodManager:IsInPeriodArea(self.magazineConfig.period, self.magazineConfig.ticket_period_area)
        local rewardId = isOpen and rewardList[index] or config.rewards_long[index]
        local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
        UIHelper.OpenPage("BoxRewardPage", {
          rewardState = RewardState.UnReceivable,
          rewards = rewards
        })
      end
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_able, function()
      local condition = conditionList[index]
      local num = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
      local isFetch = Data.magazineData:GetFetchRewardTime(config.id, index) > 0
      if condition <= num and not isFetch then
        Service.magazineService:SendFetchReward({
          MagazineId = config.id,
          Index = index
        })
      end
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_star, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(item[1], item[2]))
    end)
  end)
  widgets.Handle.fillAmount = num / numMax
  local max = config.condition_max
  UIHelper.SetTextColorByBool(widgets.tx_num, num .. "/" .. max, 111, 110, num >= max)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_star, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(item[1], item[2]))
  end)
end

function MagazineSinglePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_back, self._ClickBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_page1, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_page2, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_content1, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_content2, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_openbutton, self._ClickCloseAll, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bookmark, self.btn_bookmark, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_large, function()
    self.tab_Widgets.obj_large:SetActive(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_large2, function()
    self.tab_Widgets.obj_large2:SetActive(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_after, function()
    if self.largePageIndex >= #self.page_id_list_ then
      return
    end
    self.largePageIndex = self.largePageIndex + 1
    self:ShowLargeImage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_before, function()
    if self.largePageIndex <= 1 then
      return
    end
    self.largePageIndex = self.largePageIndex - 1
    self:ShowLargeImage()
  end)
  self:RegisterEvent(LuaEvent.GetMagazineMsg, self.Refresh, self)
  self:RegisterEvent(LuaEvent.GetMagazineFetchReward, self.FetchReward, self)
end

function MagazineSinglePage:FetchReward(state)
  local index = state.Index
  local config = self.magazineConfig
  local rewardList = config.rewards
  local isOpen = PeriodManager:IsInPeriodArea(self.magazineConfig.period, self.magazineConfig.ticket_period_area)
  local rewardId = isOpen and rewardList[index] or config.rewards_long[index]
  local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
  Logic.rewardLogic:ShowCommonReward(rewards)
end

function MagazineSinglePage:_ClickClose()
  local left = self.isJapan and 1 or 0
  local right = self.isJapan and 0 or 1
  self:CloseMagazineSinglePage()
  self:SetActivePage(false)
  BookFlip:SetPageIndex(left, right, function()
    self:SetActivePage(true)
  end)
end

function MagazineSinglePage:CloseMagazineSinglePage()
  local widgets = self:GetWidgets()
  widgets.tween_rewards:Play(false)
  widgets.tween_left:Play(false)
  local parameter = configManager.GetDataById("config_parameter", 358).value
  local during = parameter / 1000
  self:CreateTimer(function()
    UIHelper.ClosePage("MagazineSinglePage")
  end, during, 1, false):Start()
end

function MagazineSinglePage:_ClickCloseAll()
  local left = self.isJapan and 1 or 0
  local right = self.isJapan and 0 or 1
  self:SetActivePage(false)
  BookFlip:SetPageIndex(left, right, function()
    self:SetActivePage(true)
    UIHelper.ClosePage("MagazinePickPage")
    UIHelper.ClosePage("MagazineSinglePage")
    UIHelper.ClosePage("MagazinePage")
    eventManager:SendEvent(LuaEvent.MagazineBack)
    GR.cameraManager:showCamera(GameCameraType.RoomSceneCamera)
  end)
end

function MagazineSinglePage:_ClickBack()
  self.index = 2
  self:_BookFlip()
end

function MagazineSinglePage:_ClickLeft()
  self:initPageId()
  if self.isJapan then
    if self.indexLeft >= #self.page_id_list then
      self:_ClickClose()
      return
    end
    self.index = self.index + 2
  else
    if self.indexLeft <= 2 then
      self:_ClickClose()
      return
    end
    self.index = self.index - 2
  end
  self:_BookFlip()
end

function MagazineSinglePage:SetActivePage(_bool)
  local widgets = self:GetWidgets()
  local pageIdLeft = self.page_id_list[self.indexLeft]
  local pageIdRight = self.page_id_list[self.indexRight]
  widgets.content1:SetActive(pageIdLeft <= 0 and _bool)
  widgets.content2:SetActive(pageIdRight <= 0 and _bool)
  widgets.page1:SetActive(0 < pageIdLeft and _bool)
  widgets.page2:SetActive(0 < pageIdLeft and _bool)
  widgets.im_backgroud:SetActive(_bool)
end

function MagazineSinglePage:_ClickRight()
  self:initPageId()
  if self.isJapan then
    if self.indexRight <= 2 then
      self:_ClickClose()
      return
    end
    self.index = self.index - 2
  else
    if self.indexRight >= #self.page_id_list then
      self:_ClickClose()
      return
    end
    self.index = self.index + 2
  end
  self:_BookFlip()
end

function MagazineSinglePage:ShowButton()
  self:initPageId()
  if self.isJapan then
    self.tab_Widgets.btn_right.gameObject:SetActive(self.indexRight > 2)
    self.tab_Widgets.btn_left.gameObject:SetActive(self.indexLeft < #self.page_id_list)
  else
    self.tab_Widgets.btn_left.gameObject:SetActive(2 < self.indexLeft)
    self.tab_Widgets.btn_right.gameObject:SetActive(self.indexRight < #self.page_id_list)
  end
end

function MagazineSinglePage:GetMagazinePageMax()
  return #self.magazineConfig.contents_left + #self.magazineConfig.contents_right
end

function MagazineSinglePage:DoOnClose()
  BookFlip:Destroy()
end

function MagazineSinglePage:_BookFlip()
  self:initPageId()
  self:SetActivePage(false)
  self:ShowContent()
  BookFlip:SetPageIndex(self.indexLeft, self.indexRight, function()
    self:SetActivePage(true)
  end)
end

function MagazineSinglePage:SetLargeIndex()
  for i, v in ipairs(self.page_id_list_) do
    if v == self.largePageId then
      self.largePageIndex = i
    end
  end
end

function MagazineSinglePage:ShowLargeImage()
  local widgets = self:GetWidgets()
  local magazinePageId = self.page_id_list_[self.largePageIndex]
  local magazinePageConfig = configManager.GetDataById("config_magazine_page", magazinePageId)
  UIHelper.SetImage(widgets.im_large, magazinePageConfig.image_big)
  self.tab_Widgets.btn_before.gameObject:SetActive(self.largePageIndex > 1)
  self.tab_Widgets.btn_after.gameObject:SetActive(self.largePageIndex < #self.page_id_list_)
end

function MagazineSinglePage:btn_bookmark()
  local itemInfo = configManager.GetDataById("config_parameter", 365).arrValue
  local sum = Logic.rewardLogic:GetPossessNum(itemInfo[1], itemInfo[2])
  if sum < itemInfo[3] then
    noticeManager:ShowTipById(4000036)
    globalNoitceManager:ShowItemInfoPage(itemInfo[1], itemInfo[2])
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.magazineService:SendUnLock({
          MagazineId = self.magazineId
        })
      end
    end
  }
  local tips = UIHelper.GetString(4000034)
  noticeManager:ShowMsgBox(tips, tabParams)
end

return MagazineSinglePage
