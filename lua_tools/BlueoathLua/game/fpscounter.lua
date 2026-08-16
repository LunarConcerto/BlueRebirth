local FPSCounter = class("game.FPSCounter")

function FPSCounter:initialize()
  self.lastValue = 0
  self.accumulate = 0
  self.previousFrameCount = 0
  self.fpsValue = 0
  self.interval = 0.1
  self.lastSendFPSTime = 0
end

function FPSCounter:start()
  if self.timer == nil then
    self.timer = Timer.New(function()
      self:_tick()
    end, 0.1, -1)
  end
  self.timer:Start()
end

function FPSCounter:stop()
  if self.timer ~= nil then
    self.timer:Stop()
  end
end

function FPSCounter:_tick()
  if self.accumulate > Time.unscaledTime then
    return
  end
  local lastTime = self.accumulate - self.interval
  local timeElapsed = Time.unscaledTime - lastTime
  local framesChanged = Time.frameCount - self.previousFrameCount
  self.fpsValue = Mathf.ToInt(framesChanged / timeElapsed)
  self.accumulate = Time.unscaledTime + self.interval
  self.previousFrameCount = Time.frameCount
  if Time.unscaledTime - self.lastSendFPSTime > 5 then
    self.lastSendFPSTime = Time.unscaledTime
    vivoSDKInterface:sendFPS(self.fpsValue)
  end
  if self.fpsValue < 10 then
    vivoSDKInterface:sendLowFPS()
  end
end

return FPSCounter
