local CHAPTER_ID = 17
local MAIN_PLOT_TYPE = 1
local FUTURE_PART = 3
local FUTURE_PART_NAME = "未来編"
local LAST_REAL_CHAPTER_ID = 13

local config_patched = false
local copy_logic_patched = false

local function safely(label, action, value)
  local ok, failure = xpcall(function()
    action(value)
  end, debug.traceback)
  if not ok then
    mod.info(label .. " failed: " .. tostring(failure))
  end
end

local function assign_with_previous(previous, target, key, value)
  if type(previous) == "function" then
    previous(target, key, value)
  elseif type(previous) == "table" then
    previous[key] = value
  else
    rawset(target, key, value)
  end
end

local function ensure_placeholder(chapters)
  if type(chapters) ~= "table" then
    return chapters
  end
  if type(chapters[CHAPTER_ID]) == "table" then
    return chapters
  end

  local template = chapters[LAST_REAL_CHAPTER_ID]
  if type(template) ~= "table" then
    return chapters
  end

  local placeholder = {}
  for key, value in pairs(template) do
    placeholder[key] = value
  end
  placeholder.id = CHAPTER_ID
  placeholder.name2 = "COMING SOON"
  placeholder.title = "COMING SOON"
  placeholder.name = "今後のアップデート"
  placeholder.level_list = {}
  placeholder.running_level_list = {}
  placeholder.star_cond = {}
  placeholder.star_reward = {}
  placeholder.star_box = {}
  placeholder.next_chapter = 0
  placeholder.activate_by_default = 0
  placeholder.is_available = 0
  placeholder.is_show = 0
  placeholder.plot_copy_cover = "uipic_ui_memory_im_gengduohuiyi"
  placeholder.__blueoath_empty_chapter = true
  chapters[CHAPTER_ID] = placeholder
  mod.info("injected empty main-story chapter id=" .. tostring(CHAPTER_ID))
  return chapters
end

local function ensure_future_part(plot_type)
  if type(plot_type) ~= "table" or
      type(plot_type.chapter_list2) ~= "table" or
      type(plot_type.plot_enter_name) ~= "table" or
      type(plot_type.image_bg) ~= "table" then
    return plot_type
  end

  local changed = false
  for part_index, part in pairs(plot_type.chapter_list2) do
    if part_index ~= FUTURE_PART and type(part) == "table" then
      for chapter_index = #part, 1, -1 do
        if tonumber(part[chapter_index]) == CHAPTER_ID then
          table.remove(part, chapter_index)
          changed = true
        end
      end
    end
  end

  local future_chapters = plot_type.chapter_list2[FUTURE_PART]
  if type(future_chapters) ~= "table" or
      #future_chapters ~= 1 or
      tonumber(future_chapters[1]) ~= CHAPTER_ID then
    plot_type.chapter_list2[FUTURE_PART] = { CHAPTER_ID }
    changed = true
  end
  if plot_type.plot_enter_name[FUTURE_PART] ~= FUTURE_PART_NAME then
    plot_type.plot_enter_name[FUTURE_PART] = FUTURE_PART_NAME
    changed = true
  end

  local future_background = plot_type.image_bg[2] or plot_type.image_bg[1]
  if future_background ~= nil and plot_type.image_bg[FUTURE_PART] ~= future_background then
    plot_type.image_bg[FUTURE_PART] = future_background
    changed = true
  end

  if changed then
    mod.info("added main-story part " .. tostring(FUTURE_PART) .. ": " .. FUTURE_PART_NAME)
  end
  return plot_type
end

local function patch_config_manager(manager)
  if config_patched or type(manager) ~= "table" then
    return
  end
  local original_get_data = manager.GetData
  local original_get_data_by_id = manager.GetDataById
  if type(original_get_data) ~= "function" or type(original_get_data_by_id) ~= "function" then
    error("configManager API is unavailable")
  end

  manager.GetData = function(name, ...)
    local data = original_get_data(name, ...)
    if name == "config_chapter" then
      ensure_placeholder(data)
    elseif name == "config_chapter_plot_type" and type(data) == "table" then
      ensure_future_part(data[MAIN_PLOT_TYPE])
    end
    return data
  end

  manager.GetDataById = function(name, id, ...)
    local numeric_id = tonumber(id)
    if name == "config_chapter" and numeric_id == CHAPTER_ID then
      local chapters = manager.GetData("config_chapter")
      return chapters and chapters[CHAPTER_ID] or nil
    end
    local data = original_get_data_by_id(name, id, ...)
    if name == "config_chapter_plot_type" and numeric_id == MAIN_PLOT_TYPE then
      ensure_future_part(data)
    end
    return data
  end

  config_patched = true
  mod.info("configManager hooks installed")
end

local function patch_copy_logic(copy_logic)
  if copy_logic_patched or type(copy_logic) ~= "table" then
    return
  end
  local original_check_lock = copy_logic.CheckPlotChapterLock
  local original_check_item_lock = copy_logic.CheckPlotChapterItemLock
  local original_get_all = copy_logic.GetAllPlotChapterInfoById
  if type(original_check_lock) ~= "function" or
      type(original_check_item_lock) ~= "function" or
      type(original_get_all) ~= "function" then
    error("CopyLogic API is unavailable")
  end

  copy_logic.CheckPlotChapterLock = function(self, chapter_id, ...)
    if tonumber(chapter_id) == CHAPTER_ID then
      return true, 0
    end
    return original_check_lock(self, chapter_id, ...)
  end

  copy_logic.CheckPlotChapterItemLock = function(self, chapter_id, ...)
    if tonumber(chapter_id) == CHAPTER_ID then
      return true
    end
    return original_check_item_lock(self, chapter_id, ...)
  end

  -- PlotCopyMainPage treats an empty level list as a completed chapter. Keep
  -- the placeholder out of its completion counter while still displaying it
  -- in PlotCopyPage through config_chapter_plot_type.chapter_list2.
  copy_logic.GetAllPlotChapterInfoById = function(self, plot_type, ...)
    local chapters = original_get_all(self, plot_type, ...)
    if tonumber(plot_type) == MAIN_PLOT_TYPE and type(chapters) == "table" then
      for index = #chapters, 1, -1 do
        if tonumber(chapters[index].id) == CHAPTER_ID then
          table.remove(chapters, index)
        end
      end
    end
    return chapters
  end

  copy_logic_patched = true
  mod.info("CopyLogic empty-chapter guards installed")
end

local function watch_logic_table(logic)
  if type(logic) ~= "table" then
    return
  end
  if type(rawget(logic, "copyLogic")) == "table" then
    patch_copy_logic(rawget(logic, "copyLogic"))
    return
  end

  local meta = getmetatable(logic) or {}
  local previous_newindex = meta.__newindex
  meta.__newindex = function(target, key, value)
    assign_with_previous(previous_newindex, target, key, value)
    if key == "copyLogic" then
      meta.__newindex = previous_newindex
      safely("CopyLogic hook", patch_copy_logic, value)
    end
  end
  setmetatable(logic, meta)
end

local function install_when_globals_are_ready()
  local handlers = {
    configManager = patch_config_manager,
    Logic = watch_logic_table
  }

  local current_config_manager = rawget(_G, "configManager")
  if current_config_manager ~= nil then
    safely("configManager hook", patch_config_manager, current_config_manager)
    handlers.configManager = nil
  end
  local current_logic = rawget(_G, "Logic")
  if current_logic ~= nil then
    safely("Logic hook", watch_logic_table, current_logic)
    handlers.Logic = nil
  end
  if next(handlers) == nil then
    return
  end

  local meta = getmetatable(_G) or {}
  local previous_newindex = meta.__newindex
  meta.__newindex = function(target, key, value)
    assign_with_previous(previous_newindex, target, key, value)
    local handler = handlers[key]
    if handler ~= nil then
      handlers[key] = nil
      safely(tostring(key) .. " hook", handler, value)
      if next(handlers) == nil then
        meta.__newindex = previous_newindex
      end
    end
  end
  setmetatable(_G, meta)
  mod.info("waiting for game configuration globals")
end

function on_bootstrap()
  install_when_globals_are_ready()
end
