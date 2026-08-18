local aiManager2d = class("game2d.aiManager2d")

function aiManager2d:InitData()
  self.aiMap = {}
end

function aiManager2d:SetAi(npc, id)
  local ai = require("game2d.ai2d.ai2d"):new(npc)
  self.aiMap[npc:GetId()] = ai
end

function aiManager2d:Destroy()
  for i, v in pairs(self.aiMap) do
    v:Destroy()
  end
  self.aiMap = nil
end

return aiManager2d
