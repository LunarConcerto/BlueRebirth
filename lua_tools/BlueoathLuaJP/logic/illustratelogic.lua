local IllustrateLogic = class("logic.IllustrateLogic")

function IllustrateLogic:initialize()
  self:ResetData()
  self:_RegisterAllEvent()
  self.actionName2Id = self:_InitName2IdConf()
  pushNoticeManager:_BindNotice("wishWall", function()
    return self:GetPushNoticeParams(Data.illustrateData:GetChargeTime())
  end)
  self.index = 0
end

function IllustrateLogic:ResetIndex()
  self.index = 0
end

function IllustrateLogic:SetIndex(index)
  self.index = index
end

function IllustrateLogic:GetIndex()
  return self.index
end

function IllustrateLogic:ResetData()
  self.is3D = false
  self.damageLv = DamageLevel.NonDamage
  self.sortway = false
  self.equipSortWay = false
  self.remouldSortway = fasle
end

function IllustrateLogic:_RegisterAllEvent()
  eventManager:RegisterEvent(LuaCSharpEvent.RecordBehaviour, function(self, args)
    self:FilterAndSendBehaviour(args)
  end, self)
end

function IllustrateLogic:_InitName2IdConf()
  local conf = {}
  local config = configManager.GetData("config_handbook_behaviour_index")
  for id, info in pairs(config) do
    conf[info.behaviour_name] = id
  end
  return conf
end

function IllustrateLogic:SetIs3D(tog)
  self.is3D = tog
end

function IllustrateLogic:GetIs3D()
  return self.is3D
end

function IllustrateLogic:SetDamageLv(damageLv)
  self.damageLv = damageLv
end

function IllustrateLogic:GetDamageLv()
  return self.damageLv
end

function IllustrateLogic:GetIllustrateConfig()
  return configManager.GetData("config_ship_handbook")
end

function IllustrateLogic:GetIllustrateConfigById(id)
  return configManager.GetDataById("config_ship_handbook", id)
end

function IllustrateLogic:Ssid2Sfid(ss_id)
  return configManager.GetDataById("config_ship_show", ss_id).sf_id
end

function IllustrateLogic:GetRecommandReason(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).word_reconmend
end

function IllustrateLogic:GetRecommand(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).ship_recommend
end

function IllustrateLogic:GetApproachConfig(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).word_gained
end

function IllustrateLogic:GetApproachStr(id)
  return configManager.GetDataById("config_ship_gained_way", id).gained_way
end

function IllustrateLogic:GetSetupConfig(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).ship_setting
end

function IllustrateLogic:GetCvConfig(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).ship_character_voice
end

function IllustrateLogic:IsUnLockBehaviour(id, behaviour)
  return self:HaveBehaviour(id, behaviour)
end

function IllustrateLogic:GetSubTitleIndex(ss_id)
  return configManager.GetDataById("config_ship_show", ss_id).ship_character
end

function IllustrateLogic:GetSubActions(ss_id)
  return configManager.GetDataById("config_ship_show", ss_id).ship_behaviour
end

function IllustrateLogic:GetSubTitleConfig(id)
  return configManager.GetDataById("config_handbook_behaviour_index", id)
end

function IllustrateLogic:GetSkillConfig(illustrateId)
  return self:GetIllustrateConfigById(illustrateId).ship_skill
end

function IllustrateLogic:IsLike(illustrateId)
  local illustrateInfo = Data.illustrateData:GetIllustrateById(illustrateId)
  return illustrateInfo.LikeTime ~= 0
end

function IllustrateLogic:LikeNum(illustrateId)
  local discussInfo = Data.discussData:GetStartDiscussData()
  return discussInfo.HeroLikeNum
end

function IllustrateLogic:GetIllustrateState(illustrateId)
  local illustrateInfo = Data.illustrateData:GetIllustrateById(illustrateId)
  return illustrateInfo.IllustrateState
end

function IllustrateLogic:HaveIllustrate(illustrateId)
  local illustrateInfo = Data.illustrateData:GetIllustrateById(illustrateId)
  return illustrateInfo.IllustrateState == IllustrateState.UNLOCK
end

function IllustrateLogic:HaveNewIllustrate()
  local datas = Data.illustrateData:GetAllIllustrate()
  for k, v in pairs(datas) do
    if v.NewHero then
      return true
    end
  end
  return false
end

function IllustrateLogic:HaveNewEquipIllustrate()
  local datas = Data.illustrateData:GetEquipData()
  for k, v in pairs(datas) do
    if v.newEquip then
      return true
    end
  end
  return false
end

function IllustrateLogic:IsNewIllustrate(illustrateId)
  local info = Data.illustrateData:GetIllustrateById(illustrateId)
  return info.NewHero
end

function IllustrateLogic:Get2DIllustrate(illustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  local config = Logic.shipLogic:GetShipShowById(sm_id)
  local illuData = Data.illustrateData:GetIllustrateById(illustrateId)
  if not illuData then
    return config.ship_draw_black
  end
  if illuData.IllustrateState == IllustrateState.UNLOCK then
    return config.ship_draw
  elseif illuData.IllustrateState == IllustrateState.LOCK then
    return config.ship_draw_black
  elseif illuData.IllustrateState == IllustrateState.CLOSE then
    return config.ship_draw_black
  end
end

function IllustrateLogic:GetCommonIcon(illustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  return Logic.shipLogic:GetShipShowById(sm_id).ship_draw
end

function IllustrateLogic:GetQuality(illustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(sm_id)
  return Logic.shipLogic:GetQualityByInfoId(si_id)
end

function IllustrateLogic:GetName(illustrateId)
  return Logic.shipLogic:GetShipInfoBySiId(illustrateId).ship_name
end

function IllustrateLogic:GetAdvanceTime(id)
  local config = self:GetIllustrateConfigById(id)
  local duration, str = 0, ""
  if 0 < config.activity then
    duration = config.enter_wish_time * 86400 + Logic.activityLogic:GetActivityStartEndTime(config.activity) - time.getSvrTime()
  elseif 0 < config.wish_activatetime then
    duration = config.wish_activatetime - time.getSvrTime()
  end
  if 0 < duration then
    str = time.getTimeStringFontDynamic(duration)
  end
  return str, duration
end

function IllustrateLogic:GetRecommandIcon(illustrateId)
  local config = configManager.GetDataById("config_ship_show", illustrateId)
  return config.ship_icon5
end

function IllustrateLogic:GetHaveStr(illustrateId)
  local res = self:HaveIllustrate(illustrateIdillustratelogic)
  return res and UIHelper.GetString(920000064) or UIHelper.GetString(920000065)
end

function IllustrateLogic:GetIllustrateTid(illustrateId)
  return configManager.GetDataById("config_ship_handbook", illustrateId).ship_data_id
end

function IllustrateLogic:GetIllustrateCountry(illustrateId)
  return configManager.GetDataById("config_ship_handbook", illustrateId).ship_country
end

function IllustrateLogic:IsFirstGetHero(shipInfoId)
  return Data.illustrateData:IsFirstGetHero(shipInfoId)
end

function IllustrateLogic:HaveBehaviour(illustrateId, behaviourName)
  local data = Data.illustrateData:GetIllustrateById(illustrateId)
  local behaviourId = self.actionName2Id[behaviourName]
  if behaviourId == nil then
    return false
  end
  for _, v in pairs(data.BehaviourList) do
    if v == behaviourId then
      return true
    end
  end
  return false
end

function IllustrateLogic:FilterAndSendBehaviour(args)
  local val = {}
  for id, behaviours in pairs(args) do
    local arrId = {}
    for _, name in ipairs(behaviours) do
      local behaviourId = self.actionName2Id["show_" .. name]
      if behaviourId ~= nil then
        if self:CheckBehaviour(id, behaviourId) then
          table.insert(arrId, behaviourId)
        end
        self:_tryAddExtendBehaviour(arrId, id, behaviourId)
      end
    end
    if next(arrId) ~= nil then
      local sf_id = configManager.GetDataById("config_ship_show", id).sf_id
      local temp = {IllustrateId = sf_id, BehaviourId = arrId}
      table.insert(val, temp)
    end
  end
  if next(val) == nil then
    return
  end
  Service.illustrateService:SendIllustrateBehaviour(val)
end

function IllustrateLogic:_tryAddExtendBehaviour(container, ss_id, behaviourId)
  if behaviourId == 3 and self:CheckBehaviour(ss_id, 2) then
    table.insert(container, 2)
  end
end

function IllustrateLogic:CheckBehaviour(ss_id, behaviourId)
  local lock = self:CheckBehaviourLock(behaviourId)
  if lock then
    local sf_id = configManager.GetDataById("config_ship_show", ss_id).sf_id
    local info = Data.illustrateData:GetIllustrateById(sf_id)
    if info ~= nil then
      for _, id in ipairs(info.BehaviourList) do
        if id == behaviourId then
          return false
        end
      end
      return true
    else
      return false
    end
  else
    return false
  end
end

function IllustrateLogic:CheckBehaviourLock(behaviourId)
  local config = self:GetSubTitleConfig(behaviourId)
  if config == nil then
    return false
  end
  return config.default_lock == 1
end

function IllustrateLogic:GetModuleDressType(id)
  return self:GetSubTitleConfig(id).dressup_type
end

function IllustrateLogic:GetIllustrateAttr(illustrateId)
  local tid = self:GetIllustrateTid(illustrateId)
  local specificType = configManager.GetDataById("config_ship_show", illustrateId).ship_type
  local attr = configManager.GetDataById("config_ship_handbook", illustrateId)
  local temp = {}
  temp[1] = attr.survival
  temp[2] = attr.plane
  temp[3] = attr.maneuver
  temp[4] = attr.torpedo
  temp[5] = attr.gun
  temp[6] = attr.air_defence
  local res = {}
  for i, v in pairs(temp) do
    local levelConfig = self:_getAttrMark(v)
    res[i] = levelConfig
  end
  return res
end

function IllustrateLogic:_getAttrMark(value)
  local config = configManager.GetData("config_ship_perform_mark")
  if not self:_checkLimit(value) then
    logError("illustrate attr limit error:" .. value)
    local res = {
      id = config[1].id,
      level = config[1].level
    }
    return res
  end
  for _, v in pairs(config) do
    if value >= v.min_value and value <= v.max_value then
      local res = {
        id = v.id,
        level = v.level
      }
      return res
    end
  end
end

function IllustrateLogic:_checkLimit(value)
  return value <= 120 and 20 <= value
end

function IllustrateLogic:GetAllNewIllustrate()
  local res, new = {}, false
  local datas = Data.illustrateData:GetAllIllustrate()
  for id, _ in pairs(datas) do
    new = Logic.illustrateLogic:IsNewIllustrate(id)
    if new then
      table.insert(res, id)
    end
  end
  return res
end

function IllustrateLogic:GetPushNoticeParams(args)
  local paramList = {}
  local noticeParam = {}
  noticeParam.key = "wishWall"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 3).text
  noticeParam.time = args
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.wishWall = noticeParam
  return paramList
end

function IllustrateLogic:GetMemoryData()
  local result = {}
  local configAll = configManager.GetData("config_chapter")
  for id, info in pairs(configAll) do
    if info.memory_id > 0 then
      if 0 >= info.memory_start then
        table.insert(result, info)
      elseif 0 < info.memory_start then
        local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(info.memory_start)
        local srv_time = time.getSvrTime()
        if startTime <= srv_time then
          table.insert(result, info)
        end
      end
    end
  end
  table.sort(result, function(a, b)
    return a.memory_id < b.memory_id
  end)
  return result
end

function IllustrateLogic:GetHeroMemorys()
  local isdirty = Data.illustrateData:IsHeroMemorysDirty()
  if not self.cachedArrList or isdirty then
    local heroMemorys = Data.illustrateData:GetHeroMemorys()
    local list = {}
    for sfId, memoryMap in pairs(heroMemorys) do
      local mlist = {}
      for pid, _ in pairs(memoryMap) do
        table.insert(mlist, pid)
      end
      table.insert(list, {sfId = sfId, memoryList = mlist})
    end
    self.cachedArrList = list
    Data.illustrateData:SetHeroMemorysDirty(false)
  end
  return self.cachedArrList
end

function IllustrateLogic:SetSortRule(sortway)
  self.sortway = sortway
end

function IllustrateLogic:GetSortRule()
  return self.sortway
end

function IllustrateLogic:SetEquipSortRule(sortway)
  self.equipSortWay = sortway
end

function IllustrateLogic:GetEquipSortRule()
  return self.equipSortWay
end

function IllustrateLogic:SetRemouldSortRule(sortway)
  self.remouldSortway = sortway
end

function IllustrateLogic:GetRemouldSortRule()
  return self.remouldSortway
end

function IllustrateLogic:GetEquipData()
  local allEquip = configManager.GetData("config_equip")
  local equip = {}
  for k, v in pairs(allEquip) do
    if v.picture_show == 1 then
      table.insert(equip, v)
    end
  end
  return equip
end

function IllustrateLogic:IsNewEquip(eqyuipId)
  local info = Data.illustrateData:GetIllustrateEquipById(eqyuipId)
  return info.newEquip
end

function IllustrateLogic:GetAllNewEquipIllustrate()
  local res = {}
  local datas = Data.illustrateData:GetEquipData()
  for _, equip in pairs(datas) do
    if equip.newEquip then
      table.insert(res, equip.EquipId)
    end
  end
  return res
end

function IllustrateLogic:GetIllustrateByShowTag(showTag)
  local illustrateData = Data.illustrateData:GetIllustrateArray()
  local tab = {}
  for _, v in ipairs(illustrateData) do
    if v.show_tag == showTag then
      table.insert(tab, v)
    end
  end
  return tab
end

function IllustrateLogic:GetNormalShipNum()
  local data = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Normal)
  local ownCount, openCount = self:_DisposeIllustrateData(data)
  return ownCount, openCount
end

function IllustrateLogic:GetRemouldShipNum()
  local data = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Remould)
  local ownCount, openCount = self:_DisposeIllustrateData(data)
  return ownCount, openCount
end

function IllustrateLogic:GetSpecialShipNum()
  local data = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Special)
  local ownCount, openCount = self:_DisposeIllustrateData(data)
  return ownCount, openCount
end

function IllustrateLogic:GetMubarShipNum()
  local data = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Mubar)
  local ownCount, openCount = self:_DisposeIllustrateData(data)
  return ownCount, openCount
end

function IllustrateLogic:_DisposeIllustrateData(data)
  local ownCount, openCount = 0, 0
  for _, v in pairs(data) do
    if v.IllustrateState == IllustrateState.UNLOCK then
      ownCount = ownCount + 1
    end
    if v.IllustrateState == IllustrateState.UNLOCK or v.IllustrateState == IllustrateState.LOCK then
      openCount = openCount + 1
    end
  end
  return ownCount, openCount
end

function IllustrateLogic:GetOwnShipNumByCamp(nCountryList)
  local data = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Normal)
  local data2 = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Special)
  local data3 = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Mubar)
  data = table.append(data, data2)
  data = table.append(data, data3)
  local count = 0
  local marryCount = 0
  for _, nCountry in pairs(nCountryList) do
    for k, v in pairs(data) do
      if v.IllustrateState == IllustrateState.UNLOCK and v.shipCountry == nCountry then
        count = count + 1
        if 0 < v.MarryCount then
          marryCount = marryCount + 1
        end
      end
    end
  end
  return count, marryCount
end

function IllustrateLogic:GetIllustrateShowId(illustrateId)
  local shipMainId = self:GetIllustrateTid(illustrateId)
  local shipInfoConf = Logic.shipLogic:GetShipInfoById(shipMainId)
  if shipInfoConf.remould_level ~= 0 then
    local fashionData = Logic.fashionLogic:GetRemouldFashionData(shipInfoConf.sf_id, shipInfoConf.remould_level)
    return fashionData.ship_show_id
  else
    return Logic.shipLogic:GetShipShowById(shipMainId).ss_id
  end
end

function IllustrateLogic:GetIllustratePicture(illustrateId)
  local shipMainId = self:GetIllustrateTid(illustrateId)
  local shipInfoConf = Logic.shipLogic:GetShipInfoById(shipMainId)
  if shipInfoConf.remould_level ~= 0 then
    local fashionData = Logic.fashionLogic:GetRemouldFashionData(shipInfoConf.sf_id, shipInfoConf.remould_level)
    local shipShowConf = Logic.shipLogic:GetShipShowConfig(fashionData.ship_show_id)
    return shipShowConf.ship_icon2
  else
    return Logic.shipLogic:GetPictureHero(illustrateId)
  end
end

function IllustrateLogic:GetShipSkillByIllustrateId(illustrateId)
  local illustrateConf = self:GetIllustrateConfigById(illustrateId)
  local arr = {}
  table.insert(arr, illustrateConf.pskill_show_id)
  for i, v in ipairs(illustrateConf.ship_skill) do
    table.insert(arr, v)
  end
  return arr
end

function IllustrateLogic:GetHeadIllustrateByShowTag()
  local illustrateData = Data.illustrateData:GetIllustrateArray()
  local tab = {}
  for _, v in ipairs(illustrateData) do
    if v.show_tag == ShipPictureType.Normal or v.show_tag == ShipPictureType.Special or v.show_tag == ShipPictureType.Mubar then
      table.insert(tab, v)
    end
  end
  return tab
end

return IllustrateLogic
