local TeachCopyLogic = class("logic.TeachCopyLogic")

function TeachCopyLogic:initialize()
end

function TeachCopyLogic:GetTeachChapterConf()
  local tabTeachChapterConf = {}
  local tabCopyChapterConf = configManager.GetData("config_chapter")
  for k, v in pairs(tabCopyChapterConf) do
    if v.id >= 9000 then
      table.insert(tabTeachChapterConf, v)
    end
  end
  table.sort(tabTeachChapterConf, function(a, b)
    return a.id < b.id
  end)
  return tabTeachChapterConf
end

function TeachCopyLogic:GetFleetInfo(baseId)
  local tabCopyInfo = Logic.copyLogic:GetCopyDataConfig(baseId)
  local fleetId = tabCopyInfo.fleet_id[1]
  local copy_enemys = configManager.GetDataById("config_fleet", fleetId).copy_enemys
  local tabShipInfo = {}
  for k, v in pairs(copy_enemys) do
    local shipInfoId = configManager.GetDataById("config_ship_enemy", v).ship_info_id
    local shipInfo = configManager.GetDataById("config_ship_info", shipInfoId)
    table.insert(tabShipInfo, shipInfo)
  end
  return tabShipInfo
end

function TeachCopyLogic:GetShipMainInfo(shipInfoId)
  local shipMainInfo = configManager.GetData("config_ship_main")
  for k, v in pairs(shipMainInfo) do
    if v.ship_info_id == shipInfoId then
      return v
    end
  end
  return nil
end

return TeachCopyLogic
