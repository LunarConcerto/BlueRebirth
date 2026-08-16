local BuildShipItem = class("UI.BuildShip.BuildShipItem")
local EXPEND_COUNT = 2
local RewardType = {Twenty = 1, Hundred = 2}

function BuildShipItem:initialize(...)
  self.page = nil
  self.nIndex = nil
  self.buildConfigInfo = nil
  self.tabPart = nil
end

function BuildShipItem:Init(page, nIndex, tblConfig, tabPart)
  self.page = page
  self.nIndex = nIndex
  self.buildConfigInfo = tblConfig
  self.tabPart = tabPart
  self.showBoxReward = false
  self.showTimesReward = false
  self:_ShowOwnItem()
  self:_ShowExpend()
  self:_ShowSurplusTimes()
  self:_SetDisplay()
  self:_SetArrows()
  self:_ShowBoxAndTimesReward()
  self:_ShowLimitShip()
end

function BuildShipItem:_ShowOwnItem()
  local recuruitId = self.buildConfigInfo.expend[1][2]
  local bagInfo = Logic.bagLogic:ItemInfoById(recuruitId)
  local itemNum = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  self.tabPart.txt_itemNum.text = "x" .. itemNum
  local itemInfo = Logic.bagLogic:GetItemByConfig(recuruitId)
  UIHelper.SetImage(self.tabPart.img_itemIcon, tostring(itemInfo.icon_small))
end

function BuildShipItem:_ShowExpend()
  self.tabPart.txt_one.text = self.buildConfigInfo.btn_one_text
  self.tabPart.txt_ten.text = self.buildConfigInfo.btn_ten_text
  local expend = self.buildConfigInfo.expend
  if #expend > EXPEND_COUNT then
    logError("expend err")
    return
  end
  for i = 1, #expend do
    local expendType = configManager.GetDataById("config_table_index", tonumber(expend[i][1]))
    local itemInfo = configManager.GetDataById(expendType.file_name, tonumber(expend[i][2]))
    UIHelper.SetImage(self.tabPart["img_expend" .. tostring(i)], tostring(itemInfo.icon_small))
    UIHelper.SetImage(self.tabPart["img_expendTen" .. tostring(i)], tostring(itemInfo.icon_small))
    UIHelper.SetImage(self.tabPart["img_dailyExpend" .. tostring(i)], tostring(itemInfo.icon_small))
    self.tabPart["txt_expend" .. tostring(i)].text = "x" .. expend[i][3]
    self.tabPart["txt_expendTen" .. tostring(i)].text = "x" .. expend[i][3] * 10
    self.tabPart["txt_dailyExpend" .. tostring(i)].text = "x" .. expend[i][3]
  end
  if self.buildConfigInfo.btn_num == 1 then
    self.tabPart.btn_build.gameObject:SetActive(false)
    self.tabPart.btn_ten.gameObject:SetActive(false)
    self.tabPart.btn_daily.gameObject:SetActive(true)
  else
    self.tabPart.btn_build.gameObject:SetActive(true)
    self.tabPart.btn_ten.gameObject:SetActive(true)
    self.tabPart.btn_daily.gameObject:SetActive(false)
  end
  self.tabPart.obj_onebtn:SetActive(true)
  local status, freeRefreshTime = Logic.buildShipLogic:GetFreeRefreshTime(self.buildConfigInfo.id, self.buildConfigInfo.free_explore_type)
  if status == -1 then
    self.tabPart.obj_free:SetActive(false)
    self.tabPart.obj_freedesc:SetActive(false)
  elseif status == 0 then
    self.tabPart.obj_onebtn:SetActive(false)
    self.tabPart.obj_free:SetActive(true)
    self.tabPart.obj_freedesc:SetActive(true)
    self.tabPart.txt_free2.text = UIHelper.GetString(1110025)
  else
    self.tabPart.obj_free:SetActive(false)
    self.tabPart.obj_freedesc:SetActive(true)
  end
  if 0 < freeRefreshTime then
    local surplusTime = freeRefreshTime - time.getSvrTime()
    self.tabPart.txt_freedesc.text = string.format(UIHelper.GetString(1110026), UIHelper.GetCountDownStr(surplusTime))
  end
  self.page:RegisterRedDot(self.tabPart.red_dot, self.buildConfigInfo)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_build, self.page._ClickBuildOne, self.page)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_daily, self.page._ClickBuildOne, self.page)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_ten, self.page._ClickBuildTen, self.page)
end

function BuildShipItem:_ShowSurplusTimes()
  self.tabPart.obj_times:SetActive(self.buildConfigInfo.show_draw_id > 0)
  if self.buildConfigInfo.show_draw_id <= 0 then
    return
  end
  local drawId = self.buildConfigInfo.show_draw_id
  local limitCount = configManager.GetDataById("config_specialdraw", drawId).max_show_num
  local normalCount = Data.buildShipData:GetBuildShipCount(self.buildConfigInfo.id)
  local times = limitCount - normalCount % limitCount
  local timesDesc
  if times ~= 1 then
    timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.tentimedesc), times)
  else
    timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.onetimedesc), times)
  end
  if normalCount < 20 and 0 < self.buildConfigInfo.twentyrewarddesc and 0 < self.buildConfigInfo.twentytenrewarddesc and 0 < self.buildConfigInfo.twentytimedesc and 0 < self.buildConfigInfo.twentyleasttentimedesc then
    local times20 = 20 - normalCount % 20
    if times20 == 1 then
      timesDesc = UIHelper.GetString(self.buildConfigInfo.twentyrewarddesc)
    elseif times == 1 then
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.twentytenrewarddesc), times20)
    elseif normalCount < 10 then
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.twentytimedesc), times, times20)
    elseif 0 < #self.buildConfigInfo.twenty_drop then
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.twentyleasttentimedesc), times20, times20)
    else
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.twentyleasttentimedesc), times20)
    end
  elseif normalCount < 100 and 0 < self.buildConfigInfo.hundredtimedesc and 0 < self.buildConfigInfo.hundredtenrewarddesc and 0 < self.buildConfigInfo.hundredrewarddesc and 0 < self.buildConfigInfo.hundredleasttentimedesc then
    local times100 = 100 - normalCount % 100
    if times100 == 1 then
      timesDesc = UIHelper.GetString(self.buildConfigInfo.hundredrewarddesc)
    elseif times == 1 then
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.hundredtenrewarddesc), times100)
    elseif normalCount < 90 then
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.hundredtimedesc), times, times100)
    else
      timesDesc = string.format(UIHelper.GetString(self.buildConfigInfo.hundredleasttentimedesc), times100, times100)
    end
  end
  self.tabPart.txt_timeDesc.text = timesDesc
  self.tabPart.txt_specialdesc:SetActive(self.buildConfigInfo.isshow_special_desc == 1)
end

function BuildShipItem:_SetDisplay()
  local dispLv = Data.buildShipData:GetDispCount(self.buildConfigInfo.id)
  UIHelper.SetImage(self.tabPart.img_showPic, Logic.buildShipLogic:GetShowPic(self.buildConfigInfo, dispLv))
  if self.buildConfigInfo.desc[dispLv] > 0 then
    UIHelper.SetLocText(self.tabPart.txt_desc, Logic.buildShipLogic:GetShowDesc(self.buildConfigInfo, dispLv))
  end
  if 0 < self.buildConfigInfo.time_desc and self.buildConfigInfo.is_show_time == 1 then
    self.tabPart.txt_actTime.gameObject:SetActive(true)
    local startTime, endTime = Logic.buildShipLogic:GetActEndTime(self.buildConfigInfo.id)
    local startT = time.formatTimeToMDHM(startTime)
    local endT = time.formatTimeToMDHM(endTime)
    UIHelper.SetText(self.tabPart.txt_actTime, string.format(UIHelper.GetString(self.buildConfigInfo.time_desc), startT, endT))
  else
    self.tabPart.txt_actTime.gameObject:SetActive(false)
  end
  local isShip = self.buildConfigInfo.extract_type == ExtractType.SHIP
  self.tabPart.obj_drawTips:SetActive(isShip)
  local pos
  if isShip then
    local coor = configManager.GetDataById("config_parameter", 184).arrValue
    pos = Vector2.New(coor[1], coor[2])
  else
    local coor = configManager.GetDataById("config_parameter", 185).arrValue
    pos = Vector2.New(coor[1], coor[2])
  end
  self.tabPart.btn_dropShow.gameObject:SetActive(self.buildConfigInfo.extract_type == ExtractType.FASHION)
  local descName, descTime = Logic.buildShipLogic:_GetTogName(self.buildConfigInfo)
  self.tabPart.txt_namePart.text = descName
  self.tabPart.txt_time.text = descTime
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_help, self.page._OpenHelp, self.page)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_dropShow, self.page._ClickDropShow, self.page)
end

function BuildShipItem:_SetArrows()
  self.tabPart.btn_right.gameObject:SetActive(self.nIndex ~= #self.page.allBuildShipConf)
  self.tabPart.btn_left.gameObject:SetActive(1 ~= self.nIndex)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_right, self.page._ClickRight, self.page)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_left, self.page._ClickLeft, self.page)
end

function BuildShipItem:_ShowBoxAndTimesReward()
  self:_ShowBoxReward()
  self:_ShowTimesReward()
  local descTime = Logic.buildShipLogic:GetSurplusTime(self.buildConfigInfo.id)
  self.tabPart.txt_rewardTime.text = descTime == "" and UIHelper.GetString(1110066) or descTime
  self.tabPart.obj_rewardBg:SetActive(self.showBoxReward or self.showTimesReward)
end

function BuildShipItem:_ShowBoxReward()
  local rewardTab = self.buildConfigInfo.twenty_drop
  self.showBoxReward = #rewardTab ~= 0
  self.tabPart.obj_boxReward:SetActive(#rewardTab ~= 0)
  self.page:RegisterRedDot(self.tabPart.im_twentyDot, rewardTab, self.buildConfigInfo.id, RewardType.Twenty)
  if #rewardTab == 0 then
    return
  end
  local usedCountTab = Data.buildShipData:GetUsedBoxCoundTab(self.buildConfigInfo.id)
  local index = #usedCountTab + 1
  if index > #rewardTab then
    self.showBoxReward = false
    self.tabPart.obj_boxReward:SetActive(false)
    return
  end
  local normalCount = Data.buildShipData:GetBuildShipCount(self.buildConfigInfo.id)
  local limitCount = rewardTab[index][1]
  local rewardId = rewardTab[index][2]
  UIHelper.SetImage(self.tabPart.img_boxRewardIcon, self.buildConfigInfo.button_image)
  self.tabPart.txt_boxRewardName.text = self.buildConfigInfo.twenty_drop_name[index]
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_getBoxReward, self.GetBoxReward, self, {
    dropId = rewardId,
    limitCount = limitCount,
    normalCount = normalCount
  })
  local needDraw = limitCount - normalCount
  if needDraw <= 0 and #self.buildConfigInfo.button_effect ~= 0 then
    local effPath = self.buildConfigInfo.button_effect[index]
    self.page:CreateUIEffect(effPath, self.tabPart.obj_getBoxReward.transform)
  end
end

function BuildShipItem:GetBoxReward(obj, param)
  if not self.page:CheckStatus() then
    return
  end
  local allReward = Logic.rewardLogic:GetAllShowRewardByDropId(param.dropId)
  Logic.buildShipLogic:BoxRewardChooseFlg(false)
  UIHelper.OpenPage("BuildShipBoxPage", {
    buildId = self.buildConfigInfo.id,
    limitCount = param.limitCount,
    normalCount = param.normalCount,
    rewards = allReward
  })
end

function BuildShipItem:_ShowTimesReward()
  local rewardTab = self.buildConfigInfo.hundred_reward
  self.showTimesReward = #rewardTab ~= 0
  self.tabPart.obj_timesReward:SetActive(#rewardTab ~= 0)
  self.page:RegisterRedDot(self.tabPart.im_hundredDot, rewardTab, self.buildConfigInfo.id, RewardType.Hundred)
  if #rewardTab == 0 then
    return
  end
  local usedCountTab = Data.buildShipData:GetUsedRewardCoundTab(self.buildConfigInfo.id)
  local index = #usedCountTab + 1
  if index > #rewardTab then
    self.showTimesReward = false
    self.tabPart.obj_timesReward:SetActive(false)
    return
  end
  local normalCount = Data.buildShipData:GetBuildShipCount(self.buildConfigInfo.id)
  local limitCount = rewardTab[index][1]
  local rewardId = rewardTab[index][2]
  local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardId)
  local tabReward = Logic.bagLogic:GetItemByTempateId(rewardInfo[1].Type, rewardInfo[1].ConfigId)
  UIHelper.SetImage(self.tabPart.img_timesRewardIcon, tabReward.icon)
  self.tabPart.txt_timesRewardName.text = tabReward.name
  self.tabPart.txt_timesRewardNum.text = rewardInfo[1].Num
  self.tabPart.slider_timesReward.value = normalCount / limitCount < 1 and normalCount / limitCount or 1
  local needDraw = limitCount - normalCount
  if needDraw <= 0 then
    UGUIEventListener.AddButtonOnClick(self.tabPart.btn_getTimesReward, self.GetTimesReward, self, limitCount)
    self.tabPart.obj_getTimesReward:SetActive(true)
    self.tabPart.txt_timesRewardProgress.text = limitCount .. "/" .. limitCount
    if #self.buildConfigInfo.button_effect ~= 0 then
      local effPath = self.buildConfigInfo.button_effect[index]
      self.page:CreateUIEffect(effPath, self.tabPart.obj_getTimesReward.transform)
    end
  else
    self.tabPart.txt_timesRewardProgress.text = normalCount .. "/" .. limitCount
    UGUIEventListener.AddButtonOnClick(self.tabPart.btn_timesRewardDrawTips, function()
      noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(1110060), needDraw, tabReward.name))
    end)
    self.tabPart.obj_getTimesReward:SetActive(false)
  end
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_hundredCheck, self._ClickHundredCheck, self, rewardInfo[1])
end

function BuildShipItem:_ClickHundredCheck(go, reward)
  local typ = reward.Type
  local id = reward.ConfigId
  noticeManager:CloseTip()
  Logic.itemLogic:ShowItemInfo(typ, id)
end

function BuildShipItem:GetTimesReward(obj, limitCount)
  if not self.page:CheckStatus() then
    return
  end
  self.page.mDrawEquip = true
  Service.buildShipService:SendBuildShipReward({
    Id = self.buildConfigInfo.id,
    Num = limitCount
  })
end

function BuildShipItem:_ShowLimitShip()
  self.tabPart.obj_dailyDrawPart:SetActive(self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP)
  if self.buildConfigInfo.extract_type ~= ExtractType.LIMIT_SHIP then
    return
  end
  local surplusTotleNum = 0
  local surplusNumTab = Data.buildShipData:GetSpecialInfo(self.buildConfigInfo.id)
  surplusNumTab = surplusNumTab[3] == nil and {} or surplusNumTab[3]
  for i, shipTId in ipairs(self.buildConfigInfo.show_ship) do
    local surplusNum = surplusNumTab[shipTId] ~= nil and surplusNumTab[shipTId] or 0
    local girlImage = 0 < surplusNum and self.buildConfigInfo.ship_image[i][1] or self.buildConfigInfo.ship_image[i][2]
    UIHelper.SetImage(self.tabPart["img_girl" .. tostring(i)], tostring(girlImage))
    UIHelper.SetLocText(self.tabPart["textNum" .. tostring(i)], 1110048, surplusNum)
    surplusTotleNum = surplusTotleNum + surplusNum
  end
  self.tabPart.obj_times:SetActive(true)
  self.tabPart.txt_timeDesc.text = string.format(UIHelper.GetString(self.buildConfigInfo.tentimedesc), surplusTotleNum)
end

return BuildShipItem
