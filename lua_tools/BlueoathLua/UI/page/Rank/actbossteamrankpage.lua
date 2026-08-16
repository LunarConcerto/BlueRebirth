local ActBossTeamRankPage = class("ui.page.Rank.ActBossTeamRankPage")
local offset = 0.01

function ActBossTeamRankPage:initialize()
  self.tabRankInfo = {}
  self.pre = nil
  self.flag = false
end

function ActBossTeamRankPage:DoOnOpen(page, param, widgets)
  self.page = page
  self.param = param
  self.tab_Widgets = widgets
  self:RegisterAllEvent()
  local userData = Data.userData:GetUserData()
  local icon, quality = Logic.meritLogic:GetUserHead(userData)
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  UIHelper.SetImage(self.tab_Widgets.obj_headFrame, headFrameInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_rankIcon, quality)
  UIHelper.SetImage(self.tab_Widgets.im_girl, icon)
  UIHelper.SetText(self.tab_Widgets.tx_name, Data.userData:GetUserName())
  self.chapterId = Logic2d:GetChapterId()
  local widgets = self.tab_Widgets
  widgets.Dropdown.gameObject:SetActive(false)
  widgets.tx_copy.gameObject:SetActive(true)
  UIHelper.SetLocText(self.tab_Widgets.tx_copy, 4300023)
  UIHelper.SetLocText(self.tab_Widgets.tx_time_title, 4300024)
  self.tab_Widgets.caidan:SetActive(false)
  self:GetRankData()
end

function ActBossTeamRankPage:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdateBossTeamRank, self.UpdatePage, self)
  self.tab_Widgets.ScrollbarVer.onValueChanged:AddListener(function(msg)
    self:_OnScrollRectChange(self, msg)
  end)
end

function ActBossTeamRankPage:UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdateBossTeamRank, self.UpdatePage)
end

function ActBossTeamRankPage:_OnScrollRectChange(go, volume)
  local pos = self.tab_Widgets.ScrollView.verticalNormalizedPosition
  if self.pre and self.pre > 0 and self.pre < 1 and pos <= offset and self.flag == false then
    self:GetRankData()
  end
  self.pre = pos
end

function ActBossTeamRankPage:GetRankData()
  local parameter = configManager.GetDataById("config_parameter", 224).arrValue
  local numMaxOnce = parameter[1]
  self.flag = true
  Service.copyService:SendGetBossTeamleRank()
end

function ActBossTeamRankPage:UpdatePage(rankData)
  self:ShowExRank(rankData)
  self:ShowSelfRank(rankData)
  self.flag = false
end

function ActBossTeamRankPage:ShowExRank(rankData)
  self.tabRankInfo = {}
  local rankDataList = rankData.List
  if #rankDataList <= 0 then
    self.tab_Widgets.im_girl_no:SetActive(#self.tabRankInfo <= 0)
    self.tab_Widgets.obj_content.gameObject:SetActive(false)
    self.tab_Widgets.obj_userInfo.gameObject:SetActive(false)
    return
  end
  for i, v in pairs(rankDataList) do
    local rank = v.Rank
    self.tabRankInfo[rank] = v
  end
  self.tab_Widgets.obj_content.gameObject:SetActive(#self.tabRankInfo > 0)
  self.tab_Widgets.obj_userInfo.gameObject:SetActive(#self.tabRankInfo > 0)
  self.tab_Widgets.im_girl_no:SetActive(#self.tabRankInfo <= 0)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.Content, self.tab_Widgets.item, #self.tabRankInfo, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for index, luaPart in pairs(tabTemp) do
      local rankDataSub = self.tabRankInfo[index]
      local config = configManager.GetDataById("config_parameter", 189)
      local index_img_bg = math.min(rankDataSub.Rank, #config.arrValue)
      local img_bg = config.arrValue[index_img_bg]
      UIHelper.SetImage(luaPart.im_bg, img_bg)
      if rankDataSub.dismissed then
        luaPart.im_quality.gameObject:SetActive(false)
        luaPart.im_girl.gameObject:SetActive(false)
        luaPart.obj_headFrame.gameObject:SetActive(false)
        luaPart.tx_guild.gameObject:SetActive(false)
        luaPart.tx_captain.gameObject:SetActive(false)
        luaPart.tx_name.gameObject:SetActive(false)
        luaPart.tx_none.gameObject:SetActive(true)
        UIHelper.SetLocText(luaPart.tx_none, 4300035)
        UIHelper.SetText(luaPart.textTime, rankDataSub.Score)
        UIHelper.SetText(luaPart.tx_rankNum, rankDataSub.Rank)
      else
        luaPart.im_quality.gameObject:SetActive(false)
        luaPart.im_girl.gameObject:SetActive(false)
        luaPart.obj_headFrame.gameObject:SetActive(false)
        luaPart.tx_guild.gameObject:SetActive(true)
        luaPart.tx_captain.gameObject:SetActive(true)
        luaPart.tx_name.gameObject:SetActive(false)
        UIHelper.SetText(luaPart.tx_guild, "\229\164\167\232\136\176\233\152\159:" .. rankDataSub.Name)
        UIHelper.SetText(luaPart.tx_captain, "\232\136\176\233\149\191:" .. rankDataSub.LeaderName)
        UIHelper.SetText(luaPart.tx_rankNum, rankDataSub.Rank)
        UIHelper.SetText(luaPart.textTime, rankDataSub.Score)
        luaPart.im_player:SetActive(rankDataSub.Uid == Data.userData:GetUserUid())
      end
    end
  end)
end

function ActBossTeamRankPage:ShowSelfRank(rankData)
  local widgets = self.tab_Widgets
  local selfRank = rankData.SelfRank
  self.tab_Widgets.TimePart:SetActive(selfRank and selfRank.Rank)
  self.tab_Widgets.imgOnRank:SetActive(selfRank and selfRank.Rank)
  local parameter = configManager.GetDataById("config_parameter", 409).arrValue
  local numMax = parameter[2][2]
  if selfRank == nil or selfRank.Rank == nil or numMax < selfRank.Rank or selfRank.Rank <= 0 then
    UIHelper.SetLocText(self.tab_Widgets.tx_rankNum, 520004)
    if next(selfRank) ~= nil then
      UIHelper.SetText(self.tab_Widgets.textTime, selfRank.Score)
    else
      UIHelper.SetText(self.tab_Widgets.textTime, 0)
    end
  elseif selfRank.dismissed then
    UIHelper.SetLocText(self.tab_Widgets.tx_rankNum, 520004)
    UIHelper.SetText(self.tab_Widgets.textTime, 0)
    self.tab_Widgets.tx_guild.gameObject:SetActive(true)
    UIHelper.SetLocText(self.tab_Widgets.tx_guild, 710062)
  else
    UIHelper.SetText(self.tab_Widgets.tx_rankNum, selfRank.Rank)
    UIHelper.SetText(self.tab_Widgets.textTime, selfRank.Score)
    self.tab_Widgets.tx_guild.gameObject:SetActive(true)
    UIHelper.SetText(self.tab_Widgets.tx_guild, "\229\164\167\232\136\176\233\152\159:" .. selfRank.Name)
  end
end

function ActBossTeamRankPage:DoOnHide()
end

function ActBossTeamRankPage:DoOnClose()
end

return ActBossTeamRankPage
