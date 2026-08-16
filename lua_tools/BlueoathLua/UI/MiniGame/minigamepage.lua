local MiniGamePage = class("UI.MiniGame.MiniGamePage", LuaUIPage)

function MiniGamePage:DoInit()
  self.start = true
  Logic2d:ResetScoreMap()
end

function MiniGamePage:DoOnOpen()
  self:SetProcess()
  self.process:InitParam(self)
  self.process:GetScore(self)
  self.process:DoOnOpen(self)
end

function MiniGamePage:SetProcess()
  local limit = require("ui.page.minigame.minigamelimit")
  local un_limit = require("ui.page.minigame.minigameunlimit")
  local params = self:GetParam() or {}
  local typ = params.typ
  if typ == Game2dPlayType.Limit then
    self.process = limit
  elseif typ == Game2dPlayType.UnLimit then
    self.process = un_limit
  else
    self.process = limit
  end
end

function MiniGamePage:ReStart()
  GameManager2d:InitGameId(self.gameId)
  GameManager2d:InitData()
  self:ShowLife()
  self:ShowItem()
  self:ShowItemSingle()
  local timer = self:CreateTimer(function()
    self:ShowTime()
  end, 0.5, -1)
  self:StartTimer(timer)
  CameraManager2d:Move(function()
    GlobalGameState2d = GameState2d.Start
  end)
end

function MiniGamePage:Start()
  local params = self:GetParam() or {}
  local copyId = params.copyId
  self.copyId = copyId
  local gameId = self.process:GetGameId(self)
  self.gameId = gameId
  local battleMode = params.battleMode or BattleMode.Normal
  self.battleMode = battleMode
  GameManager2d:InitGameId(gameId)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MiniGame
  })
  LateUpdateBeat:Add(self.__tick, self)
  self:ShowLife()
  self:ShowItem()
  self:ShowItemSingle()
  local timer = self:CreateTimer(function()
    self:ShowTime()
  end, 0.5, -1)
  self:StartTimer(timer)
  CameraManager2d:Move(function()
    GlobalGameState2d = GameState2d.Start
  end)
end

function MiniGamePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnPointDown(widgets.btn_left, function(obj, val)
    widgets.im_left:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Left, 1)
  end)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_left, function()
    widgets.im_left:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Left, 0)
  end)
  UGUIEventListener.AddButtonOnPointDown(widgets.btn_right, function(obj, val)
    widgets.im_right:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Right, 1)
  end)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_right, function()
    widgets.im_right:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Right, 0)
  end)
  UGUIEventListener.AddButtonOnPointDown(widgets.btn_up, function(obj, val)
    widgets.im_up:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Up, 1)
  end)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_up, function()
    widgets.im_up:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Up, 0)
  end)
  UGUIEventListener.AddButtonOnPointDown(widgets.btn_down, function(obj, val)
    widgets.im_down:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Down, 1)
  end)
  UGUIEventListener.AddButtonOnPointUp(widgets.btn_down, function()
    widgets.im_down:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Down, 0)
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_skill, self.btn_skill, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_item, self.btn_item, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_stop, self.btn_stop, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_start, function()
    local widgets = self:GetWidgets()
    widgets.obj_start:SetActive(false)
    local gameId = self.process:GetGameId(self)
    local config = configManager.GetDataById("config_minigame_copy", gameId)
    UIHelper.SetImage(widgets.im_startbg, config.tips_image)
    widgets.obj_tips:SetActive(true)
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_tips, function()
    local widgets = self:GetWidgets()
    widgets.obj_tips:SetActive(false)
    self:Start()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_stop, function()
    self:_ClickClose()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_restart, function()
    local widgets = self:GetWidgets()
    widgets.obj_stop:SetActive(false)
    self:Restart()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_restart1, function()
    local widgets = self:GetWidgets()
    widgets.obj_continue:SetActive(false)
    self:Restart()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_stop1, function()
    self:_ClickClose()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_continue1, function()
    local widgets = self:GetWidgets()
    widgets.obj_continue:SetActive(false)
    GlobalGameState2d = GameState2d.Start
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_continue, function()
    local widgets = self:GetWidgets()
    widgets.obj_stop:SetActive(false)
    GlobalGameState2d = GameState2d.Start
  end)
  self:RegisterEvent(LuaEvent.UpdateLife2d, self.ShowLife, self)
  self:RegisterEvent(LuaEvent.UpdateItem2d, self.ShowItem, self)
  self:RegisterEvent(LuaEvent.UpdateItemSingle2d, self.ShowItemSingle, self)
  self:RegisterEvent(LuaEvent.GameOver2d, self.GameOver2d, self)
  self:RegisterEvent(LuaEvent.Success2d, self.Success2d, self)
  self:RegisterEvent(LuaEvent.Stop2d, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.Next2d, self.Next2d, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_next_gm, self.Next2dGm, self)
end

function MiniGamePage:GameOver2d()
  self.process:GameOver2d(self)
end

function MiniGamePage:Success2d()
  self.process:Success2d(self)
end

function MiniGamePage:_ClickClose()
  GameManager2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  UIHelper.ClosePage("MiniGamePage")
end

function MiniGamePage:Next2dGm()
  GlobalGameState2d = GameState2d.Stop
  Logic2d:SetScoreById(self.process:GetGameId(self), 0)
  self:Next2d()
end

function MiniGamePage:Next2d()
  GameManager2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  local gameId = self.process:GetGameId(self)
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  gameId = config.next_copy
  local widgets = self:GetWidgets()
  local config = configManager.GetDataById("config_minigame_copy", gameId)
  UIHelper.SetLocText(widgets.tx_copy, 4100025, config.copy_order)
  Logic2d:SetGameId(gameId)
  if 0 < gameId then
    self.gameId = gameId
    self:ReStart()
    LateUpdateBeat:Add(self.__tick, self)
  end
end

function MiniGamePage:Restart()
  GameManager2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  self:ReStart()
  LateUpdateBeat:Add(self.__tick, self)
end

function MiniGamePage:btn_skill()
  if GlobalGameState2d == GameState2d.Stop then
    return
  end
  PlayerManager2d:Skill()
end

function MiniGamePage:btn_item()
  if GlobalGameState2d == GameState2d.Stop then
    return
  end
  PlayerManager2d:Pick()
end

function MiniGamePage:ShowSkillCd()
  local widgets = self:GetWidgets()
  local id = GameManager2d:GetSkillId()
  local value = SkillManager2d:GetCd(id)
  widgets.im_skillcd.fillAmount = value
end

function MiniGamePage:__tick()
  local widgets = self:GetWidgets()
  if Input.GetKeyDown(KeyCode.A) then
    widgets.im_left:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Left, 1)
  end
  if Input.GetKeyDown(KeyCode.D) then
    widgets.im_right:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Right, 1)
  end
  if Input.GetKeyDown(KeyCode.W) then
    widgets.im_up:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Up, 1)
  end
  if Input.GetKeyDown(KeyCode.S) then
    widgets.im_down:SetActive(true)
    PlayerManager2d:SetDir(Dir2d.Down, 1)
  end
  if Input.GetKeyUp(KeyCode.A) then
    widgets.im_left:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Left, 0)
  end
  if Input.GetKeyUp(KeyCode.D) then
    widgets.im_right:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Right, 0)
  end
  if Input.GetKeyUp(KeyCode.W) then
    widgets.im_up:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Up, 0)
  end
  if Input.GetKeyUp(KeyCode.S) then
    widgets.im_down:SetActive(false)
    PlayerManager2d:SetDir(Dir2d.Down, 0)
  end
  if Input.GetKeyUp(KeyCode.J) then
    self:btn_skill()
  end
  if Input.GetKeyUp(KeyCode.K) then
    self:btn_item()
  end
  self:ShowSkillCd()
end

function MiniGamePage:DoOnClose()
  GR.cameraManager:destroyCamera(GameCameraType.MiniGameSceneCamera, true)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN
  })
end

function MiniGamePage:btn_stop()
  if GlobalGameState2d == GameState2d.Stop then
    return
  end
  local widgets = self:GetWidgets()
  widgets.obj_stop:SetActive(true)
  GlobalGameState2d = GameState2d.Stop
end

function MiniGamePage:ShowLife()
  local widgets = self:GetWidgets()
  local life = GameManager2d:GetLife()
  UIHelper.CreateSubPart(widgets.im_heart, widgets.Content_life, life, function(index, tabPart)
  end)
end

function MiniGamePage:ShowItem()
  local widgets = self:GetWidgets()
  local config = configManager.GetDataById("config_minigame_copy", self.gameId)
  local successId = config.victory_condition
  local successConfig = configManager.GetDataById("config_minigame_victory_condition", successId)
  local items = config.item_num_show
  widgets.obj_item1:SetActive(0 < #items)
  if 0 < #items then
    UIHelper.CreateSubPart(widgets.im_item, widgets.Content_item, #items, function(index, tabPart)
      local templateId = items[index]
      local config_template = configManager.GetDataById("config_minigame_item_template", templateId)
      local num = GameManager2d:GetPickNumByTid(templateId)
      UIHelper.SetText(tabPart.tx_time, num .. "/" .. successConfig.parameter[2])
      UIHelper.SetImage(tabPart.im_item, config_template.image)
    end)
  end
end

function MiniGamePage:ShowItemSingle()
  local widgets = self:GetWidgets()
  local itemId = PlayerManager2d:GetItemId()
  widgets.obj_item2:SetActive(0 < itemId)
  if 0 < itemId then
    local templateId = ItemManager2d:GetItemIdById(itemId)
    local config = configManager.GetDataById("config_minigame_item", templateId)
    UIHelper.SetImage(widgets.im_item2, config.ui_resource)
  end
end

function MiniGamePage:ShowTime()
  local widgets = self:GetWidgets()
  local time_num = GameManager2d:GetTime()
  UIHelper.SetText(widgets.tx_time, time.getHoursString(math.floor(time_num)))
end

return MiniGamePage
