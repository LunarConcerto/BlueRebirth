local EnterNormalCopy = class("game.Guide.guidebehaviours.EnterNormalCopy", GR.requires.BehaviourBase)

function EnterNormalCopy:doBehaviour()
  local tblParam = self.objParam
  local nChapterId = tblParam[1]
  local nCopyId = tblParam[2]
  GR.PVETestCopyHelper:StartCopy(nChapterId, nCopyId)
  self:onDone()
end

return EnterNormalCopy
