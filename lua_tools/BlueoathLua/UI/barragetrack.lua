local BarrageTrack = class("UI.BarrageTrack")
local BarrageText = require("ui.page.Barrage.BarrageText")

function BarrageTrack:Init(options)
  self.page = options.page
  self.part = options.part
  self.spacing = options.spacing or 20
  self.gameObject = self.part.gameObject
  local rightPos = self.part.right.localPosition
  local leftPos = self.part.left.localPosition
  local width = rightPos.x - leftPos.x
  self.speed = options.speed
  self.enabled = true
  self.queue = {}
  self.queueLength = 0
  self.textList = {}
  self.time = 0
  self.deltaTime = 0.1
  self.interval = options.delay and options.delay / 10000 or 0
  self:StartTimer()
end

function BarrageTrack:SetEnabled(enabled)
  self.enabled = enabled
end

function BarrageTrack:Append(options)
  if not self.enabled then
    return
  end
  self:Queue({
    page = self.page,
    parent = self.part,
    content = options.content,
    speed = self.speed,
    params = options.params,
    onDestroy = function(barrageText)
      self:OnBarrageTextDestroy(barrageText)
    end
  })
end

function BarrageTrack:AppendHead(options)
  local options = {
    page = self.page,
    parent = self.part,
    content = options.content,
    speed = self.speed,
    params = options.params,
    onDestroy = function(barrageText)
      self:OnBarrageTextDestroy(barrageText)
    end
  }
  table.insert(self.queue, 1, options)
  self.queueLength = self.queueLength + 1
end

function BarrageTrack:Queue(options)
  self.queueLength = self.queueLength + 1
  self.queue[self.queueLength] = options
end

function BarrageTrack:Dequeue()
  self.queueLength = self.queueLength - 1
  return table.remove(self.queue, 1)
end

function BarrageTrack:ClearQueue()
  self.queue = {}
  self.queueLength = 0
end

function BarrageTrack:StartTimer()
  self.timer = self.page:CreateTimer(function()
    self.time = self.time + self.deltaTime
    if self.time >= self.interval then
      self.time = self.time - self.interval
      self:ShowOne()
    end
  end, self.deltaTime, -1)
  self.page:StartTimer(self.timer)
end

function BarrageTrack:ResetTimer(interval)
  self.time = 0
  self.interval = interval
end

function BarrageTrack:MakeBarrageText()
  local barrage = BarrageText:new()
  table.insert(self.textList, barrage)
  return barrage
end

function BarrageTrack:OnBarrageTextDestroy(barrageText)
  for k, v in pairs(self.textList) do
    if v == barrageText then
      table[k] = nil
      break
    end
  end
end

function BarrageTrack:ClearBarrageList()
  for k, v in pairs(self.textList) do
    v:Destroy()
  end
  self.textList = {}
end

function BarrageTrack:ShowOne()
  if self.queueLength <= 0 then
    return
  end
  local options = self:Dequeue()
  local barrage = self:MakeBarrageText()
  barrage:Init(options)
  local width = barrage:GetWidth()
  local interval = (width + self.spacing) / self.speed
  self:ResetTimer(interval)
  CSUIHelper.SetParent(barrage.obj.transform, self.gameObject.transform)
  barrage:Move()
  eventManager:SendEvent(LuaEvent.ShowOneBarrage)
end

function BarrageTrack:StopTimer()
  self.page:StopTimer(self.timer)
end

function BarrageTrack:Destroy()
  self:ClearQueue()
  self:ClearBarrageList()
  self.page = nil
  self.gameObject = nil
  self.queue = nil
  self.part = nil
end

return BarrageTrack
