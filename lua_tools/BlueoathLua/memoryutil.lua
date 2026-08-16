local memory = require("perf.memory")
local mri = require("perf.MemoryReferenceInfo")
local memoryUtil = {}
local timer
memoryUtil.cacheTotal = {}
memoryUtil.threshold = 10
memoryUtil.snapFilePath = CS.UnityEngine.Application.persistentDataPath
memoryUtil.m_cacheNum = {}

function memoryUtil.m_recordCache(msg)
  table.insert(memoryUtil.cacheTotal, msg)
end

function memoryUtil.m_clearTotal()
  memoryUtil.cacheTotal = {}
end

function memoryUtil.m_writeFile()
  local content = "---------------------------------------------\n" .. "time\t\ttotal\t\tremark\n" .. "---------------------------------------------"
  for i, v in ipairs(memoryUtil.cacheTotal) do
    content = content .. "\n" .. v
  end
  ChatInfoManager.SaveData("LuaProfiler", tostring(os.date("%Y-%m-%d %H-%M-%S", os.time())), "txt", content)
end

function memoryUtil.LuaMemory(remark, console, record)
  if LuaMacro and LuaMacro.LUAPROFILER then
    local total = memory.total() * 9.77E-4
    local debug = CS.UnityEngine.Debug.LogError
    local time = os.date("%Y-%m-%d   %H:%M:%S", os.time())
    local msg = time .. "\t\t" .. total .. "\t\t" .. remark
    memoryUtil.m_recordCache(msg)
    if record then
      memoryUtil.m_writeFile()
      memoryUtil.m_clearTotal()
    end
    if console then
      debug("<color=#000FFF>[luaProfiler]" .. remark .. ":" .. string.format("%.4f", total) .. "MB" .. "</color>")
    end
    return total
  end
  return 0
end

function memoryUtil.BaseLuaMemory()
  return memory.total() * 9.77E-4
end

function memoryUtil.RecordTotal()
  local callback = function()
    memoryUtil.LuaMemory(tostring(CS.UnityEngine.Time.realtimeSinceStartup))
  end
  timer = Timer.New(callback, memoryUtil.threshold, -1, false)
  timer:Start()
end

function memoryUtil.RecordFinish()
  if timer ~= nil then
    timer:Stop()
    timer = nil
  end
end

memoryUtil.testTotal = 0
memoryUtil.testTable = {}

function memoryUtil.SetFinishTotal()
  memoryUtil.testTotal = memory.total() * 9.77E-4
end

function memoryUtil.SaveCache(path, value)
  table.insert(memoryUtil.testTable, {path = path, value = value})
end

function memoryUtil.SortAndPrint()
  local total = 0
  local res = {}
  local temp = memoryUtil.testTable
  for i = 1, #temp do
    if i ~= #temp then
      table.insert(res, {
        path = temp[i].path,
        value = temp[i + 1].value - temp[i].value
      })
    else
      table.insert(res, {
        path = temp[i].path,
        value = memoryUtil.testTotal - temp[i].value
      })
    end
  end
  table.sort(res, function(date1, date2)
    return date1.value > date2.value
  end)
  for i, v in ipairs(res) do
    total = total + v.value
    print("config:" .. v.path .. "\t" .. v.value)
  end
  print("total:" .. total)
end

function memoryUtil.SnapShot()
  memory.snapshot()
end

return memoryUtil
