local EmptyTrigger = class("game.guide.guideTrigger.EmptyTrigger", GR.requires.GuideTriggerBase)

function EmptyTrigger:initialize(nType)
end

function EmptyTrigger:tick()
end

return EmptyTrigger
