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
  self:SetEffRatio()
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
  RetentionHelper.Retention(PlatformDotType.roleNameFinish)
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
    end, 3, 1, false)
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

local speicalEff = {
  eff_Im_bg02_01_diyigechuxianhuan = 1,
  eff_Im_bg02_08_dierge = 2,
  eff_Im_bg02_03_zhongxin = 3,
  eff_Im_bg02_01 = 4,
  eff_Im_bg02_02 = 5,
  eff_Im_bg02_03 = 6,
  eff_Im_bg02_04 = 7,
  eff_Im_bg02_08 = 8
}
local noProcessingEff = {
  eff_Im_bg02_12_dasibianxing = 1,
  eff_Im_bg02_12_dasibianxing_1 = 2,
  eff_Im_bg02_xiaosibianxing = 3,
  eff_Im_bg02_12_dasibianxing_2 = 4
}

function CreateCharacterPage:SetEffRatio()
  local radio = ResolutionHelper.real2Standard
  local msRenders = self.tab_Widgets.eff_nickName:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer), true)
  local msRenders2 = self.tab_Widgets.masaike:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer), true)
  if msRenders.Length ~= 0 then
    for i = 0, msRenders.Length - 1 do
      local __render = msRenders[i]
      local res = string.split(__render, " ")
      local scale = {}
      if speicalEff[res[1]] ~= nil then
        scale = {
          __render.transform.localScale.x * radio,
          __render.transform.localScale.y * radio
        }
      elseif ResolutionHelper.resolutionType == ResolutionType.NARROW then
        scale = {
          __render.transform.localScale.x,
          __render.transform.localScale.y / radio
        }
      else
        scale = {
          __render.transform.localScale.x * radio,
          __render.transform.localScale.y
        }
      end
      if noProcessingEff[res[1]] == nil then
        __render.transform.localScale = Vector3.New(scale[1], scale[2], 1)
      end
    end
  end
  if msRenders2.Length ~= 0 then
    for i = 0, msRenders2.Length - 1 do
      local __render = msRenders2[i]
      if ResolutionHelper.resolutionType == ResolutionType.NARROW then
        __render.transform.localScale = Vector3.New(__render.transform.localScale.x, __render.transform.localScale.y / radio)
      else
        __render.transform.localScale = Vector3.New(__render.transform.localScale.x * radio, __render.transform.localScale.y, 1)
      end
    end
  end
end

return CreateCharacterPage
