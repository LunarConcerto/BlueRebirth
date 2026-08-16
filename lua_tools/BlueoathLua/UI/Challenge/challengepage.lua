local ChallengePage = class("UI.Challenge.ChallengePage", LuaUIPage)

function ChallengePage:DoInit()
  self.func = {
    [FunctionID.GoodsCopy] = self.GoodsCopy,
    [FunctionID.Tower] = self.Tower,
    [FunctionID.TowerActivity] = self.TowerActivity,
    [FunctionID.MultiPveEntrance] = self.MultiPveEntrance
  }
  self.tbl = {}
end

function ChallengePage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {TitleName = "\230\140\145\230\136\152", CloseFunc = nil})
  local configs = self:GetChallenges()
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.template, widgets.Content, #configs, function(index, tabPart)
    local config = configs[index]
    UIHelper.SetText(tabPart.tx_name, config.name)
    if config.icon ~= "" then
      UIHelper.SetImage(tabPart.img_icon, config.icon)
    end
    if config.function_id > 0 then
      UGUIEventListener.AddButtonOnClick(tabPart.bu_template, self._btnClick, self, config)
    end
    tabPart.reddot.gameObject:SetActive(0 < #config.red_dot)
    if 0 < #config.red_dot then
      self:RegisterRedDotByParamList(tabPart.reddot, config.red_dot, config.red_dot_param)
    end
    tabPart.im_line_left_up.gameObject:SetActive(index % 2 == 0 and index ~= 1)
    tabPart.im_line_left_down.gameObject:SetActive(index % 2 == 1 and index ~= 1)
    tabPart.im_line_right_up.gameObject:SetActive(index % 2 == 1 and index ~= #configs)
    tabPart.im_line_right_down.gameObject:SetActive(index % 2 == 0 and index ~= #configs)
    tabPart.im_line_left_up_long.gameObject:SetActive(index % 2 == 0 and index == 1)
    tabPart.im_line_left_down_long.gameObject:SetActive(index % 2 == 1 and index == 1)
    tabPart.im_line_right_up_long.gameObject:SetActive(index % 2 == 1 and index == #configs)
    tabPart.im_line_right_down_long.gameObject:SetActive(index % 2 == 0 and index == #configs)
    self:_handle(config, tabPart)
  end)
end

function ChallengePage:_handle(config, tabPart)
  self.tbl[config.function_id] = tabPart
  if self.func[config.function_id] then
    self.func[config.function_id](self, tabPart)
  else
    self:_handleDefault(config, tabPart)
  end
  self:_handleCommon(config, tabPart)
end

function ChallengePage:_handleDefault(config, tabPart)
  tabPart.tx_timeleft.gameObject:SetActive(false)
  tabPart.tx_progress.gameObject:SetActive(false)
end

function ChallengePage:_handleCommon(config, tabPart)
  tabPart.LongMessage:SetActive(config.message1 ~= "" and config.message2 ~= "")
  tabPart.tx_message1.text = config.message1
  tabPart.tx_message2.text = config.message2
end

function ChallengePage:_btnClick(go, config)
  moduleManager:JumpToFunc(config.function_id, table.unpack(config.function_param))
end

function ChallengePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  self:RegisterEvent(LuaEvent.UpdateTowerInfo, self.UpdateTowerInfo, self)
end

function ChallengePage:GetChallenges()
  local result = {}
  local config = configManager.GetData("config_challenge")
  for i, v in pairs(config) do
    if v.is_open == 1 then
      if v.function_id == FunctionID.ARKit then
        if XR:IsSupport() then
          table.insert(result, v)
        end
      elseif v.function_id == FunctionID.TowerActivity then
        if Logic.towerActivityLogic:GetTowerActivity() > 0 then
          table.insert(result, v)
        end
      elseif v.function_id == FunctionID.MultiPveEntrance then
        local actConfig = Logic.multiPveActLogic:GetActConfig()
        local isOpen = Data.activityData:IsActivityOpen(actConfig.id)
        if isOpen then
          table.insert(result, v)
        end
      else
        table.insert(result, v)
      end
    end
  end
  table.sort(result, function(data1, data2)
    if data1.order ~= data2.order then
      return data1.order < data2.order
    else
      return data1.id < data2.id
    end
  end)
  return result
end

function ChallengePage:Tower(tabPart)
  local towerData = Data.towerData:GetData() or {}
  local flag = towerData and towerData.ChapterId and towerData.ChapterId > 0
  tabPart.progress:SetActive(true)
  tabPart.time:SetActive(true)
  local timeLeft = Logic.towerLogic:GetLeftTime()
  tabPart.TowerOver:SetActive(flag and timeLeft < 0)
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontOnly(timeLeft)
  UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
  if flag then
    local progress = Logic.towerLogic:GetProgress()
    UIHelper.SetLocText(tabPart.tx_progress, 1700003, progress)
    local timer = self:CreateTimer(function()
      local timeLeft = Logic.towerLogic:GetLeftTime()
      local timeShow = 0 <= timeLeft and timeLeft or 0
      tabPart.TowerOver:SetActive(timeLeft < 0)
      local timeFormat = time.getTimeStringFontOnly(timeShow)
      UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
    end, 0.5, -1)
    self:StartTimer(timer)
  else
    local timeFormat = time.getTimeStringFontOnly(0)
    UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
    UIHelper.SetLocText(tabPart.tx_progress, 1700003, UIHelper.GetString(510002))
  end
end

function ChallengePage:TowerActivity(tabPart)
  tabPart.progress:SetActive(true)
  tabPart.time:SetActive(true)
  local timeLeft = Logic.towerActivityLogic:GetLeftTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontOnly(timeLeft)
  UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
  local passNum = Logic.towerActivityLogic:GetPassNum()
  if 0 < passNum then
    UIHelper.SetLocText(tabPart.tx_progress, 2900020, passNum)
  else
    UIHelper.SetLocText(tabPart.tx_progress, 1700003, UIHelper.GetString(510002))
  end
  local timer = self:CreateTimer(function()
    local timeLeft = Logic.towerActivityLogic:GetLeftTime()
    local timeShow = 0 <= timeLeft and timeLeft or 0
    tabPart.TowerOver:SetActive(timeLeft < 0)
    local timeFormat = time.getTimeStringFontOnly(timeShow)
    UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
  end, 0.5, -1)
  self:StartTimer(timer)
end

function ChallengePage:GoodsCopy(tabPart)
  tabPart.progress:SetActive(true)
  tabPart.time:SetActive(true)
  local rank = Logic.goodsCopyLogic:GetRankPercent() / 100
  if rank < 0 then
    rank = UIHelper.GetString(510002)
  else
    rank = string.format("%.2f%%", rank)
  end
  UIHelper.SetLocText(tabPart.tx_progress, 1700002, rank)
  local timeLeft = Logic.goodsCopyLogic:GetRemainTime()
  local timeFormat = time.getTimeStringFontOnly(timeLeft)
  UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
end

function ChallengePage:UpdateTowerInfo()
  self:Tower(self.tbl[FunctionID.Tower])
end

function ChallengePage:MultiPveEntrance(tabPart)
  tabPart.time:SetActive(true)
  tabPart.progress:SetActive(true)
  local timeLeft = Logic.multiPveActLogic:GetActTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontOnly(timeLeft)
  UIHelper.SetLocText(tabPart.tx_timeleft, 1700032, timeFormat)
  local chapterId = 15000
  local times = Data.copyData:GetCopyRewardCount(chapterId)
  UIHelper.SetLocText(tabPart.tx_progress, 4800012, times)
end

return ChallengePage
