local bombManager2d = class("game2d.bombManager2d")

function bombManager2d:InitData(scene_root)
  self.bomb_root = scene_root:Find("Bomb")
  self.bombTal = {}
  self.bombPool = {}
  self.index = 1
end

function bombManager2d:CreateBomb()
  if #self.bombPool <= 0 then
    local bomb = require("game2d.bomb2d"):new(self.bomb_root, self.index)
    table.insert(self.bombTal, bomb)
    self.index = self.index + 1
  else
    local bomb = self.bombPool[1]
    bomb.bomb:SetActive(true)
    table.remove(self.bombPool, 1)
    table.insert(self.bombTal, bomb)
    bomb:InitData()
  end
end

function bombManager2d:DestroyBomb(id)
  local bomb
  for i, v in ipairs(self.bombTal) do
    if v.id == id then
      bomb = v
      table.remove(self.bombTal, i)
    end
  end
  table.insert(self.bombPool, bomb)
end

function bombManager2d:Destroy()
  self.bomb_root = nil
  for i, v in ipairs(self.bombTal) do
    v:Destroy()
  end
  for i, v in ipairs(self.bombPool) do
    v:Destroy()
  end
  self.bombTal = {}
  self.bombPool = {}
end

return bombManager2d
