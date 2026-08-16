require("Debug.GM.GM_Guild")
require("Debug.GM.GM_Bag")
GMMgr = {
  MapCmdHandlers = {
    GM_Handler_Guild = GM_Handler_Guild,
    GM_Handler_Bag = GM_Handler_Bag
  }
}

function GMMgr.GetCmd(cmdstr)
  for name, handler in pairs(GMMgr.MapCmdHandlers) do
    local func = handler[cmdstr]
    if func ~= nil then
      return func, name .. "." .. cmdstr
    end
  end
  return nil
end

function GMMgr.ExecuteGmCommond(str)
  logDebug("gmc", str)
  local fields = string.split(str, ".")
  if #fields <= 0 then
    return
  end
  local parm1 = fields[1]
  local cmd, cmdkey = GMMgr.GetCmd(parm1)
  if cmd == nil then
    logError("GMC not exist [" .. parm1 .. "]")
    return
  end
  logError("Execute GMC Cmd:", cmdkey, fields)
  cmd(fields)
end
