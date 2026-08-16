local require = require
local string = string
local table = table

function string.split(input, delimiter)
  input = tostring(input)
  delimiter = tostring(delimiter)
  if delimiter == "" then
    return false
  end
  local pos, arr = 0, {}
  for st, sp in function()
    return string.find(input, delimiter, pos, true)
  end, nil, nil do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end

function import(moduleName, currentModuleName)
  local currentModuleNameParts
  local moduleFullName = moduleName
  local offset = 1
  while true do
    if string.byte(moduleName, offset) ~= 46 then
      moduleFullName = string.sub(moduleName, offset)
      if currentModuleNameParts and 0 < #currentModuleNameParts then
        moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
      end
      break
    end
    offset = offset + 1
    if not currentModuleNameParts then
      if not currentModuleName then
        local n, v = debug.getlocal(3, 1)
        currentModuleName = v
      end
      currentModuleNameParts = string.split(currentModuleName, ".")
    end
    table.remove(currentModuleNameParts, #currentModuleNameParts)
  end
  return require(moduleFullName)
end

function reimport(name)
  local package = package
  package.loaded[name] = nil
  package.preload[name] = nil
  return require(name)
end

function printf(fmt, ...)
  print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
  return tonumber(value, base) or 0
end

function checkint(value)
  return math.round(checknumber(value))
end

function checkbool(value)
  return value ~= nil and value ~= false
end

function checktable(value)
  if type(value) ~= "table" then
    value = {}
  end
  return value
end

function isset(hashtable, key)
  local t = type(hashtable)
  return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

function printTable(tab)
  local str = {}
  local tabRecord = {}
  
  local function printTableImp(tab, tabRecord, space)
    local ret = ""
    if tab == nil then
      return "nil"
    end
    if rawget(tabRecord, tab) ~= nil then
      return rawget(tabRecord, tab) .. "\n"
    else
      rawset(tabRecord, tab, tostring(tab))
    end
    local nextSpace = space .. "   "
    if type(tab) == "table" then
      ret = ret .. tostring(tab)
      ret = ret .. "\n" .. space .. "{\n"
      for k, v in pairs(tab) do
        ret = ret .. nextSpace .. "[" .. toStringEx(k) .. "]" .. ":" .. printTableImp(v, tabRecord, nextSpace)
      end
      ret = ret .. space .. "}"
    else
      ret = ret .. toStringEx(tab)
    end
    return ret .. "\n"
  end
  
  local str = printTableImp(tab, tabRecord, "")
  tabRecord = nil
  return str
end

function traceTable(tb, printTableAddress, depthMax)
  if tb == nil then
    return "nil"
  end
  if depthMax == nil or depthMax < 0 then
    depthMax = -1
  end
  local traceMap = {}
  traceMap[tb] = "."
  
  local function fun(tb, space, name, depth)
    local nextSpace = space .. "    "
    local ret = ""
    if 0 <= depthMax and depth >= depthMax then
      ret = ret .. tostring(tb)
    else
      local typestr = type(tb)
      if typestr == "table" then
        if printTableAddress then
          ret = ret .. tostring(tb)
        end
        ret = ret .. "\n" .. space .. "{\n"
        for k, v in pairs(tb) do
          local newname = name .. "." .. tostring(k)
          local valstr = ""
          if traceMap[v] ~= nil then
            valstr = "-->(" .. traceMap[v] .. ")\n"
          else
            if type(v) == "table" then
              traceMap[v] = newname
            end
            valstr = fun(v, nextSpace, newname, depth + 1)
          end
          ret = ret .. nextSpace .. "[" .. tostring(k) .. "]" .. ":" .. valstr
        end
        ret = ret .. space .. "}"
      else
        ret = ret .. " (" .. typestr .. ") " .. tostring(tb)
      end
    end
    return ret .. "\n"
  end
  
  return fun(tb, "", "", 0)
end

local stringify = function(...)
  local arg = {
    ...
  }
  local t = {}
  for i = 1, select("#", ...) do
    local k = select(i, ...)
    if k == nil then
      table.insert(t, "nil")
    elseif type(k) == "table" then
      if string.sub(tostring(k), 1, 5) == "table" then
        table.insert(t, traceTable(k))
      else
        table.insert(t, tostring(k))
      end
    else
      table.insert(t, tostring(k))
    end
  end
  local r = string.find(t[1], "%%%l")
  if r ~= nil and 1 < #t then
    local ok, res = pcall(string.format, table.unpack(t))
    if ok then
      return res
    end
  end
  return table.concat(t, "  ")
end

function toStringEx(value)
  if value ~= nil and type(value) == "string" then
    return "'" .. value .. "'"
  end
  return tostring(value)
end

function logError(...)
  local traceback = debug.traceback("", 2)
  local prefix = ""
  local info = debug.getinfo(2, "Slf")
  if info ~= nil then
    local t = info.short_src
    prefix = t
    local lineNumber = info.currentline
    if prefix ~= nil and lineNumber ~= nil then
      prefix = "[<color=green>" .. prefix .. ":" .. lineNumber .. "</color>] "
    end
  end
  local str = stringify(...)
  LuaInterface_Debugger.LogError(tostring(prefix) .. tostring(str) .. "\n" .. traceback)
end

function logWarning(...)
  local traceback = debug.traceback("", 2)
  local str = stringify(...)
  LuaInterface_Debugger.LogWarning(tostring(str) .. "\n" .. traceback)
end

function logDebug(...)
  log(...)
end

function log(...)
  local str = stringify(...)
  LuaInterface_Debugger.Log(str)
end

function table.empty(t)
  return next(t) == nil
end

function table.nums(t)
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
  end
  return count
end

function table.removebyvalue(array, value, removeall)
  local c, i, max = 0, 1, #array
  while i <= max do
    if array[i] == value then
      table.remove(array, i)
      c = c + 1
      i = i - 1
      max = max - 1
      if not removeall then
        break
      end
    end
    i = i + 1
  end
  return c
end

function table.keys(hashtable)
  local keys = {}
  for k, v in pairs(hashtable) do
    keys[#keys + 1] = k
  end
  return keys
end

function table.values(hashtable)
  local values = {}
  for k, v in pairs(hashtable) do
    values[#values + 1] = v
  end
  return values
end

function table.merge(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
end

function table.insertto(dest, src, begin)
  begin = checkint(begin)
  if begin <= 0 then
    begin = #dest + 1
  end
  local len = #src
  for i = 0, len - 1 do
    dest[i + begin] = src[i + 1]
  end
end

function table.indexof(array, value, begin)
  for i = begin or 1, #array do
    if array[i] == value then
      return i
    end
  end
  return false
end

function table.keyof(hashtable, value)
  for k, v in pairs(hashtable) do
    if v == value then
      return k
    end
  end
  return nil
end

function table.map(t, fn)
  for k, v in pairs(t) do
    t[k] = fn(v, k)
  end
end

function table.walk(t, fn)
  for k, v in pairs(t) do
    fn(v, k)
  end
end

function table.filter(t, fn)
  for k, v in pairs(t) do
    if not fn(v, k) then
      t[k] = nil
    end
  end
end

function table.unique(t, bArray)
  local check = {}
  local n = {}
  local idx = 1
  for k, v in pairs(t) do
    if not check[v] then
      if bArray then
        n[idx] = v
        idx = idx + 1
      else
        n[k] = v
      end
      check[v] = true
    end
  end
  return n
end

function table.containV(t, v)
  for _, val in pairs(t) do
    if val == v then
      return true
    end
  end
  return false
end

function table.removebykey(tab, key)
  if tab[key] ~= nil then
    tab[key] = nil
    return true
  else
    return false
  end
end

function table.containValue(t, value)
  for k, v in pairs(t) do
    if value == v then
      return true
    end
  end
  return false
end

function table.containKey(t, key)
  for k, v in pairs(t) do
    if key == k then
      return true
    end
  end
  return false
end

function table.append(dst, src)
  local res = {}
  local len = #dst + #src
  for i = 1, len do
    if i <= #dst then
      res[i] = dst[i]
    else
      res[i] = src[i - #dst]
    end
  end
  return res
end

function math.newrandomseed()
  math.randomseed(os.time())
  math.random()
  math.random()
  math.random()
  math.random()
end

function math.round(value)
  value = checknumber(value)
  return math.floor(value + 0.5)
end

function math.angle2radian(angle)
  return angle * math.pi / 180
end

function math.radian2angle(radian)
  return radian / math.pi * 180
end

function io.exists(path)
  local file = io.open(path, "r")
  if file then
    io.close(file)
    return true
  end
  return false
end

function io.readfile(path)
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    io.close(file)
    return content
  end
  return nil
end

function io.writefile(path, content, mode)
  mode = mode or "w+b"
  local file = io.open(path, mode)
  if file then
    if file:write(content) == nil then
      return false
    end
    io.close(file)
    return true
  else
    return false
  end
end

function io.pathinfo(path)
  local pos = string.len(path)
  local extpos = pos + 1
  while 0 < pos do
    local b = string.byte(path, pos)
    if b == 46 then
      extpos = pos
    elseif b == 47 then
      break
    end
    pos = pos - 1
  end
  local dirname = string.sub(path, 1, pos)
  local filename = string.sub(path, pos + 1)
  extpos = extpos - pos
  local basename = string.sub(filename, 1, extpos - 1)
  local extname = string.sub(filename, extpos)
  return {
    dirname = dirname,
    filename = filename,
    basename = basename,
    extname = extname
  }
end

function io.filesize(path)
  local size = false
  local file = io.open(path, "r")
  if file then
    local current = file:seek()
    size = file:seek("end")
    file:seek("set", current)
    io.close(file)
  end
  return size
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
  for k, v in pairs(string._htmlspecialchars_set) do
    input = string.gsub(input, k, v)
  end
  return input
end

function string.restorehtmlspecialchars(input)
  for k, v in pairs(string._htmlspecialchars_set) do
    input = string.gsub(input, v, k)
  end
  return input
end

function string.nl2br(input)
  return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
  input = string.gsub(input, "\t", "    ")
  input = string.htmlspecialchars(input)
  input = string.gsub(input, " ", "&nbsp;")
  input = string.nl2br(input)
  return input
end

function string.split(input, delimiter)
  input = tostring(input)
  delimiter = tostring(delimiter)
  if delimiter == "" then
    return false
  end
  local pos, arr = 0, {}
  for st, sp in function()
    return string.find(input, delimiter, pos, true)
  end, nil, nil do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end

function string.ltrim(input)
  return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
  return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
  input = string.gsub(input, "^[ \t\n\r]+", "")
  return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
  return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local urlencodechar = function(char)
  return "%" .. string.format("%02X", string.byte(char))
end

function string.urlencode(input)
  input = string.gsub(tostring(input), "\n", "\r\n")
  input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
  return string.gsub(input, " ", "+")
end

function string.urldecode(input)
  input = string.gsub(input, "+", " ")
  input = string.gsub(input, "%%(%x%x)", function(h)
    return string.char(checknumber(h, 16))
  end)
  input = string.gsub(input, "\r\n", "\n")
  return input
end

function string.utf8len(input)
  local len = string.len(input)
  local left = len
  local cnt = 0
  local arr = {
    0,
    192,
    224,
    240,
    248,
    252
  }
  while left ~= 0 do
    local tmp = string.byte(input, -left)
    local i = #arr
    while arr[i] do
      if tmp >= arr[i] then
        left = left - i
        break
      end
      i = i - 1
    end
    cnt = cnt + 1
  end
  return cnt
end

function string.formatnumberthousands(num)
  local formatted = tostring(checknumber(num))
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then
      break
    end
  end
  return formatted
end

function get_data_by_sec(sec)
  sec = sec < 0 and 0 or sec
  local data = {
    day = math.floor(sec / 3600 / 24),
    hour = math.floor(sec / 3600) % 24,
    min = math.floor(sec % 3600 / 60),
    sec = sec % 60
  }
  return data
end

function play_open_window_anim(trans, ui_animhandler)
  if ui_animhandler and ui_animhandler.before_handler then
    ui_animhandler.before_handler()
  end
  trans.localScale = Vector3.zero
  local ltDescr = LeanTween.scale(trans, Vector3.one, 0.2):setEase(LeanTweenType.easeOutBack)
  if ltDescr and ui_animhandler and ui_animhandler.after_handler then
    ltDescr:setOnComplete(System.Action(ui_animhandler.after_handler))
  end
end

function clone(object)
  local lookup_table = {}
  
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = {}
    lookup_table[object] = new_table
    for key, value in pairs(object) do
      new_table[_copy(key)] = _copy(value)
    end
    return setmetatable(new_table, getmetatable(object))
  end
  
  return _copy(object)
end

function IsNil(uobj)
  local Test = function()
    return uobj == nil or uobj:Equals(nil)
  end
  local r, errRet = pcall(Test, err)
  if not r then
    return true
  end
  return errRet
end

function NonBreakingSpaceReplace(str)
  return (string.gsub(str, " ", "\194\160"))
end

function DeepReplace(src, dst)
  local lookup_table = {}
  local _replace = function(src, dst)
    for k, v in pairs(src) do
      if dst[k] == nil then
        src[k] = nil
      end
      if type(dst[k]) == "table" then
        if lookup_table[dst[k]] then
          break
        end
        DeepReplace(v, dst[k])
        lookup_table[dst[k]] = true
      else
        src[k] = dst[k]
      end
    end
  end
  _replace(src, dst)
end

function InitINC(base, length)
  local _base = base
  return function()
    _base = _base + 1
    if length and _base > base + length then
      logError("increase events too large")
    end
    return _base
  end
end

function Serialize(obj)
  local lua = ""
  local t = type(obj)
  if t == "number" then
    lua = lua .. obj
  elseif t == "boolean" then
    lua = lua .. tostring(obj)
  elseif t == "string" then
    lua = lua .. string.format("%q", obj)
  elseif t == "table" then
    lua = lua .. "{\n"
    for k, v in pairs(obj) do
      lua = lua .. "[" .. Serialize(k) .. "]=" .. Serialize(v) .. ",\n"
    end
    local metatable = getmetatable(obj)
    if metatable ~= nil and type(metatable.__index) == "table" then
      for k, v in pairs(metatable.__index) do
        lua = lua .. "[" .. Serialize(k) .. "]=" .. Serialize(v) .. ",\n"
      end
    end
    lua = lua .. "}"
  elseif t == "nil" then
    return nil
  else
    error("can not serialize a " .. t .. " type.")
  end
  return lua
end

function Unserialize(lua)
  local t = type(lua)
  if t == "nil" or lua == "" then
    return nil
  elseif t == "number" or t == "string" or t == "boolean" then
    lua = tostring(lua)
  else
    error("can not unserialize a " .. t .. " type.")
  end
  lua = "return " .. lua
  local func = load(lua)
  if func == nil then
    return nil
  end
  return func()
end

function ScheduleUpdate(interval, callback, immediately, timeScale)
  if callback == nil then
    return
  end
  local timer = Timer.New(callback, interval, -1, timeScale)
  if immediately then
    callback()
  end
  timer:Start()
  return timer
end

function ScheduleUpdateCount(interval, callback, immediately, loopCount, timeScale)
  if callback == nil then
    return
  end
  loopCount = immediately and loopCount - 1 or loopCount
  local timer = Timer.New(function()
    callback()
  end, interval, loopCount, timeScale)
  if immediately then
    callback()
  end
  timer:Start()
  return timer
end

function string.formatEx(str, array)
  local temp = {}
  local args = {}
  for w in string.gmatch(str, "<%d>") do
    w = string.sub(w, 2, 2)
    table.insert(temp, tonumber(w))
  end
  local res, len = string.gsub(str, "<%d>", "%%s")
  for i, v in ipairs(temp) do
    if array[v] then
      args[i] = array[v]
    else
      args[i] = 0
      print("lose args,index:" .. v)
    end
  end
  if len <= 0 then
    return str
  end
  return string.format(res, table.unpack(args))
end

function specialize(f, ...)
  local args = {
    ...
  }
  return function(...)
    local vars = {
      ...
    }
    local a = {}
    for i, v in ipairs(args) do
      a[#a + 1] = v
    end
    for i, v in ipairs(vars) do
      a[#a + 1] = v
    end
    return f(table.unpack(a))
  end
end

function randperm(n)
  local m = {}
  for i = 1, n do
    local j = math.random(i)
    m[i] = m[j]
    m[j] = i
  end
  return m
end

function randweight(weights)
  local totalweight = 0
  for _, weight in ipairs(weights) do
    totalweight = totalweight + weight
  end
  if totalweight <= 0 then
    logError("err weights", weights)
    return 1
  end
  local value = math.random(totalweight)
  for index, weight in ipairs(weights) do
    if weight > value then
      return index
    end
    value = value - weight
  end
  return 1
end
