local MiniGameScorePage = class("UI.MiniGame.MiniGameScorePage", LuaUIPage)
local limit = require("ui.page.minigame.minigamescorelimit")
local un_limit = require("ui.page.minigame.minigamescoreunlimit")

function MiniGameScorePage:DoInit()
  self.start = true
end

function MiniGameScorePage:SetProcess()
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

function MiniGameScorePage:DoOnOpen()
  self:SetProcess()
  local widgets = self:GetWidgets()
  local params = self:GetParam()
  local isSuccess = params.isSuccess
  local gameConfig = GameManager2d:GetConfig()
  local successId = gameConfig.victory_condition
  local successConfig = configManager.GetDataById("config_minigame_victory_condition", successId)
  local gameType = successConfig.type
  local score_sum = 0
  local time_num = math.floor(GameManager2d:GetTime())
  UIHelper.SetText(widgets.tx_time, time.getHoursString(time_num))
  local paramConf = configManager.GetDataById("config_parameter", 369).arrValue
  local conditionConf = paramConf[1]
  local valueConf = paramConf[2]
  local score_time = 0
  if isSuccess then
    for i = #conditionConf, 1, -1 do
      if time_num >= conditionConf[i] then
        score_time = valueConf[i]
        break
      end
    end
  end
  score_sum = score_sum + score_time
  local score_time_format = string.format("%011d", score_time)
  UIHelper.SetText(widgets.tx_score_time, score_time_format)
  local life = GameManager2d:GetLife()
  UIHelper.SetText(widgets.tx_num_life, "x" .. life)
  local life_rate = configManager.GetDataById("config_parameter", 370).value
  score_sum = score_sum + life * life_rate
  local score_life_format = string.format("%011d", life * life_rate)
  UIHelper.SetText(widgets.tx_score_life, score_life_format)
  widgets.obj_photo:SetActive(gameType == Game2dType.Photo)
  if gameType == Game2dType.Photo then
    local photo_num = GameManager2d:GetPhotoNum()
    local photo_rate = configManager.GetDataById("config_parameter", 371).value
    score_sum = score_sum + photo_num * photo_rate
    local score_photo_format = string.format("%011d", photo_num * photo_rate)
    UIHelper.SetText(widgets.tx_num_photo, "x" .. photo_num)
    UIHelper.SetText(widgets.tx_score_photo, score_photo_format)
  end
  widgets.obj_bomb:SetActive(gameType == Game2dType.Bomb or gameType == Game2dType.Pick)
  if gameType == Game2dType.Bomb or gameType == Game2dType.Pick then
    local param = successConfig.parameter
    local templateId = param[1]
    local num = GameManager2d:GetPickNumByTid(templateId)
    UIHelper.SetText(widgets.tx_num_bomb, "x" .. num)
    local bomb_rate = configManager.GetDataById("config_parameter", 372).value
    score_sum = score_sum + num * bomb_rate
    local score_bomb_format = string.format("%011d", num * bomb_rate)
    UIHelper.SetText(widgets.tx_score_bomb, score_bomb_format)
    UIHelper.SetLocText(widgets.tx_desc_bomb, gameConfig.score_desc)
  end
  UIHelper.SetText(widgets.tx_score_all, string.format("%011d", score_sum))
  Logic2d:SetScoreById(params.gameId, score_sum)
  self.process:DoOnOpenCustom(self)
end

function MiniGameScorePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close_stop, self.btn_stop, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_restart, function()
    UIHelper.ClosePage("MiniGameScorePage")
    eventManager:SendEvent(LuaEvent.Restart2d)
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_next, function()
    UIHelper.ClosePage("MiniGameScorePage")
    eventManager:SendEvent(LuaEvent.Next2d)
  end)
end

function MiniGameScorePage:_ClickClose()
  UIHelper.ClosePage("MiniGameScorePage")
  eventManager:SendEvent(LuaEvent.Stop2d)
end

function MiniGameScorePage:btn_stop()
  self.process:btn_stop(self)
end

return MiniGameScorePage
