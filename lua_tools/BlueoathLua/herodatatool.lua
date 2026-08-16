HeroDataTool = {}
local m = HeroDataTool
local g = _G
local rawget = rawget
local rawset = rawset
_ENV = setmetatable({}, {
  __index = function(t, k)
    return rawget(m, k) or rawget(g, k)
  end,
  __newindex = m
})
configManager = configManager
