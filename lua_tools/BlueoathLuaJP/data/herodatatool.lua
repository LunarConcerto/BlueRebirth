HeroDataTool = {}
local m = HeroDataTool
local g = _G
local rawget = _ENV.rawget
local rawset = _ENV.rawset
_ENV = setmetatable({}, {
  __index = function(t, k)
    return rawget(m, k) or rawget(g, k)
  end,
  __newindex = m
})
configManager = configManager
