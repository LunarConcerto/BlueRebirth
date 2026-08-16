local CreateCharacterPage = class("UI.CreateCharacter.CreateCharacterPage", LuaUIPage)

function CreateCharacterPage:DoInit()
  self.m_timer = nil
  self.m_nextTimer = nil
  self.m_connectTimer = nil
end

function CreateCharacterPage:DoOnOpen()
  self.enRandom = {
    configManager.GetData("config_random_first_name_en"),
    configManager.GetData("config_random_last_name_en")
  }
  self.jaRandom = {
    configManager.GetData("config_random_first_name_ja"),
    configManager.GetData("config_random_last_name_ja")
  }
  self.countryRandom = {
    self.enRandom,
    self.jaRandom
  }
  self.tab_Widgets.playable_textBg:Play()
  self:_StartTimer()
end

function CreateCharacterPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_random, function()
    self:_OnClickRandom()
  end, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confire, function()
    self:_OnClickConfire()
  end, self)
  self:RegisterEvent(LuaEvent.ChangeNameOk, self._PlayNextAnim, self)
end

function CreateCharacterPage:_ChangeNameOk(msg)
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.ChangeNameOk)
end

function CreateCharacterPage:_TimeLineFinish()
  self:_StopTimer()
  self.tab_Widgets.obj_create:SetActive(true)
end

function CreateCharacterPage:_OnClickConfire()
  local input = self.tab_Widgets.input_content.text
  local _, len = string.gsub(input, ".[\128-\191]*", "")
  local lenMin = configManager.GetDataById("config_parameter", 65).value
  local lenMax = configManager.GetDataById("config_parameter", 66).value
  if input and len >= lenMin then
    Service.userService:SendChangeName(input)
  else
    noticeManager:ShowTip(UIHelper.GetString(250001))
  end
end

function CreateCharacterPage:_OnClickRandom()
  self.tab_Widgets.input_content.text = self:_GetRandomName()
end

function CreateCharacterPage:_GetRandomName()
  local random = math.random(2)
  local firstNameIndex = math.random(GetTableLength(self.countryRandom[random][1]))
  local lastNameIndex = math.random(GetTableLength(self.countryRandom[random][2]))
  local firstName = self.countryRandom[random][1][firstNameIndex].firstName
  local lastName = self.countryRandom[random][2][lastNameIndex].lastName
  return firstName .. lastName
end

function CreateCharacterPage:DoOnHide()
end

function CreateCharacterPage:DoOnClose()
end

function CreateCharacterPage:_StartTimer()
  if self.m_timer == nil then
    self.m_timer = self:CreateTimer(function()
      self:_TimeLineFinish()
    end, 3.96666, 1, false)
  end
  self:StartTimer(self.m_timer)
end

function CreateCharacterPage:_StopTimer()
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
  end
  self.m_timer = nil
end

function CreateCharacterPage:_PlayNextAnim()
  self.tab_Widgets.anim_banner:Play("eff2d_nickname_background_plate_02")
  self:_NextAnimTimer()
end

function CreateCharacterPage:_NextAnimTimer()
  if self.m_nextTimer == nil then
    self.m_nextTimer = self:CreateTimer(function()
      self:_ShowConnecting()
    end, 1.8, 1, false)
  end
  self:StartTimer(self.m_nextTimer)
end

function CreateCharacterPage:_ShowConnecting()
  self:_StopNextTimer()
  self.tab_Widgets.obj_connect:SetActive(true)
  self:_ConnectTimer()
end

function CreateCharacterPage:_StopNextTimer()
  if self.m_nextTimer ~= nil then
    self:StopTimer(self.m_nextTimer)
  end
  self.m_nextTimer = nil
end

function CreateCharacterPage:_ConnectTimer()
  if self.m_connectTimer == nil then
    self.m_connectTimer = self:CreateTimer(function()
      self:_Connected()
    end, 7, 1, false)
  end
  self:StartTimer(self.m_connectTimer)
end

function CreateCharacterPage:_Connected()
  self:_StopConnectTimer()
  self:_ChangeNameOk()
end

function CreateCharacterPage:_StopConnectTimer()
  if self.m_connectTimer ~= nil then
    self:StopTimer(self.m_connectTimer)
  end
  self.m_connectTimer = nil
end

return CreateCharacterPage
