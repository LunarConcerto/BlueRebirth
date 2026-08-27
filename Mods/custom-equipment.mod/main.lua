local EQUIP_ID = 900001
local SOURCE_EQUIP_ID = 30023
local SHOP_GOOD_ID = 990001
local SOURCE_SHOP_GOOD_ID = 20013

local config_patched = false

local function assign_with_previous(previous, target, key, value)
  if type(previous) == "function" then
    previous(target, key, value)
  elseif type(previous) == "table" then
    previous[key] = value
  else
    rawset(target, key, value)
  end
end

local function deep_clone(value, seen)
  if type(value) ~= "table" then
    return value
  end
  seen = seen or {}
  if seen[value] ~= nil then
    return seen[value]
  end
  local result = {}
  seen[value] = result
  for key, child in pairs(value) do
    result[deep_clone(key, seen)] = deep_clone(child, seen)
  end
  return result
end

local function ensure_equipment(configs)
  if type(configs) ~= "table" or type(configs[SOURCE_EQUIP_ID]) ~= "table" then
    return configs
  end
  if type(configs[EQUIP_ID]) == "table" then
    return configs
  end

  local equipment = deep_clone(configs[SOURCE_EQUIP_ID])
  equipment.e_id = EQUIP_ID
  equipment.name = "未来試作砲"
  equipment.equip_prop = {{8, 90}, {3200, 300}}
  equipment.enhance_prop = {{8, 6}, {3200, 20}}
  equipment.drop_path = {}
  equipment.no_resolve = 1
  equipment.__blueoath_custom_equipment = true
  configs[EQUIP_ID] = equipment
  mod.info("injected equipment template id=" .. tostring(EQUIP_ID))
  return configs
end

local function ensure_shop_good(configs)
  if type(configs) ~= "table" or type(configs[SOURCE_SHOP_GOOD_ID]) ~= "table" then
    return configs
  end
  if type(configs[SHOP_GOOD_ID]) == "table" then
    return configs
  end

  local good = deep_clone(configs[SOURCE_SHOP_GOOD_ID])
  good.id = SHOP_GOOD_ID
  good.name = "未来試作砲×1"
  good.goods = {2, EQUIP_ID, 1}
  good.stock = 1
  good.manual_refresh_stock = 1
  good.goods_visible = 1
  good.__blueoath_custom_equipment = true
  configs[SHOP_GOOD_ID] = good
  mod.info("injected equipment shop good id=" .. tostring(SHOP_GOOD_ID))
  return configs
end

local function patch_config_manager(manager)
  if config_patched or type(manager) ~= "table" then
    return
  end
  local original_get_data = manager.GetData
  local original_get_data_by_id = manager.GetDataById
  if type(original_get_data) ~= "function" or type(original_get_data_by_id) ~= "function" then
    error("configManager API is unavailable")
  end

  manager.GetData = function(name, ...)
    local data = original_get_data(name, ...)
    if name == "config_equip" then
      ensure_equipment(data)
    elseif name == "config_shop_goods" then
      ensure_shop_good(data)
    end
    return data
  end

  manager.GetDataById = function(name, id, ...)
    local numeric_id = tonumber(id)
    if name == "config_equip" and numeric_id == EQUIP_ID then
      local configs = manager.GetData("config_equip")
      return configs and configs[EQUIP_ID] or nil
    elseif name == "config_shop_goods" and numeric_id == SHOP_GOOD_ID then
      local configs = manager.GetData("config_shop_goods")
      return configs and configs[SHOP_GOOD_ID] or nil
    end
    return original_get_data_by_id(name, id, ...)
  end

  config_patched = true
  mod.info("configManager equipment hooks installed")
end

local function safely_patch(manager)
  local ok, failure = xpcall(function()
    patch_config_manager(manager)
  end, debug.traceback)
  if not ok then
    mod.info("configManager equipment hook failed: " .. tostring(failure))
  end
end

local function install_when_config_manager_is_ready()
  local current = rawget(_G, "configManager")
  if current ~= nil then
    safely_patch(current)
    return
  end

  local meta = getmetatable(_G) or {}
  local previous_newindex = meta.__newindex
  meta.__newindex = function(target, key, value)
    assign_with_previous(previous_newindex, target, key, value)
    if key == "configManager" then
      meta.__newindex = previous_newindex
      safely_patch(value)
    end
  end
  setmetatable(_G, meta)
  mod.info("waiting for configManager")
end

function on_bootstrap()
  install_when_config_manager_is_ready()
end
