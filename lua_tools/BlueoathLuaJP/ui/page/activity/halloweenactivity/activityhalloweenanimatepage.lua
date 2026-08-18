local ActivityHalloweenAnimatePage = class("ui.page.Activity.HalloweenActivity.ActivityHalloweenAnimatePage", LuaUIPage)
local InteractionEffType = {
  [1] = "effects/prefabs/eff_ui_halloween_anim_ink",
  [2] = "effects/prefabs/ui/eff_ui_halloween_anim_explosion"
}
local TrickEffType = {
  INK = 1,
  EXPLOSION = 2,
  REWARDS = 0
}
local lightEffPath = "effects/prefabs/ui/eff_ui_halloween_anim_reward_light"

function ActivityHalloweenAnimatePage:DoInit()
  self.m_tabWidgets = nil
  self.LightEff = nil
  self.eventEff = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function ActivityHalloweenAnimatePage:DoOnOpen()
  local params = self:GetParam() or {}
  self.m_EventId = params.eventId
  self.m_Rewards = params.rewards
  self:_DestroyTrickEffect()
  self.m_tabWidgets.theatre:SetActive(true)
  self:ShowPage()
end

function ActivityHalloweenAnimatePage:RegisterAllEvent()
end

function ActivityHalloweenAnimatePage:ShowPage()
  local eventStartTime = configManager.GetDataById("config_parameter", 294).value / 10000
  self.m_EventTime = self:CreateTimer(function()
    self:ShowEvent()
  end, eventStartTime, 1, false)
  local theatreInkClose = configManager.GetDataById("config_parameter", 299).value / 10000
  local theatreExplosionClose = configManager.GetDataById("config_parameter", 298).value / 10000
  local theatreCloseTime = theatreInkClose
  if self.m_EventId == TrickEffType.INK then
    theatreCloseTime = theatreInkClose
  elseif self.m_EventId == TrickEffType.EXPLOSION then
    theatreCloseTime = theatreExplosionClose
  elseif self.m_EventId == TrickEffType.REWARDS then
  end
  self.m_HideBackGround = self:CreateTimer(function()
    self:HideSelfBg()
  end, theatreCloseTime, 1, false)
  self:StartTimer(self.m_EventTime)
  if self.m_EventId ~= TrickEffType.REWARDS then
    self:StartTimer(self.m_HideBackGround)
  end
end

function ActivityHalloweenAnimatePage:CloseSelfPage()
  UIHelper.ClosePage("ActivityHalloweenAnimatePage")
end

function ActivityHalloweenAnimatePage:HideSelfBg()
  self.m_tabWidgets.theatre:SetActive(false)
end

function ActivityHalloweenAnimatePage:ShowEvent()
  local ligitTime = configManager.GetDataById("config_parameter", 296).value / 10000
  local eventInkTime = configManager.GetDataById("config_parameter", 297).value / 10000
  local eventExplosionTime = configManager.GetDataById("config_parameter", 295).value / 10000
  local dataCloseTime = ligitTime
  if self.m_EventId == TrickEffType.INK then
    dataCloseTime = eventInkTime
  elseif self.m_EventId == TrickEffType.EXPLOSION then
    dataCloseTime = eventExplosionTime
  elseif self.m_EventId == TrickEffType.REWARDS then
  end
  self.m_LightTime = self:CreateTimer(function()
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = self.m_Rewards,
      callBack = function()
        self:CloseSelfPage()
      end
    })
  end, ligitTime, 1, false)
  self.m_WaitForCloseTime = self:CreateTimer(function()
    self:CloseSelfPage()
  end, dataCloseTime, 1, false)
  if self.m_EventId == TrickEffType.REWARDS then
    if self.m_Rewards ~= nil and next(self.m_Rewards) ~= nil then
      self.LightEff = UIHelper.CreateUIEffect(lightEffPath, self.m_tabWidgets.obj_LightEff)
      self:StartTimer(self.m_LightTime)
    end
  elseif self.m_EventId == TrickEffType.INK or self.m_EventId == TrickEffType.EXPLOSION then
    eventManager:SendEvent(LuaEvent.RefreshSetSecretary)
    self.eventEff = UIHelper.CreateUIEffect(InteractionEffType[self.m_EventId], self.m_tabWidgets.obj_TrickEff)
    self:StartTimer(self.m_WaitForCloseTime)
  end
end

function ActivityHalloweenAnimatePage:_DestroyTrickEffect(...)
  if self.eventEff ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.eventEff)
    self.eventEff = nil
  end
  if self.LightEff ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.LightEff)
    self.LightEff = nil
  end
end

function ActivityHalloweenAnimatePage:DoOnHide()
end

function ActivityHalloweenAnimatePage:DoOnClose()
  self:_DestroyTrickEffect()
end

return ActivityHalloweenAnimatePage
