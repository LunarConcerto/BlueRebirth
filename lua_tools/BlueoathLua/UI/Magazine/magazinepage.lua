local MagazinePage = class("UI.Magazine.MagazinePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local InitCamPosX = 999999

function MagazinePage:DoInit()
end

function MagazinePage:DoOnOpen()
  local camera = GR.cameraManager:showCamera(GameCameraType.MagazineSceneCamera)
  local cam = camera:GetCam()
  if 999998 < InitCamPosX then
    InitCamPosX = cam.transform.position.x
  end
  local x = InitCamPosX
  local rate = Screen.width / Screen.height
  if rate < 1.7777777777777777 then
    x = (x - 3.49) * 16 / 9 / rate + 3.49
  end
  cam.transform.position = Vector3.New(x, cam.transform.position.y, cam.transform.position.z)
  local config = Logic.magazineLogic:GetLatest()
  if config then
    PlayerPrefs.SetInt(PlayerPrefsKey.NewStrategy, config.id)
  end
  local configs = Logic.magazineLogic:GetSortAndOpen()
  self.configs = configs
  self:ShowCover()
  self:ShowAllMagazine()
  self:ShowTag()
  self:ShowTask()
end

function MagazinePage:Refresh()
  local configs = Logic.magazineLogic:GetSortAndOpen()
  self.configs = configs
  self:ShowCover()
  self:ShowAllMagazine()
  self:ShowTag()
  self:ShowTask()
end

function MagazinePage:RefreshBuffHero()
  local serverTime = time.getSvrTime()
  local configs = self.configs
  local startTime, endTime = PeriodManager:GetPeriodTime(configs[1].period, configs[1].task_period_area)
  local _time = endTime - serverTime
  if 0 <= _time then
    local timer = self:CreateTimer(function()
      Service.taskService:SendTaskInfo()
      Service.magazineService:SendGetMagazine()
    end, _time + 1, 1)
    self:StartTimer(timer)
  end
end

function MagazinePage:ShowTicket()
  local widgets = self:GetWidgets()
  local parameter = configManager.GetDataById("config_parameter", 356).arrValue
  local num = Logic.bagLogic:GetConsumeCurrNum(parameter[1], parameter[2])
  UIHelper.SetLocText(widgets.tx_ticket, 4000013, num)
end

function MagazinePage:ShowCover()
  local widgets = self:GetWidgets()
  local configs = self.configs
  for i = 1, 1 do
    local config = configs[i]
    self.tab_Widgets["cover" .. i].gameObject:SetActive(config)
    if config then
      UIHelper.SetImage(self.tab_Widgets["cover" .. i], config.cover_image)
    end
    if i == 1 then
      UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cover.gameObject, function()
        self:OpenMagazineSinglePage(config.id)
      end)
    end
  end
  self:ShowTicket()
  local startTime, endTime = PeriodManager:GetPeriodTime(configs[1].period, configs[1].task_period_area)
  self:StopAllTimer()
  local timer = self:CreateTimer(function()
    local timeLeft = endTime - time.getSvrTime()
    widgets.tx_time.gameObject:SetActive(0 < timeLeft)
    if 0 < timeLeft then
      local timeLeftFormat = time.getTimeStringFontTwo(timeLeft)
      UIHelper.SetLocText(widgets.tx_time, 4000019, timeLeftFormat)
    else
      UIHelper.SetLocText(widgets.tx_time, 4000020)
    end
  end, 0.5, -1)
  self:StartTimer(timer)
  self:RefreshBuffHero()
  local isOpen = PeriodManager:IsInPeriodArea(configs[1].period, configs[1].task_period_area)
  widgets.title:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_enlarge1, function()
    self.tab_Widgets.btn_large.gameObject:SetActive(true)
    UIHelper.SetImage(self.tab_Widgets.im_large, configs[1].cover_image_big)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_large, function()
    self.tab_Widgets.btn_large.gameObject:SetActive(false)
  end)
end

function MagazinePage:ShowAllMagazine()
  local widgets = self:GetWidgets()
  local configs = self.configs
  UIHelper.CreateSubPart(widgets.im_magazine, widgets.Content, #configs, function(index, tabPart)
    local config = configs[index]
    UIHelper.SetImage(tabPart.img, config.cover_image)
    self:RegisterRedDot(tabPart.reddot, config.id)
    UIHelper.SetText(tabPart.tx_number, "No." .. config.id)
    if config.special ~= MagazineSpecial.Special then
      local item = config.item
      local conditionList = config.condition
      local num = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
      local numMax = config.condition_max
      UIHelper.SetTextColorByBool(tabPart.tx_num, num .. "/" .. numMax, 111, 110, num >= numMax)
    end
    tabPart.obj_star:SetActive(config.special ~= MagazineSpecial.Special)
    local magazineState = Logic.magazineLogic:GetMagazineState(config.id)
    tabPart.tag_lock:SetActive(magazineState == MagazineState.Lock)
    tabPart.tag_release:SetActive(magazineState == MagazineState.UnLock)
    tabPart.tag_active:SetActive(magazineState == MagazineState.Active)
    UGUIEventListener.AddButtonOnClick(tabPart.btn, function()
      self:OpenMagazineSinglePage(config.id)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.im_enlarge, function()
      self.tab_Widgets.btn_large.gameObject:SetActive(true)
      UIHelper.SetImage(self.tab_Widgets.im_large, config.cover_image_big)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_star, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(item[1], item[2]))
    end)
  end)
end

function MagazinePage:ShowTag()
  local widgets = self:GetWidgets()
  local config = self.configs[1]
  self.tab_Widgets.btn_pick.gameObject:SetActive(config.special ~= MagazineSpecial.Special)
  self.tab_Widgets.tx_ticket.gameObject:SetActive(config.special ~= MagazineSpecial.Special)
  local finishNum = Logic.magazineLogic:GetLeftTaskFinishNum(config.id)
  local tags = config.show_tag_id
  local release_lock = config.release_lock
  local buffList = config.buff_id
  local isOpen = PeriodManager:IsInPeriodArea(config.period, config.task_period_area)
  local im_num = config.tag_num_image
  UIHelper.CreateSubPart(widgets.tag, widgets.content_tag, #tags, function(index, tabPart)
    local tag = tags[index]
    local tagConfig = configManager.GetDataById("config_magazine_tag", tag)
    local cond_num = release_lock[index]
    local buff_id = buffList[index]
    local buffConfig = configManager.GetDataById("config_value_effect", buff_id)
    UIHelper.SetImage(tabPart.im_buff, buffConfig.buff_icon)
    UIHelper.SetImage(tabPart.im_num, im_num[index])
    UIHelper.SetText(tabPart.tx_buff, buffConfig.type_show)
    UIHelper.SetText(tabPart.tx_buffup, buffConfig.value_show)
    local heroId = Data.magazineData:GetHeroIdByIndex(index)
    tabPart.im_add.gameObject:SetActive(heroId <= 0 and cond_num <= finishNum and isOpen)
    tabPart.im_lock.gameObject:SetActive(cond_num > finishNum or not isOpen)
    tabPart.im_shipbg.gameObject:SetActive(0 < heroId and isOpen)
    if 0 < heroId then
      local heroInfo = Data.heroData:GetHeroById(heroId)
      local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
      local ship_show_config = configManager.GetDataById("config_ship_show", shipInfo.sf_id)
      local icon = ship_show_config.ship_icon_bathroom
      UIHelper.SetText(tabPart.tx_shipname, shipInfo.ship_name)
      UIHelper.SetImage(tabPart.im_ship, icon)
    end
    UIHelper.SetText(tabPart.tx_tag, tagConfig.name)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_choose, function()
      if not isOpen then
        noticeManager:ShowTipById(4000020)
        return
      end
      if finishNum < cond_num then
        noticeManager:ShowTipById(4000005, cond_num)
        return
      end
      local displayInfo = Logic.magazineLogic:GetAllHeroByTagId(tag)
      local heroList = 0 < heroId and {heroId} or {}
      UIHelper.OpenPage("CommonSelectPage", {
        CommonHeroItem.Magazine,
        displayInfo,
        {m_selectMax = 1, m_selectedIdList = heroList},
        magazineIndex = index,
        magazineId = config.id
      })
    end)
  end)
end

function MagazinePage:ShowTask()
  local widgets = self:GetWidgets()
  local config = self.configs[1]
  local taskList = config.task_left_id
  UIHelper.CreateSubPart(widgets.task, widgets.content_task, #taskList, function(index, tabPart)
    local taskId = taskList[index]
    local taskData = Data.taskData:GetTaskDataById(taskId, TaskType.Magazine)
    local taskConfig = configManager.GetDataById("config_task_magazine", taskId)
    UIHelper.SetText(tabPart.tx_task, taskConfig.desc)
    local max = Logic.taskLogic:GetTotalCount(taskId, TaskType.Magazine)
    local cur = Logic.taskLogic:GetCurCount(taskData, max)
    UIHelper.SetText(tabPart.tx_progress, cur .. "/" .. max)
    UIHelper.SetTextColorByBool(tabPart.tx_progress, cur .. "/" .. max, 111, 112, max <= cur)
  end)
  local taskIdRight = config.task_right_id[1]
  local state = Logic.taskLogic:GetTaskFinishState(taskIdRight, TaskType.Magazine)
  widgets.tx_task_des:SetActive(state == TaskState.TODO)
  widgets.tx_get_des:SetActive(state ~= TaskState.TODO)
  local taskConfig = configManager.GetDataById("config_task_magazine", taskIdRight)
  local rewardId = taskConfig.rewards
  local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
  local rewardFirst = rewardInfo[1]
  local tabReward = ItemInfoPage.GenDisplayData(rewardFirst.Type, rewardFirst.ConfigId)
  UIHelper.SetImage(widgets.im_reward, tabReward.icon)
  UGUIEventListener.AddButtonOnClick(widgets.btn_im_reward, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewardFirst.Type, rewardFirst.ConfigId))
  end)
  UIHelper.CreateSubPart(widgets.reward1, widgets.Content1, #rewardInfo - 1, function(nIndex, luaPart)
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local rewardInfoSub = rewardInfo[nIndex + 1]
    local tabReward = ItemInfoPage.GenDisplayData(rewardInfoSub.Type, rewardInfoSub.ConfigId)
    UIHelper.SetImage(luaPart.img_icon, tabReward.icon)
    UIHelper.SetImage(luaPart.img_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(luaPart.tx_num, rewardInfoSub.Num)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_reward, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(rewardInfoSub.Type, rewardInfoSub.ConfigId))
    end)
  end)
  widgets.im_mask:SetActive(not PeriodManager:IsInPeriodArea(config.period, config.task_period_area))
end

function MagazinePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_open, self._ClickOpen, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_case, self._ClickCloseCover, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_pick, self._ClickPick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_openbutton, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowTicket, self)
  self:RegisterEvent(LuaEvent.GetMagazineMsg, self.Refresh, self)
end

function MagazinePage:_ClickClose()
  UIHelper.ClosePage("MagazinePickPage")
  UIHelper.ClosePage("MagazineSinglePage")
  UIHelper.ClosePage("MagazinePage")
  eventManager:SendEvent(LuaEvent.MagazineBack)
  GR.cameraManager:showCamera(GameCameraType.RoomSceneCamera)
end

function MagazinePage:_ClickOpen()
  self.tab_Widgets.obj_case:SetActive(true)
end

function MagazinePage:_ClickCloseCover()
  self.tab_Widgets.obj_case:SetActive(false)
end

function MagazinePage:_ClickPick()
  local configs = self.configs
  local isOpen = PeriodManager:IsInPeriodArea(configs[1].period, configs[1].ticket_period_area)
  if not isOpen then
    noticeManager:ShowTipById(4000024)
    return
  end
  UIHelper.OpenPage("MagazinePickPage", {
    magazineId = self.configs[1].id
  })
end

function MagazinePage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 4000022})
end

function MagazinePage:DoOnClose()
end

function MagazinePage:OpenMagazineSinglePage(magazineId)
  UIHelper.OpenPage("MagazineSinglePage", {magazineId = magazineId})
end

return MagazinePage
