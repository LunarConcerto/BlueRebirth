local AssistNewLogic = class("logic.AssistNewLogic")
local TypeColorMap = {RMD = 1, LIMIT = 2}

function AssistNewLogic:initialize()
  self:ResetData()
  self:RegisterAllEvent()
  pushNoticeManager:_BindNotice("supportFleet", function()
    return self:GetPushNoticeParams(Data.assistNewData:GetAssistData())
  end)
end

function AssistNewLogic:ResetData()
  self.m_assistData = nil
  self.m_context = {
    CurIndex = 0,
    LastFinish = {},
    ShowDetail = false
  }
  if self.m_logictimers and 0 < #self.m_logictimers then
    for id, timer in ipairs(self.m_logictimers) do
      timer:Stop()
    end
  end
  self.m_logictimers = {}
  self.m_isSafePass = false
end

function AssistNewLogic:_setSafePass(bool)
  self.m_isSafePass = bool
end

function AssistNewLogic:_getSafePass()
  return self.m_isSafePass
end

function AssistNewLogic:ResetLogicData()
  self.m_assistData = nil
end

function AssistNewLogic:GetAssistContext()
  return self.m_context
end

function AssistNewLogic:SetCurIndex(index)
  self.m_context.CurIndex = index
end

function AssistNewLogic:SetLastFinish(param)
  self.m_context.LastFinish = param
end

function AssistNewLogic:SetShowDetail(bool)
  self.m_context.ShowDetail = bool
end

function AssistNewLogic:RefreshGetAssistData()
  local total = Logic.assistNewLogic:GetTotalFleetNum()
  local data = Data.assistNewData:GetAssistData()
  local res = {}
  for i = 1, total do
    if data[i] then
      table.insert(res, data[i])
    else
      local temp = Logic.assistNewLogic.GenAssistTemplate()
      table.insert(res, temp)
    end
  end
  self.m_assistData = res
  Logic.assistNewLogic:SortAssistData(self.m_assistData)
  return self.m_assistData
end

function AssistNewLogic:GetAssistData()
  if self.m_assistData == nil or #self.m_assistData == 0 then
    self:RefreshGetAssistData()
  end
  return self.m_assistData
end

function AssistNewLogic:GetFirstEmptySlot()
  local data = self:GetAssistData()
  local state
  for i, v in ipairs(data) do
    state = self:GetAssistState(v.SupportId, v.StartTime)
    if state == AssistFleetState.TODO then
      return i
    end
  end
  return 0
end

function AssistNewLogic:GetAssistByIndex(index)
  return self.m_assistData[index]
end

function AssistNewLogic:SetAssistByIndex(index, assist)
  self.m_assistData[index] = assist
  return self.m_assistData
end

function AssistNewLogic:SetAssistHeros(index, heros)
  self.m_assistData[index].HeroList = heros
end

function AssistNewLogic:ResetAssistDataById(id)
  local index = 0
  local data = Data.assistNewData:GetAssistData()
  for i, v in ipairs(data) do
    if id == v.Id then
      index = i
      break
    end
  end
  if data[index] then
    table.remove(data, index)
  end
  if self.m_assistData[index] then
    self.m_assistData[index] = Logic.assistNewLogic.GenAssistTemplate()
  end
end

function AssistNewLogic:ResetAllTODOAssist()
  if self.m_assistData then
    for i = 1, #self.m_assistData do
      local temp = self.m_assistData[i]
      local state = self:GetAssistState(temp.SupportId, temp.StartTime)
      if state == AssistFleetState.TODO then
        temp.SupportId = 0
        temp.HeroList = {}
      end
    end
    return self.m_assistData
  end
  return nil
end

function AssistNewLogic.GenAssistTemplate()
  return {
    Id = 0,
    SupportId = 0,
    StartTime = 0,
    HeroList = {}
  }
end

function AssistNewLogic:SortAssistData(assistData)
  table.sort(assistData, function(data1, data2)
    local state1 = Logic.assistNewLogic:GetAssistState(data1.SupportId, data1.StartTime)
    local state2 = Logic.assistNewLogic:GetAssistState(data2.SupportId, data2.StartTime)
    if state1 ~= state2 then
      return state1 > state2
    elseif data1.StartTime ~= data2.StartTime then
      return data1.StartTime < data2.StartTime
    else
      return data1.SupportId > data2.SupportId
    end
  end)
end

function AssistNewLogic:FormatSupportById(supportId)
  return {
    Type = GoodsType.COMMAND,
    ConfigId = supportId,
    Num = ""
  }
end

function AssistNewLogic:FormatFinishArgs(args)
  local lastFinish = Logic.assistNewLogic:GetAssistContext().LastFinish
  local res = {}
  res.fleets = lastFinish.HeroList
  res.supportId = lastFinish.SupportId
  res.result = args.RewardType
  local temp = {}
  for i, v in ipairs(args.BaseReward) do
    table.insert(temp, v)
  end
  for i, v in ipairs(args.RandomReward) do
    table.insert(temp, v)
  end
  res.rewards = temp
  return res
end

function AssistNewLogic:GetAssistState(supportId, startTime)
  if startTime == 0 or supportId == 0 then
    return AssistFleetState.TODO
  end
  local configTime = configManager.GetDataById("config_support_fleet_item", supportId).time
  if configTime <= time.getSvrTime() - startTime then
    return AssistFleetState.FINISH
  else
    return AssistFleetState.DOING
  end
end

function AssistNewLogic:GetAssistRemainTime(supportId, startTime)
  local configTime = configManager.GetDataById("config_support_fleet_item", supportId).time
  if startTime == 0 or supportId == 0 then
    return configTime
  end
  local remain = configTime - (time.getSvrTime() - startTime)
  return remain
end

function AssistNewLogic:GetAssistEndTime(supportId, startTime)
  local configTime = configManager.GetDataById("config_support_fleet_item", supportId).time
  local endTime = startTime + configTime
  return endTime
end

function AssistNewLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaCSharpEvent.SupportFleetFinish, function(self, param)
    self:_OnSupportCopy(param)
  end, self)
  eventManager:RegisterEvent(LuaEvent.UpdateAssistList, self.TickAssist, self)
  eventManager:RegisterEvent("CopyPassBase", self._OnCopyPassBase, self)
end

function AssistNewLogic:_OnSupportCopy(param)
  self:_setSafePass(true)
  self.m_param = self:_formatParam(param)
  if Logic.settlementLogic:IsInSettle() then
    Logic.settlementLogic:FastResetAndExit()
  end
end

function AssistNewLogic:_formatParam(param)
  local res = {}
  res.result = param.results == EvaGradeType.F and SupportResult.Failure or SupportResult.Success
  local myFleetId = Logic.fleetLogic:GetBattleFleetId()
  res.fleets = Data.fleetData:GetShipByFleet(myFleetId)
  res.rewards = param.Reward
  res.userAddExp = 0
  res.heroAddExp = param.ExpReward
  res.exitFunc = param.exitFunc
  res.isAuto = param.isAuto
  return res
end

function AssistNewLogic:_formatExRewards(exRewards)
  local res = {}
  for i, v in ipairs(exRewards) do
    res[v.Key] = v.Value
  end
  return res
end

function AssistNewLogic:_OnCopyPassBase(param)
  local safe = self:_getSafePass()
  if safe then
    self:_setSafePass(false)
    if param.ExReward then
      local rxRewards = self:_formatExRewards(param.ExReward)
      self.m_param.userAddExp = rxRewards.UserExp or 0
    end
    local args = self.m_param
    if 0 < #args.heroAddExp or 0 < #args.rewards then
      UIHelper.OpenPage("CrusadeSuccessPage", args, 1, false)
    end
  end
end

function AssistNewLogic:TickAssist()
  for id, timer in ipairs(self.m_logictimers) do
    timer:Stop()
  end
  self.m_logictimers = {}
  local data = Data.assistNewData:GetAssistData()
  if #data < 1 then
    return
  end
  local duration = 0
  for i, v in ipairs(data) do
    duration = self:GetAssistRemainTime(v.SupportId, v.StartTime)
    if duration <= 0 then
      eventManager:SendEvent(LuaEvent.SupportTimerFinish, v)
    else
      local timer = Timer.New(function()
        eventManager:SendEvent(LuaEvent.SupportTimerFinish, v)
      end, duration, 1, false)
      timer:Start()
      self.m_logictimers[v.Id] = timer
    end
  end
  self:RefreshGetAssistData()
end

function AssistNewLogic:GetIcon(id)
  return self:GetCommandConfigById(id).icon
end

function AssistNewLogic:GetName(id)
  return self:GetCommandConfigById(id).name
end

function AssistNewLogic:GetDesc(id)
  return ""
end

function AssistNewLogic:GetQuality(id)
  return self:GetCommandConfigById(id).quality
end

function AssistNewLogic:GetFrame(id)
  return ""
end

function AssistNewLogic:GetTexIcon(id)
  return self:GetCommandConfigById(id).icon
end

function AssistNewLogic:GetItemGroup(id)
  return self:GetCommandConfigById(id).group
end

function AssistNewLogic:GetSupportConsume(id)
  return self:GetCommandConfigById(id).consumption
end

function AssistNewLogic:CheckSupportConsume(type, id, needNum)
  if not Logic.currencyLogic:CheckCurrencyEnough(id, needNum) then
    local name = Logic.goodsLogic:GetName(id, type)
    local str = string.format(UIHelper.GetString(971028), name)
    return false, str
  end
  return true, ""
end

function AssistNewLogic:_formatBaseReward(table)
  local res = {}
  res.Type = table[1]
  res.ConfigId = table[2]
  res.Num = table[3]
  return res
end

function AssistNewLogic:GetBaseReward(id)
  local rewards = self:GetCommandConfigById(id).base_award
  local res = {}
  for _, v in ipairs(rewards) do
    local temp = self:_formatBaseReward(v)
    table.insert(res, temp)
  end
  return res
end

function AssistNewLogic:GetExtraReward(id)
  local dropId = self:GetCommandConfigById(id).extra_drop_id
  return Logic.rewardLogic:GetAllShowRewardByDropId(dropId)
end

function AssistNewLogic:GetAllReward(id)
  local base = self:GetBaseReward(id)
  local extra = self:GetExtraReward(id)
  local res = {}
  for i, v in ipairs(base) do
    table.insert(res, v)
  end
  for i, v in ipairs(extra) do
    table.insert(res, v)
  end
  return res
end

function AssistNewLogic:_formatReward(id)
  local res = {}
  local config = configManager.GetDataById("config_drop_item", id)
  res.Type = config.table_index
  res.ConfigId = config.item_id
  res.Num = config.lower_count .. "~" .. config.upper_count
  return res
end

function AssistNewLogic:GetCommandConfigById(id)
  return configManager.GetDataById("config_support_fleet_item", id)
end

function AssistNewLogic:GetStartTipShowTime()
  return 2
end

function AssistNewLogic:GetStartTipCloseTime()
  return 1
end

function AssistNewLogic:GetCurFleetNum()
  return #Data.assistNewData:GetAssistData()
end

function AssistNewLogic:GetTotalFleetNum()
  return configManager.GetDataById("config_parameter", 79).value
end

function AssistNewLogic:CheckAssistTeamRmd(heroList, commandId)
  local res = {}
  local config = self:GetCommandConfigById(commandId)
  table.insert(res, self:_checkAssistTeamType(heroList, config.ships_recommend_type, TypeColorMap.RMD))
  table.insert(res, self:_checkAssistTeamShip(heroList, config.ships_available, TypeColorMap.RMD))
  return res
end

function AssistNewLogic:CheckAssistTeamLimit(heroList, commandId)
  local res = {}
  local config = self:GetCommandConfigById(commandId)
  if config == nil then
    logError(commandId)
  end
  table.insert(res, self:_checkAssistTeamNum(heroList, config.at_least_number))
  table.insert(res, self:_checkAssistTeamType(heroList, config.ship_types_available, TypeColorMap.LIMIT))
  table.insert(res, self:_checkAssistTeamShip(heroList, config.ship_id_available, TypeColorMap.LIMIT))
  table.insert(res, self:CheckAssistLevelLimit(heroList, config.support_fleet_average_level_min))
  table.insert(res, self:_checkAssistMinLevelShip(heroList, config.support_fleet_few_level_min))
  return res
end

function AssistNewLogic:_checkAssistTeamType(herolist, param, type)
  if param == nil or #param == 0 then
    return nil
  end
  local res = {}
  local str = ""
  local checkMedia = {}
  for i = 1, #param do
    checkMedia[i] = {}
  end
  res.check = false
  if #herolist ~= 0 then
    res.check = true
    for _, heroId in pairs(herolist) do
      local typ = Data.heroData:GetHeroById(heroId).type
      local pos = self:_setCheck(param, typ)
      if 0 < pos then
        table.insert(checkMedia[pos], heroId)
      end
    end
  end
  for pos, typ in ipairs(param) do
    str = str .. self:_getGameLimitColorStr(checkMedia[pos], ShipTypeNameMap[typ], type) .. " "
  end
  for _, v in ipairs(checkMedia) do
    if #v == 0 then
      res.check = false
      break
    end
  end
  res.des = str
  res.detail = checkMedia
  return res
end

function AssistNewLogic:_checkAssistTeamShip(herolist, param, type)
  if param == nil or #param == 0 then
    return nil
  end
  local res = {}
  local str = ""
  local checkMedia = {}
  for i = 1, #param do
    checkMedia[i] = {}
  end
  res.check = false
  if #herolist ~= 0 then
    res.check = true
    for _, heroId in pairs(herolist) do
      local tid = Data.heroData:GetHeroById(heroId).TemplateId
      local sfId = Logic.shipLogic:GetSfIdBySmId(tid)
      local pos = self:_setCheck(param, sfId)
      if 0 < pos then
        table.insert(checkMedia[pos], heroId)
      end
    end
  end
  for pos, sfid in ipairs(param) do
    local shipInfoConfig = Logic.shipLogic:GetShipInfoBySiId(sfid)
    local name = ""
    if shipInfoConfig then
      name = shipInfoConfig.ship_name
    end
    str = str .. self:_getGameLimitColorStr(checkMedia[pos], name, type) .. " "
  end
  for _, v in ipairs(checkMedia) do
    if #v == 0 then
      res.check = false
      break
    end
  end
  res.des = str
  res.detail = checkMedia
  return res
end

function AssistNewLogic:CheckAssistLevelLimit(heroList, num)
  local temp = {}
  local arrValue = configManager.GetDataById("config_parameter", 89).arrValue
  if 0 < num then
    temp.check, _ = self:_checkFleetAverageLevel(heroList, num)
    if temp.check then
      temp.des = string.format(UIHelper.GetString(971013), "<color=#" .. arrValue[2] .. ">", num, "</color>")
    else
      temp.des = string.format(UIHelper.GetString(971013), "<color=#" .. arrValue[1] .. ">", num, "</color>")
    end
  else
    return nil
  end
  return temp
end

function AssistNewLogic:_checkFleetAverageLevel(heroList, condition)
  local totalLv = 0
  for _, v in ipairs(heroList) do
    local lv = Data.heroData:GetHeroById(v).Lvl
    totalLv = lv + totalLv
  end
  if condition <= totalLv / #heroList then
    return true, nil
  end
  return false, nil
end

function AssistNewLogic:_checkAssistMinLevelShip(herolist, param)
  if param == nil or #param == 0 then
    return nil
  end
  local total = param[1]
  local min = param[2]
  local arrValue = configManager.GetDataById("config_parameter", 89).arrValue
  local temp = {}
  temp.check, _ = self:_checkFleetMinLevel(herolist, total, min)
  if temp.check then
    temp.des = string.format(UIHelper.GetString(971037), "<color=#" .. arrValue[2] .. ">", total, "</color>", "<color=#" .. arrValue[2] .. ">", min, "</color>")
  else
    temp.des = string.format(UIHelper.GetString(971037), "<color=#" .. arrValue[1] .. ">", total, "</color>", "<color=#" .. arrValue[1] .. ">", min, "</color>")
  end
  return temp
end

function AssistNewLogic:_checkFleetMinLevel(heroList, total, min)
  if #heroList <= 0 then
    return false, nil
  end
  local count = 0
  local lv = 0
  for _, v in ipairs(heroList) do
    lv = Data.heroData:GetHeroById(v).Lvl
    if min <= lv then
      count = count + 1
    end
  end
  if total <= count then
    return true, nil
  end
  return false, nil
end

function AssistNewLogic:GetExtraRewardAdd(supportId, heroList)
  if supportId == 0 then
    return 0
  end
  if #heroList == 0 then
    return 0
  end
  local config = self:GetCommandConfigById(supportId)
  local shipResult = self:_checkAssistTeamShip(heroList, config.ships_available)
  local typeResult = self:_checkAssistTeamType(heroList, config.ships_recommend_type)
  if shipResult == nil and typeResult == nil then
    return 0
  end
  local allHero = {}
  if shipResult then
    for _, heros in ipairs(shipResult.detail) do
      if 0 < #heros then
        for _, v in ipairs(heros) do
          table.insert(allHero, v)
        end
      end
    end
  end
  if typeResult then
    for _, heros in ipairs(typeResult.detail) do
      if 0 < #heros then
        for _, v in ipairs(heros) do
          if self:_setCheck(allHero, v) == 0 then
            table.insert(allHero, v)
          end
        end
      end
    end
  end
  return self:GetExtraAddFactor(supportId, allHero)
end

function AssistNewLogic:GetBaseHeroAdd(supportId, heroList)
  if supportId == 0 then
    return 0
  end
  if #heroList == 0 then
    return 0
  end
  local config = self:GetCommandConfigById(supportId)
  local shipResult = self:_checkAssistTeamShip(heroList, config.ships_available)
  local typeResult = self:_checkAssistTeamType(heroList, config.ships_recommend_type)
  if shipResult == nil and typeResult == nil then
    return 0
  end
  local allHero = {}
  if shipResult then
    for _, heros in ipairs(shipResult.detail) do
      if 0 < #heros then
        for _, v in ipairs(heros) do
          table.insert(allHero, v)
        end
      end
    end
  end
  if typeResult then
    for _, heros in ipairs(typeResult.detail) do
      if 0 < #heros then
        for _, v in ipairs(heros) do
          if self:_setCheck(allHero, v) == 0 then
            table.insert(allHero, v)
          end
        end
      end
    end
  end
  local res = self:GetAddByRecommandHeros(supportId, #allHero)
  return res
end

function AssistNewLogic:_getGameLimitColorStr(check, str, type)
  local arrValue = configManager.GetDataById("config_parameter", 89).arrValue
  local color
  if #check == 0 then
    if type == TypeColorMap.LIMIT then
      color = arrValue[1]
    else
      color = arrValue[3]
    end
  else
    color = arrValue[2]
  end
  return UIHelper.SetColor(str, color)
end

function AssistNewLogic:_setCheck(set, id)
  for index, v in ipairs(set) do
    if v == id then
      return index
    end
  end
  return 0
end

function AssistNewLogic:_checkAssistTeamNum(herolist, param)
  local res = {}
  local arrValue = configManager.GetDataById("config_parameter", 89).arrValue
  res.check = param <= #herolist
  if res.check then
    res.des = string.format(UIHelper.GetString(971012), "<color=#" .. arrValue[2] .. ">", param, "</color>")
  else
    res.des = string.format(UIHelper.GetString(971012), "<color=#" .. arrValue[1] .. ">", param, "</color>")
  end
  return res
end

function AssistNewLogic:CheckFixTypeLimit(id)
  if id == nil or id == 0 then
    return false, {}
  end
  local config = self:GetCommandConfigById(id).ship_types_available
  return 0 < #config, config
end

function AssistNewLogic:CheckFixShipLimit(id)
  if id == nil or id == 0 then
    return false, {}
  end
  local config = self:GetCommandConfigById(id).ship_id_available
  return 0 < #config, config
end

function AssistNewLogic:CheckFixTypeRmd(id)
  if id == nil or id == 0 then
    return false, {}
  end
  local config = self:GetCommandConfigById(id).ships_recommend_type
  return 0 < #config, config
end

function AssistNewLogic:CheckFixShipRmd(id)
  if id == nil or id == 0 then
    return false, {}
  end
  local config = self:GetCommandConfigById(id).ships_available
  return 0 < #config, config
end

function AssistNewLogic:CheckAssistFleetNum()
  local cur = #Data.assistNewData:GetAssistData()
  local total = self:GetTotalFleetNum()
  return cur >= total
end

function AssistNewLogic:CheckFastFinish(supportId)
  local item = self:GetCommandConfigById(supportId).complete_item
  local itemTab = Data.bagData:GetItemData()
  for id, info in pairs(itemTab) do
    if id == item[2] then
      return info.num >= item[3], info.num
    end
  end
  return false, 0
end

function AssistNewLogic:GetRecommandItem(copyId)
  local res = {}
  local orginInfo = configManager.GetDataById("config_copy_display", copyId).support_fleet_target_and_effect
  for index, info in ipairs(orginInfo) do
    local limitConfig = configManager.GetDataById("config_game_limits", info[1])
    if limitConfig.limit_type == 15 then
      local param = limitConfig.limit_param
      for _, id in ipairs(param) do
        table.insert(res, id)
      end
    end
  end
  return res
end

function AssistNewLogic:GetAddByRecommandHeros(id, heroNum)
  if heroNum == 0 then
    return 0
  end
  local config = self:GetCommandConfigById(id).condition_add
  if #config == 0 then
    return 0
  end
  if config[heroNum] then
    return config[heroNum] * 1.0E-4
  else
    return config[#config] * 1.0E-4
  end
end

function AssistNewLogic:GetExtraAddFactor(id, rmdHeros)
  local exAdd = self:GetCommandConfigById(id).condition_add2
  if #rmdHeros == 0 or #exAdd == 0 then
    return 0
  end
  local res, quality, star, addMap, hero = 0, 0, 0, {}
  for _, data in ipairs(exAdd) do
    addMap[data[1]] = data[2]
  end
  for _, id in ipairs(rmdHeros) do
    hero = Data.heroData:GetHeroById(id)
    quality = hero.quality
    star = hero.Advance
    if addMap[quality] then
      res = res + addMap[quality] * star
    end
  end
  return res * 1.0E-4
end

function AssistNewLogic:GetHaveRecommandItem(copyId)
  local res = {}
  local _, haveCommands = Logic.assistNewLogic:GetUserCommandWithOutUsing()
  local recommands = Logic.assistNewLogic:GetRecommandItem(copyId)
  for _, id in ipairs(recommands) do
    if haveCommands[id] then
      table.insert(res, id)
    end
  end
  return res
end

function AssistNewLogic:GetFinishTweenTime()
  return configManager.GetDataById("config_parameter", 121).value * 1.0E-4
end

function AssistNewLogic:GetSupportNames(herolist)
  local res = ""
  for index, heroId in ipairs(herolist) do
    local tid = Data.heroData:GetHeroById(heroId).TemplateId
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
    local name = Logic.shipLogic:GetName(si_id)
    res = res .. index .. ":" .. name .. ","
  end
  return res
end

function AssistNewLogic:GetSupportLevels(herolist)
  local res = ""
  for index, heroId in ipairs(herolist) do
    local lv = Data.heroData:GetHeroById(heroId).Lvl
    res = res .. index .. ":" .. lv .. ","
  end
  return res
end

function AssistNewLogic:GetSupportItem()
  local res = {}
  local items = self:GetUserCommand()
  for _, item in ipairs(items) do
    res[tostring(item.templateId)] = item.num
  end
  return res
end

function AssistNewLogic:CheckCanSupport(tabSelectId, heroId)
  local tid = Logic.shipLogic:GetHeroTid(heroId)
  for i, v in ipairs(tabSelectId) do
    if v == heroId then
      return nil
    end
    local temp = Logic.shipLogic:GetHeroTid(v)
    if Logic.shipLogic:CheckSameShipMain(tid, temp) then
      return i
    end
  end
  return nil
end

function AssistNewLogic:MerageTable(tab1, tab2)
  for k, v in pairs(tab2) do
    table.insert(tab1, v)
  end
  return tab1
end

function AssistNewLogic:GetAllBuildingData()
  local allBuildingData = {}
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  allBuildingData = self:MerageTable(allBuildingData, bathHero)
  local buildingHero = Data.buildingData:GetBuildingHero()
  allBuildingData = self:MerageTable(allBuildingData, buildingHero)
  local outpostHero = Data.mubarOutpostData:GetOutPostHeroData()
  allBuildingData = self:MerageTable(allBuildingData, outpostHero)
  return allBuildingData
end

function AssistNewLogic:GetAllBuildingHeroTidData(herolist)
  local res = {}
  for k, v in pairs(herolist) do
    local tid = Data.heroData:GetHeroById(v).TemplateId
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    res[sf_id] = 0
  end
  return res
end

function AssistNewLogic:CheckHeroCanSupport(heroId)
  local canSupport = true
  local allData = self:GetAllBuildingData()
  if allData and table.containValue(allData, heroId) then
    return canSupport
  end
  local tid = Data.heroData:GetHeroById(heroId).TemplateId
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
  local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
  local allTidData = self:GetAllBuildingHeroTidData(allData)
  if allTidData[sf_id] ~= nil then
    return false
  end
  return canSupport
end

function AssistNewLogic:GetUserCommand()
  local res = {}
  local itemTab = Data.bagData:GetItemData()
  local config = configManager.GetData("config_support_fleet_item")
  for id, _ in pairs(config) do
    for i, info in pairs(itemTab) do
      if id == i then
        table.insert(res, {
          templateId = info.templateId,
          num = info.num
        })
      end
    end
  end
  return res
end

function AssistNewLogic:GetUserCommandWithOutUsing()
  local base = self:GetUserCommand()
  local map = {}
  local array = {}
  for _, item in ipairs(base) do
    if item.num > 0 then
      table.insert(array, item)
      map[item.templateId] = item.num
    end
  end
  return array, map
end

function AssistNewLogic:GetSameGroupSupporter(id)
  local base = self:GetUserCommand()
  local gop1, gop2
  gop1 = self:GetItemGroup(id)
  local res = {}
  for i, v in ipairs(base) do
    gop2 = self:GetItemGroup(v.templateId)
    if gop2 == gop1 then
      table.insert(res, v)
    end
  end
  return res
end

function AssistNewLogic:GetBestSameGroupSupporter(id)
  local sel = self:GetSameGroupSupporter(id)
  if #sel < 1 then
    return 0
  end
  for _, v in ipairs(sel) do
    if v.templateId == id then
      return id
    end
  end
  table.sort(sel, function(data1, data2)
    return data1.templateId < data2.templateId
  end)
  return sel[1].templateId
end

function AssistNewLogic:FinishSupportValue()
  local info = Data.assistNewData:GetAssistData()
  if #info < 1 then
    return 0
  end
  local res = 0
  for _, v in ipairs(info) do
    local state = self:GetAssistState(v.SupportId, v.StartTime)
    if state == AssistFleetState.FINISH then
      res = res + 1
    end
  end
  return res
end

function AssistNewLogic:SupportSlotValue()
  local total = self:GetTotalFleetNum()
  local data = Data.assistNewData:GetAssistData()
  if data then
    return total - #data
  else
    return total
  end
end

function AssistNewLogic:GetRecommandHero(supportId, selectHeros)
  local res = {}
  local ok = false
  res = self:GetFilerHeroByCommand(supportId)
  res = self:RemoveSelectHero(res, selectHeros)
  res = self:RemoveSupportHero(res)
  res = self:RemoveFleetHero(res)
  res = self:GetFilerHeroByQuality(res)
  res = self:RemoveRepeatHero(res)
  res = self:SortHero(res)
  res = self:PriorRmdHero(res, supportId)
  ok, res = self:HandleCopyLimit(selectHeros, res, supportId)
  return ok, res
end

function AssistNewLogic:GetRmdConfigId()
  return 1
end

function AssistNewLogic:GetRmdConfig(id)
  return configManager.GetDataById("config_support_fleet_recommend", id)
end

function AssistNewLogic:GetRemoveFleetConfig()
  local configId = self:GetRmdConfigId()
  return self:GetRmdConfig(configId).occupy_include == 0
end

function AssistNewLogic:GetFilterConfig()
  local configId = self:GetRmdConfigId()
  local temp = {}
  local config = self:GetRmdConfig(configId).select_range
  for _, v in ipairs(config) do
    temp[v[1]] = {
      v[2],
      v[3]
    }
  end
  return temp
end

function AssistNewLogic:GetRepeatConfig()
  local configId = self:GetRmdConfigId()
  return self:GetRmdConfig(configId).duplicate_removal_rule
end

function AssistNewLogic:GetSortConfig()
  local configId = self:GetRmdConfigId()
  return self:GetRmdConfig(configId).sort_rule
end

function AssistNewLogic:GetMinHeroNumberConfig(supportId)
  local config = self:GetCommandConfigById(supportId)
  return config.at_least_number
end

function AssistNewLogic:GetRmdNumber(selectHeros, supportId)
  local up = self:SupportShipUp(supportId)
  return up - #selectHeros
end

function AssistNewLogic:SupportShipUp(supportId)
  return self:GetCommandConfigById(supportId).ship_num_limit
end

function AssistNewLogic:GetMinLevelConfig(supportId)
  return self:GetCommandConfigById(supportId).support_fleet_average_level_min
end

function AssistNewLogic:GetFilerHeroByCommand(supportId)
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  local checkType, types = Logic.assistNewLogic:CheckFixTypeLimit(supportId)
  local checkFix, tids = Logic.assistNewLogic:CheckFixShipLimit(supportId)
  if checkType then
    tabShowHero = Logic.dockLogic:FilterByType(tabShowHero, types)
  end
  if checkFix then
    tabShowHero = Logic.dockLogic:FilterByTids(tabShowHero, tids)
  end
  return tabShowHero
end

function AssistNewLogic:RemoveSelectHero(herolist, selectHero)
  local res = {}
  local sf_ids, tid = {}, 0
  for _, hero in ipairs(selectHero) do
    tid = Data.heroData:GetHeroById(hero).TemplateId
    local sf_id = Logic.shipLogic:GetSfIdBySmId(tid)
    sf_ids[sf_id] = 0
  end
  local sf_id = 0
  for k, v in pairs(herolist) do
    sf_id = Logic.shipLogic:GetSfidBySmid(v.TemplateId)
    if sf_ids[sf_id] == nil then
      table.insert(res, v)
    end
  end
  return res
end

function AssistNewLogic:RemoveSupportHero(herolist)
  local res = {}
  local tids = {}
  for k, v in pairs(herolist) do
    local support = Logic.shipLogic:IsInCrusade(v.HeroId)
    if not support then
      table.insert(res, v)
    else
      local sf_id = Logic.shipLogic:GetSfidBySmid(v.TemplateId)
      tids[sf_id] = 0
    end
  end
  local temp = {}
  for k, v in ipairs(res) do
    local sf_id = Logic.shipLogic:GetSfidBySmid(v.TemplateId)
    if tids[sf_id] == nil then
      table.insert(temp, v)
    end
  end
  return temp
end

function AssistNewLogic:RemoveFleetHero(herolist)
  local removeFleet = self:GetRemoveFleetConfig()
  if removeFleet then
    local res = {}
    local temp = Logic.fleetLogic:GetFleetHeroSfId()
    for k, v in pairs(herolist) do
      local sf_id = Logic.shipLogic:GetSfidBySmid(v.TemplateId)
      if not table.containV(temp, sf_id) then
        table.insert(res, v)
      end
    end
    return res
  else
    return herolist
  end
end

function AssistNewLogic:GetFilerHeroByQuality(herolist)
  local config = self:GetFilterConfig()
  local res = {}
  for k, v in pairs(herolist) do
    local limit = config[v.quality]
    if limit then
      if v.Lvl >= limit[1] and v.Lvl <= limit[2] then
        table.insert(res, v)
      end
    else
      table.insert(res, v)
    end
  end
  return res
end

function AssistNewLogic:RemoveRepeatHero(herolist)
  local config = self:GetRepeatConfig()
  local cache = self:_handleHerolist(herolist)
  local res = {}
  for _, v in ipairs(cache) do
    local hero = self:_repeatImp(v, config)
    table.insert(res, hero)
  end
  return res
end

function AssistNewLogic:_repeatImp(herolist, config)
  local temp = self:_sortImp(herolist, config)
  return temp[1]
end

function AssistNewLogic:_sortImp(herolist, config)
  HeroSortHelper.CustomSortHero(herolist, config)
  return herolist
end

function AssistNewLogic:_handleHerolist(herolist)
  local res = {}
  local temp = {}
  for k, v in pairs(herolist) do
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(v.TemplateId)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    if temp[sf_id] then
      table.insert(temp[sf_id], v)
    else
      temp[sf_id] = {v}
    end
  end
  for k, v in pairs(temp) do
    table.insert(res, v)
  end
  return res
end

function AssistNewLogic:SortHero(herolist)
  local config = self:GetSortConfig()
  local res = self:_sortImp(herolist, config, 1)
  return res
end

function AssistNewLogic:PriorRmdHero(herolist, supportId)
  local have, fix = self:CheckFixShipRmd(supportId)
  local checkType, types = self:CheckFixTypeRmd(supportId)
  if not have and not checkType then
    return herolist
  end
  local other, rmd, res = {}, {}, {}
  for k, v in pairs(herolist) do
    local sf_id = Logic.shipLogic:GetSfidBySmid(v.TemplateId)
    if table.containV(fix, sf_id) or table.containV(types, v.type) then
      table.insert(rmd, v)
    else
      table.insert(other, v)
    end
  end
  rmd = self:SortHero(rmd)
  other = self:SortHero(other)
  local len = #rmd + #other
  for i = 1, len do
    if i <= #rmd then
      res[i] = rmd[i]
    else
      res[i] = other[i - #rmd]
    end
  end
  return res
end

function AssistNewLogic:HandleCopyLimit(id, herolist, supportId)
  local minNum = self:GetRmdNumber(id, supportId)
  local minLevel = self:GetMinLevelConfig(supportId)
  local res = {}
  local ok = false
  if minNum > #herolist then
    for i = 1, #herolist do
      table.insert(res, herolist[i].HeroId)
    end
    return false, res
  end
  local totalLv = 0
  for i = 1, minNum do
    totalLv = totalLv + herolist[i].Lvl
    table.insert(res, herolist[i].HeroId)
  end
  if minLevel <= totalLv / minNum then
    return true, res
  end
  local pos = self:_getMinLvlExpectRmd(res, supportId)
  if 0 < pos then
    table.remove(res, pos)
    for i = minNum + 1, #herolist do
      table.insert(res, herolist[i].HeroId)
      ok = self:_checkFleetAverageLevel(res, minLevel)
      if ok then
        return ok, res
      else
        pos = self:_getMinLvlExpectRmd(res, supportId)
        if 0 < pos then
          table.remove(res, pos)
        else
          table.remove(res, #res)
        end
      end
    end
  else
  end
  return ok, res
end

function AssistNewLogic:_getMinLvlExpectRmd(heros, supportId)
  if #heros < 1 then
    return 0
  end
  local pos = 0
  local hero, tagLv, sf_id
  for i = 1, #heros do
    hero = Data.heroData:GetHeroById(heros[i])
    sf_id = Logic.shipLogic:GetSfidBySmid(hero.TemplateId)
    tagLv = hero.Lvl
    if not self:_isRmd(supportId, sf_id, hero.type) then
      pos = i
      break
    end
  end
  if pos == 0 then
    return 0
  end
  for i = pos + 1, #heros do
    hero = Data.heroData:GetHeroById(heros[i])
    sf_id = Logic.shipLogic:GetSfidBySmid(hero.TemplateId)
    local lv = hero.Lvl
    if tagLv > lv and not self:_isRmd(supportId, sf_id, hero.type) then
      pos = i
    end
  end
  return pos
end

function AssistNewLogic:_isRmd(supportId, sf_id, type)
  local have, fix = self:CheckFixShipRmd(supportId)
  local checkType, types = self:CheckFixTypeRmd(supportId)
  return have and table.containV(fix, sf_id) or checkType and table.containV(types, type)
end

function AssistNewLogic:HandleInFleet(heros)
  if self:GetRemoveFleetConfig() then
    return false, {}
  end
  local res = {}
  for i, v in ipairs(heros) do
    local fleet = Logic.shipLogic:IsInFleet(v)
    if fleet then
      table.insert(res, v)
    end
  end
  return 0 < #res, res
end

function AssistNewLogic:CheckNormalFinish(data)
  local state = self:GetAssistState(data.SupportId, data.StartTime)
  if state ~= AssistFleetState.FINISH then
    return false, "\230\148\175\230\143\180\230\156\170\231\187\147\230\157\159\230\151\160\230\179\149\233\162\134\229\143\150\229\165\150\229\138\177"
  end
  return true, ""
end

function AssistNewLogic:CheckFastFinishRPC(data)
  local state = self:GetAssistState(data.SupportId, data.StartTime)
  if state ~= AssistFleetState.DOING then
    return false, "\229\143\170\232\131\189\229\191\171\233\128\159\229\174\140\230\136\144\232\191\155\232\161\140\228\184\173\231\154\132\228\187\187\229\138\161"
  end
  return true, ""
end

function AssistNewLogic:CheckCancelSupport(data)
  if data.Id <= 0 then
    return false, "\230\151\160\230\149\136\231\154\132assist id"
  end
  local state = self:GetAssistState(data.SupportId, data.StartTime)
  if state ~= AssistFleetState.DOING then
    return false, "\229\143\170\232\131\189\229\143\150\230\182\136\232\191\155\232\161\140\228\184\173\231\154\132\230\148\175\230\143\180"
  end
  return true, ""
end

function AssistNewLogic:CheckStartSupport(data)
  if data.SupportId == 0 then
    return false, "\230\156\170\232\174\190\231\189\174\230\148\175\230\143\180\228\187\164"
  end
  local state = self:GetAssistState(data.SupportId, data.StartTime)
  if state ~= AssistFleetState.TODO then
    noticeManager:ShowTip(UIHelper.GetString(971007))
    return false, "\229\143\170\232\131\189\229\143\150\230\182\136\232\191\155\232\161\140\228\184\173\231\154\132\230\148\175\230\143\180"
  end
  local consumeConfig = Logic.assistNewLogic:GetSupportConsume(data.SupportId)
  if #consumeConfig ~= 0 then
    local enough, str = Logic.assistNewLogic:CheckSupportConsume(consumeConfig[1], consumeConfig[2], consumeConfig[3])
    if not enough then
      noticeManager:ShowTip(str)
      return false, str
    end
  end
  local info = Logic.assistNewLogic:CheckAssistTeamLimit(data.HeroList, data.SupportId)
  for i, v in ipairs(info) do
    if not v.check then
      return v.check, "\228\184\141\230\187\161\232\182\179\232\166\129\230\177\130:" .. v.des
    end
  end
  return true, ""
end

function AssistNewLogic:GetPushNoticeParams(args)
  local paramList = {}
  local noticeParam = {}
  local firstEndTime = 9999999999
  if #args == 0 then
    return paramList
  end
  for k, v in pairs(args) do
    local endTime = self:GetAssistEndTime(v.SupportId, v.StartTime)
    if endTime > time.getSvrTime() then
      firstEndTime = math.min(firstEndTime, endTime)
    end
  end
  noticeParam.key = "supportFleet"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 4).text
  noticeParam.time = firstEndTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.supportFleet = noticeParam
  return paramList
end

return AssistNewLogic
