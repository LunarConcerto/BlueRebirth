local GuideUserPermit = class("game.Guide.Kits.GuideUserPermit")

function GuideUserPermit:initialize()
end

function GuideUserPermit:userPermit(objStage)
  local nId = objStage.nId
  local tblConfig = StageNeedUserPermit[nId]
  if tblConfig == nil then
    return false
  else
    self:doUserPermit(tblConfig, objStage)
    return true
  end
end

function GuideUserPermit:doUserPermit(tblConfig, objStage)
  local nLanguageId = tblConfig[1]
  local tblParam = {
    msgType = NoticeType.TwoButton,
    callback = function(bOk)
      if not bOk then
        self:__doSkip(objStage)
      else
        self:__doStart(objStage)
      end
    end
  }
  noticeManager:ShowMsgBox(nLanguageId, tblParam)
end

function GuideUserPermit:__doSkip(objStage)
  GR.guideManager:onGuideStageDone(objStage)
end

function GuideUserPermit:__doStart(objStage)
  objStage:doNormalStart()
end

return GuideUserPermit
