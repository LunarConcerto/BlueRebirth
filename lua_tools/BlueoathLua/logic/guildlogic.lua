local GuildLogic = class("logic.GuildLogic")

function GuildLogic:initialize()
  self.cache_GuildPageToggleIndex = 0
  self.cache_GuildTaskPartialToggleIndex = 0
  self.cache_GuildMemberSort_Sort = 0
  self.cache_GuildMemberSort_Index = 0
end

function GuildLogic:GetUserPostConfig()
  local myGuild = Data.guildData:getMyGuildInfo()
  local post = myGuild:getPost()
  local cfg = configManager.GetDataById("config_guildpost", GuildPostCfgID[post])
  return cfg
end

function GuildLogic:GetGuildParamConfig()
  local paramRec = configManager.GetDataById("config_guildparam", GUILD_PARAM_DEFAULT)
  return paramRec
end

return GuildLogic
