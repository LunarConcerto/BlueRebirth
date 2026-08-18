local BarrageTextPool = class("BarrageTextPool")

function BarrageTextPool:Init(initSize, maxSize)
  self.objPool = {}
end

function BarrageTextPool:Expand()
end

function BarrageTextPool:Shrink()
end

return BarrageTextPool
