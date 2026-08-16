local setmetatable = setmetatable
local UpdateBeat = UpdateBeat
local CoUpdateBeat = CoUpdateBeat
local Time = Time
Timer = {
  time = 0,
  duration = 1,
  loop = 1,
  running = false,
  scale = false,
  func = nil
}
local Timer = Timer
local mt = {}
mt.__index = Timer

function Timer.New(func, duration, loop, scale)
  local timer = {}
  scale = scale or false
  setmetatable(timer, mt)
  timer:Reset(func, duration, loop, scale)
  return timer
end

function Timer:Start()
  if not self.running then
    UpdateBeat:Add(self.Update, self)
  end
  self.running = true
end

function Timer:Reset(func, duration, loop, scale)
  if self.running then
    UpdateBeat:Remove(self.Update, self)
  end
  self.duration = duration
  self.loop = loop or 1
  self.scale = scale
  self.func = func
  self.time = duration
  self.running = false
  self.count = Time.frameCount + 1
end

function Timer:Stop()
  if self.running then
    UpdateBeat:Remove(self.Update, self)
  end
  self.running = false
end

function Timer:Pause()
  self.running = false
end

function Timer:Resume()
  self.running = true
end

function Timer:Update()
  if not self.running then
    return
  end
  local delta = self.scale and Time.unscaledDeltaTime or Time.deltaTime
  self.time = self.time - delta
  if self.time <= 0 and Time.frameCount > self.count then
    self.func()
    if 0 < self.loop then
      self.loop = self.loop - 1
      self.time = self.time + self.duration
    end
    if self.loop == 0 then
      self:Stop()
    elseif 0 > self.loop then
      self.time = self.time + self.duration
    end
  end
end

FrameTimer = {
  count = 1,
  duration = 1,
  loop = 1,
  func = nil,
  running = false
}
local FrameTimer = FrameTimer
local mt2 = {}
mt2.__index = FrameTimer

function FrameTimer.New(func, count, loop)
  local timer = {}
  setmetatable(timer, mt2)
  timer.count = Time.frameCount + count
  timer.duration = count
  timer.loop = loop
  timer.func = func
  return timer
end

function FrameTimer:Start()
  self.running = true
  CoUpdateBeat:Add(self.Update, self)
end

function FrameTimer:Stop()
  self.running = false
  CoUpdateBeat:Remove(self.Update, self)
end

function FrameTimer:Update()
  if not self.running then
    return
  end
  if Time.frameCount >= self.count then
    self.func()
    if self.loop > 0 then
      self.loop = self.loop - 1
    end
    if self.loop == 0 then
      self:Stop()
    else
      self.count = Time.frameCount + self.duration
    end
  end
end

CoTimer = {
  time = 0,
  duration = 1,
  loop = 1,
  running = false,
  func = nil
}
local CoTimer = CoTimer
local mt3 = {}
mt3.__index = CoTimer

function CoTimer.New(func, duration, loop)
  local timer = {}
  setmetatable(timer, mt3)
  timer:Reset(func, duration, loop)
  return timer
end

function CoTimer:Start()
  self.running = true
  self.count = Time.frameCount + 1
  CoUpdateBeat:Add(self.Update, self)
end

function CoTimer:Reset(func, duration, loop)
  self.duration = duration
  self.loop = loop or 1
  self.func = func
  self.time = duration
  self.running = false
  self.count = Time.frameCount + 1
end

function CoTimer:Stop()
  self.running = false
  CoUpdateBeat:Remove(self.Update, self)
end

function CoTimer:Update()
  if not self.running then
    return
  end
  if self.time <= 0 and Time.frameCount > self.count then
    self.func()
    if 0 < self.loop then
      self.loop = self.loop - 1
      self.time = self.time + self.duration
    end
    if self.loop == 0 then
      self:Stop()
    elseif 0 > self.loop then
      self.time = self.time + self.duration
    end
  end
  self.time = self.time - Time.deltaTime
end

CustomTimer = {
  time = 0,
  running = false,
  scale = false,
  func = nil
}
local CustomTimer = CustomTimer
local mt4 = {}
mt4.__index = CustomTimer

function CustomTimer.New(func, scale)
  local timer = {}
  scale = scale or false
  setmetatable(timer, mt4)
  timer:Reset(func, duration, loop, scale)
  return timer
end

function CustomTimer:Start()
  if not self.running then
    UpdateBeat:Add(self.Update, self)
  end
  self.running = true
end

function CustomTimer:Reset(func, duration, loop, scale)
  if self.running then
    UpdateBeat:Remove(self.Update, self)
  end
  self.scale = scale
  self.func = func
  self.running = false
  self.count = Time.frameCount + 1
end

function CustomTimer:Stop()
  if self.running then
    UpdateBeat:Remove(self.Update, self)
  end
  self.running = false
end

function CustomTimer:Update()
  if not self.running then
    return
  end
  local delta = self.scale and Time.unscaledDeltaTime or Time.deltaTime
  self.func(delta)
end
