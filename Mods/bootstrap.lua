local root = assert(__BLUEOATH_MOD_ROOT, "__BLUEOATH_MOD_ROOT is missing")
local native_loadfile = assert(__blueoath_loadfile, "__blueoath_loadfile is missing")
local native_log = __blueoath_log

local function log(message)
  local text = "[BlueOath.Mods] " .. tostring(message)
  if native_log then
    native_log(text)
  else
    print(text)
  end
end

-- Mods load before most game globals exist. Keep one shared watcher so mods
-- do not replace each other's _G.__newindex hooks while waiting for them.
local global_watchers = {}
local function assign_with_previous(previous, target, key, value)
  if type(previous) == "function" then
    previous(target, key, value)
  elseif type(previous) == "table" then
    previous[key] = value
  else
    rawset(target, key, value)
  end
end

local global_meta = getmetatable(_G) or {}
local previous_global_newindex = global_meta.__newindex
global_meta.__newindex = function(target, key, value)
  assign_with_previous(previous_global_newindex, target, key, value)
  local watchers = global_watchers[key]
  if watchers ~= nil then
    global_watchers[key] = nil
    for _, watcher in ipairs(watchers) do
      watcher(value)
    end
  end
end
setmetatable(_G, global_meta)

local function watch_global(name, callback)
  local current = rawget(_G, name)
  if current ~= nil then
    callback(current)
    return
  end
  local watchers = global_watchers[name]
  if watchers == nil then
    watchers = {}
    global_watchers[name] = watchers
  end
  table.insert(watchers, callback)
end

local function load_mod(entry)
  local environment = setmetatable({
    mod = {
      info = function(message)
        log(entry .. ": " .. tostring(message))
      end,
      watch_global = function(name, callback)
        assert(type(name) == "string", "global name must be a string")
        assert(type(callback) == "function", "global watcher must be a function")
        watch_global(name, function(value)
          local ok, failure = xpcall(function()
            callback(value)
          end, debug.traceback)
          if not ok then
            log(entry .. ": " .. tostring(name) .. " hook failed: " .. tostring(failure))
          end
        end)
      end
    }
  }, {__index = _G})
  local chunk, load_error = native_loadfile(entry)
  if not chunk then
    error("cannot load " .. entry .. ": " .. tostring(load_error))
  end
  assert(debug and debug.setupvalue, "debug.setupvalue is unavailable")
  debug.setupvalue(chunk, 1, environment)
  local ok, run_error = xpcall(chunk, debug.traceback)
  if not ok then
    error("cannot run " .. entry .. ": " .. tostring(run_error))
  end
  if type(environment.on_bootstrap) == "function" then
    environment.on_bootstrap({root = root, entry = entry})
  end
  return environment
end

-- This explicit index is intentionally tiny for the first runtime proof. A
-- later step will generate it from mod.json dependency/loadOrder metadata.
local entries = {
  "future-chapter.mod/main.lua",
  "custom-equipment.mod/main.lua",
  "fashion-preview-fix.mod/main.lua",
  "example.mod/main.lua"
}

BlueOathMods = BlueOathMods or {loaded = {}}
for _, entry in ipairs(entries) do
  BlueOathMods.loaded[entry] = load_mod(entry)
end

log("bootstrap complete; loaded " .. tostring(#entries) .. " mod(s)")
__BLUEOATH_MOD_BOOTSTRAPPED = true
