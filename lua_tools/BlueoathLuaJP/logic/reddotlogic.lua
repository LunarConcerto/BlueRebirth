local RedDotLogic = class("logic.RedDotLogic")

function RedDotLogic.EmailDotState()
  if Data.emailData:GetUpdataTog() or Data.emailData:HaveNew() then
    return true
  end
  return false
end

function RedDotLogic.FriendDotState()
  local teachingApply = Data.teachingData:GetApplyRedState()
  return teachingApply or Data.friendData:GetRedState()
end

function RedDotLogic.StudyDotState()
  local marginNum = Logic.studyLogic:GetStudyMargin()
  local bookNum = Logic.studyLogic:CheckStudyBook()
  local finish = Logic.studyLogic:CheckStudyEnd()
  local emptyCheck = Logic.studyLogic.emptyCheck
  if not emptyCheck and marginNum ~= 0 and bookNum then
    return true
  end
  if finish then
    return true
  end
  return false
end

function RedDotLogic.WishDotState()
  local _, countDownTime = Logic.wishLogic:CheckCharge()
  return countDownTime <= 0
end

function RedDotLogic.Task()
  for taskType = TaskType.TaskBegin, TaskType.TaskEnd do
    if RedDotLogic.TaskByType(taskType) then
      return true
    end
  end
  return false
end

function RedDotLogic.TaskByType(taskType)
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(taskType)
  if tabTaskInfo == nil then
    return false
  end
  for _, taskInfo in ipairs(tabTaskInfo) do
    if taskInfo.State == TaskState.FINISH then
      return true
    end
  end
  return false
end

function RedDotLogic:Achieve()
  for achieveType = 1, 4 do
    if RedDotLogic.AchieveByType(achieveType) then
      return true
    end
  end
  return false
end

function RedDotLogic.AchieveByType(achieveType)
  local achieveData = Data.taskData:GetAchieveData()
  local tabAchieve = Logic.achieveLogic:GetAchieveByType(achieveType, achieveData)
  if tabAchieve == nil then
    return false
  end
  for _, taskInfo in ipairs(tabAchieve) do
    if taskInfo.status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function RedDotLogic.TaskOrAchieve()
  if RedDotLogic.Task() then
    return true
  end
  if RedDotLogic.Achieve() then
    return true
  end
  return false
end

function RedDotLogic.Supply()
  local data = Data.userData:GetUserData().GetSupplyInfo
  local supplyInfo = {}
  for _, v in pairs(data) do
    supplyInfo[v.Id] = v
  end
  local configInfo = Logic.currencyLogic:GetSupplyconfig()
  for index, config in pairs(configInfo) do
    local status = Logic.currencyLogic:SupplyStatus(config.time, supplyInfo[index])
    if status == GetSupplyStatus.CANGET then
      return true
    end
  end
  return false
end

function RedDotLogic.Illustrate()
  local new = Data.illustrateData:GetHaveNewIllustrate()
  if new then
    return Logic.illustrateLogic:HaveNewIllustrate()
  else
    return false
  end
end

function RedDotLogic.DecorateFurnitureBagItem()
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local mapFur = {}
  for i, v in pairs(ownedItem) do
    local group = configManager.GetDataById("config_interaction_item_bag", i).interactionitem_bag_group
    if group ~= 0 then
      mapFur[i] = i
    end
  end
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  for i, itemId in pairs(mapFur) do
    local isNew = PlayerPrefs.GetBool(uid .. "DecorateFurnitureBagItem" .. itemId, true)
    if isNew then
      return true
    end
  end
  return false
end

function RedDotLogic.FriendApply()
  local listData = Data.friendData:GetApplyData() or {}
  return 0 < #listData
end

function RedDotLogic.PrivateChat()
  return Logic.chatLogic:GetPersonTagUnReadNum()
end

function RedDotLogic.AllChat()
  local count = 0
  for k, v in pairs(Logic.chatLogic:GetChatTipChannel()) do
    local c = Data.chatData:GetUnReadNumByChannelType(v, Data.chatData:GetRoomNum())
    if c then
      count = count + c
    end
  end
  return count
end

function RedDotLogic.FriendChat()
  return Logic.chatLogic:GetFriendTagUnReadNum()
end

function RedDotLogic.UserChatUnRend(uid)
  return Logic.chatLogic:GetUserUnReadNum(uid)
end

function RedDotLogic.AssistFleetFinish()
  return Logic.assistNewLogic:FinishSupportValue() > 0
end

function RedDotLogic.AssistFleetFree()
  local items = Logic.assistNewLogic:GetUserCommandWithOutUsing()
  return Logic.assistNewLogic:SupportSlotValue() > 0 and 0 < #items
end

function RedDotLogic.ShipBreakByShipId(shipId)
  return Logic.shipLogic:DotBreakCondition(shipId)
end

function RedDotLogic.MoreQualityEquipByShipId(shipId, fleetType)
  return Logic.equipLogic:CheckEquipQualityEx(shipId, fleetType)
end

function RedDotLogic.MoreQualityEquipByIndex(shipId, index, fleetType)
  return Logic.equipLogic:CheckEquipQualityByIndex(shipId, index, fleetType)
end

function RedDotLogic.CanEquipByShipId(shipId, fleetType)
  return Logic.equipLogic:CheckHeroEquip(shipId, fleetType)
end

function RedDotLogic.CanEquipByShipIdByIndex(shipId, index, fleetType)
  return Logic.equipLogic:CheckHeroEquipByIndex(shipId, index, fleetType)
end

function RedDotLogic.EquipEnhanceByShipId(shipId, fleetType)
  return Logic.equipLogic:CheckEquipEnhance(shipId, fleetType)
end

function RedDotLogic.EquipEnhanceByIndex(shipId, index, fleetType)
  return Logic.equipLogic:CheckEquipEnhanceByIndex(shipId, index, fleetType)
end

function RedDotLogic.EquipRiseStarByShipId(shipId, fleetType)
  return Logic.equipLogic:CheckEquipRise(shipId, fleetType)
end

function RedDotLogic.EquipRiseStarByIndex(shipId, index, fleetType)
  return Logic.equipLogic:CheckEquipRiseByIndex(shipId, index, fleetType)
end

function RedDotLogic:AEquipCanUp(shipId, index, fleetType)
  return Logic.equipLogic:CanAddAEquipByIndex(shipId, index, fleetType)
end

function RedDotLogic.Plot()
  local _, plotCopyId = Logic.copyLogic:GetCurPlotChapterSection()
  local copyInfo = Data.copyData:GetPlotCopyDataCopyId(plotCopyId)
  if copyInfo == nil then
    logError("RedDotLogic GetPlotCopyDataCopyId plotCopyId:", plotCopyId)
    return
  end
  return copyInfo.FirstPassTime == 0
end

function RedDotLogic.PlotById(chapterId)
  local isPass = Logic.copyLogic:IsChapterPassByChapterId(chapterId)
  local plotChapterIsOpen = Logic.copyLogic:_CheckPlotCopyIsOpen(chapterId)
  local firstDisplayId = Logic.copyLogic:GetChatperFirshCopy(chapterId)
  local lockdata = Data.copyData:GetCopyInfoById(firstDisplayId) == nil
  if not (not isPass and plotChapterIsOpen) or lockdata then
    return false
  end
  return true
end

function RedDotLogic.MianPlot(classId)
  local chapterInfoList = configManager.GetDataById("config_chapter_plot_type", classId)
  if chapterInfoList and chapterInfoList.chapter_list then
    local list = chapterInfoList.chapter_list
    for i = 1, #list do
      if RedDotLogic.PlotById(list[i]) then
        return true
      end
    end
  end
  return false
end

function RedDotLogic.TimelimitedTaskPage(Id)
  local timeTaskConfig = configManager.GetData("config_days_activity_limited")
  for v, k in pairs(timeTaskConfig) do
    local id = k.id
    local isShow = RedDotLogic.TimeTaskDays(id)
    if isShow then
      return true
    end
  end
  return false
end

function RedDotLogic.FleetStrategy(fleetId, fleetType)
  if not moduleManager:CheckFunc(FunctionID.Strategy, false) then
    return false
  end
  local imageFleetShip = Logic.fleetLogic:GetImageFleetShip(fleetId, fleetType)
  local fleetInfo
  if imageFleetShip then
    fleetInfo = imageFleetShip
  else
    fleetInfo = Data.fleetData:GetFleetDataById(fleetId, fleetType)
  end
  if fleetInfo.noStrategyRedDot then
    return false
  end
  if #fleetInfo.heroInfo <= 0 then
    return false
  end
  return fleetInfo.strategyId == 0
end

function RedDotLogic.TrainChestReward(chapterId)
  local datas = Logic.copyLogic:GetStarRewardDatas(chapterId)
  for i, data in ipairs(datas) do
    if data.state == RewardState.Receivable then
      return true
    end
  end
  return false
end

function RedDotLogic.BigActivity()
  local activityData = configManager.GetData("config_activity")
  for _, k in pairs(activityData) do
    if k.type == ActivityType.DailyLogin and Logic.redDotLogic.BigActivityById(k.id) then
      return true
    end
  end
  return false
end

function RedDotLogic.BigActivityById(id)
  local result = Logic.activityLogic:CheckActivityOpenById(id)
  if not result then
    return false
  end
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, id)
  local tabAllTaskInfo = Logic.taskLogic:GetAllTaskListByTypeNoDeal(TaskType.Activity, id)
  local isCanReceive = Logic.taskLogic:GetCanReceive(tabTaskInfo, tabAllTaskInfo)
  return isCanReceive
end

function RedDotLogic.NewPlayer()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.NewPlayer)
  if actId == nil then
    return false
  end
  local isCanReceive = Logic.activityLogic:IsCanShowRedDot()
  return isCanReceive
end

function RedDotLogic.ReturnPlayer()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ReturnPlayer)
  if actId == nil then
    return false
  end
  local isCanReceive = Logic.taskReturnLogic:IsCanShowRedDot()
  return isCanReceive
end

function RedDotLogic.BuildShipGirl()
  local isHaveRedDot = Logic.buildLogic:IsHaveRedDot()
  return isHaveRedDot
end

function RedDotLogic.NewPlayerDays(index)
  local isHaveRedDot = Logic.activityLogic:IsHaveDaysRedDot(index)
  return isHaveRedDot
end

function RedDotLogic.TimeTaskDays(index)
  local isHaveRedDot = Logic.activityLogic:IsHaveTimeTaskDaysRedDot(index)
  return isHaveRedDot
end

function RedDotLogic.ReturnPlayerDays(index)
  local isHaveRedDot = Logic.taskReturnLogic:IsHaveDaysRedDot(index)
  return isHaveRedDot
end

function RedDotLogic.FirstRecharge()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.FirstRecharge)
  if actId == nil then
    return false
  end
  return Logic.activityLogic:FirstRechargeRedDot()
end

function RedDotLogic.CumuCost()
  return Logic.achieveLogic:IsCumuActivityReceviable(Activity.CumuCost)
end

function RedDotLogic.CumuRecharge()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.CumuRecharge)
  if not activityId then
    return false
  end
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  local startTime = ""
  for i, pid in ipairs(activityCfg.period_list) do
    if PeriodManager:IsInPeriod(pid) then
      startTime = PeriodManager:GetPeriodTime(pid)
      local userId = Data.userData:GetUserUid()
      local currTime = string.format("crch%s%s", userId, startTime)
      local storedTime = PlayerPrefs.GetString("crch")
      if storedTime ~= currTime then
        return true
      end
    end
  end
  return Logic.achieveLogic:IsCumuRechargeReceviable()
end

function RedDotLogic.SingleRecharge()
  return Logic.achieveLogic:IsCumuActivityReceviable(Activity.SingleRecharge)
end

function RedDotLogic.MaintenanceAnnouncement(state)
  return announcementManager:HaveRedDot()
end

function RedDotLogic.ShipLevelUpByShipId(heroId)
  if not heroId or heroId <= 0 then
    return false
  end
  local heroDev = Logic.developLogic
  local state = heroDev:GetLHeroState(heroId)
  if state ~= heroDev.E_HeroLvState.LEVELUP then
    return false
  end
  return Logic.shipLogic:CheckLevelUpByItem(heroId)
end

function RedDotLogic.Strategy(strategyId)
  if not moduleManager:CheckFunc(FunctionID.Strategy, false) then
    return false
  end
  local isLearn = Data.strategyData:GetStrategyDataById(strategyId)
  if not isLearn then
    return false
  end
  local strategyConf = configManager.GetDataById("config_strategy", strategyId)
  if strategyConf.strategy_flag > 0 and PlayerPrefs.GetBool(PlayerPrefsKey.StrategyReset .. strategyId .. strategyConf.strategy_flag, true) then
    PlayerPrefs.DeleteBoolKey(PlayerPrefsKey.Strategy .. strategyId)
    PlayerPrefs.SetBool(PlayerPrefsKey.StrategyReset .. strategyId .. strategyConf.strategy_flag, false)
  end
  return PlayerPrefs.GetBool(PlayerPrefsKey.Strategy .. strategyId, true)
end

function RedDotLogic.SafeArea(copyId)
  local copyInfo = Data.copyData:GetCopyInfoById(copyId)
  return copyInfo.SfDot
end

function RedDotLogic.ShipSkill(heroId, skillId)
  return Logic.shipSkillLogic:CheckMaterials(heroId, skillId)
end

function RedDotLogic.DailyLogin(activityId)
  local activityData = configManager.GetData("config_activity")
  for _, k in pairs(activityData) do
    if k.type == ActivityType.DailyLogin and Logic.redDotLogic.DailyLoginById(k.id) then
      return true
    end
  end
  return false
end

function RedDotLogic.DailyLoginById(activityId)
  local config = configManager.GetDataById("config_activity", activityId)
  if config.period > 0 and not PeriodManager:IsInPeriodArea(config.period, config.period_area) then
    return false
  end
  local configAll = Logic.activityLogic:GetDailyTask(activityId)
  for index, config in pairs(configAll) do
    local achieveTyp = config.login_type[1]
    local achieveId = config.login_type[2]
    local status = Logic.taskLogic:GetTaskFinishState(achieveId, achieveTyp)
    if status == TaskState.FINISH then
      return true
    end
  end
  return false
end

function RedDotLogic.ShopLevelGift1(redDotId, indexList)
  local result = false
  for i = 1, #indexList do
    local index = indexList[i]
    result = RedDotLogic.CheckRecommandGoods(redDotId, index)
    if result then
      return true
    end
  end
  return result
end

function RedDotLogic.CheckRecommandGoods(redDotId, index)
  local redDot = configManager.GetDataById("config_flagsystem", redDotId)
  local requireIds = redDot.param
  local goodsList = Logic.shopLogic:GetRecommendShopGoods()
  local goods = goodsList[index]
  if not goods then
    return false
  end
  local isInSet = RedDotLogic.IsGoodsInSet(redDotId, goods.id)
  return isInSet and not goods.soldout
end

function RedDotLogic.IsGoodsInSet(redDotId, goodsId)
  local redDot = configManager.GetDataById("config_flagsystem", redDotId)
  local requireIds = redDot.param
  local result = false
  for i, rid in ipairs(requireIds) do
    result = goodsId == rid
    if result then
      return true
    end
  end
  return result
end

function RedDotLogic.ShopLevelGift2(redDotId)
  local shopId = ShopId.Gift
  local shopInfo = Data.shopData:GetShopInfoById(shopId)
  if not shopInfo then
    return false
  end
  local shopGoods = shopInfo.ShopGoodsData
  for i, svrGoods in ipairs(shopGoods) do
    local inset = RedDotLogic.IsGoodsInSet(redDotId, svrGoods.GoodsId)
    if inset then
      local goodsCfg = Logic.shopLogic:GetGoodsInfoById(svrGoods.GoodsId)
      local canBuyNum = -1
      if goodsCfg.stock ~= -1 then
        canBuyNum = math.tointeger(goodsCfg.stock) - math.tointeger(svrGoods.Num)
      end
      local bIsRefresh = Logic.shopLogic:IsShopRefreshById(shopId)
      local soldout = svrGoods.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
      local reachLimit = true
      for _, v in ipairs(goodsCfg.buy_limits) do
        reachLimit = Logic.gameLimitLogic.CheckConditionById(v)
        if not reachLimit then
          break
        end
      end
      local available = not soldout and reachLimit
      if available then
        return true
      end
    end
  end
  return false
end

function RedDotLogic.ShopLevelGift3(redDotId, goodsId)
  local redDot = configManager.GetDataById("config_flagsystem", redDotId)
  local requireIds = redDot.param
  local shopId = ShopId.Gift
  local shopInfo = Data.shopData:GetShopInfoById(shopId)
  if not shopInfo then
    return false
  end
  local requireId = redDot.param[1] or -1
  local shopGoods = shopInfo.ShopGoodsData
  local inset = RedDotLogic.IsGoodsInSet(redDotId, goodsId)
  if not inset then
    return false
  end
  for i, svrGoods in ipairs(shopGoods) do
    if svrGoods.GoodsId == goodsId then
      local goodsCfg = Logic.shopLogic:GetGoodsInfoById(svrGoods.GoodsId)
      local canBuyNum = -1
      if goodsCfg.stock ~= -1 then
        canBuyNum = math.tointeger(goodsCfg.stock) - math.tointeger(svrGoods.Num)
      end
      local bIsRefresh = Logic.shopLogic:IsShopRefreshById(shopId)
      local soldout = svrGoods.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
      local reachLimit = true
      for _, v in ipairs(goodsCfg.buy_limits) do
        reachLimit = Logic.gameLimitLogic.CheckConditionById(v)
        if not reachLimit then
          break
        end
      end
      local available = not soldout and reachLimit
      return available
    end
  end
  return false
end

function RedDotLogic.ShopLevelGift4(redDotId)
  local funcOpen = moduleManager:CheckFunc(FunctionID.Shop, false)
  if not funcOpen then
    return false
  end
  local shopId = ShopId.Gift
  local shopInfo = Data.shopData:GetShopInfoById(shopId)
  if not shopInfo then
    return false
  end
  local svrGoodsList = shopInfo.ShopGoodsData
  local redDot = configManager.GetDataById("config_flagsystem", redDotId)
  local requireIds = redDot.param
  for i, goodsId in ipairs(requireIds) do
    local svrGoods
    for i, sg in ipairs(svrGoodsList) do
      if goodsId == sg.GoodsId then
        svrGoods = sg
        break
      end
    end
    svrGoods = svrGoods or {Num = 0}
    local goodsCfg = configManager.GetDataById("config_shop_goods", goodsId)
    local userLevel = Data.userData:GetLevel()
    if userLevel >= goodsCfg.level_deblocking then
      local canBuyNum = -1
      if goodsCfg.stock ~= -1 then
        canBuyNum = math.tointeger(goodsCfg.stock) - math.tointeger(svrGoods.Num)
      end
      local bIsRefresh = Logic.shopLogic:IsShopRefreshById(shopId)
      local soldout = svrGoods.Status == BuyStatus.HaveBuy and bIsRefresh or canBuyNum == 0
      local reachLimit = true
      for _, v in ipairs(goodsCfg.buy_limits) do
        reachLimit = Logic.gameLimitLogic.CheckConditionById(v)
        if not reachLimit then
          break
        end
      end
      local available = not soldout and reachLimit
      if available then
        return true
      end
    end
  end
  local dailyShopRed = RedDotLogic.DailyShop()
  local fashionShopRed = RedDotLogic.FashionShop()
  local brokenFashionShop = RedDotLogic.BrokenFashionShop()
  if dailyShopRed or fashionShopRed or brokenFashionShop then
    return true
  end
  return false
end

function RedDotLogic.SeaCopyBoxById(chapterId)
  return Logic.copyLogic:SeaCopyBoxById(chapterId) > 0
end

function RedDotLogic.SeaCopyBox()
  local configAll = configManager.GetData("config_chapter")
  for i, v in pairs(configAll) do
    if v.class_type == ChapterType.SeaCopy and Logic.copyLogic:SeaCopyBoxById(v.id) > 0 then
      return true
    end
  end
  return false
end

function RedDotLogic.GoodsCopyFirstBattle()
  local chapterId = configManager.GetDataById("config_parameter", 174).value
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local copyId = chapter.level_list[1]
  local data = Data.goodsCopyData:GetRankData()
  return data.Percent == nil or data.Percent < 0
end

function RedDotLogic.TestShip(activityId)
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  local userId = Data.userData:GetUserUid()
  local startTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local flag = PlayerPrefs.GetString(string.format("tstshp%s%s", userId, startTime), "")
  if flag == "" or flag == nil then
    return true
  end
  return false
end

function RedDotLogic.EquipTest(activityId)
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  local userId = Data.userData:GetUserUid()
  local startTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local flag = PlayerPrefs.GetString(string.format("eqptst%s%s", userId, startTime), "")
  if flag == "" or flag == nil then
    return true
  end
  local rewardData = activityCfg.p4
  local receiveData = Data.equipTestCopyData:GetReceivedRewards()
  local curMaxDamage = Data.equipTestCopyData:GetMaxDamage()
  local recvMap = {}
  for j, recv in ipairs(receiveData) do
    recvMap[recv.RewardId] = true
  end
  for i, data in ipairs(rewardData) do
    if curMaxDamage >= data[1] and not recvMap[data[2]] then
      return true
    end
  end
  return false
end

function RedDotLogic.EquipNewTest(activityId)
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  local isAllReceive = true
  local copyList = activityCfg.p1
  local dmgList = activityCfg.p4
  for copyIndex, copyId in ipairs(copyList) do
    local maxDamage = Data.equipNewTestData:GetMaxDamageByCopy(copyIndex)
    local receiveInfo = Data.equipNewTestData:GetReceivedRewardsByCopy(copyIndex)
    local m_dmgList = dmgList[copyIndex]
    for dmgIndex, dmgValue in ipairs(m_dmgList) do
      local isH = dmgValue < maxDamage
      local isGain = receiveInfo[dmgIndex]
      if not isGain then
        isAllReceive = false
      end
      if isH and not isGain then
        return true
      end
    end
  end
  local firstLoginToday = Data.userData:IsFirstLoginToday()
  local pageDot = Logic.equipNewTestLogic:GetDot()
  return firstLoginToday and not isAllReceive and pageDot
end

function RedDotLogic.ShipSkillByHeroId(heroId)
  if heroId <= 0 then
    return false
  end
  local heroInfo = Data.heroData:GetHeroById(heroId)
  if not heroInfo then
    return false
  end
  if heroInfo.PSKillMap then
    for skillId, v in pairs(heroInfo.PSKillMap) do
      if Logic.shipSkillLogic:CheckMaterials(heroId, skillId) then
        return true
      end
    end
  end
  return false
end

function RedDotLogic.GuildHaveApply()
  return Data.guildData:getHaveApply() > 0
end

function RedDotLogic.DailyShop()
  local showRed = Logic.shopLogic:DailySubShop()
  return showRed
end

function RedDotLogic.DailySubShop(shopId)
  return PlayerPrefs.GetBool("DailySubShop" .. shopId, false)
end

function RedDotLogic.BuildingCanGetOil()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local productmax = 0
  local oil = 0
  for i, data in ipairs(buildingDatas) do
    local buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if buildingCfg.type == MBuildingType.OilFactory then
      productmax = buildingCfg.productmax
      oil = Logic.buildingLogic:Produce(data)
    end
  end
  if productmax == 0 then
    return false
  else
    return productmax <= oil
  end
end

function RedDotLogic.BuildingCanGetGold()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local productmax = 0
  local gold = 0
  for i, data in ipairs(buildingDatas) do
    local buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if buildingCfg.type == MBuildingType.ResourceFactory then
      productmax = buildingCfg.productmax
      gold = Logic.buildingLogic:Produce(data)
    end
  end
  if productmax == 0 then
    return false
  else
    return productmax <= gold
  end
end

function RedDotLogic.BuildingCanGetItem()
  local item = Logic.buildingLogic:BuildingIsHaveItem()
  return item
end

function RedDotLogic.BuildShipStatus()
  local free = Logic.buildShipLogic:CheckFreeStatus()
  local reward = Logic.buildShipLogic:CheckTimesReward()
  return free or reward
end

function RedDotLogic.InSingleBuildingHero(args)
  local heroData = args.heroData
  local itemCount = args.itemCount
  local buildingType = args.buildingType
  if buildingType == MBuildingType.DormRoom then
    return false
  end
  local isHave = Logic.buildingLogic:IsHaveHeroInSingleBuilding(heroData)
  if buildingType == MBuildingType.ItemFactory then
    local item = itemCount == 0
    local isNew = RedDotLogic.FactoryItemIsClicked()
    isHave = isHave or item or isNew
  end
  return isHave
end

function RedDotLogic.FactoryItemIsClicked()
  local isNew = false
  local officeData = Data.buildingData:GetBuildingsByType(MBuildingType.ItemFactory)
  if officeData ~= nil and officeData[1] ~= nil and 1 <= officeData[1].Level then
    local userInfo = Data.userData:GetUserData()
    local uid = tostring(userInfo.Uid)
    isNew = PlayerPrefs.GetBool(uid .. "composeReddot", true)
  end
  return isNew
end

function RedDotLogic.InAllBuildingHero()
  local isHave = Logic.buildingLogic:IsHaveHeroInBuilding()
  return isHave
end

function RedDotLogic.BuildShipFree(config)
  local free = Logic.buildShipLogic:CheckBtnFreeStatus(config)
  return free
end

function RedDotLogic.BuildTenFree(buildid)
  local isFree = Logic.buildShipLogic:CheckTenFreeStatus(buildid)
  return isFree
end

function RedDotLogic.BuildShipTimesReward(config, id, rewardType)
  local haveReward = Logic.buildShipLogic:CheckTimesRewardInBuild(config, id, rewardType)
  return haveReward
end

function RedDotLogic.TeachingApply()
  local haveApplyInfo = Logic.teachingLogic:GetApplyInfo()
  return false
end

function RedDotLogic.TeachingCanEvaTeacher()
  local CanEva = Logic.teachingLogic:CanEvaTeacher()
  return false
end

function RedDotLogic.TeachingCanTaskReward()
  local getReward = Logic.teachingLogic:CanGetDailyTaskReward()
  return false
end

function RedDotLogic.TeachingGetCareerReward()
  local getReward = Logic.teachingLogic:CanGetCareerReward()
  return false
end

function RedDotLogic.ActivityTaskCanGetReward(activityId)
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, activityId)
  if tabTaskInfo == nil then
    return false
  end
  for _, taskInfo in ipairs(tabTaskInfo) do
    if taskInfo.State == TaskState.FINISH and taskInfo.Data.RewardTime == 0 then
      return true
    end
  end
  return false
end

function RedDotLogic:ActivitySchoolSumm()
  local activityInfo = Logic.activityLogic:GetActivityShow(ActivityPageShowType.School)
  for _, config in ipairs(activityInfo) do
    if RedDotLogic.ActivityTaskCanGetReward(config.id) then
      return true
    end
  end
  return false
end

function RedDotLogic.PresetFleetStatus()
  local isOpen = Logic.presetFleetLogic:GetRedDotState()
  return isOpen
end

function RedDotLogic:ActivityNationSumm()
  local activityInfo = Logic.activityLogic:GetActivityShow(ActivityPageShowType.NationalDay)
  for _, config in ipairs(activityInfo) do
    if RedDotLogic.ActivityTaskCanGetReward(config.id) then
      return true
    end
  end
  return false
end

function RedDotLogic:CanGetGuildTaskConstantReward()
  if not Data.guildData:inGuild() then
    return false
  end
  local myConstReward = Data.guildtaskData:GetMyGetConstantReward()
  if myConstReward ~= nil then
    return true
  end
  return false
end

function RedDotLogic:CanGetGuildTaskRandomReward()
  return Data.guildtaskData:CanDrawRandomReward()
end

function RedDotLogic:NotYetApplyGuildTask()
  if not Data.guildData:inGuild() then
    return false
  end
  local userTodayApplyTaskCount = Data.guildtaskData:GetUserTodayAcceptTaskCount()
  if 0 < userTodayApplyTaskCount then
    return false
  end
  return true
end

function RedDotLogic:OpenedTeaching()
  return false
end

function RedDotLogic:ActSSRIsHaveTimes()
  return Logic.activitySSRLogic:IsShowRedDot(Activity.ActivitySSR)
end

function RedDotLogic:WishCanUseItem()
  return Logic.wishLogic:CanUseItem()
end

function RedDotLogic:DailyCopy()
  local dailyGroupAll = configManager.GetData("config_daily_group")
  for i, dailyGroupInfo in pairs(dailyGroupAll) do
    if Logic.dailyCopyLogic:GetRewardTimesLeft(dailyGroupInfo) > 0 then
      return true
    end
  end
  return false
end

function RedDotLogic.BuildingHeroPlotSingle(args)
  local buildingId = args.buildingId
  local normalPlots = Data.buildingData:GetNormalPlots()
  local specialPlots = Data.buildingData:GetSpecialPlots()
  return normalPlots[buildingId] ~= nil or specialPlots[buildingId] ~= nil
end

function RedDotLogic.BuildingHeroPlotAll()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local normalPlots = Data.buildingData:GetNormalPlots()
  local specialPlots = Data.buildingData:GetSpecialPlots()
  local hasHero = false
  for buildingId, bdata in pairs(buildingDatas) do
    if not hasHero and #bdata.HeroList > 0 then
      hasHero = true
    end
    if normalPlots[buildingId] ~= nil or specialPlots[buildingId] ~= nil then
      return true
    end
  end
  if hasHero then
    local normalUpdateTime = Data.buildingData:GetNormalPlotUpdateTime()
    local now = time.getSvrTime()
    local cdHour = configManager.GetDataById("config_parameter", 288).value
    if now - normalUpdateTime >= cdHour * 3600 then
      Logic.buildingLogic:UpdateBuildings(false)
    end
  end
  return false
end

function RedDotLogic:HalloweenActivityNewStory()
  local activityId = Logic.activityLogic:GetActivityIdByType(ActivityType.HalloweenStory)
  if activityId == nil or activityId <= 0 then
    return false
  end
  local activityCfg = configManager.GetDataById("config_activity", activityId)
  local plotList = activityCfg.p1
  for _, plotData in ipairs(plotList) do
    local copyId = plotData[1]
    local requireCandy = plotData[2]
    local curCandy = Data.bagData:GetItemNum(HalloweenStoryCandyItemId)
    local isCandyUnlock = requireCandy <= curCandy
    if isCandyUnlock then
      local copyData = Data.copyData:GetCopyInfoById(copyId)
      if copyData ~= nil and 0 >= copyData.FirstPassTime then
        return true
      end
    end
  end
  return false
end

function RedDotLogic:ActivityEquipCanGetReward()
  local info = Data.equipactivityData:GetInfo()
  for _, data in pairs(info) do
    local equipCfg = configManager.GetDataById("config_equip", data.TemplateId)
    if data.IsReward <= 0 and data.PowerPoint >= equipCfg.max_energy then
      return true
    end
  end
  return false
end

function RedDotLogic.ActivityEquipCanGetRewardById(equipId)
  return Logic.equipLogic:CanGetAReward(equipId)
end

function RedDotLogic.ActivityEquipCanGetRewardByHero(heroId, fleetType)
  return Logic.equipLogic:CanGetARewardByHero(heroId, fleetType)
end

function RedDotLogic.ActivityEquipCanGetRewardByIndex(heroId, index, fleetType)
  return Logic.equipLogic:CanGetARewardByIndex(heroId, index, fleetType)
end

function RedDotLogic:ActivitySecretCopyCanGetReward()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActivitySecretCopy)
  if actId == nil or actId <= 0 then
    return false
  end
  local haslook = PlayerPrefs.GetBool("ActivitySecretCopy_Look", false)
  if not haslook then
    return true
  end
  local activityCfg = configManager.GetDataById("config_activity", actId)
  local rateinfo = activityCfg.p4
  local bestpasstime = Data.activitysecretcopyData:GetPassTimePerfect()
  for rateIndex, info in ipairs(rateinfo) do
    local iscan = 0 < bestpasstime and bestpasstime < info[1]
    local isGet = Data.activitysecretcopyData:IsGetRewardByRate(rateIndex)
    if iscan and not isGet then
      return true
    end
  end
  return false
end

function RedDotLogic.ThanksgivingDayReawrd(id)
  local result = Logic.activityLogic:CheckActivityOpenById(id)
  if not result then
    return false
  end
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, id)
  local tabAllTaskInfo = Logic.taskLogic:GetAllTaskListByTypeNoDeal(TaskType.Activity, id)
  local isCanReceive = Logic.taskLogic:GetCanReceive(tabTaskInfo, tabAllTaskInfo)
  return isCanReceive
end

function RedDotLogic.HeroCanFurther(heroId)
  return Logic.developLogic:CanLFurther(heroId)
end

function RedDotLogic.CheckNewYearSign(activityId)
  return Logic.activityLogic:CheckNewYearSign(activityId)
end

function RedDotLogic.ActivityShipTestReward()
  local cfgs = configManager.GetData("config_testship_task")
  for _, cfg in pairs(cfgs) do
    local taskId = cfg.id
    local status = Data.shiptaskData:GetTaskStatus(taskId)
    if status == ShipTaskStatus.Finish then
      return true
    end
  end
  local achiInfoList = Logic.shiptaskLogic:GetAchiInfoList()
  for _, achiData in ipairs(achiInfoList) do
    if achiData.IsCanGetReward then
      return true
    end
  end
  return false
end

function RedDotLogic.ActivityShipTestRewardByTaskType(taskType)
  if 0 < taskType then
    local cfgs = configManager.GetData("config_testship_task")
    for _, cfg in pairs(cfgs) do
      local taskId = cfg.id
      if taskType == cfg.test_type then
        local status = Data.shiptaskData:GetTaskStatus(taskId)
        if status == ShipTaskStatus.Finish then
          return true
        end
      end
    end
  else
    local achiInfoList = Logic.shiptaskLogic:GetAchiInfoList()
    for _, achiData in ipairs(achiInfoList) do
      if achiData.IsCanGetReward then
        return true
      end
    end
  end
  return false
end

function RedDotLogic.ActivityPageLook(activityId)
  if activityId == nil or activityId <= 0 then
    return false
  end
  local playerPrefsKey = PlayerPrefsKey.ActivityLookPrefix .. activityId
  local haslook = PlayerPrefs.GetBool(playerPrefsKey, false)
  if not haslook then
    return true
  end
  return false
end

function RedDotLogic:GMAnswerUpdate()
  return Logic.displaySettingLogic:HaveNewAnswer()
end

function RedDotLogic.FashionShop()
  local shopId = ShopId.Fashion
  return Logic.shopLogic:CheckShopNewFashion(shopId)
end

function RedDotLogic:GeneralShop()
  local fashionShopRed = RedDotLogic.FashionShop()
  local brokenFashionShop = RedDotLogic.BrokenFashionShop()
  return fashionShopRed or brokenFashionShop
end

function RedDotLogic:JOpen(id)
  local id = Activity.JOpen
  local result = Logic.activityLogic:CheckActivityOpenById(id)
  if not result then
    return false
  end
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, id)
  local tabAllTaskInfo = Logic.taskLogic:GetAllTaskListByTypeNoDeal(TaskType.Activity, id)
  local isCanReceive = Logic.taskLogic:GetCanReceive(tabTaskInfo, tabAllTaskInfo)
  if isCanReceive then
    return true
  end
  local isAllReceive = Logic.activityLogic:CheckJOpenTaskReceive()
  local fetchHeroTime = Data.jOpenData:GetFetchHeroTime()
  if isAllReceive and fetchHeroTime <= 0 then
    return true
  end
  return false
end

function RedDotLogic.NewFirstRecharge()
  local achieveID = Logic.achieveLogic:GetGlobalAchieveId()
  local status = Logic.taskLogic:GetTaskFinishState(achieveID, TaskType.Achieve)
  if status == TaskState.FINISH then
    return true
  end
  if status ~= TaskState.RECEIVED then
    local flag = Logic.activityLogic.firstRecharge or false
    if not flag then
      return true
    end
  end
  return false
end

function RedDotLogic.FreeGiftRecharge(redDotId, indexList, id)
  if id then
    return Logic.rechargeLogic:ChackGoodsCanFreeGet(id)
  else
    return Logic.rechargeLogic:CheckHaveFreeGift()
  end
  return false
end

function RedDotLogic.ActiveBrowse(actId)
  return announcementManager:CheckActNotClickById(actId)
end

function RedDotLogic.EquipIllustrate()
  local new = Data.illustrateData:IsHaveNewEquip()
  if new then
    return Logic.illustrateLogic:HaveNewEquipIllustrate()
  else
    return false
  end
end

function RedDotLogic.Exchange(id)
  local configData = configManager.GetDataById("config_activity", id)
  for i, exchangeId in ipairs(configData.p1) do
    local checkCondition = Logic.exchangeLogic:CheckCondition(exchangeId)
    local checkConsume = Logic.exchangeLogic:CheckConsume(exchangeId)
    local checkTimes = Logic.exchangeLogic:CheckTimes(exchangeId)
    if checkCondition and checkConsume and checkTimes then
      return true
    end
  end
  return false
end

function RedDotLogic.ActivitySceneLogin()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.JChildSign)
  if not actId then
    return false
  end
  local config = configManager.GetDataById("config_activity", actId)
  local inPeriod = PeriodManager:IsInPeriodArea(config.period, config.period_area)
  if not inPeriod then
    return false
  end
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local curTime = time.getSvrTime()
  local lastTime = PlayerPrefs.GetInt(uid .. "ActivitySceneLogin", 1)
  if time.isSameDay(curTime, lastTime) then
    return false
  end
  return true
end

function RedDotLogic.NewMagazine()
  local config = Logic.magazineLogic:GetLatest()
  if not config then
    return false
  end
  local idPre = PlayerPrefs.GetInt(PlayerPrefsKey.NewStrategy, 0)
  return idPre ~= config.id
end

function RedDotLogic.MagazineRewardAll()
  local configAll = configManager.GetData("config_magazine_info")
  for magazineId, v in pairs(configAll) do
    if Logic.redDotLogic.MagazineReward(magazineId) then
      return true
    end
  end
  return false
end

function RedDotLogic.MagazineReward(magazineId)
  local config = configManager.GetDataById("config_magazine_info", magazineId)
  local conditionList = config.condition
  local rewardList = config.rewards
  local item = config.item
  local num = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
  for index = 1, #rewardList do
    local condition = conditionList[index]
    local isFetch = Data.magazineData:GetFetchRewardTime(config.id, index) > 0
    if num >= condition and not isFetch then
      return true
    end
  end
  return false
end

function RedDotLogic.BattlePassCanRecieveTaskRewardByIndex(index)
  if index == nil then
    return false
  end
  local curPassLevel = Data.battlepassData:GetPassLevel()
  local maxPassLevel = Logic.battlepassLogic:GetBattlePassMaxLevel()
  if curPassLevel >= maxPassLevel then
    return false
  end
  local tasklist = {}
  if index == TgTaskIndexType.WeekTask_1 then
    tasklist = Logic.battlepassLogic:GetPerWeekPassTaskList() or {}
  elseif index == TgTaskIndexType.AchiTask_2 then
    tasklist = Logic.battlepassLogic:GetAchievePassTaskList() or {}
  end
  for _, cfg in ipairs(tasklist) do
    local taskId = cfg.id
    local taskData = Data.battlepassData:GetPassTaskData(taskId)
    if taskData.Status == BATTLEPASS_TASK_STATUS.Finished then
      return true
    end
  end
  return false
end

function RedDotLogic.BattlePassCanRecieveTaskReward()
  for _, index in pairs(TgTaskIndexType) do
    if RedDotLogic.BattlePassCanRecieveTaskRewardByIndex(index) then
      return true
    end
  end
  return false
end

function RedDotLogic.BattlePassCanRecieveLevelReward()
  local isCan = Logic.battlepassLogic:CanRewardGet()
  if isCan then
    return true
  end
  return false
end

function RedDotLogic.BattlePassActivityCanRecieveTaskRewardByIndex(index)
  if index == nil then
    return false
  end
  local curPassLevel = Data.battlepassactivityData:GetPassLevel()
  local maxPassLevel = Logic.battlepassactivityLogic:GetBattlePassMaxLevel()
  if curPassLevel >= maxPassLevel then
    return false
  end
  local tasklist = {}
  if index == TgActivityTaskIndexType.WeekTask_1 then
    tasklist = Logic.battlepassactivityLogic:GetPerWeekPassTaskList() or {}
  elseif index == TgActivityTaskIndexType.AchiTask_2 then
    tasklist = Logic.battlepassactivityLogic:GetAchievePassTaskList() or {}
  end
  for _, cfg in ipairs(tasklist) do
    local taskId = cfg.id
    local taskData = Data.battlepassactivityData:GetPassTaskData(taskId)
    if taskData.Status == BATTLEPASSACTIVITY_TASK_STATUS.Finished then
      return true
    end
  end
  return false
end

function RedDotLogic.BattlePassActivityCanRecieveTaskReward()
  for _, index in pairs(TgActivityTaskIndexType) do
    if RedDotLogic.BattlePassActivityCanRecieveTaskRewardByIndex(index) then
      return true
    end
  end
  return false
end

function RedDotLogic.BattlePassActivityCanRecieveLevelReward()
  local isCan = Logic.battlepassactivityLogic:CanRewardGet()
  if isCan then
    return true
  end
  return false
end

function RedDotLogic.BrokenFashionShop()
  local shopId = ShopId.BrokenFashion
  return Logic.shopLogic:CheckShopNewFashion(shopId)
end

function RedDotLogic.BirthdayCakePage()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.BirthdayCake)
  if actId == nil then
    return false
  end
  local isCanReceive = Logic.activityBirthdayLogic:IsCanShowRedDot()
  return isCanReceive
end

function RedDotLogic.DriftingBottlePage()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.DriftingBottle)
  if actId == nil then
    return false
  end
  if RedDotLogic.ActivityTaskCanGetReward(actId) then
    return true
  end
  return false
end

function RedDotLogic.ActivityRollsTime()
  local actRollsInfo = Data.activityRollsData:GetData()
  local time = actRollsInfo.DaySelectCount or 1
  if time < 1 then
    return true
  end
  return false
end

function RedDotLogic.ActivityMiniGame()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActMiniGame)
  if actId == nil then
    return false
  end
  if RedDotLogic.ActivityTaskCanGetReward(actId) then
    return true
  end
  return false
end

function RedDotLogic.FreePackageSelective(actId)
  return Logic.packageSelectiveLogic:CheckFreeGift(actId)
end

function RedDotLogic.ActivityLoveLetterReward()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActivityValentineGift)
  if actId == nil or actId <= 0 then
    return false
  end
  local activityCfg = configManager.GetDataById("config_activity", actId)
  local isInPeriod = 0 < activityCfg.period and PeriodManager:IsInPeriodArea(activityCfg.period, activityCfg.period_area)
  if not isInPeriod then
    return false
  end
  local isGet = Data.activityvalentineloveletterData:GetCurActShipCanGet()
  if isGet then
    return false
  end
  return true
end

function RedDotLogic.MultiPveTask(actId)
  local tabTaskInfo = Logic.taskLogic:GetTaskListByTypeWithRewardSort(TaskType.Activity, actId, true)
  for _, taskInfo in ipairs(tabTaskInfo) do
    if taskInfo.State == TaskState.FINISH then
      return true
    end
  end
  return false
end

function RedDotLogic.MultiPveEntrance()
  local actId = Logic.multiPveActLogic:GetPveActRedDotParam()
  local actConfig = Logic.multiPveActLogic:GetActConfig(actId)
  local isOpen = Data.activityData:IsActivityOpen(actId)
  if not isOpen then
    return false
  end
  local copyId = actConfig.p2[1]
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local copyRewardCount = Data.copyData:GetCopyRewardCount(chapterId)
  return 0 < copyRewardCount
end

function RedDotLogic.ActivityGalgame(actId)
  local activityCfg = configManager.GetDataById("config_activity", actId)
  local openNewPlot = false
  local taskFinish = false
  local openExtraPlot = false
  local drawReward = false
  if #activityCfg.p1 > 0 then
    openNewPlot = Logic.activityGalgameLogic:CheckOpenNewPlot(activityCfg.p1[1])
  end
  if 0 < #activityCfg.p2 then
    taskFinish = Logic.activityGalgameLogic:CheckTaskReward(activityCfg.p2[1])
  end
  if 0 < #activityCfg.p3 then
    openExtraPlot = Logic.activityGalgameLogic:CheckOpenExtraPlot(activityCfg.p3[1])
  end
  if 0 < #activityCfg.p6 then
    drawReward = Logic.activityGalgameLogic:CheckCanRandom(activityCfg.p6[1])
  end
  return openNewPlot or taskFinish or openExtraPlot or drawReward
end

function RedDotLogic.ActGalgamePlot(actId)
  return Logic.activityGalgameLogic:CheckOpenNewPlot(actId)
end

function RedDotLogic.ActGalgameTask(actId)
  return Logic.activityGalgameLogic:CheckTaskReward(actId)
end

function RedDotLogic.ActGalgameExtraPlot(actId)
  return Logic.activityGalgameLogic:CheckOpenExtraPlot(actId)
end

function RedDotLogic.ActGalgameChapter(actId)
  return Logic.activityGalgameLogic:CheckNewChapter(actId)
end

function RedDotLogic.ActGalgameRandom(actId)
  return Logic.activityGalgameLogic:CheckCanRandom(actId)
end

function RedDotLogic.VideoOpen()
  local configAll = configManager.GetData("config_anniversary_video")
  for _, info in pairs(configAll) do
    local isOpen = info.period < 0 or PeriodManager:IsInPeriodArea(info.period, info.period_area)
    local haveWatched = Data.activityVideoData:IsVideoWatched(info.id)
    if isOpen and not haveWatched then
      return true
    end
  end
  return false
end

function RedDotLogic.ActCopyDropUp()
  local activityOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.ActDropShipUp)
  local functionOpen = moduleManager:CheckFunc(FunctionID.DropShipUpActivity, false)
  return activityOpen and functionOpen
end

function RedDotLogic.AnniversaryMemoryReward(actId)
  return Logic.activityLogic:CheckAnniversaryMemoryReward(actId)
end

function RedDotLogic.AffectionGiftEnterCheck()
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  return PlayerPrefs.GetInt(PlayerPrefsKey.AffectionGiftEnter .. uid, 1) == 1
end

function RedDotLogic.HaveGuildWarBossReward()
  local guildwarData = Data.guildData:GetGuildWarData()
  return guildwarData.haveKillReward
end

function RedDotLogic.ActivityTaskFoodCompose()
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.FoodCompose)
  if actId == nil then
    return false
  end
  local tabTaskInfo = Logic.taskLogic:GetTaskListByType(TaskType.Activity, actId)
  if tabTaskInfo == nil then
    return false
  end
  for _, taskInfo in ipairs(tabTaskInfo) do
    if taskInfo.State == TaskState.FINISH and taskInfo.Data.RewardTime == 0 then
      return true
    end
  end
  return false
end

function RedDotLogic.SportRed()
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local isNew = PlayerPrefs.GetBool(uid .. "SportMeetMainPage", true)
  return isNew
end

function RedDotLogic.PlotPartRed(classId, partId)
  local chapterInfoList = configManager.GetDataById("config_chapter_plot_type", classId)
  if chapterInfoList and chapterInfoList.chapter_list2[partId] then
    local list = chapterInfoList.chapter_list2[partId]
    for i = 1, #list do
      if RedDotLogic.PlotById(list[i]) then
        return true
      end
    end
  end
  return false
end

function RedDotLogic.CheckGORewardRed()
  local guildPoint = Data.guildOfferData:GetGuildPoints() or 0
  local perPoint = Data.guildOfferData:GetUserOfferInfo().PersonalPoints or 0
  local guildRecv = Data.guildOfferData:GetUserOfferInfo().GuildRewardProgress
  local personRecv = Data.guildOfferData:GetUserOfferInfo().PersonalRewardProgress
  local perCfg, guildCfg = Data.guildOfferData:GetPerAndGdScoreCfg()
  local guildCanRec = {}
  local perCanRec = {}
  for i = 1, #perCfg do
    if perPoint >= perCfg[i].score then
      table.insert(perCanRec, perCfg[i])
    end
  end
  for i = 1, #guildCfg do
    if guildPoint >= guildCfg[i].score and perPoint >= guildCfg[i].personscore then
      table.insert(guildCanRec, guildCfg[i])
    end
  end
  if (perCanRec ~= nil and #perCanRec or 0) > (personRecv ~= nil and #personRecv or 0) or (guildCanRec ~= nil and #guildCanRec or 0) > (guildRecv ~= nil and #guildRecv or 0) then
    return true
  end
  return false
end

function RedDotLogic.CheckGuildBoxRewardRed()
  local boxData = Data.guildData:GetGuildBoxData()
  return boxData:CheckCanGetBox()
end

function RedDotLogic.CheckGuildBigActRewardRed()
  local bigActData = Data.guildData:GetGuildBigActivityData()
  return bigActData:CheckHaveTaskReward()
end

function RedDotLogic.CheckGuildBigActPerRewardRed(index)
  local bigActData = Data.guildData:GetGuildBigActivityData()
  return bigActData:CheckHavePeriodTaskReward(index)
end

return RedDotLogic
