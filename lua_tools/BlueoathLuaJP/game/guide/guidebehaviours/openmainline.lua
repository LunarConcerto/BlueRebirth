local OpenMainLine = class("game.Guide.guidebehaviours.OpenMainLine", GR.requires.BehaviourBase)

function OpenMainLine:doBehaviour()
  UIHelper.OpenPage("MainLineCopyPage")
  self:onDone()
end

return OpenMainLine
