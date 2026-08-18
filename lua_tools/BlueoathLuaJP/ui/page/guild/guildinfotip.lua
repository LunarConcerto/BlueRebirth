local GuildInfoTip = class("UI.Teaching.GuildInfoTip", LuaUIPage)

function GuildInfoTip:DoInit()
  self.m_userInfo = nil
end

function GuildInfoTip:DoOnOpen()
  self.m_userInfo = self:GetParam()
  if self.m_userInfo.GuildId > 0 then
    self:_ShowRoot(false)
    Service.guildService:SendSearch({
      sGuildId = self.m_userInfo.GuildId,
      sName = self.m_userInfo.GuildName
    })
  end
end

function GuildInfoTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._AddGuild, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
  self:RegisterEvent(LuaEvent.MOTO_SEARCH_RESULT, self._OnGetGuildInfo, self)
  self:RegisterEvent(LuaEvent.GUILD_ApplyOk, self._OnApplyGuild, self)
end

function GuildInfoTip:_ShowRoot(show)
  local widgets = self:GetWidgets()
  widgets.obj_fg:SetActive(show)
end

function GuildInfoTip:_OnGetGuildInfo(data)
  self:_Refresh(data.GuildList)
end

function GuildInfoTip:_OnApplyGuild()
  noticeManager:ShowTip(UIHelper.GetString(210012))
end

function GuildInfoTip:_Refresh(data)
  local info = data[1]
  if info then
    self:_ShowRoot(true)
    self:_ShowInfo(info)
  else
    noticeManager:ShowTip(UIHelper.GetString(710029))
  end
end

function GuildInfoTip:_ShowInfo(info)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_name, info.Name)
  UIHelper.SetText(widgets.tx_lv, info.Level)
  UIHelper.SetText(widgets.tx_leader, info.LeaderName)
  local numup = configManager.GetDataById("config_guildlevel", info.Level).playernum
  UIHelper.SetText(widgets.tx_number, info.MemberNum .. "/" .. numup)
  UIHelper.SetText(widgets.tx_intro, info.Enounce)
end

function GuildInfoTip:_CloseSelf()
  UIHelper.ClosePage("TeachingFamilyPage")
end

function GuildInfoTip:_AddGuild()
  Logic.teachingLogic:RequesetAddGuildWrap(self.m_userInfo.GuildId)
end

function GuildInfoTip:DoOnHide()
end

function GuildInfoTip:DoOnClose()
end

return GuildInfoTip
