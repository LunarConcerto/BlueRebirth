local MiniGameLimit = class("UI.MiniGame.MiniGameLimit")

function MiniGameLimit:DoOnOpen(page)
  if page.start then
    local params = page:GetParam() or {}
    local copyId = params.copyId
    page.copyId = copyId
    local battleMode = params.battleMode or BattleMode.Normal
    page.battleMode = battleMode
    local callback = function()
      local widgets = page:GetWidgets()
      widgets.obj_start:SetActive(true)
      SoundManager.Instance:PlayMusic("System|Mini_Game_Start")
      widgets.obj_gameover:SetActive(false)
      page.start = false
    end
    local triggerId = plotManager:GetTriggerId(PlotTriggerType.mini_game_2d_start, page.copyId)
    if triggerId then
      plotManager:OpenPlotByType(PlotTriggerType.mini_game_2d_start, page.copyId, page.battleMode, callback)
    else
      callback()
    end
  end
end

function MiniGameLimit:GetGameId(page)
  return self.gameId
end

function MiniGameLimit:GetScore(page)
end

function MiniGameLimit:InitParam(page)
  local params = page:GetParam() or {}
  local copyId = params.copyId
  local copyInfo = configManager.GetDataById("config_copy_display", copyId)
  self.gameId = copyInfo.minigame_id
end

function MiniGameLimit:GameOver2d(page)
  local widgets = page:GetWidgets()
  GlobalGameState2d = GameState2d.Stop
  widgets.obj_gameover:SetActive(true)
  SoundManager.Instance:PlayMusic("System|Mini_Game_Lose")
  local timer = Timer.New(function()
    UIHelper.OpenPage("MiniGameScorePage", {
      copyId = page.copyId,
      isSuccess = false,
      battleMode = page.battleMode
    })
    local triggerId = plotManager:GetTriggerId(PlotTriggerType.mini_game_2d_fail, page.copyId)
    if triggerId then
      plotManager:OpenPlotByType(PlotTriggerType.mini_game_2d_fail, page.copyId, page.battleMode)
    end
  end, TimeConfig2d.Fail, 1, false)
  timer:Start()
end

function MiniGameLimit:Success2d(page)
  local isPass = Logic.copyLogic:IsCopyPassById(page.copyId)
  Service.copyService:SendPassMiniGame({
    BaseId = page.copyId,
    IsFinishMission = true,
    BattleTime = GameManager2d:GetTime(),
    BattleType = page.battleMode
  })
  local widgets = page:GetWidgets()
  GlobalGameState2d = GameState2d.Stop
  widgets.obj_success:SetActive(true)
  SoundManager.Instance:PlayMusic("System|Mini_Game_Win")
  local timer = Timer.New(function()
    UIHelper.OpenPage("MiniGameScorePage", {
      copyId = page.copyId,
      isSuccess = true,
      battleMode = page.battleMode,
      firstPass = not isPass
    })
    local triggerId = plotManager:GetTriggerId(PlotTriggerType.mini_game_2d_success, page.copyId)
    if triggerId then
      plotManager:OpenPlotByType(PlotTriggerType.mini_game_2d_success, page.copyId, page.battleMode)
    end
  end, TimeConfig2d.Success, 1, false)
  timer:Start()
end

return MiniGameLimit
