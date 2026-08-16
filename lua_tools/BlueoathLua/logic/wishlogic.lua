local WishLogic = class("logic.WishLogic")

function WishLogic:initialize()
  self:ResetData()
end

function WishLogic:ResetData()
  self.m_expend = false
  self.m_page = nil
  self.m_maskTag = false
  self.m_posConfig = {}
  self.m_pageIndex = 1
  self:_initShippPos()
  self.banHero = {}
  self.m_pressLock = true
  self.m_dummyItems = {}
  self.m_ship2item = {}
  self:_HandleConfig()
end

function WishLogic:_HandleConfig()
  self:_HandleVowItemConfig()
end

function WishLogic:_HandleVowItemConfig()
  local configs = configManager.GetData("config_vow_item")
  local res = {}
  for id, config in pairs(configs) do
    for _, hero in ipairs(config.ship_id) do
      if res[hero] then
        table.insert(res[hero], id)
      else
        res[hero] = {id}
      end
    end
  end
  self.m_ship2item = res
end

function WishLogic:SetPageIndex(index)
  self.m_pageIndex = index
end

function WishLogic:GetPageIndex()
  return self.m_pageIndex
end

function WishLogic:SetBanHero(hero)
  self.banHero = hero
end

function WishLogic:GetBanHero()
  return self.banHero
end

function WishLogic:_initShippPos()
  local config = self:GetWishShipConfig()
  for i, v in ipairs(config) do
    self.m_posConfig[i] = {
      x = v.vow_pos_x,
      y = v.vow_pos_y
    }
  end
end

function WishLogic:SetExpend(param)
  self.m_expend = param
end

function WishLogic:GetExpend()
  return self.m_expend
end

function WishLogic:SetBanPage(page)
  self.m_page = page
end

function WishLogic:GetBanPage()
  return self.m_page
end

function WishLogic:SetHideMask(hide)
  self.m_maskTag = hide
end

function WishLogic:GetHideMask()
  return self.m_maskTag
end

function WishLogic:GetChargeUp(quality)
  if quality == ShipQuality.SSR then
    return configManager.GetDataById("config_parameter", 85).value
  elseif quality == ShipQuality.SR then
    return configManager.GetDataById("config_parameter", 86).value
  end
end

function WishLogic:GetChargeUpStr(quality)
  if quality == ShipQuality.SSR then
    local upTime = configManager.GetDataById("config_parameter", 85).value
    return UIHelper.GetLocString(951037, time.getTimeStringFontDynamic(upTime))
  elseif quality == ShipQuality.SR then
    local upTime = configManager.GetDataById("config_parameter", 86).value
    return UIHelper.GetLocString(951036, time.getTimeStringFontDynamic(upTime))
  end
end

function WishLogic:GetWishItemConfigById(id)
  return configManager.GetDataById("config_vow_item", id)
end

function WishLogic:GetWishItemType(tid)
  return self:GetWishItemConfigById(tid).type
end

function WishLogic:GetWishItemBindHeros(tid)
  if self:GetWishItemType(tid) == EWishItemType.COMMON then
    return {}
  end
  return self:GetWishItemConfigById(tid).ship_id
end

function WishLogic:GetHeroBindWishItem(tid)
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
  return self.m_ship2item[si_id] or {}
end

function WishLogic:CheckBindActive()
  local tid = Data.illustrateData:GetVowHero()
  if tid == 0 then
    return {}
  end
  local res = self:GetHeroBindWishItem(tid)
  return res
end

function WishLogic:GetWishItemTime(id)
  local superId = self:GetSuperWishItemId()
  if id == superId then
    return -1
  end
  local config = self:GetWishItemConfigById(id)
  if config == nil then
    return 0
  end
  local vip = Logic.userLogic:CheckMonthCardPrivilege()
  if vip then
    return config.time + config.vip_add_time, vip and 0 < config.vip_add_time
  end
  return config.time, false
end

function WishLogic:GetWishItemVipAddTime(id)
  return self:GetWishItemConfigById(id).vip_add_time
end

function WishLogic:GetIcon(id)
  if self:IsSuperWishItem(id) then
    return Logic.itemLogic:GetIcon(id)
  end
  return self:GetWishItemConfigById(id).icon
end

function WishLogic:GetName(id)
  if id == self:GetSuperWishItemId() then
    local cfg = configManager.GetDataById("config_item_info", id)
    if cfg == nil then
      logError("error: no item " .. tostring(id) .. " found in item_info")
      return ""
    end
    return cfg.name
  end
  return self:GetWishItemConfigById(id).name
end

function WishLogic:GetDesc(id)
  if self:IsSuperWishItem(id) then
    return Logic.itemLogic:GetDesc(id)
  end
  return self:GetWishItemConfigById(id).description
end

function WishLogic:GetQuality(id)
  if self:IsSuperWishItem(id) then
    return Logic.itemLogic:GetQuality(id)
  end
  return self:GetWishItemConfigById(id).quality
end

function WishLogic:GetFrame(id)
  return ""
end

function WishLogic:GetTexIcon(id)
  return self:GetWishItemConfigById(id).icon
end

function WishLogic:GetWishConfigByType(type)
  return configManager.GetDataById("config_vow", type)
end

function WishLogic:GetWishShipConfig()
  return configManager.GetData("config_vow_wall_ship")
end

function WishLogic:GetShipPosByIndex(index)
  local temp = self.m_posConfig[index]
  if temp then
    return Vector3.New(temp.x, temp.y, 0)
  else
    return Vector3.New(1000, 25, 0)
  end
end

function WishLogic:WallPos2IndexLeft(x)
  local config = self:GetWishShipConfig()
  if x <= config[1].vow_pos_x then
    return 0
  end
  if x > config[#config].vow_pos_x then
    return #config + 1
  end
  local factor = self:_getPosThreshold()
  for i = 2, #config do
    if x > config[i - 1].vow_pos_x + factor and x <= config[i].vow_pos_x - factor then
      return i
    end
  end
  return -1
end

function WishLogic:_getPosThreshold()
  return 0.01
end

function WishLogic:WallPos2IndexRight(x)
  local config = self:GetWishShipConfig()
  if x < config[1].vow_pos_x then
    return 0
  end
  if x >= config[#config].vow_pos_x then
    return #config + 1
  end
  local factor = self:_getPosThreshold()
  for i = #config, 2, -1 do
    if x >= config[i - 1].vow_pos_x + factor and x < config[i].vow_pos_x - factor then
      return i - 1
    end
  end
  return -1
end

function WishLogic:_getDirection(posCurX, posInitX)
  local factor = self:_getPosThreshold()
  if posCurX > posInitX + factor then
    return 1
  else
    return 2
  end
end

function WishLogic:WallPos2Index(posCurX, posInitX)
  local direct = self:_getDirection(posCurX, posInitX)
  if direct == 1 then
    return self:WallPos2IndexRight(posCurX)
  else
    return self:WallPos2IndexLeft(posCurX)
  end
end

function WishLogic:GetWishItemAndFormat()
  local config = configManager.GetData("config_vow_item")
  local itemTab = Data.bagData:GetItemData()
  local filter = function(tid)
    return self:GetWishItemType(tid) == EWishItemType.COMMON or table.containV(self:CheckBindActive(), tid)
  end
  local res = {}
  for id, v in pairs(config) do
    if filter(id) then
      local temp = {}
      temp.Type = GoodsType.WISH
      temp.ConfigId = id
      temp.Num = 0
      temp.Quality = v.quality
      if itemTab[id] then
        temp.Num = itemTab[id].num
      end
      temp.Desc = time.getTimeStringFontDynamic(Mathf.ToInt(self:GetWishItemTime(id)), false)
      table.insert(res, temp)
    end
  end
  table.sort(res, function(l, r)
    return l.Quality > r.Quality
  end)
  return res
end

function WishLogic:GetWishItemNumById(tid)
  local bagData = Data.bagData:GetItemData()
  return bagData[tid] and bagData[tid].num or 0
end

function WishLogic:GetWishItemRetention()
  local config = configManager.GetData("config_vow_item")
  local itemTab = Data.bagData:GetItemData()
  local res = {}
  for id, v in pairs(config) do
    local num = itemTab[id] and itemTab[id].num or 0
    res[tostring(id)] = num
  end
  local superItemId = self:GetSuperWishItemId()
  local num = itemTab[superItemId] and itemTab[superItemId].num or 0
  res[tostring(superItemId)] = num
  return res
end

function WishLogic:GetSuperWishItemId()
  return configManager.GetDataById("config_parameter", 84).value
end

function WishLogic:IsSuperWishItem(id)
  return id == self:GetSuperWishItemId()
end

function WishLogic:CheckCharge()
  local tim = Data.illustrateData:GetChargeTime()
  if 0 < tim then
    local res = tim - time.getSvrTime()
    if res <= 0 then
      return false, 0
    end
    return true, res
  else
    return false, 0
  end
end

function WishLogic:GetLimitTime()
  local hi_if = Data.illustrateData:GetVowHero()
  local si_id = configManager.GetDataById("config_ship_main", hi_if).ship_info_id
  local type = Logic.shipLogic:GetQualityByInfoId(si_id)
  local config = self:GetWishConfigByType(type)
  return config.result_that_quality_limit_time
end

function WishLogic:GetLimitTimeStr()
  local hi_if = Data.illustrateData:GetVowHero()
  local si_id = configManager.GetDataById("config_ship_main", hi_if).ship_info_id
  local quality = Logic.shipLogic:GetQualityByInfoId(si_id)
  local limitTime = self:GetChargeUp(quality)
  local str
  if quality == ShipQuality.SR then
    return UIHelper.GetLocString(951036, time.getTimeStringFontDynamic(limitTime))
  else
    return UIHelper.GetLocString(951037, time.getTimeStringFontDynamic(limitTime))
  end
  return str
end

function WishLogic:GetResChargeTime()
  local sm_id = Data.illustrateData:GetVowHero()
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(sm_id)
  if sm_id ~= 0 then
    local type = Logic.shipLogic:GetQualityByInfoId(si_id)
    local config = self:GetWishConfigByType(type)
    return config.result_that_quality_add_time
  end
  return 0
end

function WishLogic:GetVowResultAddTimeStr()
  local sm_id = Data.illustrateData:GetVowHero()
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(sm_id)
  local str = ""
  if sm_id ~= 0 then
    local quality = Logic.shipLogic:GetQualityByInfoId(si_id)
    local config = self:GetWishConfigByType(quality)
    local addTime = config.result_that_quality_add_time
    if quality == ShipQuality.SR then
      return UIHelper.GetLocString(951034, time.getTimeStringFontDynamic(addTime))
    else
      return UIHelper.GetLocString(951035, time.getTimeStringFontDynamic(addTime))
    end
  end
  return str
end

function WishLogic:GetResChargeTimeByQuality(quality)
  local config = self:GetWishConfigByType(quality)
  return config.result_that_quality_add_time
end

function WishLogic:GetResChargeTimeStrByQuality(quality)
  local config = self:GetWishConfigByType(quality)
  if quality == ShipQuality.SR then
    return UIHelper.GetLocString(951034, time.getTimeStringFontDynamic(config.result_that_quality_add_time))
  else
    return UIHelper.GetLocString(951035, time.getTimeStringFontDynamic(config.result_that_quality_add_time))
  end
end

function WishLogic:GetBanHeroNum()
  local _, t_sr, t_ssr = Data.wishData:GetAllWishNum()
  local s_sr, s_ssr = Logic.wishLogic:GetPickHeroNum()
  return t_sr - s_sr, t_ssr - s_ssr
end

function WishLogic:GetPickHeroNum()
  local data = Data.wishData:GetSelectHeroList()
  local sr, ssr = 0, 0
  for _, info in pairs(data) do
    if info.quality == HeroRarityType.SR then
      sr = sr + 1
    elseif info.quality == HeroRarityType.SSR then
      ssr = ssr + 1
    end
  end
  return sr, ssr
end

function WishLogic:GetBanPickNumStr(t)
  local sr, ssr = 0
  if t == "ban" then
    sr, ssr = self:GetBanHeroNum()
  else
    sr, ssr = self:GetPickHeroNum()
  end
  return {sr = sr, ssr = ssr}
end

function WishLogic:GetCurCoolDownTime()
  local chargeTime = Data.illustrateData:GetChargeTime()
  local serverTime = time.getSvrTime()
  return chargeTime - serverTime
end

function WishLogic:GetBanHeroAddTime()
  local data = Data.wishData:GetBanHeroList()
  local time = 0
  for _, info in pairs(data) do
    time = time + self:getChargeTime(info)
  end
  return time
end

function WishLogic:GetBanHeroAddTimeStr()
  local sr, ssr = Logic.wishLogic:GetBanHeroNum()
  local oTime = Logic.wishLogic:GetBanHeroAddTime()
  local str = UIHelper.GetLocString(951033, sr, ssr, time.getTimeStringFontDynamic(oTime))
  return str
end

function WishLogic:GetFinalChargeTime()
  local time = self:GetBanHeroAddTime()
  local preHero = Data.illustrateData:GetVowHero()
  if preHero ~= 0 then
    time = time + self:GetResChargeTime()
  end
  local infoId = Logic.shipLogic:GetShipInfoIdByTid(preHero)
  local quality = Logic.shipLogic:GetQualityByInfoId(infoId)
  local up = self:GetChargeUp(quality)
  if time > up then
    return up, true
  else
    return time, false
  end
end

function WishLogic:GetFinalChargeTimeStr()
  local finalTime, isLimit = self:GetFinalChargeTime()
  return UIHelper.GetLocString(951040, time.getTimeStringFontDynamic(finalTime)), isLimit
end

function WishLogic:GetHeroChargeTimeByQuality(quality)
  local time = self:GetBanHeroAddTime()
  time = time + self:GetResChargeTimeByQuality(quality)
  local up = self:GetChargeUp(quality)
  if time > up then
    return up, true
  else
    return time, false
  end
end

function WishLogic:GetHeroChargeTimeStrByQuality(quality)
  local addTime = self:GetBanHeroAddTime()
  addTime = addTime + self:GetResChargeTimeByQuality(quality)
  local up = self:GetChargeUp(quality)
  addTime = addTime > up and up or addTime
  if quality == ShipQuality.SR then
    return UIHelper.GetLocString(951038, time.getTimeStringFontDynamic(addTime))
  else
    return UIHelper.GetLocString(951039, time.getTimeStringFontDynamic(addTime))
  end
end

function WishLogic:getChargeTime(hero)
  local config = self:GetWishConfigByType(hero.quality)
  if hero.Advance ~= 6 then
    return config.ban_not_full_break_add_time
  else
    return config.ban_full_break_add_time
  end
end

function WishLogic:GetBanHeroNames()
  local res = {}
  local count = 1
  local banHeros = Data.wishData:GetBanHeroList()
  for _, info in pairs(banHeros) do
    local name = Data.illustrateData:GetIllustrateById(info.IllustrateId).Name
    res[tostring(count)] = name
    count = count + 1
  end
  return res
end

function WishLogic:GetPickHeroNames()
  local res = {}
  local count = 1
  local pickHeros = Data.wishData:GetSelectHeroList()
  for _, info in pairs(pickHeros) do
    local name = Data.illustrateData:GetIllustrateById(info.IllustrateId).Name
    res[tostring(count)] = name
    count = count + 1
  end
  return res
end

function WishLogic:GetDailyWishUp()
  local base = self:GetDailyWishBaseUp()
  return base
end

function WishLogic:GetDailyWishBaseUp()
  return configManager.GetDataById("config_parameter", 115).value
end

function WishLogic:GetDailyWishExtraUp()
  return configManager.GetDataById("config_parameter", 116).value
end

function WishLogic:GetWishTweenTime()
  return 1
end

function WishLogic:GetIndexByPos(localPos)
  local len = #self.m_posConfig
  if localPos.x < self.m_posConfig[1].x then
    return 1
  elseif localPos.x > self.m_posConfig[len].x then
    return len
  end
  for i = 1, len - 1 do
    if localPos.x > self.m_posConfig[i].x and localPos.x < self.m_posConfig[i + 1].x then
      return i
    end
  end
  return 0
end

function WishLogic:CheckCanWish(id)
  local config = Logic.illustrateLogic:GetIllustrateConfigById(id)
  if config == nil then
    return false
  end
  if config.is_wish == ShipWishState.ALLNO then
    return false
  elseif config.is_wish == ShipWishState.ALLYES then
    return true
  elseif config.is_wish == ShipWishState.CONDITION then
    if config.activity > 0 then
      local startTime, endTime = Logic.activityLogic:GetActivityStartEndTime(config.activity)
      return time.getSvrTime() > startTime + config.enter_wish_time * 86400
    elseif 0 < config.wish_activatetime then
      return time.getSvrTime() > config.wish_activatetime
    end
    logError("wish type need time and time is zero,id :" .. id)
    return false
  else
    logError("invalid wish type,id:" .. id .. " type:" .. config.is_wish)
    return false
  end
end

function WishLogic:GetAllNoHeros()
  local res = {}
  local filter = function(config)
    return config.is_wish == ShipWishState.ALLNO and config.quality >= HeroRarityType.SR and config.show_state > IllustrateShow.NOOPEN
  end
  local configs = Logic.illustrateLogic:GetIllustrateConfig()
  for id, config in pairs(configs) do
    if filter(config) then
      table.insert(res, id)
    end
  end
  return res
end

function WishLogic:FilterCanWish(ids)
  local res = {}
  for i, id in ipairs(ids) do
    if self:CheckCanWish(id) then
      table.insert(res, id)
    end
  end
  return res
end

function WishLogic:CheckAdvance()
  local config = Logic.illustrateLogic:GetIllustrateConfig()
  local res = {}
  for id, info in pairs(config) do
    if info.is_wish == ShipWishState.CONDITION and info.activity > 0 then
      local startTime, _ = Logic.activityLogic:GetActivityStartEndTime(info.activity)
      if time.getSvrTime() < startTime + info.enter_wish_time * 86400 then
        table.insert(res, id)
      end
    end
  end
  return 0 < #res, res
end

function WishLogic:CheckWishItemNum(id)
  local ok, total = self:HaveNumLimit(id)
  local num = Data.illustrateData:GetWishItemNum(id)
  if ok then
    return total > num, total - num, true
  else
    return true, 0, false
  end
end

function WishLogic:HaveNumLimit(id)
  local config = self:GetWishItemConfigById(id)
  if self:IsSuperWishItem(id) then
    return false, 0
  end
  local act, tid, num = self:InActivty()
  if id == tid and act then
    return true, num
  end
  return 0 < config.daily_limit, config.daily_limit
end

function WishLogic:CheckSelectTip(hero)
  return hero.Advance == Logic.shipLogic:GetBreakMaxByShipMainId(hero.TemplateId) and self:_CheckSelectMaxShipTip()
end

function WishLogic:_CheckSelectMaxShipTip()
  local playerPrefsKey = PlayerPrefsKey.WishMaxShip
  if playerPrefsKey then
    local setok = PlayerPrefs.GetBool(playerPrefsKey, false)
    local settime = PlayerPrefs.GetInt(playerPrefsKey .. "Time", 0)
    if setok then
      return not time.isSameDay(settime, time.getSvrTime())
    end
  end
  return true
end

function WishLogic:GetBanHeroCount()
  local total = Data.wishData:GetAllWishNum()
  local select = Data.wishData:GetSelectWishNum()
  return total - select
end

function WishLogic:GetPressUseItemDurationConfig()
  return configManager.GetDataById("config_parameter", 186).value * 1.0E-4
end

function WishLogic:DummyCheckWishItemNum(id)
  local ok, total = self:HaveNumLimit(id)
  if ok then
    local num = Data.illustrateData:GetWishItemNum(id)
    num = num + self:GetDummyItem(id)
    return total > num, num
  else
    return true, 0
  end
end

function WishLogic:DummyGetWishItemNum(id)
  local num = Data.bagData:GetItemNum(id)
  num = num - self:GetDummyItem(id)
  return num
end

function WishLogic:DummyCheckCharge(id)
  local num = self:GetDummyItem(id)
  local tim = Data.illustrateData:GetChargeTime()
  tim = tim - self:GetWishItemTime(id) * num
  if 0 < tim then
    local res = tim - time.getSvrTime()
    if res <= 0 then
      return false, 0
    end
    return true, res
  else
    return false, 0
  end
end

function WishLogic:DummyGetCurCoolDownTime(tid)
  local num = self:GetDummyItem(tid)
  local chargeTime = Data.illustrateData:GetChargeTime()
  chargeTime = chargeTime - self:GetWishItemTime(tid) * num
  local serverTime = time.getSvrTime()
  return chargeTime - serverTime
end

function WishLogic:SetPressLock(isOn)
  self.m_pressLock = isOn
end

function WishLogic:GetPressLock()
  return self.m_pressLock
end

function WishLogic:SetDummyItem(tid, num)
  self.m_dummyItems[tid] = num
end

function WishLogic:GetDummyItem(tid)
  return self.m_dummyItems[tid] or 0
end

function WishLogic:AddDummyItem(tid, num)
  num = num or 1
  if self.m_dummyItems[tid] then
    self.m_dummyItems[tid] = self.m_dummyItems[tid] + num
  else
    self.m_dummyItems[tid] = num
  end
end

function WishLogic:ResetAllDummyItem()
  self.m_dummyItems = {}
end

function WishLogic:CheckAndSendUseItem(id, num)
  if num < 1 then
    return
  end
  if self:IsSuperWishItem(id) then
    logError("press send super wish item, it is exception")
    return
  end
  num = self:_pressCheckCDOverflow(id, num)
  num = self:_pressCheckRemainItemNum(id, num)
  num = self:_pressCheckWishItemNum(id, num)
  Service.illustrateService:SendVowDecTime({
    {ItemTid = id, ItemNum = num}
  }, nil, WishUseItemWay.PRESS)
end

function WishLogic:CheckUseItem(param)
  local res = {}
  for id, num in pairs(param) do
    if 0 < num and not self:IsSuperWishItem(id) then
      num = self:_pressCheckCDOverflow(id, num)
      num = self:_pressCheckRemainItemNum(id, num)
      num = self:_pressCheckWishItemNum(id, num)
      res[id] = num
    else
      logError("use wish item check exception:id:" .. id .. " num:" .. num)
    end
  end
  return res
end

function WishLogic:_pressCheckCDOverflow(id, argNum)
  if argNum <= 1 then
    return argNum
  end
  for i = argNum, 1, -1 do
    if not self:_checkOverflowImp(i - 1, id) and self:_checkOverflowImp(i, id) then
      return i
    end
  end
  return argNum
end

function WishLogic:_checkOverflowImp(num, id)
  local _, time = self:CheckCharge()
  local reduce = self:GetWishItemTime(id) * num
  local limitTime = self:GetLimitTime()
  return reduce > time - limitTime
end

function WishLogic:_pressCheckRemainItemNum(id, argNum)
  local itemNum = Data.bagData:GetItemNum(id)
  return Mathf.Min(argNum, itemNum)
end

function WishLogic:_pressCheckWishItemNum(id, argNum)
  local ok, total = self:HaveNumLimit(id)
  if ok then
    local usedNum = Data.illustrateData:GetWishItemNum(id)
    return Mathf.Min(argNum, total - usedNum)
  else
    return argNum
  end
end

function WishLogic:PressBaseSend(id)
  Service.illustrateService:SendVowDecTime({
    {ItemTid = id, ItemNum = 1}
  }, nil, WishUseItemWay.PRESS)
end

function WishLogic:GetAutoTimeConfig()
  return 86400
end

function WishLogic:AutoAddCommonAssert()
  local bAllZero = true
  local limitOk, limit
  local limitCount, limitUpCount, limitNoCount = 0, 0, 0
  local data = self:GetWishItemAndFormat()
  for index, info in ipairs(data) do
    if not self:IsSuperWishItem(info.ConfigId) then
      if 0 < info.Num then
        bAllZero = false
      end
      limitOk, _, limit = self:CheckWishItemNum(info.ConfigId)
      if limit then
        limitCount = limitCount + 1
      elseif 0 < info.Num then
        limitNoCount = limitNoCount + 1
      end
      if not limitOk then
        limitUpCount = limitUpCount + 1
      end
    end
  end
  if bAllZero or limitNoCount == 0 and 0 < limitUpCount and limitCount == limitUpCount then
    return false, "\229\189\147\229\137\141\230\151\160\229\143\175\231\148\168\232\174\184\230\132\191\231\159\179"
  end
  return true, ""
end

function WishLogic:GetAutoAddRmd(time)
  local cdTime = self:GetCurCoolDownTime()
  time = time or cdTime
  time = Mathf.Min(time, cdTime)
  local datas = self:GetWishItemAndFormat()
  local GetOrder = function(tid)
    return self:GetWishItemType(tid) == EWishItemType.BINDSHIP and 1 or 0
  end
  local o1, o2
  table.sort(datas, function(t1, t2)
    o1 = GetOrder(t1.ConfigId)
    o2 = GetOrder(t2.ConfigId)
    if o1 ~= o2 then
      return o1 > o2
    else
      return t1.Quality < t2.Quality
    end
  end)
  local res = {}
  local numCache, limit, waste = 0, 0, 0
  local ok
  for index, info in ipairs(datas) do
    if not self:IsSuperWishItem(info.ConfigId) then
      numCache = self:GetWishItemNumById(info.ConfigId)
      ok = self:HaveNumLimit(info.ConfigId)
      if ok then
        _, limit = self:CheckWishItemNum(info.ConfigId)
        numCache = Mathf.Min(numCache, limit)
      end
      if 0 < numCache then
        for i = 1, numCache do
          time = time - self:GetWishItemTime(info.ConfigId)
          if time <= 0 then
            res[info.ConfigId] = i
            waste = -time
            goto lbl_78
          end
        end
        res[info.ConfigId] = numCache
      end
    end
  end
  goto lbl_78
  ::lbl_78::
  if next(res) == nil or waste == 0 then
    return res
  end
  local wasteMedia = {}
  for id, _ in pairs(res) do
    local time = self:GetWishItemTime(id)
    table.insert(wasteMedia, {ConfigId = id, Time = time})
  end
  table.sort(wasteMedia, function(t1, t2)
    return t1.Time < t2.Time
  end)
  local wasetTag = wasteMedia[1].Time
  if waste >= wasetTag then
    local num, len, id = 0, #wasteMedia, 0
    for j = 1, len do
      id = wasteMedia[j].ConfigId
      num = res[id]
      for i = num, 1, -1 do
        waste = waste - wasteMedia[j].Time
        if i == 1 then
          res[id] = nil
          if wasteMedia[j + 1] then
            wasetTag = wasteMedia[j + 1].Time
          end
        else
          res[id] = i - 1
        end
        if waste < wasetTag then
          return res
        end
      end
    end
    return res
  else
    return res
  end
end

function WishLogic:GetCdMinItem(param)
  table.sort(param, function(id1, id2)
    local cd1, cd2
    cd1 = self:GetWishItemTime(id1)
    cd2 = self:GetWishItemTime(id2)
    return cd1 < cd2
  end)
  return param[1]
end

function WishLogic:CheckWishWaste(items)
  local time = Logic.wishLogic:GetCurCoolDownTime()
  local sub = 0
  for id, num in pairs(items) do
    sub = sub + Logic.wishLogic:GetWishItemTime(id) * num
  end
  local res = sub - time
  return 0 < res, res
end

function WishLogic:InActivty()
  local actIds = self:_GetActId()
  if actIds then
    local config, startTime, endTime, num, tid
    for _, actId in ipairs(actIds) do
      config = configManager.GetDataById("config_activity", actId)
      startTime, endTime = Logic.activityLogic:GetActivityStartEndTime(actId)
      if startTime <= time.getSvrTime() and endTime >= time.getSvrTime() then
        num = config.p13[1]
        tid = config.p8[1]
        return true, tid, num
      end
    end
    return false, nil, nil
  else
    return false, nil, nil
  end
end

function WishLogic:_GetActId()
  local actIds = Logic.activityLogic:GetActivityIdsByType(ActivityType.WishUp)
  if 0 < #actIds then
    return actIds
  end
  return nil
end

function WishLogic:GetActivityState()
  local actIds = self:_GetActId()
  if actIds then
    local startTime, endTime, starts = 0, 0, {}
    local cur = time.getSvrTime()
    for _, actId in ipairs(actIds) do
      startTime, endTime = Logic.activityLogic:GetActivityStartEndTime(actId)
      if startTime <= cur and cur >= time.getSvrTime() then
        return WISH_ActivityState.DOING, endTime - cur
      end
      table.insert(starts, startTime)
    end
    table.sort(starts)
    for i = #starts, 1, -1 do
      if cur < starts[i] then
        return WISH_ActivityState.TODO, startTime - cur
      end
    end
    return WISH_ActivityState.DONE, 0
  else
    return WISH_ActivityState.DONE, 0
  end
end

function WishLogic:CanUseItem()
  local inCD = self:CheckCharge()
  local config = configManager.GetData("config_vow_item")
  local canUse = false
  for id, _ in pairs(config) do
    local cur = self:GetWishItemNumById(id)
    local _, remain, limit = self:CheckWishItemNum(id)
    if limit and 0 < cur and 0 < remain then
      canUse = true
      break
    end
  end
  return inCD and canUse
end

function WishLogic:DWrap_ShowActiveTip(text)
  local tid = Data.illustrateData:GetVowHero()
  if tid == 0 then
    return
  end
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
  local sname = Logic.shipLogic:GetName(si_id)
  local iname = ""
  local res = self:CheckBindActive()
  if 0 < #res then
    iname = string.format(UIHelper.GetString(951062), self:GetName(res[1]))
  end
  UIHelper.SetText(text, string.format(UIHelper.GetString(951061), sname) .. iname)
end

function WishLogic:GetHeroMaxLvByillId(illId, data)
  local advance = data ~= nil and data.Advance or 1
  local lv = data ~= nil and data.Lvl or 1
  local targetFleetId = Logic.shipLogic:GetShipInfoBySiId(illId).sf_id
  local heroData = Data.heroData:GetHeroData()
  for _, heroInfo in pairs(heroData) do
    if targetFleetId == heroInfo.fleetId and advance < heroInfo.Advance then
      advance = heroInfo.Advance
      lv = heroInfo.Lvl
    end
  end
  return advance, lv
end

return WishLogic
