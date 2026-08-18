local CSharpBuildingLogic = class("logic.CSharpBuildingLogic")

function CSharpBuildingLogic:initialize()
  self:RegisterAllEvent()
end

function CSharpBuildingLogic:RegisterAllEvent()
  eventManager:RegisterEvent(LuaCSharpEvent.BaseBuildingPlotOver, self.RecordPlayedPlot, self)
  eventManager:RegisterEvent(LuaCSharpEvent.BaseBuildingCommon, self.CommonHandler, self)
end

function CSharpBuildingLogic:RecordPlayedPlot(args)
  Service.buildingService:TriggerPlot(args.buildingId, args.heroId, args.storyId)
end

function CSharpBuildingLogic:CommonHandler(args)
end

return CSharpBuildingLogic
