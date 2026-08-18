local BuildLogic = class("logic.BuildLogic")

function BuildLogic:initialize()
  self:ResetData()
  pushNoticeManager:_BindNotice("build", function()
    return self:GetPushNoticeParams(Data.buildData:GetData())
  end)
end

function BuildLogic:ResetData()
  self.index = BuildShipGirl.Bulid
  self.isFirst = true
end

function BuildLogic:SetTogLastIndex(index)
  self.index = index
end

function BuildLogic:GetTogLastIndex(index)
  return self.index
end

function BuildLogic:IsHaveRedDot()
  local sequeData = Data.buildData:GetData()
  if #sequeData.BuildedList ~= 0 then
    return true
  else
    return false
  end
end

function BuildLogic:FilterAndSort(tabHero, index)
  if tabHero == nil then
    return
  end
  local filterHeroInfo = {
    [NotesType.All] = self:FilterAllHero(tabHero),
    [NotesType.SSR] = self:FilterSSRHero(tabHero),
    [NotesType.SR] = self:FilterSRHero(tabHero),
    [NotesType.R] = self:FilterRHero(tabHero)
  }
  local filterHero = filterHeroInfo[index]
  table.sort(filterHero, function(data1, data2)
    if data1.Count ~= data2.Count then
      return data1.Count > data2.Count
    else
      return data1.BuildedInfo.EndTime < data2.BuildedInfo.EndTime
    end
  end)
  return filterHero
end

function BuildLogic:FilterAllHero(tabHero)
  return tabHero
end

function BuildLogic:FilterSSRHero(tabHero)
  local filterHero = {}
  for v, k in pairs(tabHero) do
    local shipInfo = Logic.shipLogic:GetShipInfoById(k.BuildedInfo.HeroId)
    if shipInfo.quality == 4 then
      table.insert(filterHero, k)
    end
  end
  return filterHero
end

function BuildLogic:FilterSRHero(tabHero)
  local filterHero = {}
  for v, k in pairs(tabHero) do
    local shipInfo = Logic.shipLogic:GetShipInfoById(k.BuildedInfo.HeroId)
    if shipInfo.quality == 3 then
      table.insert(filterHero, k)
    end
  end
  return filterHero
end

function BuildLogic:FilterRHero(tabHero)
  local filterHero = {}
  for v, k in pairs(tabHero) do
    local shipInfo = Logic.shipLogic:GetShipInfoById(k.BuildedInfo.HeroId)
    if shipInfo.quality == 1 or shipInfo.quality == 2 then
      table.insert(filterHero, k)
    end
  end
  return filterHero
end

function BuildLogic:SetIsFirst(isFirst)
  self.isFirst = isFirst
end

function BuildLogic:GetIsFirst()
  return self.isFirst
end

function BuildLogic:GetPushNoticeParams(args)
  local paramList = {}
  local noticeParam = {}
  local firstEndTime = 9999999999
  if args.BuildingList == 0 then
    return paramList
  end
  for k, v in pairs(args.BuildingList) do
    local endTime = v.EndTime
    if endTime > time.getSvrTime() then
      firstEndTime = math.min(firstEndTime, endTime)
    end
  end
  noticeParam.key = "build"
  noticeParam.text = configManager.GetDataById("config_pushnotice", 5).text
  noticeParam.time = firstEndTime
  noticeParam.repeatTime = LocalNotificationInterval.NoRepeat
  paramList.build = noticeParam
  return paramList
end

return BuildLogic
