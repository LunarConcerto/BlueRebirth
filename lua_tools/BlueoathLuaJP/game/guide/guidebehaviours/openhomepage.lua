local OpenHomePage = class("game.Guide.Guidebehaviours.OpenHomePage", GR.requires.BehaviourBase)

function OpenHomePage:doBehaviour()
  UIHelper.OpenPage("HomePage")
  self:onDone()
end

return OpenHomePage
