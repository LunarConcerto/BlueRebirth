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

local function load_mod(entry)
  local environment = setmetatable({
    mod = {
      info = function(message)
        log(entry .. ": " .. tostring(message))
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
  "example.mod/main.lua"
}

BlueOathMods = BlueOathMods or {loaded = {}}
for _, entry in ipairs(entries) do
  BlueOathMods.loaded[entry] = load_mod(entry)
end

log("bootstrap complete; loaded " .. tostring(#entries) .. " mod(s)")
__BLUEOATH_MOD_BOOTSTRAPPED = true
