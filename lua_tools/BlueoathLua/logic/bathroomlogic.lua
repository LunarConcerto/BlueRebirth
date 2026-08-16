local BathroomLogic = class("logic.BathroomLogic")
local TICKET_ID = 90001

function BathroomLogic:initialize()
  self:ResetData()
end

function BathroomLogic:ResetData()
  self.SvrStatus = 0
  self.HeroDetails = nil
  self.isOpenedPage = false
  self.limitTime = 0
  pushNoticeManager:_BindNotice("bath", function()
    return self:GetPushNoticeParams(Data.bathroomData:GetBathHero())
  end)
end

function BathroomLogic:SetSvrStatus(status)
  self.SvrStatus = status
end

function BathroomLogic:GetSvrStatus()
  return self.SvrStatus
end

function BathroomLogic:SetHeroDetails(heroInfo)
  self.HeroDetails = heroInfo
end

function BathroomLogic:GetHeroDetails()
  return self.HeroDetails
end

function BathroomLogic:GetBathHero()
  local bathHero = {}
  local bathroomInfo = Data.bathroomData:GetBathHero()
  for i, v in ipairs(bathroomInfo) do
    if next(v) ~= nil then
      bathHero[i] = {}
      for k, v in pairs(v) do
        bathHero[i][k] = v
      end
    end
  end
  for _, v in pairs(bathHero) do
    local heroInfo = Data.heroData:GetHeroById(v.HeroId)
    for k, value in pairs(heroInfo) do
      v[k] = value
    end
    bathHero[v.Pos] = v
  end
  return bathHero
end

function BathroomLogic:GetHeroLikeGift(tId)
  local giftTab = {}
  local likeGift = configManager.GetDataById("config_ship_main", tId).favorite_gift
  local giftconfig = configManager.GetData("config_gift")
  for id, v in pairs(giftconfig) do
    for _, giftType in ipairs(likeGift) do
      if giftType == v.gift_type then
        table.insert(giftTab, v)
        break
      end
    end
  end
  return giftTab
end

function BathroomLogic:GetGiftList(tid)
  local configTab = {}
  local likeTab = {}
  local giftconfig = configManager.GetData("config_gift")
  for _, v in pairs(giftconfig) do
    table.insert(configTab, v)
  end
  local likeGift = self:GetHeroLikeGift(tid)
  for _, v in ipairs(likeGift) do
    likeTab[v.id] = v
  end
  return configTab, likeTab
end

function BathroomLogic:CheckInBath(heroId)
  local bathInfo = Data.bathroomData:GetBathHeroId()
  if bathInfo[heroId] then
    return true
  end
  return false
end

function BathroomLogic.GetBathAttrBuff(heroId)
  local bathInfo = Data.bathroomData:GetBathHeroId()
  local heroBath = bathInfo[heroId]
  local ret = {}
  if not heroBath or heroBath.BuffId == 0 then
    ret = nil
  else
    local buffInfo = configManager.GetDataById("config_value_effect", heroBath.BuffId)
    local time = heroBath.BuffTime + buffInfo.time - time.getSvrTime()
    if time < 0 then
      ret = nil
    else
      table.insert(ret, {
        power = heroBath.Power or 1,
        values = buffInfo.values
      })
    end
  end
  return ret
end

function BathroomLogic:BathStatistics(param)
  local bathInfo = param.bathInfo
  local giftTab = param.gift
  local buffTab = param.buff
  local time = time.getSvrTime() - param.time
  local repairMainID = {}
  local repairName = {}
  for k, v in pairs(bathInfo) do
    local heroInfo = Data.heroData:GetHeroById(v.HeroId)
    local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
    repairMainID[tostring(k)] = heroInfo.TemplateId
    repairName[tostring(k)] = shipInfo.ship_name
  end
  local giftId = {}
  for k, v in pairs(giftTab) do
    giftId[tostring(k)] = v
  end
  local buffId = {}
  for k, v in pairs(buffTab) do
    buffId[tostring(k)] = v
  end
  local tabInfo = {
    repair_mainID = repairMainID,
    repair_name = repairName,
    gift_id = giftId,
    buff_id = buffId,
    time = time,
    type = 0
  }
  RetentionHelper.Retention(PlatformDotType.bathing, tabInfo)
end

function BathroomLogic:GetBathAnimKey()
  local uid = Data.userData:GetUserUid()
  return "bathroom_anim" .. uid
end

function BathroomLogic:IsBathAnimEnabled()
  local key = self:GetBathAnimKey()
  local bathroom = PlayerPrefs.GetInt(key, 0)
  return bathroom == 0
end

function BathroomLogic:IsOpenBathroom(opened)
  self.isOpenedPage = opened
end

function BathroomLogic:GetIsOpenBathroom()
  return self.isOpenedPage
end

function BathroomLogic:TransTimeStr(left)
  local sec = left % 60
  left = math.floor(left / 60)
  local min = left % 60
  left = math.floor(left / 60)
  local hour = left % 24
  local day = math.floor(left / 24)
  return string.format("%02d:%02d:%02d", hour, min, sec)
end

function BathroomLogic:GetLimitTime()
  if self.limitTime == 0 then
    self.limitTime = configManager.GetDataById("config_bathroom_item", TICKET_ID).time
  end
  return self.limitTime
end

function BathroomLogic:BathHeroSort(allHeroInfo, filterRule, sortRule, descend, recommend)
  local tabHero = {}
  if sortRule == HeroSortType.Mood then
    local bathHero, fleetHero, workHero, otherHero = self:GetBathHeroInfoMood(allHeroInfo)
    if next(bathHero) ~= nil then
      bathHero = HeroSortHelper.FilterAndSort(bathHero, filterRule, sortRule, descend, recommend)
      table.insertto(tabHero, bathHero)
    end
    if next(otherHero) ~= nil then
      otherHero = HeroSortHelper.FilterAndSort(otherHero, filterRule, sortRule, descend, recommend)
      table.insertto(tabHero, otherHero)
    end
  else
    if sortRule == HeroSortType.BathFleet then
      sortRule = HeroSortType.Mood
    end
    local bathHero, fleetHero, workHero, otherHero = self:GetBathHeroInfo(allHeroInfo)
    if next(bathHero) ~= nil then
      bathHero = HeroSortHelper.FilterAndSort(bathHero, filterRule, sortRule, descend, recommend)
      table.insertto(tabHero, bathHero)
    end
    if next(fleetHero) ~= nil then
      fleetHero = HeroSortHelper.FilterAndSort(fleetHero, filterRule, sortRule, descend, recommend)
      table.insertto(tabHero, fleetHero)
    end
    if next(otherHero) ~= nil then
      otherHero = HeroSortHelper.FilterAndSort(otherHero, filterRule, sortRule, descend, recommend)
      table.insertto(tabHero, otherHero)
    end
  end
  return tabHero
end

function BathroomLogic:GetBathHeroInfo(heros)
  local bath, fleets, work, others = {}, {}, {}, {}
  local inBath = false
  local inFleet = false
  for k, hero in pairs(heros) do
    inBath = Logic.bathroomLogic:CheckInBath(hero.HeroId)
    inFleet = Logic.shipLogic:IsInFleet(hero.HeroId)
    if inBath then
      table.insert(bath, hero)
    elseif inFleet then
      table.insert(fleets, hero)
    else
      table.insert(others, hero)
    end
  end
  return bath, fleets, work, others
end

function BathroomLogic:GetBathHeroInfoMood(heros)
  local bath, fleets, work, others = {}, {}, {}, {}
  local inBath = false
  for k, hero in pairs(heros) do
    inBath = Logic.bathroomLogic:CheckInBath(hero.HeroId)
    if inBath then
      table.insert(bath, hero)
    else
      table.insert(others, hero)
    end
  end
  return bath, fleets, work, others
end

function BathroomLogic:GetPushNoticeParams(args)
  local paramList = {}
  local noticeParam = {}
  local firstEndTime = 9999999999
  if args[1].HeroId == nil then
    return paramList
  end
  for k, v in pairs(args) do
    if v.HeroId == nil then
      break
    end
    local endTime = v.StartTime + 28800
    if endTime > time.getSvrTime() then
      firstEndTime = math.min(firstEndTime, endTime)
    end
  end
  noticeParam.key = "bath"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 6).text
  noticeParam.time = firstEndTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.bath = noticeParam
  return paramList
end

return BathroomLogic
