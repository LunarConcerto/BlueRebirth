local GoodsCopyLogic = class("logic.GoodsCopyLogic")

function GoodsCopyLogic:initialize()
  self:ResetData()
end

function GoodsCopyLogic:ResetData()
end

function GoodsCopyLogic:IsGoodsCopyLogic(copyId)
  local chapter = Logic.copyLogic:GetChapterByCopyId(copyId)
  if chapter and chapter.class_type == ChapterType.GoodsCopy then
    return true
  end
  return false
end

function GoodsCopyLogic:GetCurCopyId()
  if self.curCopyId == nil then
    local copyList = self:GetGoodsCopyIdList()
    local userId = Data.userData:GetUserUid()
    local copyId = PlayerPrefs.GetString(string.format("gdscpy%s", userId), nil)
    if copyId == nil or copyId == "" then
      copyId = copyList[1]
      PlayerPrefs.SetString(string.format("gdscpy%s", userId), self.curCopyId)
    end
    if type(copyId) == "string" then
      copyId = tonumber(copyId, 10)
    end
    self.curCopyId = copyId
  end
  return self.curCopyId
end

function GoodsCopyLogic:SetGoodsCopyId(copyId)
  if copyId ~= self.curCopyId then
    self.curCopyId = copyId
    local userId = Data.userData:GetUserUid()
    PlayerPrefs.SetString(string.format("gdscpy%s", userId), self.curCopyId)
  end
end

function GoodsCopyLogic:GetCfgByRank(percent)
  local cfg = configManager.GetData("config_challenge_reward")
  local all = {}
  for k, v in pairs(cfg) do
    table.insert(all, v)
  end
  table.sort(all, function(l, r)
    return l.id > r.id
  end)
  if percent == nil or percent == -1 then
    return nil, all[1]
  end
  local curCfg, nextCfg
  for k, v in ipairs(all) do
    if percent >= v.p1 and percent <= v.p2 then
      curCfg = v
    end
    if percent > v.p2 then
      nextCfg = v
      break
    end
  end
  return curCfg, nextCfg
end

function GoodsCopyLogic:GetGoodsCopyId()
  local chapterId = configManager.GetDataById("config_parameter", 174).value
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  local copyId = chapter.level_list[1]
  return copyId
end

function GoodsCopyLogic:GetRemainTime()
  local data = Data.goodsCopyData:GetRankData()
  local nextRefresh = PeriodManager:GetNextRefreshTime(1)
  local now = time.getSvrTime()
  return nextRefresh - now
end

function GoodsCopyLogic:GetRankPercent()
  local data = Data.goodsCopyData:GetRankData()
  local percent = -1
  if data.Percent then
    percent = data.Percent
  end
  return percent
end

function GoodsCopyLogic:GetGoodsCopyDamages()
  local damageData = {}
  local chapterId = configManager.GetDataById("config_parameter", 174).value
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  for i, copyId in ipairs(chapter.level_list) do
    local data = Data.goodsCopyData:GetDataByCopyId(copyId)
    table.insert(damageData, data)
  end
  return damageData
end

function GoodsCopyLogic:GetGoodsCopyIdList()
  local chapterId = configManager.GetDataById("config_parameter", 174).value
  local chapter = configManager.GetDataById("config_chapter", chapterId)
  return chapter.level_list
end

return GoodsCopyLogic
