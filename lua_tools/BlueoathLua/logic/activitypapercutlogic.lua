local ActivityPaperCutLogic = class("logic.ActivityPaperCutLogic")
ACTIVITYPAPERCUT_CUTNUM = 5
CUT_ITEM_ID = {
  17010,
  17011,
  17012,
  17013,
  17014
}
PAPERCUT_ID = {
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34
}

function ActivityPaperCutLogic:initialize()
  self.mMaterials = {}
end

function ActivityPaperCutLogic:CheckFormula(formulaId)
  local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
  local materials = cfg.formula
  local cmap = {}
  for _, itemId in ipairs(materials) do
    local n = cmap[itemId] or 0
    local count = Data.bagData:GetItemNum(itemId)
    if n < count then
      cmap[itemId] = n + 1
    else
      return false
    end
  end
  return true
end

function ActivityPaperCutLogic:CheckMaterials()
  local materials = self.mMaterials or {}
  local ret = {}
  local cmap = {}
  for _, itemId in ipairs(materials) do
    local n = cmap[itemId] or 0
    local count = Data.bagData:GetItemNum(itemId)
    if n < count then
      cmap[itemId] = n + 1
      table.insert(ret, itemId)
    end
  end
  self.mMaterials = ret
end

function ActivityPaperCutLogic:SetMaterials(materias)
  local data = materias or {}
  self.mMaterials = data
end

function ActivityPaperCutLogic:GetMaterials()
  self:CheckMaterials()
  local materials = self.mMaterials or {}
  local ret = {}
  for _, itemId in ipairs(materials) do
    table.insert(ret, itemId)
  end
  return ret
end

function ActivityPaperCutLogic:GetShowMaterials()
  self:CheckMaterials()
  local materials = self.mMaterials or {}
  local ret = {}
  for i = 1, ACTIVITYPAPERCUT_CUTNUM do
    local itemId = materials[i] or 0
    table.insert(ret, itemId)
  end
  return ret
end

function ActivityPaperCutLogic:MakePaper()
  local materials = self.mMaterials or {}
  if #materials ~= ACTIVITYPAPERCUT_CUTNUM then
    noticeManager:ShowTipById(1300052)
    return
  end
  Service.activitypapercutService:SendMakePaperCut({Materials = materials})
end

function ActivityPaperCutLogic:GetCutList()
  local materials = self.mMaterials or {}
  local materialMap = {}
  for _, itemId in pairs(materials) do
    local count = materialMap[itemId] or 0
    materialMap[itemId] = count + 1
  end
  local cutlist = {}
  for _, itemId in ipairs(CUT_ITEM_ID) do
    local count = Data.bagData:GetItemNum(itemId)
    for i = 1, count do
      local data = {}
      data.ItemId = itemId
      data.IsSelect = false
      if materialMap[itemId] ~= nil and 0 < materialMap[itemId] then
        data.IsSelect = true
        materialMap[itemId] = materialMap[itemId] - 1
      end
      table.insert(cutlist, data)
    end
  end
  return cutlist
end

function ActivityPaperCutLogic:GetPaperCutFormulaInfo()
  local pcfinfo = {}
  local formulaList = Data.activitypapercutData:GetFormulaList()
  for _, formulaId in ipairs(formulaList) do
    local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
    local paperId = cfg.paper_cut
    local list = pcfinfo[paperId] or {}
    table.insert(list, formulaId)
    pcfinfo[paperId] = list
  end
  local sortFormulaList = function(list)
    local flist = {}
    for _, fid in ipairs(list) do
      local data = {}
      data.FormulaId = fid
      data.IsCanUse = self:CheckFormula(fid)
      table.insert(flist, data)
    end
    table.sort(flist, function(a, b)
      if a.IsCanUse ~= b.IsCanUse then
        return a.IsCanUse
      end
      if a.FormulaId ~= b.FormulaId then
        return a.FormulaId < b.FormulaId
      end
      return false
    end)
    local ret = {}
    for _, data in ipairs(flist) do
      table.insert(ret, data.FormulaId)
    end
    return ret
  end
  local retlist = {}
  for _, paperId in ipairs(PAPERCUT_ID) do
    local data = {}
    data.PaperId = paperId
    local list = pcfinfo[paperId] or {}
    data.FormulaList = sortFormulaList(list)
    data.Unlock = 0 < #list
    table.insert(retlist, data)
  end
  table.sort(retlist, function(a, b)
    if a.Unlock ~= b.Unlock then
      return a.Unlock
    end
    if a.PaperId ~= b.PaperId then
      return a.PaperId < b.PaperId
    end
    return false
  end)
  return retlist
end

return ActivityPaperCutLogic
