local MubarCopyLogic = class("logic.MubarCopyLogic")

function MubarCopyLogic:initialize()
end

function MubarCopyLogic:ResetData()
  self.mubarSChpterIndex = 0
  self.selectChapter = false
end

function MubarCopyLogic:GetOpenChapter()
  local openChapterTab = {}
  local chapterInfo = Logic.copyLogic:GetMubarChapterConfig()
  for _, info in ipairs(chapterInfo) do
    for _, levelId in ipairs(info.level_list) do
      local copyInfo = Data.copyData:GetMubarCopyInfoById(levelId)
      if copyInfo ~= nil then
        table.insert(openChapterTab, info)
        break
      end
    end
  end
  return openChapterTab
end

function MubarCopyLogic:GetChapterProgress(chapterInfo)
  local openChapterTab = {}
  for _, levelId in ipairs(chapterInfo.level_list) do
    local copyInfo = Data.copyData:GetMubarCopyInfoById(levelId)
    if copyInfo ~= nil and copyInfo.FirstPassTime > 0 then
      table.insert(openChapterTab, levelId)
    end
  end
  return #chapterInfo.level_list, #openChapterTab
end

function MubarCopyLogic:SetMubarSChapterIndex(index)
  self.mubarSChpterIndex = index
end

function MubarCopyLogic:GetMubarSChapterIndex()
  return self.mubarSChpterIndex
end

function MubarCopyLogic:CheckCopyInChapter(chapterInfo, copyId)
  for _, v in ipairs(chapterInfo) do
    if v.id == copyId then
      return true
    end
  end
  return false
end

function MubarCopyLogic:SetSelectChapter(enable)
  if Logic.copyLogic:GetUserCurStatus() then
    return
  end
  self.selectChapter = enable
end

function MubarCopyLogic:GetSelectChapter()
  return self.selectChapter
end

return MubarCopyLogic
