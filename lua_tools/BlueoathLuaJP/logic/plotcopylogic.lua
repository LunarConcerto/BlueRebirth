local PlotCopyLogic = class("logic.PlotCopyLogic")

function PlotCopyLogic:initialize()
  self:ResetData()
end

function PlotCopyLogic:ResetData()
  self.m_classId = 0
  self.m_partId = 1
  self.copyBgPos = {}
  self.copyCardPos = {}
  self.m_CPMap = {}
  self.nSelectedPart = {}
  self.nSelectedChapter = {}
end

function PlotCopyLogic:LoadChapterPlotTypeConfigData()
  local data = clone(configManager.GetData("config_chapter_plot_type"))
  return data
end

function PlotCopyLogic:LoadChapterPlotPartTypeConfigData(classId)
  local data = clone(configManager.GetDataById("config_chapter_plot_type", classId))
  return data.chapter_list2
end

function PlotCopyLogic:GetSelectChapterID()
  return self.copyCardPos
end

function PlotCopyLogic:SetSelectChapterID(Index)
  self.copyCardPos = Index
end

function PlotCopyLogic:SetPlotCID(classId)
  self.m_classId = classId
end

function PlotCopyLogic:GetPlotCID()
  return self.m_classId
end

function PlotCopyLogic:SetPlotPartID(classId, partId)
  self.nSelectedPart[classId] = partId
end

function PlotCopyLogic:GetPlotPartID(classId)
  return self.nSelectedPart[classId] or 1
end

function PlotCopyLogic:SetSelectChapterr(classid, partid, index)
  self.nSelectedChapter[classid][partid] = index
end

function PlotCopyLogic:GetSelectChapterr(classid, partid)
  local nnil = self.nSelectedChapter[classid] == nil or self.nSelectedChapter[classid][partid] == nil
  if self.nSelectedChapter[classid] == nil then
    self.nSelectedChapter[classid] = {}
  end
  if self.nSelectedChapter[classid][partid] == nil then
    self.nSelectedChapter[classid][partid] = 1
  end
  return self.nSelectedChapter[classid][partid]
end

return PlotCopyLogic
