local GuildMainPage = class("UI.Guild.GuildMainPage", LuaUIPage)
local TypeApply = 1
local TypeCancel = 2
local offset = 0.1

function GuildMainPage:DoInit()
  self.mGuildList = {}
  self.mGuildListNum = 10
  self.mflagScroll = false
end

function GuildMainPage:DoOnOpen()
  self.mHaveShowMainMoto = false
  self:OpenTopPage("GuildMainPage", 1, "\229\164\167\232\136\176\233\152\159", self, false)
  self:resetGuildList()
end

function GuildMainPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCreate, self.onBtnCreateClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSearch, self.onBtnSearchClick, self)
  self:RegisterEvent(LuaEvent.Update_OurGuildInfo, self.updateGuildInfo, self)
  self:RegisterEvent(LuaEvent.Update_MyGuildInfo, self.updateGuildInfo, self)
  self:RegisterEvent(LuaEvent.MOTO_GUILD_LIST, self.updateGuildList, self)
  self:RegisterEvent(LuaEvent.MOTO_BUILD_MOTO_UPDATE, self.resetGuildList, self)
  self:RegisterEvent(LuaEvent.MOTO_GUILD_CREATE_SUCCESS, self.updateMoto, self)
  self:RegisterEvent(LuaEvent.REFRESH_APPLY_INFO, self.updateMoto, self)
  self.tab_Widgets.scrollbarVer.onValueChanged:AddListener(function(msg)
    self:_OnScrollRectChange(self, msg)
  end)
end

function GuildMainPage:DoOnHide()
end

function GuildMainPage:DoOnClose()
end

function GuildMainPage:onBtnCreateClick()
  UIHelper.OpenPage("CreateGuildPage")
end

function GuildMainPage:onBtnSearchClick()
  local text = self.tab_Widgets.inputField.text
  if text == nil or text == "" then
    noticeManager:ShowTip("\232\175\183\232\190\147\229\133\165\229\164\167\232\136\176\233\152\159\229\144\141\231\167\176")
    return
  end
  local pageParam = {name = text}
  UIHelper.OpenPage("SearchGuildPage", pageParam)
end

function GuildMainPage:resetGuildList()
  Service.guildService:SendGetList({
    fromRank = 0,
    num = self.mGuildListNum
  })
  self.mflagScroll = true
  self:updateMoto()
end

function GuildMainPage:getGuildList()
  Service.guildService:SendGetList({
    fromRank = 0,
    num = self.mGuildListNum
  })
end

function GuildMainPage:updateGuildInfo()
  logDebug("BuildMoto:updateGuildInfo")
  if not Data.guildData:inGuild() then
    return
  end
  if not self.mHaveShowMainMoto then
    self.mHaveShowMainMoto = true
    UIHelper.ClosePage("GuildMainPage")
    UIHelper.OpenPage("GuildPage")
  end
end

function GuildMainPage:updateMoto()
  logDebug("BuildMoto:updateMoto")
  if Data.guildData:inGuild() then
    logDebug("in guild", self.mHaveShowMainMoto)
    if not self.mHaveShowMainMoto then
      UIHelper.ClosePage("GuildMainPage")
      self.mHaveShowMainMoto = true
      UIHelper.OpenPage("GuildPage")
    end
    return
  end
  self:showGuildList()
end

function GuildMainPage:_OnScrollRectChange(go, volume)
  local pos = self.tab_Widgets.scrollRect.verticalNormalizedPosition
  if self.pre and self.pre > 0 and self.pre < 1 and pos <= offset and self.mflagScroll == false then
    self.mflagScroll = true
    self.mGuildListNum = #self.mGuildList + 10
    self:getGuildList()
  end
  self.pre = pos
end

function GuildMainPage:updateGuildList(data)
  logDebug("GuildMainPage:updateGuildList ", data)
  self.mGuildList = data.GuildList
  self.mflagScroll = false
  self:showGuildList()
end

function GuildMainPage:updatePart(indexNew, part)
  logDebug("BuildMoto:updatePart", #self.mGuildList, indexNew, part)
  local myGuild = Data.guildData:getMyGuildInfo()
  local guild = self.mGuildList[indexNew]
  local enounce = guild.Enounce
  if enounce == nil or enounce == "" then
    local paramRec = Logic.guildLogic:GetGuildParamConfig()
    enounce = UIHelper.GetString(paramRec.acqnote)
  end
  UIHelper.SetText(part.txtLevel, guild.Level or "")
  UIHelper.SetText(part.txtName, guild.Name)
  UIHelper.SetText(part.txtBossName, guild.LeaderName)
  UIHelper.SetText(part.txtDeclare, enounce or "")
  local lvRec = configManager.GetDataById("config_guildlevel", guild.Level)
  UIHelper.SetText(part.txtPlayerNum, guild.MemberNum .. "/" .. lvRec.playernum)
  UGUIEventListener.AddButtonOnClick(part.btnApply, self.btnApplyOnClick, self, {
    part = part,
    id = guild.GuildId,
    typ = TypeApply
  })
  UGUIEventListener.AddButtonOnClick(part.btnCancel, self.btnApplyOnClick, self, {
    part = part,
    id = guild.GuildId,
    typ = TypeCancel
  })
  if myGuild ~= nil and myGuild:getApplyTime(guild.GuildId) > 0 then
    part.btnApply.gameObject:SetActive(false)
    part.btnCancel.gameObject:SetActive(true)
  elseif guild.MemberNum >= lvRec.playernum then
    part.btnApply.gameObject:SetActive(false)
    part.btnCancel.gameObject:SetActive(false)
  else
    part.btnApply.gameObject:SetActive(true)
    part.btnCancel.gameObject:SetActive(false)
  end
end

function GuildMainPage:showGuildList()
  logDebug("BuildMoto:showGuildList num:", #self.mGuildList)
  self.tab_Widgets.objEmpty:SetActive(#self.mGuildList == 0)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.content, self.tab_Widgets.item, #self.mGuildList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updatePart(index, part)
    end
  end)
end

function GuildMainPage:btnApplyOnClick(go, param)
  logDebug("BuildMoto:btnApplyOnClick ", param)
  local part = param.part
  if param.typ == TypeApply then
    local can, dictId = Data.guildData:canApply()
    if not can then
      noticeManager:ShowTipById(dictId)
      return
    end
    part.btnCancel.gameObject:SetActive(true)
    part.btnApply.gameObject:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btnCancel, self.btnApplyOnClick, self, {
      part = part,
      id = param.id,
      typ = TypeCancel
    })
    Service.guildService:SendApply({
      GuildId = param.id
    })
  elseif param.typ == TypeCancel then
    part.btnCancel.gameObject:SetActive(false)
    part.btnApply.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnApply, self.btnApplyOnClick, self, {
      part = part,
      id = param.id,
      typ = TypeApply
    })
    Service.guildService:SendCancelApply({
      GuildId = param.id
    })
  end
end

return GuildMainPage
