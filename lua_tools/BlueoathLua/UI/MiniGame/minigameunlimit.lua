local MiniGameUnLimit = class("UI.MiniGame.MiniGameUnLimit")

function MiniGameUnLimit:DoOnOpen(page)
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
    callback()
  end
  local widgets = page:GetWidgets()
  widgets.btn_next_gm.gameObject:SetActive(isEditor)
  widgets.im_copy:SetActive(true)
  local gameId = self:GetGameId()
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  UIHelper.SetLocText(widgets.tx_copy, 4100025, config.copy_order)
end

function MiniGameUnLimit:GetGameId(page)
  return Logic2d:GetGameId()
end

function MiniGameUnLimit:GetScore(page)
  Service.userService:GetMiniGameScore({
    ChapterId = page.chapterId
  })
end

function MiniGameUnLimit:InitParam(page)
  if page.start == true then
    local params = page:GetParam() or {}
    page.chapterId = params.chapterId
    Logic2d:SetGameId(params.gameId)
  end
end

function MiniGameUnLimit:GameOver2d(page)
  local widgets = page:GetWidgets()
  GlobalGameState2d = GameState2d.Stop
  widgets.obj_gameover:SetActive(true)
  SoundManager.Instance:PlayMusic("System|Mini_Game_Lose")
  local timer = Timer.New(function()
    widgets.obj_gameover:SetActive(false)
    UIHelper.OpenPage("MiniGameScorePage", {
      copyId = page.copyId,
      isSuccess = false,
      battleMode = page.battleMode,
      typ = Game2dPlayType.UnLimit,
      gameId = page.gameId,
      chapterId = page.chapterId
    })
  end, TimeConfig2d.Fail, 1, false)
  timer:Start()
end

function MiniGameUnLimit:Success2d(page)
  local widgets = page:GetWidgets()
  GlobalGameState2d = GameState2d.Stop
  widgets.obj_success:SetActive(true)
  SoundManager.Instance:PlayMusic("System|Mini_Game_Win")
  local timer = Timer.New(function()
    widgets.obj_success:SetActive(false)
    UIHelper.OpenPage("MiniGameScorePage", {
      copyId = page.copyId,
      isSuccess = true,
      battleMode = page.battleMode,
      typ = Game2dPlayType.UnLimit,
      gameId = page.gameId,
      chapterId = page.chapterId
    })
  end, TimeConfig2d.Success, 1, false)
  timer:Start()
end

return MiniGameUnLimit
