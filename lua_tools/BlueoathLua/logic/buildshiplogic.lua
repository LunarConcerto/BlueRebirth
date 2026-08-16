local BuildShipLogic = class("logic.BuildShipLogic")
local ParamIdByType = {
  170,
  171,
  170,
  257
}
local IndexTab = {
  4,
  3,
  2,
  1
}
local TitleTab = {
  "SSR",
  "SR",
  "R",
  "N"
}
local RewardType = {Twenty = 1, Hundred = 2}
local ShowBoxLimitNum = 2

function BuildShipLogic:initialize()
  self.displayModel = false
  self.cardQuality = {}
  self.haveSSR = false
  self.displayId = {}
  self.dropTab = {}
  self.clothesTab = {}
  self.rewardTab = {}
  self.tabBuildConfig = configManager.GetData("config_extract_ship")
  pushNoticeManager:_BindNotice("freeBuildShip", function()
    return self:GetPushNoticeParams()
  end)
end

function BuildShipLogic:ResetData()
  self.displayModel = false
  self.cardQuality = {}
  self.haveSSR = false
  self.displayId = {}
  self.dropTab = {}
  self.clothesTab = {}
  self.rewardTab = {}
  self.openPeriodIndex = {}
  self.tabBuildConfig = configManager.GetData("config_extract_ship")
end

function BuildShipLogic:SetDisplay(enable)
  if not enable then
    self.displayId = {}
  end
  self.displayModel = enable
end

function BuildShipLogic:GetDisplay()
  return self.displayModel
end

function BuildShipLogic:GetBuildConfig(buildId)
  return configManager.GetDataById("config_extract_ship", buildId)
end

function BuildShipLogic:CheckShowMeet(tId)
  local shipInfo = Logic.shipLogic:GetShipInfoById(tId)
  local isNew = Logic.illustrateLogic:IsFirstGetHero(shipInfo.si_id)
  isNew = isNew and self.displayId[tId] == nil
  local data = Data.illustrateData:GetAllIllustrate()
  local quality = data[shipInfo.si_id].quality
  self.displayId[tId] = 0
  return isNew, quality
end

function BuildShipLogic:GetDockFree(num)
  local shipTotal = Logic.shipLogic:GetBaseShipNum()
  local tabHaveHero = Data.heroData:GetHeroData()
  local tabTemp = {}
  for k, v in pairs(tabHaveHero) do
    tabTemp[#tabTemp + 1] = v
  end
  return shipTotal - #tabTemp
end

function BuildShipLogic:GetEquipBagFree()
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  return equipSize - size
end

function BuildShipLogic:DisposeCardQuality(param)
  self.cardQuality = {}
  for _, v in ipairs(param) do
    local shipInfo = Logic.shipLogic:GetShipInfoById(v.ConfigId)
    table.insert(self.cardQuality, shipInfo.quality)
  end
end

function BuildShipLogic:GetCardQuality()
  return self.cardQuality
end

function BuildShipLogic:ClearCardQuality()
  self.cardQuality = {}
end

function BuildShipLogic:SetHaveSSR(rewards, btype)
  self.buildType = btype
  if btype == ExtractType.SHIP or btype == ExtractType.LIMIT_SHIP then
    for _, v in ipairs(rewards) do
      local shipInfo = Logic.shipLogic:GetShipInfoById(v.ConfigId)
      if shipInfo.quality == HeroRarityType.SSR then
        self.haveSSR = true
        return
      end
    end
  elseif btype == ExtractType.EQUIP then
    for _, v in ipairs(rewards) do
      local equipCfg = Logic.equipLogic:GetEquipConfigById(v.ConfigId)
      if equipCfg.quality == HeroRarityType.SSR then
        self.haveSSR = true
        return
      end
    end
  end
  self.haveSSR = false
end

function BuildShipLogic:GetHaveSSR()
  return self.haveSSR, self.buildType
end

function BuildShipLogic:SetExtractReward(reward)
  self.extractReward = reward
end

function BuildShipLogic:GetExtractReward(reward)
  local rewards = self.extractReward
  self.extractReward = nil
  return rewards
end

function BuildShipLogic:CheckServerOpenDay(buildId)
  local config = configManager.GetDataById("config_extract_ship", buildId)
  if config.open_limit == 0 then
    return true
  end
  return time.getServerStartDay() > config.open_limit
end

function BuildShipLogic:CheckPeriod(arrPeriod, arrPeriodArea)
  if arrPeriod == nil or #arrPeriod == 0 then
    return -1
  end
  local index = -1
  for i, v in ipairs(arrPeriod) do
    local isOpen = PeriodManager:IsInPeriodArea(arrPeriod[i], arrPeriodArea[i])
    if isOpen then
      index = i
      break
    end
  end
  return index
end

function BuildShipLogic:CheckActIsOpen(buildId)
  local endTime = Data.buildShipData:GetEndtime(buildId)
  if endTime ~= nil then
    local surplusTime = tonumber(endTime) - tonumber(time.getSvrTime())
    if 0 < surplusTime then
      return true
    else
      return false
    end
  else
    local config = configManager.GetDataById("config_extract_ship", buildId)
    if config.force_open_time ~= 0 then
      local startTime = tonumber(time.getSvrTime()) - tonumber(config.force_open_time)
      if 0 <= startTime then
        return true
      end
    end
    if config.open_by_boss == 1 then
      local bossInfo = Data.copyData:GetBossInfo()
      if bossInfo == nil or bossInfo.Status == nil then
        Service.copyService:SendGetBossData()
      elseif bossInfo.Status == ActBattleBossStage.BattleEnd then
        return true
      end
    end
    if config.force_open_time == 0 then
      if config.new_period ~= nil and 0 < #config.new_period then
        local index = self:CheckPeriod(config.new_period, config.new_period_area)
        if index == -1 then
          return false
        end
        if config.statue ~= -1 then
          local startTime, _ = PeriodManager:GetPeriodTime(config.new_period[index], config.new_period_area[index])
          local paramConf = configManager.GetDataById("config_parameter", 232)
          if paramConf == nil or #paramConf.arrValue ~= 6 then
            return false
          end
          local tagTimeArray = paramConf.arrValue
          local tagTime = time.getIntervalByString(string.format("%d%02d%02d%02d%02d%02d", tagTimeArray[1], tagTimeArray[2], tagTimeArray[3], tagTimeArray[4], tagTimeArray[5], tagTimeArray[6]))
          if startTime >= tagTime then
            if config.statue == 0 then
              return false
            end
          elseif config.statue == 1 then
            return false
          end
        end
        if self.openPeriodIndex[buildId] ~= nil and self.openPeriodIndex[buildId] ~= index then
          Data.buildShipData:RefreshBuildData(buildId)
        end
        self.openPeriodIndex[buildId] = index
      end
      return true
    end
    return false
  end
end

function BuildShipLogic:GetOpenPeriodIndex(buildId)
  return self.openPeriodIndex[buildId]
end

function BuildShipLogic:GetActEndTime(buildId)
  local config = configManager.GetDataById("config_extract_ship", buildId)
  local index = self.openPeriodIndex[buildId]
  if index == nil then
    return 0, 0
  end
  local startTime, endTime = PeriodManager:GetPeriodTime(config.new_period[index], config.new_period_area[index])
  return startTime, endTime
end

function BuildShipLogic:GetDisplayInfo(buildConfig)
  local upName = self:GetShowUpName(buildConfig)
  self.dropTab[buildConfig.id] = {}
  if next(buildConfig.up) ~= nil then
    local timeLimitUp = {}
    local upInfos = {}
    local temp = {}
    for _, v in ipairs(buildConfig.ssr_up_ship_info) do
      if v and 0 < #v then
        table.insert(temp, BuildShipLogic:GetSpecialInfo(v))
      end
    end
    upInfos[1] = table.concat(temp, "\n")
    temp = {}
    for _, v in ipairs(buildConfig.sr_up_ship_info) do
      if v and 0 < #v then
        table.insert(temp, BuildShipLogic:GetSpecialInfo(v))
      end
    end
    upInfos[2] = table.concat(temp, "\n")
    temp = nil
    for i, v in ipairs(buildConfig.up) do
      if v ~= 0 then
        timeLimitUp[i] = {}
        timeLimitUp[i].value = v .. "%"
        timeLimitUp[i].title = TitleTab[i]
        if buildConfig.up_type == 1 then
          if upInfos[i] then
            timeLimitUp[i].dropNameStr = upInfos[i]
          else
            timeLimitUp[i].dropNameStr = ""
            logError("\230\156\170\233\133\141\231\189\174R\228\184\142N\231\154\132\229\135\186\231\142\176Up\230\166\130\231\142\135")
          end
        elseif buildConfig.up_type == 0 then
          timeLimitUp[i].dropNameStr = UIHelper.GetString(upName[i])
        end
      end
    end
    self.dropTab[buildConfig.id].TimeLimitUp = timeLimitUp
  end
  if buildConfig.drop_item_id ~= 0 then
    self.dropTab[buildConfig.id].DropInfo = self:_GetDropDisplay(buildConfig)
  end
  if buildConfig.special_info ~= "" then
    self.dropTab[buildConfig.id].Addition = UIHelper.GetString(tonumber(buildConfig.special_info))
  end
  return self.dropTab[buildConfig.id]
end

function BuildShipLogic:GetSpecialInfo(upInfoTb)
  local shipTypeId = Logic.shipLogic:GetHeroType(Logic.shipLogic:GetShipInfoId(upInfoTb[1]))
  local shipType = Logic.shipLogic:GetShipTypeName({shipTypeId})
  local shipName = Logic.shipLogic:GetShipShowById(upInfoTb[1]).ship_name
  local rate = tostring(upInfoTb[2] / 100) .. "%"
  return shipType .. " : " .. shipName .. "(" .. rate .. ")"
end

function BuildShipLogic:_GetDropDisplay(buildConfig)
  local dropInfo = {}
  local equipIdMap = {}
  local rate = configManager.GetDataById("config_parameter", ParamIdByType[buildConfig.extract_type])
  for i, v in ipairs(rate.arrValue) do
    if v ~= 0 then
      dropInfo[i] = {}
      dropInfo[i].value = v .. "%"
      dropInfo[i].title = TitleTab[i]
      dropInfo[i].dropNameTab = {}
    end
  end
  if buildConfig.extract_type ~= ExtractType.FASHION then
    local dropItemConfig = Logic.rewardLogic:GetAllRewardByDropId(buildConfig.drop_item_id)
    for _, v in ipairs(dropItemConfig) do
      local tId = v[2]
      local dropType = v[1]
      local itemConfig
      if dropType == GoodsType.EQUIP then
        if equipIdMap[tId] == nil then
          equipIdMap[tId] = tId
          itemConfig = Logic.equipLogic:GetEquipConfigById(tId)
          if dropInfo[IndexTab[itemConfig.quality]] ~= nil then
            local typeName = configManager.GetDataById("config_equip_wear_type", itemConfig.equip_type_id)
            table.insert(dropInfo[IndexTab[itemConfig.quality]].dropNameTab, {
              name = itemConfig.name,
              tname = typeName.equip_show_name
            })
          end
        end
      elseif dropType == GoodsType.SHIP then
        itemConfig = Logic.shipLogic:GetShipInfoById(tId)
        if dropInfo[IndexTab[itemConfig.quality]] ~= nil then
          local typeName = configManager.GetDataById("config_ship_type", itemConfig.ship_type)
          table.insert(dropInfo[IndexTab[itemConfig.quality]].dropNameTab, {
            name = itemConfig.ship_name,
            tname = typeName.name
          })
        end
      end
    end
  else
    local clothseTab, rewardTab = Logic.buildShipLogic:DisposeClothesDrop(buildConfig)
    local temp = {}
    local typeName = ""
    table.insertto(temp, clothseTab)
    table.insertto(temp, rewardTab)
    for _, v in pairs(temp) do
      if v.tabIndex == GoodsType.EQUIP then
        itemConfig = Logic.equipLogic:GetEquipConfigById(v.id)
        typeName = "\232\163\133\229\164\135"
      elseif v.tabIndex == GoodsType.FASHION then
        itemConfig = Logic.fashionLogic:GetFashionConfig(v.id)
        typeName = "\230\151\182\232\163\133"
      elseif v.tabIndex == GoodsType.SHIP then
        itemConfig = Logic.shipLogic:GetShipInfoById(v.id)
        typeName = "\230\136\152\229\167\172"
      else
        itemConfig = Logic.bagLogic:GetItemByTempateId(v.tabIndex, v.id)
        typeName = "\231\137\169\229\147\129"
      end
      if dropInfo[IndexTab[itemConfig.quality]] ~= nil then
        table.insert(dropInfo[IndexTab[itemConfig.quality]].dropNameTab, {
          name = itemConfig.name,
          tname = typeName
        })
      end
    end
  end
  return dropInfo
end

function BuildShipLogic:GetFreeRefreshTime(buildId, refreshType)
  local freeInfo = Data.buildShipData:GetFreeRefreshInfo()
  if freeInfo[refreshType] == nil then
    return -1, 0
  end
  local config = self:GetBuildConfig(buildId)
  if 0 >= config.free_explore_refresh then
    return -1, 0
  end
  local coolTime = config.free_explore_refresh * 3600
  local periodNum = math.floor((time.getSvrTime() - freeInfo[refreshType]) / coolTime)
  local currRefreshTime = freeInfo[refreshType] + periodNum * coolTime + coolTime
  if freeInfo[refreshType] + coolTime <= time.getSvrTime() then
    return 0, currRefreshTime
  end
  return 1, currRefreshTime
end

function BuildShipLogic:DisposeClothesDrop(buildConfig)
  if #self.clothesTab == 0 or #self.rewardTab == 0 then
    local dropItemConfig = configManager.GetDataById("config_drop_item", buildConfig.drop_item_id).drop
    for _, v in ipairs(buildConfig.special_draw_id) do
      local dropId = configManager.GetDataById("config_specialdraw", v).drop_item
      local config = configManager.GetDataById("config_drop_item", dropId).drop
      table.insertto(dropItemConfig, config)
    end
    local tempClothes = {}
    local tempReward = {}
    for _, v in ipairs(dropItemConfig) do
      local goodsType = v[1]
      local tId = v[2]
      local itemConfig = Logic.bagLogic:GetItemByTempateId(goodsType, tId)
      if goodsType == GoodsType.FASHION then
        tempClothes[tId] = itemConfig
      else
        tempReward[tId] = itemConfig
      end
    end
    for _, v in pairs(tempClothes) do
      table.insert(self.clothesTab, v)
    end
    for _, v in pairs(tempReward) do
      table.insert(self.rewardTab, v)
    end
  end
  return self.clothesTab, self.rewardTab
end

function BuildShipLogic:CheckOtherLimit(config)
  if config.extract_type == ExtractType.LIMIT_SHIP then
    if Logic.dailyCopyLogic:CheckDailyCopyByIndex(config.open_daily_condition) then
      return true
    end
    return false
  end
  return true
end

function BuildShipLogic:GetSurplusTime(buildId)
  local config = self:GetBuildConfig(buildId)
  local dispLv = Data.buildShipData:GetDispCount(config.id)
  local descTime = ""
  local time = ""
  local dynEndTime = Data.buildShipData:GetEndtime(config.id)
  if dynEndTime ~= nil then
    time = self:GetFormatSurplusTime(dynEndTime)
    descTime = string.format(config.tag_duration[dispLv], time)
  elseif config.new_period ~= nil and #config.new_period > 0 then
    time = self:GetSurplusTimeByConfig(config)
    if #config.tag_duration ~= 0 then
      descTime = string.format(config.tag_duration[dispLv], time)
    end
  elseif #config.tag_duration ~= 0 then
    descTime = config.tag_duration[dispLv]
  end
  return descTime, time
end

function BuildShipLogic:GetSurplusTimeByConfig(config)
  local descTime = ""
  if config.new_period ~= nil and #config.new_period > 0 then
    local startTime, endTime = self:GetActEndTime(config.id)
    descTime = self:GetFormatSurplusTime(endTime)
  end
  return descTime
end

function BuildShipLogic:GetFormatSurplusTime(surplusTime)
  local descTime = ""
  if surplusTime ~= nil then
    local day, hour, min = time.getDHMDiff(surplusTime)
    if 1 <= day then
      descTime = tostring(day) .. "\229\164\169"
    elseif 0 < hour then
      descTime = tostring(day * 24 + hour) .. "\229\176\143\230\151\182"
    else
      min = 0 < min and min or 1
      descTime = tostring(min) .. "\229\136\134\233\146\159"
    end
  end
  return descTime
end

function BuildShipLogic:_GetTogName(config)
  local descName = ""
  local dispLv = Data.buildShipData:GetDispCount(config.id)
  descName = config.name_pic[dispLv]
  local descTime = self:GetSurplusTime(config.id)
  return descName, descTime
end

function BuildShipLogic:CheckAllClothesOwn(buildConfig)
  local dropClothes, _ = self:DisposeClothesDrop(buildConfig)
  for _, v in ipairs(dropClothes) do
    local showOwn = Logic.fashionLogic:CheckFashionOwn(v.id)
    if not showOwn then
      return false
    end
  end
  return true
end

function BuildShipLogic:CheckFreeStatus()
  local open = self:GetOpenExplore()
  if open and 0 < #open then
    local status, _ = self:GetFreeRefreshTime(open[1].id, open[1].free_explore_type)
    if status == 0 then
      return true
    end
  end
  return false
end

function BuildShipLogic:GetPushNoticeParams()
  local pushtimes = {}
  local togGroupInfo = self:GetOpenExplore()
  for k, v in pairs(togGroupInfo) do
    local status, ftime = self:GetFreeRefreshTime(v.id, v.free_explore_type)
    if status == 1 then
      local t = ftime
      table.insert(pushtimes, t)
    end
  end
  table.sort(pushtimes, function(d1, d2)
    return d1 < d2
  end)
  local pTime = pushtimes[1] and pushtimes[1] or 9999999999
  local paramList = {}
  local noticeParam = {}
  noticeParam.key = "freeBuildShip"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 11).text
  noticeParam.time = pTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.freeBuildShip = noticeParam
  return paramList
end

function BuildShipLogic:CheckLimitShipCount(config)
  local surplusNumTab = Data.buildShipData:GetSpecialInfo(config.id)
  surplusNumTab = surplusNumTab[3] == nil and {} or surplusNumTab[3]
  for i, shipTId in ipairs(config.show_ship) do
    local surplusNum = surplusNumTab[shipTId] ~= nil and surplusNumTab[shipTId] or 0
    if 0 < surplusNum then
      return true
    end
  end
  return false
end

function BuildShipLogic:BoxRewardChooseFlg(flg)
  if flg ~= nil then
    self.boxRewardFlg = flg
  end
  return self.boxRewardFlg
end

function BuildShipLogic:CheckTimesRewardInBuild(limit, id, rewardType)
  local usedCountTab = rewardType == RewardType.Twenty and Data.buildShipData:GetUsedBoxCoundTab(id) or Data.buildShipData:GetUsedRewardCoundTab(id)
  local normalCount = Data.buildShipData:GetBuildShipCount(id)
  local limitCount = limit
  local needDraw = limitCount - normalCount
  local noGet = true
  if 0 < #usedCountTab then
    for _, v in ipairs(usedCountTab) do
      if v == limit then
        noGet = false
      end
    end
  end
  return needDraw <= 0 and noGet
end

function BuildShipLogic:CheckTimesReward()
  local openConfig = self:GetOpenExplore()
  if openConfig and 0 < #openConfig then
    for _, config in pairs(openConfig) do
      local canGet = self:CheckTimesRewardById(config)
      if canGet then
        return true
      end
    end
  end
  return false
end

function BuildShipLogic:CheckTimesRewardById(config)
  local normalCount = Data.buildShipData:GetBuildShipCount(config.id)
  local rewardTab = config.twenty_drop
  local twentyCountTab = Data.buildShipData:GetUsedBoxCoundTab(config.id)
  local twentyIndex = #twentyCountTab + 1
  if #rewardTab ~= 0 and twentyIndex <= #rewardTab then
    local limitCount = rewardTab[twentyIndex][1]
    if twentyIndex <= #rewardTab and limitCount - normalCount <= 0 then
      return true
    end
  end
  local hundredRewardTab = config.hundred_reward
  local hundredCountTab = Data.buildShipData:GetUsedRewardCoundTab(config.id)
  local hundredIndex = #hundredCountTab + 1
  if #hundredRewardTab ~= 0 and hundredIndex <= #hundredRewardTab then
    local limitCount = hundredRewardTab[hundredIndex][1]
    if hundredIndex <= #hundredRewardTab and limitCount - normalCount <= 0 then
      return true
    end
  end
end

function BuildShipLogic:CheckBtnFreeStatus(config)
  if config then
    local status, _ = self:GetFreeRefreshTime(config.id, config.free_explore_type)
    if status == 0 then
      return true
    end
  end
  return false
end

function BuildShipLogic:GetShowPic(config, dispLv)
  local index = self:_getIndex4ShowInfo(config.changetime)
  if -1 < index then
    return config.change_show_pic[index]
  end
  return config.show_pic[dispLv]
end

function BuildShipLogic:GetShowDesc(config, dispLv)
  local str = ""
  local index = self:_getIndex4ShowInfo(config.changetime)
  if -1 < index then
    if #config.change_desc ~= 0 then
      str = config.change_desc[index]
    end
    return str
  end
  if #config.desc ~= 0 then
    str = config.desc[dispLv]
  end
  return str
end

function BuildShipLogic:GetShowUpName(config)
  local index = self:_getIndex4ShowInfo(config.changetime)
  if -1 < index then
    return config.change_up_name[index]
  end
  return config.up_name
end

function BuildShipLogic:_getIndex4ShowInfo(changetime)
  local index = -1
  for i, v in ipairs(changetime) do
    if v <= time.getSvrTime() then
      index = i
    end
  end
  return index
end

function BuildShipLogic:GetResetTypeCountByBuildId(buildId)
  local cfg = configManager.GetDataById("config_extract_ship", buildId)
  local count = Data.buildShipData:GetResetTypeCount(cfg.reset_type)
  return count
end

function BuildShipLogic:CheckNewBuildOpen()
  local bFunOpen = moduleManager:CheckFunc(FunctionID.BuildShip, false)
  if not bFunOpen then
    return false
  end
  local uid = Data.userData:GetUserUid()
  local openBuildTab = self:GetOpenExplore()
  for _, buildInfo in ipairs(openBuildTab) do
    local periodId = self:GetBuildPeriodId(buildInfo)
    local isRecord = PlayerPrefs.GetBool("NewBuildShipOpen" .. uid .. buildInfo.id .. periodId, false)
    if not isRecord then
      return true
    end
  end
  return false
end

function BuildShipLogic:RecordOpenBuildId()
  local uid = Data.userData:GetUserUid()
  local openBuildTab = self:GetOpenExplore()
  for _, buildInfo in ipairs(openBuildTab) do
    local periodId = self:GetBuildPeriodId(buildInfo)
    local isRecord = PlayerPrefs.GetBool("NewBuildShipOpen" .. uid .. buildInfo.id .. periodId, false)
    if not isRecord then
      PlayerPrefs.SetBool("NewBuildShipOpen" .. uid .. buildInfo.id .. periodId, true)
    end
  end
end

function BuildShipLogic:GetBuildPeriodId(buildInfo)
  local periodId = 0
  for i, v in ipairs(buildInfo.new_period) do
    if #buildInfo.new_period_area[i] ~= 0 then
      local isOpen = PeriodManager:IsInPeriodArea(buildInfo.new_period[i], buildInfo.new_period_area[i])
      if isOpen then
        periodId = buildInfo.new_period[i]
        break
      end
    end
  end
  return periodId
end

function BuildShipLogic:GetUpCountByBuildId(buildId)
  local cfg = configManager.GetDataById("config_extract_ship", buildId)
  local data = {}
  if cfg.extract_reset_type == EXTRACT_RESET_TYPE.UpEquip then
    for _, upId in ipairs(cfg.up_list) do
      local count = Data.buildShipData:GetExtractUpCount(cfg.reset_type, upId)
      data[upId] = count
    end
  end
  return data
end

function BuildShipLogic:GetShowBoxReward(rewardTypeTab, buildConfigInfo)
  local showReward = {}
  for i, v in ipairs(rewardTypeTab) do
    local limitCount = v[1]
    local rewardType = v[2]
    local config = self:DisposeBoxDate(buildConfigInfo, limitCount, rewardType, i)
    if #rewardTypeTab <= ShowBoxLimitNum then
      if not config.finish then
        table.insert(showReward, config)
      end
    else
      table.insert(showReward, config)
    end
  end
  return showReward
end

function BuildShipLogic:_CheckRewardDate(id, limitCount, rewardType)
  local dateTab = rewardType == TotalExploreReward.ChooseShip and Data.buildShipData:GetUsedBoxCoundTab(id) or Data.buildShipData:GetUsedRewardCoundTab(id)
  local noGet = true
  if #dateTab ~= 0 then
    for _, num in ipairs(dateTab) do
      if num == limitCount then
        noGet = false
        break
      end
    end
  end
  return noGet
end

function BuildShipLogic:DisposeBoxDate(buildConfigInfo, limitCount, rewardType, index)
  local config = {}
  local dropTab = rewardType == TotalExploreReward.ChooseShip and buildConfigInfo.twenty_drop or buildConfigInfo.hundred_reward
  for j, k in ipairs(dropTab) do
    if k[1] == limitCount then
      if rewardType == TotalExploreReward.ChooseShip then
        config.dropId = k[2]
      else
        config.itemType = k[2]
        config.itemId = k[3]
        config.count = k[4]
      end
      config.icon = rewardType == TotalExploreReward.ChooseShip and buildConfigInfo.button_image[j] or ""
    end
  end
  config.rewardTips = buildConfigInfo.reward_tips_image[index]
  config.limitCount = limitCount
  config.rewardType = rewardType
  local noGet = self:_CheckRewardDate(buildConfigInfo.id, limitCount, rewardType)
  config.finish = not noGet
  return config
end

function BuildShipLogic:GetOpenExplore()
  local openExplore = {}
  for _, v in pairs(self.tabBuildConfig) do
    if self:CheckActIsOpen(v.id) and self:CheckServerOpenDay(v.id) and self:CheckOtherLimit(v) then
      table.insert(openExplore, v)
    end
  end
  table.sort(openExplore, function(data1, data2)
    local dispLv1 = Data.buildShipData:GetDispCount(data1.id)
    local dispLv2 = Data.buildShipData:GetDispCount(data2.id)
    if data1.show_order[dispLv1] ~= data2.show_order[dispLv2] then
      return data1.show_order[dispLv1] < data2.show_order[dispLv2]
    else
      return data1.id < data2.id
    end
  end)
  return openExplore
end

return BuildShipLogic
