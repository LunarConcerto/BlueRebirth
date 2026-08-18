local BuildShipMainPage = class("UI.BuildShip.BuildShipMainPage")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local EXPEND_COUNT = 2
local RewardType = {Twenty = 1, Hundred = 2}
local Slider_Height = 356
local ShowBoxLimitNum = 2

function BuildShipMainPage:Init(page)
  self.page = page
  self.m_tabWidgets = page.m_tabWidgets
  self.buildConfigInfo = nil
end

function BuildShipMainPage:DisplayChangeByConfig(tblConfig)
  self.buildConfigInfo = tblConfig
  self.showBoxReward = true
  self:_ShowExpend()
  self:_ShowSurplusTimes()
  self:_SetDisplay()
  self:_ShowBoxAndTimesReward()
  self:_ShowLimitShip()
end

function BuildShipMainPage:_ShowExpend()
  self.m_tabWidgets.txt_one.text = self.buildConfigInfo.btn_one_text
  self.m_tabWidgets.txt_ten.text = self.buildConfigInfo.btn_ten_text
  local expend = self.buildConfigInfo.expend
  if #expend > EXPEND_COUNT then
    logError("expend err")
    return
  end
  for i = 1, #expend do
    local expendType = configManager.GetDataById("config_table_index", tonumber(expend[i][1]))
    local itemInfo = configManager.GetDataById(expendType.file_name, tonumber(expend[i][2]))
    UIHelper.SetImage(self.m_tabWidgets["img_expend" .. tostring(i)], tostring(itemInfo.icon_small))
    UIHelper.SetImage(self.m_tabWidgets["img_expendTen" .. tostring(i)], tostring(itemInfo.icon_small))
    UIHelper.SetImage(self.m_tabWidgets["img_dailyExpend" .. tostring(i)], tostring(itemInfo.icon_small))
    self.m_tabWidgets["txt_expend" .. tostring(i)].text = "x" .. expend[i][3]
    self.m_tabWidgets["txt_expendTen" .. tostring(i)].text = "x" .. expend[i][3] * 10
    self.m_tabWidgets["txt_dailyExpend" .. tostring(i)].text = "x" .. expend[i][3]
  end
  local newExpend = Logic.buildShipLogic:GetOwnFreeItem(self.buildConfigInfo)
  if 0 < #newExpend and #self.buildConfigInfo.new_ten_expend ~= 0 then
    local expendType = configManager.GetDataById("config_table_index", tonumber(newExpend[1]))
    local itemInfo = configManager.GetDataById(expendType.file_name, tonumber(newExpend[2]))
    UIHelper.SetImage(self.m_tabWidgets["img_expendTen" .. tostring(1)], tostring(itemInfo.icon_small))
    self.m_tabWidgets["txt_expendTen" .. tostring(1)].text = "x" .. newExpend[3]
  end
  if self.buildConfigInfo.btn_num == 1 then
    self.m_tabWidgets.btn_build.gameObject:SetActive(false)
    self.m_tabWidgets.btn_ten.gameObject:SetActive(false)
    self.m_tabWidgets.btn_daily.gameObject:SetActive(true)
  else
    self.m_tabWidgets.btn_build.gameObject:SetActive(true)
    self.m_tabWidgets.btn_ten.gameObject:SetActive(true)
    self.m_tabWidgets.btn_daily.gameObject:SetActive(false)
  end
  self:ShowFreeTips()
  self:ShowTenFreeTips()
  self.page:RegisterRedDot(self.m_tabWidgets.red_dot, self.buildConfigInfo)
  self.page:RegisterRedDot(self.m_tabWidgets.tenRedDot, self.buildConfigInfo.id)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_build, self.page._ClickBuildOne, self.page)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_daily, self.page._ClickBuildOne, self.page)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ten, self.page._ClickBuildTen, self.page)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_upEquip, self._OpenUpInfo, self)
end

function BuildShipMainPage:ShowFreeTips()
  self.m_tabWidgets.obj_onebtn:SetActive(true)
  local status, freeRefreshTime = Logic.buildShipLogic:GetFreeRefreshTime(self.buildConfigInfo.id, self.buildConfigInfo.free_explore_type)
  if status == -1 then
    self.m_tabWidgets.obj_free:SetActive(false)
    self.m_tabWidgets.obj_freedesc:SetActive(false)
  elseif status == 0 then
    self.m_tabWidgets.obj_onebtn:SetActive(false)
    self.m_tabWidgets.obj_free:SetActive(true)
    self.m_tabWidgets.obj_freedesc:SetActive(true)
    self.m_tabWidgets.txt_free2.text = UIHelper.GetString(1110025)
  else
    self.m_tabWidgets.obj_free:SetActive(false)
    self.m_tabWidgets.obj_freedesc:SetActive(true)
  end
  if 0 < freeRefreshTime then
    local surplusTime = freeRefreshTime - time.getSvrTime()
    self.m_tabWidgets.txt_freedesc.text = string.format(UIHelper.GetString(1110026), UIHelper.GetCountDownStr(surplusTime))
  end
end

function BuildShipMainPage:ShowTenFreeTips()
  local tenStates = Logic.buildShipLogic:CheckTenFreeStatus(self.buildConfigInfo.id)
  self.m_tabWidgets.txt_ten.gameObject:SetActive(not tenStates)
  self.m_tabWidgets.obj_tenfree:SetActive(tenStates)
end

function BuildShipMainPage:_ShowSurplusTimes()
  self.m_tabWidgets.obj_times:SetActive(self.buildConfigInfo.show_draw_id > 0)
  self.m_tabWidgets.obj_times_long:SetActive(false)
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
  self.m_tabWidgets.txt_timeDesc.text = timesDesc
  self.m_tabWidgets.txt_specialdesc.gameObject:SetActive(self.buildConfigInfo.isshow_special_desc == 1)
  self.m_tabWidgets.btn_upEquip.gameObject:SetActive(self.buildConfigInfo.extract_reset_type ~= 0)
  if self.buildConfigInfo.extract_reset_type ~= 0 then
    local limit = self.buildConfigInfo.show_appear_num
    local uptimes = Logic.buildShipLogic:GetResetTypeCountByBuildId(self.buildConfigInfo.id)
    local surplusTimes = limit - uptimes
    self.m_tabWidgets.obj_times_long:SetActive(true)
    self.m_tabWidgets.obj_times:SetActive(false)
    local upDesc = ""
    if 1 < surplusTimes then
      upDesc = string.format(UIHelper.GetString(1200019), surplusTimes)
    else
      upDesc = UIHelper.GetString(1200020)
    end
    self.m_tabWidgets.txt_timeDesc_long.text = upDesc .. timesDesc
  end
end

function BuildShipMainPage:_SetDisplay()
  local dispLv = Data.buildShipData:GetDispCount(self.buildConfigInfo.id)
  UIHelper.SetImage(self.m_tabWidgets.img_showPic, Logic.buildShipLogic:GetShowPic(self.buildConfigInfo, dispLv))
  self.m_tabWidgets.obj_Preview:SetActive(Logic.buildShipLogic:IsShowPreview(self.buildConfigInfo.id))
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.obj_Preview, function()
    UIHelper.OpenPage("DrawPreviewPage", {
      id = self.buildConfigInfo.id,
      page = self.page
    })
  end, self)
  if #self.buildConfigInfo.desc > 0 and self.buildConfigInfo.desc[dispLv] > 0 then
    if self.buildConfigInfo.up_type == 1 and self.buildConfigInfo.extract_type == ExtractType.SHIP then
      local nameTable = {}
      for _, v in ipairs(self.buildConfigInfo.ssr_up_ship_info) do
        if v and 0 < #v then
          local name = Logic.shipLogic:GetShipShowById(v[1]).ship_name
          table.insert(nameTable, name)
        end
      end
      for _, v in ipairs(self.buildConfigInfo.sr_up_ship_info) do
        if v and 0 < #v then
          local name = Logic.shipLogic:GetShipShowById(v[1]).ship_name
          table.insert(nameTable, name)
        end
      end
      local nameStr = table.concat(nameTable, "\227\128\129")
      local languageId = Logic.buildShipLogic:GetShowDesc(self.buildConfigInfo, dispLv)
      local descStr = string.format(UIHelper.GetString(languageId), nameStr)
      UIHelper.SetText(self.m_tabWidgets.txt_desc, descStr)
    else
      UIHelper.SetLocText(self.m_tabWidgets.txt_desc, Logic.buildShipLogic:GetShowDesc(self.buildConfigInfo, dispLv))
    end
  end
  self.m_tabWidgets.obj_desc.gameObject:SetActive(#self.buildConfigInfo.desc > 0)
  self.m_tabWidgets.txt_actTime.gameObject:SetActive(false)
  local isShip = self.buildConfigInfo.extract_type == ExtractType.SHIP
  self.m_tabWidgets.obj_drawTips:SetActive(isShip)
  local isLaisha = self.buildConfigInfo.extract_type == ExtractType.MixTure
  self.m_tabWidgets.obj_imgObj:SetActive(not isLaisha)
  local pos
  if isShip then
    local coor = configManager.GetDataById("config_parameter", 184).arrValue
    pos = Vector2.New(coor[1], coor[2])
  else
    local coor = configManager.GetDataById("config_parameter", 185).arrValue
    pos = Vector2.New(coor[1], coor[2])
  end
  self.m_tabWidgets.btn_dropShow.gameObject:SetActive(self.buildConfigInfo.extract_type == ExtractType.FASHION)
  self.m_tabWidgets.img_name.gameObject:SetActive(#self.buildConfigInfo.name_pic ~= 0)
  if #self.buildConfigInfo.name_pic ~= 0 then
    local namePic = self.buildConfigInfo.name_pic[dispLv]
    UIHelper.SetImage(self.m_tabWidgets.img_name, namePic)
  end
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_help, self.page._OpenHelp, self.page)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_dropShow, self.page._ClickDropShow, self.page)
end

function BuildShipMainPage:_SetArrows()
  self.m_tabWidgets.btn_right.gameObject:SetActive(self.nIndex ~= #self.page.allBuildShipConf)
  self.m_tabWidgets.btn_left.gameObject:SetActive(1 ~= self.nIndex)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, self.page._ClickRight, self.page)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, self.page._ClickLeft, self.page)
end

function BuildShipMainPage:_ShowBoxAndTimesReward()
  self:_ShowTotalExploreReward()
  if not self.showBoxReward then
    self.m_tabWidgets.obj_rewardBg:SetActive(false)
    self.m_tabWidgets.obj_sliderReward:SetActive(false)
  else
  end
end

function BuildShipMainPage:GetBoxReward(obj, param)
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

function BuildShipMainPage:_ClickHundredCheck(go, params)
  local reward = params[1]
  local str = params[2]
  Logic.itemLogic:ShowItemInfo(reward.itemType, reward.itemId)
  eventManager:SendEvent(LuaEvent.SetBuildTips, str)
end

function BuildShipMainPage:GetTimesReward(obj, config)
  if not self.page:CheckStatus() then
    return
  end
  self.page.mDrawEquip = true
  local reward = {}
  local rewards = {}
  reward[1] = config.itemType
  reward[2] = config.itemId
  reward[3] = config.count
  table.insert(rewards, reward)
  if not Logic.rewardLogic:CanGotReward(rewards, true) then
    return
  end
  Service.buildShipService:SendBuildShipReward({
    Id = self.buildConfigInfo.id,
    Num = config.limitCount
  })
end

function BuildShipMainPage:_ShowLimitShip()
  self.m_tabWidgets.obj_dailyDrawPart:SetActive(self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP)
  if self.buildConfigInfo.extract_type ~= ExtractType.LIMIT_SHIP then
    return
  end
  local surplusTotleNum = 0
  local surplusNumTab = Data.buildShipData:GetSpecialInfo(self.buildConfigInfo.id)
  surplusNumTab = surplusNumTab[3] == nil and {} or surplusNumTab[3]
  for i, shipTId in ipairs(self.buildConfigInfo.show_ship) do
    local surplusNum = surplusNumTab[shipTId] ~= nil and surplusNumTab[shipTId] or 0
    local girlImage = 0 < surplusNum and self.buildConfigInfo.ship_image[i][1] or self.buildConfigInfo.ship_image[i][2]
    UIHelper.SetImage(self.m_tabWidgets["img_girl" .. tostring(i)], tostring(girlImage))
    UIHelper.SetLocText(self.m_tabWidgets["textNum" .. tostring(i)], 1110048, surplusNum)
    surplusTotleNum = surplusTotleNum + surplusNum
  end
  self.m_tabWidgets.txt_timeDesc.text = string.format(UIHelper.GetString(self.buildConfigInfo.tentimedesc), surplusTotleNum)
end

function BuildShipMainPage:_OpenUpInfo()
  UIHelper.OpenPage("UPEquipInfoPage", self.buildConfigInfo)
end

function BuildShipMainPage:_ShowTotalExploreReward()
  local rewardTypeTab = self.buildConfigInfo.reward_type
  if #rewardTypeTab == 0 then
    self.showBoxReward = false
    return
  end
  local showReward = Logic.buildShipLogic:GetShowBoxReward(rewardTypeTab, self.buildConfigInfo)
  if #showReward == 0 then
    self.showBoxReward = false
    return
  end
  if #showReward <= ShowBoxLimitNum then
    self:_DisplayBoxReward(showReward)
  else
    self:_DisplayProgressReward(showReward)
  end
end

function BuildShipMainPage:_DisplayBoxReward(showReward)
  self.m_tabWidgets.obj_sliderReward:SetActive(false)
  self.m_tabWidgets.obj_rewardBg:SetActive(true)
  local normalCount = Data.buildShipData:GetBuildShipCount(self.buildConfigInfo.id)
  self:_CreateRewardList(self.m_tabWidgets.obj_rewardItem, self.m_tabWidgets.trans_rewardList, showReward, normalCount)
  self.m_tabWidgets.txt_rewardTime.text = normalCount
end

function BuildShipMainPage:_DisplayProgressReward(showReward)
  self.m_tabWidgets.obj_sliderReward:SetActive(true)
  self.m_tabWidgets.obj_rewardBg:SetActive(false)
  local normalCount = Data.buildShipData:GetBuildShipCount(self.buildConfigInfo.id)
  self.m_tabWidgets.txt_totalNum.text = normalCount
  local tabPart = self:_CreateRewardList(self.m_tabWidgets.obj_sRewardItem, self.m_tabWidgets.trans_sliderReward, showReward, normalCount)
  self:_SetBuildProgress(showReward, tabPart, normalCount)
end

function BuildShipMainPage:_CreateRewardList(objItem, trans, showReward, normalCount)
  local tabPart = {}
  UIHelper.CreateSubPart(objItem, trans, #showReward, function(i, part)
    local config = showReward[i]
    if config.limitCount == 200 and (config.finish == true and Data.buildShipData:HasRewardBoxChanged(self.buildConfigInfo.id, 200) == true or config.finish == false and self.page:_HasSpecialInIlustrate() and self.buildConfigInfo.special_change_reward ~= nil and #self.buildConfigInfo.special_change_reward > 0) then
      local k = self.buildConfigInfo.special_change_reward
      if config.rewardType == TotalExploreReward.ChooseShip then
        config.dropId = k[1]
      else
        config.itemType = k[1]
        config.itemId = k[2]
        config.count = k[3]
      end
      config.icon = config.rewardType == TotalExploreReward.ChooseShip and buildConfigInfo.button_image[j] or ""
    end
    local needDraw = config.limitCount - normalCount
    if part.tx_buildNum ~= nil then
      part.tx_buildNum.text = config.limitCount
      part.obj_finish:SetActive(config.finish)
      part.obj_check:SetActive(needDraw <= 0)
      part.obj_get:SetActive(not config.finish and needDraw <= 0)
    else
      UIHelper.SetImage(part.img_name, config.rewardTips)
    end
    if config.rewardType == TotalExploreReward.ChooseShip then
      self.page:RegisterRedDotById(part.im_redFlag, {68}, config.limitCount, self.buildConfigInfo.id, RewardType.Twenty)
      UIHelper.SetImage(part.im_icon, config.icon)
      if not config.finish then
        UGUIEventListener.AddButtonOnClick(part.btn_getBoxReward, self.GetBoxReward, self, {
          dropId = config.dropId,
          limitCount = config.limitCount,
          normalCount = normalCount
        })
      end
      if part.im_numbg then
        part.im_numbg:SetActive(false)
      end
    elseif config.rewardType == TotalExploreReward.GetBox then
      self.page:RegisterRedDotById(part.im_redFlag, {69}, config.limitCount, self.buildConfigInfo.id, RewardType.Hundred)
      local tabReward = Logic.bagLogic:GetItemByTempateId(config.itemType, config.itemId)
      UIHelper.SetImage(part.im_icon, tabReward.icon)
      local str
      if not config.finish and 0 < needDraw then
        str = string.format(UIHelper.GetString(1110060), needDraw, tabReward.name)
      end
      if not config.finish then
        if needDraw <= 0 then
          UGUIEventListener.AddButtonOnClick(part.btn_getBoxReward, self.GetTimesReward, self, config)
        else
          UGUIEventListener.AddButtonOnClick(part.btn_getBoxReward, self._ClickHundredCheck, self, {config, str})
        end
      end
      if part.im_numbg then
        part.im_numbg:SetActive(true)
        part.tx_num.text = "x" .. config.count
      end
    end
    table.insert(tabPart, part)
  end)
  return tabPart
end

function BuildShipMainPage:_SetBuildProgress(showReward, tabPart, normalCount)
  local currBuildCount = normalCount
  local sliderValue = 0
  local limit = 0
  local ratio = 1 / #tabPart
  local OneBoxHight = 53
  self.m_tabWidgets.trans_rewardPart:SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, Slider_Height + OneBoxHight)
  self.m_tabWidgets.scrollView_reward.verticalNormalizedPosition = 1
  self.m_tabWidgets.scrollView_reward:StopMovement()
  local sliderHight = Slider_Height
  local needHeight = OneBoxHight * #tabPart + 15 * (#tabPart - 1)
  if sliderHight < needHeight then
    self.m_tabWidgets.trans_rewardPart:SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, needHeight + OneBoxHight)
    sliderHight = needHeight
    self.m_tabWidgets.scrollView_reward.verticalNormalizedPosition = 0
    self.m_tabWidgets.scrollView_reward:StopMovement()
  end
  for i, v in ipairs(tabPart) do
    local posY = sliderHight * (ratio * i)
    v.obj_self.transform.localPosition = Vector3.New(0, posY, 0)
    local currLimit = showReward[i].limitCount - limit
    if 0 < currBuildCount then
      if currBuildCount >= currLimit then
        sliderValue = sliderValue + ratio
      else
        sliderValue = sliderValue + currBuildCount / currLimit * ratio
      end
      currBuildCount = currBuildCount - (showReward[i].limitCount - limit)
      limit = showReward[i].limitCount
    end
  end
  self.m_tabWidgets.slider_reward.value = sliderValue
end

function BuildShipMainPage:SetActiveSelf(_bool)
  self.cs_page.gameObject:SetActive(_bool)
end

return BuildShipMainPage
