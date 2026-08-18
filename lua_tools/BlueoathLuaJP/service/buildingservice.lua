local BuildingService = class("servic.BuildingService", Service.BaseService)

function BuildingService:initialize()
  self:_InitHandlers()
  self.triggerPlotStamp = time.getSvrTime()
end

function BuildingService:_InitHandlers()
  self:BindEvent("building.AddBuilding", self._OnAddBuilding, self)
  self:BindEvent("building.UpdateBuildingInfo", self._UpdateBuildingInfo, self)
  self:BindEvent("building.UpgradeBuilding", self._OnUpBuilding, self)
  self:BindEvent("building.DegradeBuilding", self._OnDownBuilding, self)
  self:BindEvent("building.SetHero", self._OnSetBuildingHero, self)
  self:BindEvent("building.FinishBuilding", self._OnFinishBuilding, self)
  self:BindEvent("building.ReceiveBuilding", self._ReceiveBuilding, self)
  self:BindEvent("building.ProduceItem", self._ProduceItem, self)
  self:BindEvent("building.ComposeItem", self._ComposeItem, self)
  self:BindEvent("building.ReceiveItem", self._ReceiveItem, self)
  self:BindEvent("building.ReceiveAll", self._ReceiveAll, self)
  self:BindEvent("building.ReceiveResource", self._ReceiveResource, self)
  self:BindEvent("building.SetBuildingListHero", self._SetBuildingListHero, self)
  self:BindEvent("building.UpdateHeroAddition", self._UpdateHeroAddition, self)
  self:BindEvent("building.UseStrengthSpeedup", self._UseStrengthSpeedup, self)
  self:BindEvent("building.TriggerNormalHeroPlot", self._OnTriggerPlot, self)
  self:BindEvent("building.TriggerSpecialHeroPlot", self._OnTriggerPlot, self)
  self:BindEvent("building.SaveTactic", self._OnSaveTactic, self)
  self:BindEvent("building.SetTacticName", self._ChangeTacticName, self)
  self:BindEvent("building.RemoveTactic", self._RemoveTactic, self)
end

function BuildingService:AddBuilding(tid, index)
  local args = {Tid = tid, Index = index}
  args = dataChangeManager:LuaToPb(args, building_pb.TADDBUILDINGARG)
  self:SendNetEvent("building.AddBuilding", args)
end

function BuildingService:_OnAddBuilding(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TADDBUILDINGRET)
    self:SendLuaEvent(LuaEvent.BuildingFinish, result.BuildingId)
    self:SendLuaEvent(LuaEvent.BuildingEndAfter, state)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ReceiveBuilding(buildingId)
  local args = {BuildingId = buildingId}
  args = dataChangeManager:LuaToPb(args, building_pb.TRECEIVEBYBUILDINGARG)
  self:SendNetEvent("building.ReceiveBuilding", args)
end

function BuildingService:_ReceiveBuilding(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingReceiveResult, result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:SendUpBuilding(buildingId)
  local args = {BuildingId = buildingId}
  args = dataChangeManager:LuaToPb(args, building_pb.TUPGRADEBUILDINGARG)
  self:SendNetEvent("building.UpgradeBuilding", args, args)
end

function BuildingService:_OnUpBuilding(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.BuildingFinish, state.BuildingId)
  else
    logError("up building err:" .. err .. " errmsg:" .. errmsg)
  end
end

function BuildingService:SendDownBuilding(buildingId)
  local args = {BuildingId = buildingId}
  args = dataChangeManager:LuaToPb(args, building_pb.TUPGRADEBUILDINGARG)
  self:SendNetEvent("building.DegradeBuilding", args)
end

function BuildingService:_OnDownBuilding(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingReceiveResult, result)
  elseif err == 3409 then
    noticeManager:ShowTip(UIHelper.GetString(920000079))
  else
    logError("down building err:" .. err .. " errmsg:" .. errmsg)
  end
end

function BuildingService:SendSetHero(buildingId, heroIdList)
  local args = {BuildingId = buildingId, HeroIdList = heroIdList}
  args = dataChangeManager:LuaToPb(args, building_pb.TSETHEROARG)
  self:SendNetEvent("building.SetHero", args)
end

function BuildingService:_OnSetBuildingHero(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.UpdateBuildingHero)
  else
    logError("add building hero err:" .. err .. " errmsg:" .. errmsg)
  end
end

function BuildingService:SendSetBuildingListHero(buildingIdList, heroIdList)
  local args = {BuildingIdList = buildingIdList, HeroIdList = heroIdList}
  args = dataChangeManager:LuaToPb(args, building_pb.TSETBUILDINGLISTHEROARG)
  self:SendNetEvent("building.SetBuildingListHero", args)
end

function BuildingService:_SetBuildingListHero(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("set building list hero err:" .. err .. " errmsg:" .. errmsg)
  end
end

function BuildingService:FinishBuilding(buildingId)
  local args = {BuildingId = buildingId}
  args = dataChangeManager:LuaToPb(args, building_pb.TFINISHBUILDINGARG)
  self:SendNetEvent("building.FinishBuilding", args, buildingId)
end

function BuildingService:_OnFinishBuilding(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.BuildingFinish, state)
    self:SendLuaEvent(LuaEvent.BuildingEndAfter, state)
  else
    logError("_OnFinishBuilding err:" .. err)
  end
end

function BuildingService:ProduceItem(buildingId, recipeId, count)
  local args = {
    BuildingId = buildingId,
    RecipeId = recipeId,
    Count = count
  }
  args = dataChangeManager:LuaToPb(args, building_pb.TPRODUCEITEMARG)
  self:SendNetEvent("building.ProduceItem", args)
end

function BuildingService:_ProduceItem(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingProduceItem, result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ComposeItem(buildingId, recipeId, count)
  local args = {
    BuildingId = buildingId,
    RecipeId = recipeId,
    Count = count
  }
  args = dataChangeManager:LuaToPb(args, building_pb.TCOMPOSEITEMARG)
  self:SendNetEvent("building.ComposeItem", args)
end

function BuildingService:_ComposeItem(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent("Building2DDetailPage_ComposeItem", result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ReceiveItem(buildingId)
  local args = {BuildingId = buildingId}
  args = dataChangeManager:LuaToPb(args, building_pb.TRECEIVEBYBUILDINGARG)
  self:SendNetEvent("building.ReceiveItem", args)
end

function BuildingService:_ReceiveItem(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingReceiveResult, result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ReceiveAll()
  local args = dataChangeManager:LuaToPb(args, module_pb.TEMPTYARG)
  self:SendNetEvent("building.ReceiveAll", args)
end

function BuildingService:_ReceiveAll(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingReceiveResult, result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ReceiveResource(resourceId)
  local args = {ResourceId = resourceId}
  args = dataChangeManager:LuaToPb(args, building_pb.TRECEIVEBYRESOURCEARG)
  self:SendNetEvent("building.ReceiveResource", args)
end

function BuildingService:_ReceiveResource(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TRECEIVERET)
    self:SendLuaEvent(LuaEvent.BuildingReceiveResult, result)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:_UpdateBuildingInfo(ret, state, err, errmsg)
  if err == 0 then
    local buildingInfo = dataChangeManager:PbToLua(ret, building_pb.TUSERBUILDINGINFO)
    Data.buildingData:SetData(buildingInfo)
    self:SendLuaEvent(LuaEvent.BuildingRefreshData)
    if Logic.loginLogic:GetLoginOK() == true then
      local noticeParam = Logic.buildingLogic:GetPushNoticeParams(buildingInfo.BuildingInfos)
      self:SendLuaEvent(LuaEvent.PushNotice, noticeParam)
    end
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:UseStrengthSpeedup(buildingId, useCount)
  local args = {BuildingId = buildingId, UseCount = useCount}
  args = dataChangeManager:LuaToPb(args, building_pb.TUSESTRENGTHSPEEDUPARG)
  self:SendNetEvent("building.UseStrengthSpeedup", args)
end

function BuildingService:_UseStrengthSpeedup(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.SpeedupOk)
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:UpdateHeroAddition(buildingIdList)
  local args = {BuildingIdList = buildingIdList}
  args = dataChangeManager:LuaToPb(args, building_pb.TUPDATEHEROADDITIONARG)
  self:SendNetEvent("building.UpdateHeroAddition", args)
end

function BuildingService:_UpdateHeroAddition(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:TriggerPlot(buildingId, heroId, plotId)
  local now = time.getSvrTime()
  if now - self.triggerPlotStamp < 2 then
    return
  end
  self.triggerPlotStamp = now
  local plotCfg = configManager.GetDataById("config_building_character_story", plotId)
  local args = {
    BuildingId = buildingId,
    HeroId = heroId,
    PlotId = plotId
  }
  local pbArgs = dataChangeManager:LuaToPb(args, building_pb.TTRIGGERPLOTARG)
  if plotCfg.plot_trigger_type == HeroPlotType.Special then
    self:SendNetEvent("building.TriggerSpecialHeroPlot", pbArgs, args)
  else
    self:SendNetEvent("building.TriggerNormalHeroPlot", pbArgs, args)
  end
end

function BuildingService:_OnTriggerPlot(ret, state, err, errmsg)
  if err == 0 then
    local result = dataChangeManager:PbToLua(ret, building_pb.TTRIGGERPLOTRET)
    if result.AffectionAdd then
      Logic.buildingLogic:SetHeroAffection(state.HeroId, result.AffectionAdd, state.PlotId)
    end
    local plotCfg = configManager.GetDataById("config_building_character_story", state.PlotId)
    if plotCfg.plot_trigger_type == HeroPlotType.Special then
      Data.buildingData:RemoveSpecialPlot(state)
    else
      Data.buildingData:RemoveNormalPlot(state)
    end
  else
    logError("err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:SaveTactic(tacticList)
  local args = {TacticList = tacticList}
  args = dataChangeManager:LuaToPb(args, building_pb.TSAVEBUILDINGTACTICARG)
  self:SendNetEvent("building.SaveTactic", args)
end

function BuildingService:_OnSaveTactic(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.ChangeNameSuccess)
  else
    self:SendLuaEvent(LuaEvent.ChangeFleetNameError, err)
    logError("_OnSaveTactic err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:ChangeTacticName(buildingId, index, name)
  local args = {
    BuildingId = buildingId,
    Index = index,
    Name = name
  }
  args = dataChangeManager:LuaToPb(args, building_pb.TCHANGETACTICNAMEARG)
  self:SendNetEvent("building.SetTacticName", args)
end

function BuildingService:_ChangeTacticName(ret, state, err, errmsg)
  if err == 0 then
    self:SendLuaEvent(LuaEvent.ChangeNameSuccess)
  else
    self:SendLuaEvent(LuaEvent.ChangeFleetNameError, err)
    logError("_ChangeTacticName err: " .. err .. ", errmsg: " .. errmsg)
  end
end

function BuildingService:RemoveTactic(buildingId, index)
  local args = {BuildingId = buildingId, Index = index}
  args = dataChangeManager:LuaToPb(args, building_pb.TREMOVEBUILDINGTACTICARG)
  self:SendNetEvent("building.RemoveTactic", args)
end

function BuildingService:_RemoveTactic(ret, state, err, errmsg)
  if err == 0 then
  else
    logError("_RemoveTactic err: " .. err .. ", errmsg: " .. errmsg)
  end
end

return BuildingService
