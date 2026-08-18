local GuildLevelUpPage = class("UI.Guild.GuildLevelUpPage", LuaUIPage)

function GuildLevelUpPage:DoInit()
end

function GuildLevelUpPage:DoOnOpen()
  local param = self:GetParam()
  local levelPre = param.LevelPre
  local levelNow = param.LevelNow
  if levelPre >= levelNow then
    logError("level up err: ", levelPre, levelNow)
  end
  UIHelper.SetText(self.tab_Widgets.textLevelPre, levelPre)
  UIHelper.SetText(self.tab_Widgets.textLevelNow, levelNow)
  local levelPreCfg = configManager.GetDataById("config_guildlevel", levelPre)
  local levelNowCfg = configManager.GetDataById("config_guildlevel", levelNow)
  UIHelper.SetText(self.tab_Widgets.textMemNumPre, levelPreCfg.playernum)
  UIHelper.SetText(self.tab_Widgets.textMemNumNow, levelNowCfg.playernum)
end

function GuildLevelUpPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.btnCloseOnClick, self)
end

function GuildLevelUpPage:DoOnHide()
end

function GuildLevelUpPage:DoOnClose()
end

function GuildLevelUpPage:btnCloseOnClick()
  UIHelper.ClosePage("GuildLevelUpPage")
end

return GuildLevelUpPage
