CSharpToLuaFunction = {}

function CSharpToLuaFunction.LoginLogic_CheckUserKick()
  return Logic.loginLogic:CheckUserKick()
end

function CSharpToLuaFunction.SettlementLogic_TestStart(CB, enemyDictId, copyId)
  Logic.settlementLogic.TestStart(CB, enemyDictId, copyId)
end

function CSharpToLuaFunction.DropRewardsHelper_DropGoods(goodsTab)
  DropRewardsHelper.DropGoods(goodsTab)
end

function CSharpToLuaFunction.DropRewardsHelper_DropGirls(girlsTab)
  DropRewardsHelper.DropGirls(girlsTab)
end

function CSharpToLuaFunction.UserData_GetUserUid()
  return Data.userData:GetUserUid()
end

function CSharpToLuaFunction.HomeEnvManager_GetHomeScenePath()
  return homeEnvManager:GetHomeScenePath()
end

function CSharpToLuaFunction.PlotManager_OpenPlotByType(type, param)
  plotManager:OpenPlotByType(type, param)
end

function CSharpToLuaFunction.BuildShipLogic_GetCardQuality()
  return Logic.buildShipLogic:GetCardQuality()
end

function CSharpToLuaFunction.IsInGuide()
  return GR.guideHub:isInGuideBattle()
end

function CSharpToLuaFunction.ShowGuidePausePage()
  return GR.guideHub:ShowGuidePausePage()
end

function CSharpToLuaFunction.GetSkipVcr()
  return Data.illustrateData:GetSkipVcr()
end

function CSharpToLuaFunction.GetQucikConditions(copyId, SafeLv)
  local QucikConditions
  QucikConditions = Logic.setLogic:GenSetCondition(copyId, SafeLv)
  return QucikConditions
end

function CSharpToLuaFunction.PlotManager_OpenPlotPage(triggerID)
  plotManager:ClearHistory()
  plotManager:OpenPlotPage(triggerID)
end

function CSharpToLuaFunction.PlotManager_PlaySection(plotID)
  Logic.plotMaker:PlaySection(plotID)
end

function CSharpToLuaFunction.PlotManager_PlayStep(plot_step_ID)
  Logic.plotMaker:PlayStep(plot_step_ID)
end

function CSharpToLuaFunction.PlotManager_PlayTrigger(plotTriggerId)
  Logic.plotMaker:PlayTrigger(plotTriggerId)
end

function CSharpToLuaFunction.PlotManager_PlayMultiStep(steps)
  Logic.plotMaker:PlayMultiStep(steps)
end

function CSharpToLuaFunction.PlotManage_OpenEditorMode()
  plotManager.EditorMode = true
end

function CSharpToLuaFunction.WritePlotLuaMemory(plotData)
  Logic.plotSyncLogic:Write(plotData)
end

function CSharpToLuaFunction.CoverPlotLuaMemory(plotData)
  Logic.plotSyncLogic:Cover(plotData)
end

function CSharpToLuaFunction.DeletePlotLuaMemory(plotData)
  Logic.plotSyncLogic:Delete(plotData)
end

function CSharpToLuaFunction.FixedPointTest(strKey, strValue)
  Service.guideService:SendUserSetting({
    {Key = strKey, Value = strValue}
  })
end

function CSharpToLuaFunction.GuideHubClear()
  GR.guideHub:clearGuide()
end

function CSharpToLuaFunction.PlotMuteEffect(yes)
  plotManager.MuteEffect = yes
end

function CSharpToLuaFunction.PlotMuteCV(yes)
  plotManager.MuteCV = yes
end

function CSharpToLuaFunction.PlotMuteBackgroundMusic(yes)
  plotManager.MuteBackgroundMusic = yes
end

function CSharpToLuaFunction.PlotMuteExchangedMusic(yes)
  plotManager.MuteExchangedMusic = yes
end

function CSharpToLuaFunction.GetUsesOpeElementHighLightPath(nId)
  if GR.guideHub == nil then
    return ""
  end
  local tblElement = GR.guideHub:getUserOpeElementConfig(nId)
  if tblElement == nil then
    return ""
  end
  return tblElement.highLightPath
end

function CSharpToLuaFunction.OnPveNetOver(speedParam)
  local objRet = speedParam.ret
  local nRet = objRet.Ret
  local bCheat = nRet ~= 0
  local battlePlayer
  if objRet.BattlePlayer ~= nil and 0 < objRet.BattlePlayer.BattlePlayerList.Count then
    battlePlayer = objRet.BattlePlayer.BattlePlayerList[0]
  else
  end
  if bCheat then
    local bSpeedCheck = nRet == 1
    local text, content
    if nRet == 1 then
      text = UIHelper.GetString(400004)
      content = UIHelper.GetString(110032)
    elseif nRet == 2 then
      text = UIHelper.GetString(400004)
      content = UIHelper.GetString(420014)
    elseif nRet == 3 then
      text = UIHelper.GetString(400004)
      content = UIHelper.GetString(420018)
    elseif nRet == 4 then
      text = UIHelper.GetString(400004)
      content = UIHelper.GetString(420018)
    elseif nRet == 5 then
      text = UIHelper.GetString(400004)
      content = UIHelper.GetString(110032)
    end
    local tblParam = {
      msgType = NoticeType.OneButton,
      callback = function(bOk)
        if nRet == 5 then
          CS.Battle.Runtime.Env.display.pushMessage:D2LResult(battlePlayer)
        else
          CS.Battle.Runtime.Env.SetBattleFiledOver(true)
        end
      end
    }
    noticeManager:ShowMsgBox(content, tblParam, UILayer.ATTENTION)
  else
    CS.Battle.Runtime.Env.display.pushMessage:D2LResult(battlePlayer)
  end
end

function CSharpToLuaFunction.SetBuildingMode(mode)
  Logic.buildingLogic:SetMode(mode)
end

function CSharpToLuaFunction.GetHeroEffect()
  local x = Logic.equipLogic:SaveEquipEffect()
  logError("\230\181\139\232\175\149\229\138\160\231\154\132log\239\188\140\228\184\141\230\152\175bug==============", x)
  return Logic.equipLogic:SaveEquipEffect()
end

function CSharpToLuaFunction.SetPowerSavingPause(bPaused)
  GR.powerSavingManager:setIsPause(bPaused)
end

function CSharpToLuaFunction.PowerSavingResume()
  if GR.powerSavingManager ~= nil then
    GR.powerSavingManager:Resume()
  end
end

function CSharpToLuaFunction.SavePrefs()
  PlayerPrefs.Save()
  Data.prefsData:SaveAll()
end

function CSharpToLuaFunction.TestMapFinder()
  Logic.pathfinder:__TestFinder()
end

function CSharpToLuaFunction.GetSvrTime()
  return time.getSvrTime()
end
