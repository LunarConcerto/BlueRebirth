local SearchGuildPage = class("UI.Guild.SearchGuildPage", LuaUIPage)
local TypeApply = 1
local TypeCancel = 2

function SearchGuildPage:DoInit()
  self.mGuildList = {}
end

function SearchGuildPage:DoOnOpen()
  local tabParam = self:GetParam()
  self.tab_Widgets.inputName.text = tabParam.name
  self:searchGuild(tabParam.name)
end

function SearchGuildPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.btnCloseOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSearch, self.btnSearchOnClick, self)
  self:RegisterEvent(LuaEvent.MOTO_SEARCH_RESULT, self.updateSearchResult, self)
end

function SearchGuildPage:DoOnHide()
end

function SearchGuildPage:DoOnClose()
end

function SearchGuildPage:btnCloseOnClick()
  eventManager:SendEvent(LuaEvent.REFRESH_APPLY_INFO)
  UIHelper.ClosePage("SearchGuildPage")
end

function SearchGuildPage:btnSearchOnClick()
  local text = self.tab_Widgets.inputName.text
  self:searchGuild(text)
end

function SearchGuildPage:searchGuild(name)
  logDebug("SearchGuildPage:searchGuild name", name)
  if name == nil or name == "" then
    return
  end
  Service.guildService:SendSearch({sName = name})
end

function SearchGuildPage:updateSearchResult(data)
  self.mGuildList = data.GuildList or {}
  if #self.mGuildList <= 0 then
    noticeManager:ShowTipById(710003)
    return
  end
  self:showSearchResult()
end

function SearchGuildPage:showSearchResult()
  logDebug("SearchGuildPage:showSearchResult num:", #self.mGuildList)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.content, self.tab_Widgets.item, #self.mGuildList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updatePart(index, part)
    end
  end)
end

function SearchGuildPage:updatePart(index, part)
  local myGuild = Data.guildData:getMyGuildInfo()
  local guild = self.mGuildList[index]
  local enounce = guild.Enounce
  if enounce == nil or enounce == "" then
    local paramRec = Logic.guildLogic:GetGuildParamConfig()
    enounce = UIHelper.GetString(paramRec.acqnote)
  end
  UIHelper.SetText(part.txtLevel, guild.Level or "")
  UIHelper.SetText(part.txtGuildName, guild.Name)
  UIHelper.SetText(part.txtLeaderName, guild.LeaderName)
  UIHelper.SetText(part.txtNote, enounce or "")
  local lvRec = configManager.GetDataById("config_guildlevel", guild.Level)
  UIHelper.SetText(part.txtNumber, guild.MemberNum .. "/" .. lvRec.playernum)
  UGUIEventListener.AddButtonOnClick(part.btnApply, self.btnApplyOnClick, self, {
    part = part,
    id = guild.GuildId,
    typ = TypeApply
  })
  UGUIEventListener.AddButtonOnClick(part.btnAbortApply, self.btnApplyOnClick, self, {
    part = part,
    id = guild.GuildId,
    typ = TypeCancel
  })
  if guild.MemberNum >= lvRec.playernum then
    part.btnApply.gameObject:SetActive(false)
    part.btnAbortApply.gameObject:SetActive(false)
  elseif myGuild ~= nil and myGuild:getApplyTime(guild.GuildId) > 0 then
    part.btnApply.gameObject:SetActive(false)
    part.btnAbortApply.gameObject:SetActive(true)
  else
    part.btnApply.gameObject:SetActive(true)
    part.btnAbortApply.gameObject:SetActive(false)
  end
end

function SearchGuildPage:btnApplyOnClick(go, param)
  local part = param.part
  if param.typ == TypeApply then
    local can, dictId = Data.guildData:canApply()
    if not can then
      if type(dictId) == "number" then
        noticeManager:ShowTipById(dictId)
      else
        noticeManager:ShowTip(dictId)
      end
      return
    end
    part.btnAbortApply.gameObject:SetActive(true)
    part.btnApply.gameObject:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btnAbortApply, self.btnApplyOnClick, self, {
      part = part,
      id = param.id,
      typ = TypeCancel
    })
    Service.guildService:SendApply({
      GuildId = param.id
    })
  elseif param.typ == TypeCancel then
    part.btnAbortApply.gameObject:SetActive(false)
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

return SearchGuildPage
