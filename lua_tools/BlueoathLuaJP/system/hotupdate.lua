local oldRequire = require
local pathMap = {}
local selfname = "system.hotupdate"
local exludes = {
  "system.hotupdate",
  "data.initdata",
  "event.LuaEvent",
  "event.LuaCSharpEvent",
  "service.InitService",
  "Common.GlobalRefrence",
  "util.GlobalNoitceManager",
  "util.HomeEnvManager",
  "ui.page.Home.HomePage",
  "util.EventManager",
  "SettlementLogic"
}
local exludesAlways = {
  "^config%.clientconfig*",
  "^game.*"
}
local enableHotUpdate = true

function formatPath(path)
  path = string.gsub(path, "@%.\\", "")
  path = string.gsub(path, "@%./", "")
  path = string.gsub(path, "@", "")
  path = string.gsub(path, "%.lua$", "")
  path = string.gsub(path, "\\", ".")
  path = string.gsub(path, "/", ".")
  path = string.gsub(path, "^lua%.", "")
  path = string.lower(path)
  return path
end

function require(luaPath)
  luaPath = formatPath(luaPath)
  if not isEditor then
    return oldRequire(luaPath)
  end
  if luaPath == selfname and package.loaded[selfname] then
    return nil
  end
  local n = 2
  local srcPath
  while true do
    local debugInfo = debug.getinfo(n)
    if debugInfo == nil then
      return oldRequire(luaPath)
    end
    srcPath = debugInfo.source
    if srcPath == nil then
      return oldRequire(luaPath)
    end
    if string.find(srcPath, "%.lua$") == nil then
      n = n + 1
    else
      break
    end
  end
  srcPath = formatPath(srcPath)
  local targetPath = luaPath
  if pathMap[targetPath] == nil then
    pathMap[targetPath] = {}
  end
  pathMap[targetPath][srcPath] = 1
  return oldRequire(targetPath)
end

function luaReload(luaPath, reloaded)
  if not enableHotUpdate then
    return
  end
  luaPath = formatPath(luaPath)
  if reloaded == nil then
    reloaded = {}
  end
  if reloaded[luaPath] ~= nil then
    return
  end
  reloaded[luaPath] = 1
  for i, v in ipairs(exludesAlways) do
    v = string.lower(v)
    if luaPath == v or string.find(luaPath, v) ~= nil then
      return
    end
  end
  for i, v in ipairs(exludes) do
    v = string.lower(v)
    if (luaPath == v or string.find(luaPath, v) ~= nil) and package.loaded[v] then
      return
    end
  end
  if package.loaded[luaPath] == nil then
    return
  end
  package.loaded[luaPath] = nil
  require(luaPath)
  local map = pathMap[luaPath]
  if map == nil then
    return
  end
  for k, v in pairs(map) do
    luaReload(k, reloaded)
  end
end
