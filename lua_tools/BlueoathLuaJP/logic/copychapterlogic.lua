local CopyChapterLogic = class("logic.CopyChapterLogic")

function CopyChapterLogic:initialize()
end

function CopyChapterLogic:CheckAllByChapterId(chapterId, isShowTip)
  if not self:CheckPeriodByChapter(chapterId, isShowTip) then
    return false
  end
  if not self:CheckCopyByChapter(chapterId, isShowTip) then
    return false
  end
  local chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  local chapterType = chapterConfig.class_type
  if not self:CheckCopyByChapterType(chapterType, isShowTip) then
    return false
  end
  if not self:CheckPeriodByChapterType(chapterType, isShowTip) then
    return false
  end
  return true
end

function CopyChapterLogic:IsOpenByChapter(chapterId, isShowTip)
  return self:CheckPeriodByChapter(chapterId, isShowTip), self:CheckCopyByChapter(chapterId, isShowTip)
end

function CopyChapterLogic:CheckCopyByChapter(chapterId, isShowTip)
  local tabActChapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  local copyId = tabActChapterConfig.chapter_open
  local conditionCopy = true
  if 0 < copyId then
    conditionCopy = Logic.copyLogic:IsCopyPassById(copyId)
  end
  if not conditionCopy and isShowTip then
    local fullName = Logic.copyLogic:GetFullNameById(copyId)
    noticeManager:ShowTipById(410017, fullName)
  end
  return conditionCopy
end

function CopyChapterLogic:CheckPeriodByChapter(chapterId, isShowTip)
  local tabActChapterConfig = Logic.copyLogic:GetChaperConfById(chapterId)
  local periodId = tabActChapterConfig.chapter_period
  local conditionPeriod = true
  if 0 < periodId then
    conditionPeriod = PeriodManager:IsInPeriodArea(periodId, tabActChapterConfig.chapter_periodarea)
  end
  if not conditionPeriod and isShowTip then
    noticeManager:ShowTipById(270022)
  end
  return conditionPeriod
end

function CopyChapterLogic:IsOpenByChapterType(chapterType, isShowTip)
  if not self:CheckCopyByChapterType(chapterType, isShowTip) then
    return false
  end
  if not self:CheckPeriodByChapterType(chapterType, isShowTip) then
    return false
  end
  return true
end

function CopyChapterLogic:CheckCopyByChapterType(chapterType, isShowTip)
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  local copyId = chapterTypeConfig.open_copydisplay
  local conditionCopy = true
  if 0 < copyId then
    conditionCopy = Logic.copyLogic:IsCopyPassById(copyId)
  end
  if not conditionCopy and isShowTip then
    local fullName = Logic.copyLogic:GetFullNameById(copyId)
    noticeManager:ShowTipById(1001001, fullName)
  end
  return conditionCopy
end

function CopyChapterLogic:CheckPeriodByChapterType(chapterType, isShowTip)
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  local periodId = chapterTypeConfig.period_id
  local conditionPeriod = true
  if 0 < periodId then
    conditionPeriod = PeriodManager:IsInPeriodArea(periodId, chapterTypeConfig.period_area)
  end
  if not conditionPeriod and isShowTip then
    noticeManager:ShowTipById(270022)
  end
  return conditionPeriod
end

function CopyChapterLogic:IsExCopyId(chapterType, copyId)
  local chapterTypeConfig = configManager.GetDataById("config_chapter_type", chapterType)
  for i, v in ipairs(chapterTypeConfig.ex_ids) do
    if v == copyId then
      return true
    end
  end
  return false
end

return CopyChapterLogic
