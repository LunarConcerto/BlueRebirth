local GuideBranch = class("Game.Guide.GuideBranch", require("Game.Guide.GuideStageNode"))
local super = GuideBranch.super

function GuideBranch:initialize(config, objGuideStage)
  self.tabConditions = config.condition
  self.tblConfig = config
  self.nId = config.id
  self.objGuideStage = objGuideStage
end

function GuideBranch:init()
end

function GuideBranch:start()
  self.objGuideStage:onNodeDone(self)
end

function GuideBranch:getRecallNodeId()
  return self.tblConfig.recallNodeId
end

function GuideBranch:getNextNodeId()
  local nCount = #self.tabConditions
  for i = 1, nCount do
    local tabCondition = self.tabConditions[i]
    local bCanDo = GR.guideHub:ismeetOneCondition(tabCondition[1])
    if bCanDo then
      return tabCondition[2]
    end
  end
end

function GuideBranch:checkJump()
  local tblJumpCondition = self.tblConfig.jumpCondition
  if tblJumpCondition == nil then
    return false
  else
    local nConditionId = tblJumpCondition[1]
    local objParam = tblJumpCondition[2]
    local bOpposite = tblJumpCondition[3]
    local bJump = GR.guideHub:ismeetOneCondition(nConditionId, objParam, bOpposite)
    return bJump
  end
end

function GuideBranch:getCurStep()
  return nil
end

return GuideBranch
