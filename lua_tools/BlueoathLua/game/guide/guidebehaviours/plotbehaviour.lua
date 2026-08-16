local PlotBehaviour = class("game.Guide.guidebehaviours.PlotBehaviour", GR.requires.BehaviourBase)

function PlotBehaviour:doBehaviour()
  plotManager:OpenPlotPage(self.objParam)
  self:onDone()
end

return PlotBehaviour
