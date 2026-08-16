CSUtil = {}

function CSUtil.OpenPage(args)
  local page_name = args[0]
  local page_args = args[1]
end

function CSUtil.CreateLuaClass(args)
  local classPath = args
  local ui_page = require(classPath)()
  return ui_page
end

return CSUtil
