local ExRankPage = class("UI.Activity.ExRankPage", LuaUIPage)
local offset = 0.01

function ExRankPage:DoInit()
  self.tabRankInfo = {}
  self.pre = nil
  self.flag = false
end

function ExRankPage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = "EX\230\140\145\230\136\152\230\142\146\232\161\140",
    ChapterId = nil
  })
  local userData = Data.userData:GetUserData()
  local icon, quality = Logic.meritLogic:GetUserHead(userData)
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  UIHelper.SetImage(self.tab_Widgets.obj_headFrame, headFrameInfo.icon)
  UIHelper.SetImage(self.tab_Widgets.im_rankIcon, quality)
  UIHelper.SetImage(self.tab_Widgets.im_girl, icon)
  UIHelper.SetText(self.tab_Widgets.tx_name, Data.userData:GetUserName())
  self:GetRankData()
end

function ExRankPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateExRank, self.UpdatePage, self)
  self.tab_Widgets.ScrollbarVer.onValueChanged:AddListener(function(msg)
    self:_OnScrollRectChange(self, msg)
  end)
end

function ExRankPage:_OnScrollRectChange(go, volume)
  local pos = self.tab_Widgets.ScrollView.verticalNormalizedPosition
  if self.pre and self.pre > 0 and self.pre < 1 and pos <= offset and self.flag == false then
    self:GetRankData()
  end
  self.pre = pos
end

function ExRankPage:GetRankData()
  local parameter = configManager.GetDataById("config_parameter", 224).arrValue
  local numMaxOnce = parameter[1]
  local args = {Start = 0, End = numMaxOnce}
  self.flag = true
  Service.meritService:SendMeritRankExInfo(args)
end

function ExRankPage:UpdatePage(rankData)
  self:ShowExRank(rankData)
  self:ShowSelfRank(rankData)
  self.flag = false
end

function ExRankPage:ShowExRank(rankData)
  local rankDataList = rankData.List
  if #rankDataList <= 0 then
    self.tab_Widgets.im_girl_no:SetActive(0 >= #self.tabRankInfo)
    return
  end
  for i, v in pairs(rankDataList) do
    local rank = v.Rank
    self.tabRankInfo[rank] = v
  end
  self.tab_Widgets.im_girl_no:SetActive(0 >= #self.tabRankInfo)
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
      local timeSum = 0
      for i, v in ipairs(rankDataSub.Time) do
        timeSum = timeSum + v
      end
      UIHelper.SetText(luaPart.textTime, timeSum)
      luaPart.TimePartDetail.gameObject:SetActive(#rankDataSub.Time > 1)
      if #rankDataSub.Time > 1 then
        UIHelper.CreateSubPart(luaPart.textTimeDetail, luaPart.TimePartDetail, #rankDataSub.Time, function(indexPart, tabPartPart)
          UIHelper.SetText(tabPartPart.Text, "Ex" .. indexPart .. ":" .. rankDataSub.Time[indexPart])
        end)
      end
    end
  end)
end

function ExRankPage:ShowSelfRank(rankData)
  local widgets = self.tab_Widgets
  local selfRank = rankData.SelfRank
  self.tab_Widgets.TimePart:SetActive(selfRank and selfRank.Rank)
  self.tab_Widgets.imgOnRank:SetActive(selfRank and selfRank.Rank)
  local parameter = configManager.GetDataById("config_parameter", 224).arrValue
  local numMax = parameter[2]
  if selfRank == nil or selfRank.Rank == nil or numMax < selfRank.Rank then
    UIHelper.SetLocText(self.tab_Widgets.tx_rankNum, 520004)
    self.tab_Widgets.TimePartDetail.gameObject:SetActive(false)
  else
    local timeSum = 0
    for i, v in ipairs(selfRank.Time) do
      timeSum = timeSum + v
    end
    UIHelper.SetText(self.tab_Widgets.tx_rankNum, selfRank.Rank)
    UIHelper.SetText(self.tab_Widgets.textTime, timeSum)
    self.tab_Widgets.TimePartDetail.gameObject:SetActive(#selfRank.Time > 1)
    if #selfRank.Time > 1 then
      UIHelper.CreateSubPart(widgets.textTimeDetail, widgets.TimePartDetail, #selfRank.Time, function(index, tabPart)
        UIHelper.SetText(tabPart.Text, "Ex" .. index .. ":" .. selfRank.Time[index] .. "s")
      end)
    end
  end
end

function ExRankPage:DoOnHide()
end

function ExRankPage:DoOnClose()
end

return ExRankPage
