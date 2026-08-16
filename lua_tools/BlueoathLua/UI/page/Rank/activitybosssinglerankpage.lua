local ActivityBossSingleRankPage = class("ui.page.Rank.ActivityBossSingleRankPage")
local offset = 0.01

function ActivityBossSingleRankPage:initialize()
  self.tabRankInfo = {}
  self.pre = nil
  self.flag = false
end

function ActivityBossSingleRankPage:DoOnOpen(page, param, widgets)
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
  UIHelper.SetLocText(self.tab_Widgets.tx_copy, 4300021)
  UIHelper.SetLocText(self.tab_Widgets.tx_time_title, 4300022)
  self.tab_Widgets.caidan:SetActive(false)
  self:GetRankData()
end

function ActivityBossSingleRankPage:RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.UpdateBossSingeRank, self.UpdatePage, self)
  self.tab_Widgets.ScrollbarVer.onValueChanged:AddListener(function(msg)
    self:_OnScrollRectChange(self, msg)
  end)
end

function ActivityBossSingleRankPage:UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdateBossSingeRank, self.UpdatePage)
end

function ActivityBossSingleRankPage:_OnScrollRectChange(go, volume)
  local pos = self.tab_Widgets.ScrollView.verticalNormalizedPosition
  if self.pre and self.pre > 0 and self.pre < 1 and pos <= offset and self.flag == false then
    self:GetRankData()
  end
  self.pre = pos
end

function ActivityBossSingleRankPage:GetRankData()
  local parameter = configManager.GetDataById("config_parameter", 224).arrValue
  local numMaxOnce = parameter[1]
  self.flag = true
  Service.copyService:SendGetBossSingleRank()
end

function ActivityBossSingleRankPage:UpdatePage(rankData)
  self:ShowExRank(rankData)
  self:ShowSelfRank(rankData)
  self.flag = false
end

function ActivityBossSingleRankPage:ShowExRank(rankData)
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
      local icon, quality = Logic.meritLogic:GetUserHead(rankDataSub.UserInfo)
      local config = configManager.GetDataById("config_parameter", 189)
      local index_img_bg = math.min(rankDataSub.Rank, #config.arrValue)
      local img_bg = config.arrValue[index_img_bg]
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetHeadFrameByUid(rankDataSub.UserInfo)
      UIHelper.SetImage(luaPart.obj_headFrame, headFrameInfo.icon)
      UIHelper.SetImage(luaPart.im_bg, img_bg)
      UIHelper.SetImage(luaPart.im_quality, quality)
      UIHelper.SetImage(luaPart.im_girl, icon)
      UIHelper.SetText(luaPart.tx_rankNum, rankDataSub.Rank)
      UIHelper.SetText(luaPart.tx_name, rankDataSub.UserInfo.Uname)
      UIHelper.SetText(luaPart.textTime, rankDataSub.Score)
      luaPart.im_player:SetActive(rankDataSub.Uid == Data.userData:GetUserUid())
    end
  end)
end

function ActivityBossSingleRankPage:ShowSelfRank(rankData)
  local widgets = self.tab_Widgets
  local selfRank = rankData.SelfRank
  self.tab_Widgets.TimePart:SetActive(selfRank and selfRank.Rank)
  self.tab_Widgets.imgOnRank:SetActive(selfRank and selfRank.Rank)
  local parameter = configManager.GetDataById("config_parameter", 409).arrValue
  local numMax = parameter[1][2]
  if selfRank == nil or selfRank.Rank == nil or numMax < selfRank.Rank or selfRank.Rank <= 0 then
    UIHelper.SetLocText(self.tab_Widgets.tx_rankNum, 520004)
    UIHelper.SetText(self.tab_Widgets.textTime, selfRank.Score)
  else
    UIHelper.SetText(self.tab_Widgets.tx_rankNum, selfRank.Rank)
    UIHelper.SetText(self.tab_Widgets.textTime, selfRank.Score)
  end
end

function ActivityBossSingleRankPage:DoOnHide()
end

function ActivityBossSingleRankPage:DoOnClose()
end

return ActivityBossSingleRankPage
