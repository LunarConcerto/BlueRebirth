local patched = false

local function assign_with_previous(previous, target, key, value)
  if type(previous) == "function" then
    previous(target, key, value)
  elseif type(previous) == "table" then
    previous[key] = value
  else
    rawset(target, key, value)
  end
end

local function patch_fashion_logic(fashion_logic)
  if patched or type(fashion_logic) ~= "table" then
    return
  end
  local original_get_own = fashion_logic.GetOwnFashionByHeroId
  if type(original_get_own) ~= "function" or
      type(fashion_logic.GetOwnFashion) ~= "function" then
    error("FashionLogic ownership API is unavailable")
  end

  fashion_logic.GetOwnFashionByHeroId = function(self, sf_id, hero_id, ...)
    -- Shop skins can be unlocked before their ship is owned. FashionPage then
    -- previews with hero_id=nil. The original implementation still asks
    -- RemouldLogic for that missing hero and aborts page initialization,
    -- leaving prefab placeholders such as the default outfit name visible.
    if hero_id == nil then
      return self:GetOwnFashion(sf_id)
    end
    return original_get_own(self, sf_id, hero_id, ...)
  end

  patched = true
  mod.info("FashionLogic nil-hero preview guard installed")
end

local function watch_logic_table(logic)
  if type(logic) ~= "table" then
    return
  end
  local current = rawget(logic, "fashionLogic")
  if type(current) == "table" then
    patch_fashion_logic(current)
    return
  end

  local meta = getmetatable(logic) or {}
  local previous_newindex = meta.__newindex
  meta.__newindex = function(target, key, value)
    assign_with_previous(previous_newindex, target, key, value)
    if key == "fashionLogic" then
      meta.__newindex = previous_newindex
      patch_fashion_logic(value)
    end
  end
  setmetatable(logic, meta)
  mod.info("waiting for Logic.fashionLogic")
end

function on_bootstrap()
  assert(type(mod.watch_global) == "function", "shared global watcher is unavailable")
  mod.watch_global("Logic", watch_logic_table)
  mod.info("waiting for Logic")
end
