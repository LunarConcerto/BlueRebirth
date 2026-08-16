local ChangeNamePage = class("UI.Marry.ChangeNamePage", LuaUIPage)

function ChangeNamePage:DoInit()
end

function ChangeNamePage:DoOnOpen()
  self.param = self:GetParam()
  self.onChange = self.param.onChange
  self:_LoadInformation()
end

function ChangeNamePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reset, self._ClickReset, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickConfirm, self)
  self:RegisterEvent(LuaEvent.ChangeNameSuccess, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.ChangeNameError, self.ChangeNameError, self)
  self:RegisterEvent(LuaEvent.ChangeNameOk, self._OnUserChangeOk, self)
  self:RegisterEvent(LuaEvent.ChangeFleetNameError, self.PresetChangeNameError, self)
end

function ChangeNamePage:_LoadInformation()
  self.tab_Widgets.tween_content:Play(true)
  if self.param[4] == ChangeNameType.Marry then
    self.tab_Widgets.tx_title.text = string.format(UIHelper.GetString(1500011), self.param[2])
  elseif self.param[4] == ChangeNameType.PresetFleet then
    UIHelper.SetText(self.tab_Widgets.tx_headline, UIHelper.GetString(1900008))
    self.tab_Widgets.tx_title.text = string.format("\232\175\183\232\190\147\229\133\165\232\136\176\233\152\159\229\144\141", self.param[2])
  elseif self.param[4] == ChangeNameType.BuildingPreset then
    UIHelper.SetText(self.tab_Widgets.tx_title, "\232\175\183\232\190\147\229\133\165\232\136\176\233\152\159\229\144\141")
    UIHelper.SetText(self.tab_Widgets.tx_headline, "\228\191\174\230\148\185\232\136\176\233\152\159\229\144\141")
  else
    self.tab_Widgets.tx_title.text = "\232\175\183\232\190\147\229\133\165\229\167\147\229\144\141"
  end
  self.tab_Widgets.btn_reset.gameObject:SetActive(self.param[4] ~= ChangeNameType.User)
  if self.param[4] == ChangeNameType.User then
    self.tab_Widgets.input_content.characterLimit = configManager.GetDataById("config_parameter", 66).value
  end
end

function ChangeNamePage:_OnUserChangeOk()
  noticeManager:ShowTip(UIHelper.GetString(290006))
  UIHelper.ClosePage("ChangeNamePage")
end

function ChangeNamePage:_ClickClose()
  if self.param[4] == ChangeNameType.Marry then
    UIHelper.ClosePage("MarryAffterPage")
    UIHelper.ClosePage("MarryProcessPage")
    UIHelper.ClosePage("ChangeNamePage")
    UIHelper.ClosePage("MarryBookPage")
  else
    UIHelper.ClosePage("ChangeNamePage")
  end
end

function ChangeNamePage:_ClickReset()
  self.tab_Widgets.input_content.text = self.param[3]
end

function ChangeNamePage:_ClickConfirm()
  if self.param[4] == ChangeNameType.PresetFleet then
    local changeImp = function()
      local newName = self.tab_Widgets.input_content.text
      local ok, msg = Logic.presetFleetLogic:CheckChangeName(self.param[1], newName)
      if ok then
        Logic.presetFleetLogic:SetChangeName(self.param[1], newName)
      else
        noticeManager:ShowTip(msg)
      end
    end
    changeImp()
    return
  end
  if self.param[4] == ChangeNameType.User then
    local changeImp = function()
      local newName = self.tab_Widgets.input_content.text
      local ok, msg = Logic.userLogic:CheckChangeName(newName)
      if ok then
        Service.userService:SendChangeName(newName)
      else
        noticeManager:ShowTip(msg)
      end
    end
    local need, cost = Logic.userLogic:CheckNeedCostItem()
    if need then
      local boxParam = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            changeImp()
          end
        end
      }
      local str = string.format(UIHelper.GetString(290005), cost.Num, Logic.goodsLogic:GetName(cost.ConfigId, cost.Type))
      noticeManager:ShowMsgBox(str, boxParam)
    else
      changeImp()
    end
    return
  end
  if self.param[4] == ChangeNameType.BuildingPreset then
    local newName = self.tab_Widgets.input_content.text
    local ok, msg = Logic.presetFleetLogic:CheckChangeName(self.param[1], newName)
    if ok then
      if newName == self.param[2] then
        self:_ClickClose()
      end
      if self.onChange then
        self.onChange(newName)
      end
    else
      noticeManager:ShowTip(msg)
    end
    return
  end
  local marry_rename_cd = configManager.GetDataById("config_parameter", 164).value
  local curTime = time.getSvrTime()
  local girlData = Data.heroData:GetHeroById(self.param[1])
  local args = {
    HeroId = self.param[1],
    Name = self.tab_Widgets.input_content.text
  }
  local name
  if self.shipName == nil then
    name = self.param[2]
  else
    name = self.shipName
  end
  local str = string.format(UIHelper.GetString(1500001), name, self.tab_Widgets.input_content.text)
  if self.tab_Widgets.input_content.text == "" then
    noticeManager:OpenTipPage(self, UIHelper.GetString(1500014))
  elseif self.tab_Widgets.input_content.text == self.param[2] then
    self:_ClickClose()
  elseif self.tab_Widgets.input_content.text == self.param[3] then
    self:_ClickClose()
    args = {
      HeroId = self.param[1],
      Name = ""
    }
    Service.heroService:SendChangeName(args)
  elseif girlData.ChangeNameTime == 0 or curTime > girlData.ChangeNameTime + marry_rename_cd then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Service.heroService:SendChangeName(args)
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
  else
    local delte = girlData.ChangeNameTime + marry_rename_cd - curTime
    local remainTime = self:ShowRemainTime(delte)
    noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(1500015), remainTime))
  end
end

function ChangeNamePage:ShowRemainTime(delte)
  local remainTime = ""
  if delte <= 60 then
    remainTime = "1\229\136\134\233\146\159"
    return remainTime
  elseif delte < 3600 then
    remainTime = math.ceil(delte / 60) .. "\229\136\134\233\146\159"
    return remainTime
  elseif delte < 86400 then
    remainTime = math.ceil(delte / 3600) .. "\229\176\143\230\151\182"
    return remainTime
  else
    remainTime = math.ceil(delte / 86400) .. "\229\164\169"
    return remainTime
  end
end

function ChangeNamePage:ChangeNameError(err)
  if err == 1011 then
    noticeManager:ShowTip(UIHelper.GetString(250003))
  elseif err == 1005 then
    noticeManager:ShowTip(UIHelper.GetString(250004))
  elseif err == 1010 then
    noticeManager:ShowTip(UIHelper.GetString(250002))
  end
end

function ChangeNamePage:PresetChangeNameError(err)
end

function ChangeNamePage:DoOnHide()
end

function ChangeNamePage:DoOnClose()
end

return ChangeNamePage
