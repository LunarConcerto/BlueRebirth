local GuideTriggerBase = class("game.guide.guideTrigger.GuideTriggerBase")

function GuideTriggerBase:startTrigger(param)
  self.objParam = param
  self:onStart(param)
end

function GuideTriggerBase:onStart(param)
end

function GuideTriggerBase:tick()
end

function GuideTriggerBase:endTrigger()
  self:onEnd()
end

function GuideTriggerBase:onEnd()
end

function GuideTriggerBase:sendTrigger()
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, {
    self.type,
    self.objParam
  })
end

return GuideTriggerBase
