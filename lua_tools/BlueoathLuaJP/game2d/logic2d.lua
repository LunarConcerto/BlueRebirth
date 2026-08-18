local logic2d = class("game2d.logic2d")

function logic2d:initialize()
  self.scoreMap = {}
  self.gameId = 0
  self.chapterId = 1
end

function logic2d:ResetScoreMap()
  self.scoreMap = {}
end

function logic2d:GetScoreSum()
  local sum = 0
  for i, v in ipairs(self.scoreMap) do
    sum = sum + v.Score
  end
  return sum
end

function logic2d:GetScoreTbl()
  return self.scoreMap
end

function logic2d:SetScoreById(id, score)
  local sub = {}
  sub.CopyId = id
  sub.Score = score
  table.insert(self.scoreMap, sub)
end

function logic2d:SetGameId(id)
  self.gameId = id
end

function logic2d:GetGameId()
  return self.gameId
end

function logic2d:SetChapterId(id)
  self.chapterId = id
end

function logic2d:GetChapterId()
  return self.chapterId
end

function logic2d:GetSceneStr(gameId)
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  return config.scenes
end

function logic2d:IsCollision(r1, r2)
  return not (r1.x1 > r2.x2) and not (r1.y1 > r2.y2) and not (r2.x1 > r1.x2) and not (r2.y1 > r1.y2)
end

function logic2d:IsInsideRect(px, py, lbx, lby, rtx, rty)
  return not (rtx < px) and not (rty < py) and not (px < lbx) and not (py < lby)
end

function logic2d:SetRect(x1, x2, y1, y2)
  local result = {}
  result.x1 = x1
  result.x2 = x2
  result.y1 = y1
  result.y2 = y2
  return result
end

function logic2d:SelectNumber(count, ...)
  local arg = {
    ...
  }
  local selected = {}
  math.random(0, #arg)
  math.randomseed(os.time())
  if count >= #arg then
    return arg
  end
  while count > #selected do
    math.random(#arg)
    table.insert(selected, table.remove(arg, math.random(#arg)))
  end
  return selected
end

return logic2d
