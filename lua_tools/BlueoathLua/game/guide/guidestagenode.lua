local GuideStageNode = class("Game.Guide.GuideStageNode")

function GuideStageNode:initialize()
  self.mGuideState = nil
  self.nId = nil
end

function GuideStageNode:getNextNodeId()
end

function GuideStageNode:start()
end

function GuideStageNode:getRecallNodeId()
end

function GuideStageNode:getDoingParam()
  return self.nId
end

return GuideStageNode
