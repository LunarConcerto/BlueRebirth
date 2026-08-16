local LeaderBoardPage = class("UI.Teaching.LeaderBoardPage", LuaUIPage)

function LeaderBoardPage:DoInit()
  self.m_rtimer = nil
  self.m_top2img = {
    "uipic_ui_teaching_bg_paihangban_nom1",
    "uipic_ui_teaching_bg_paihangban_nom2",
    "uipic_ui_teaching_bg_paihangban_nom3"
  }
end

function LeaderBoardPage:DoOnOpen()
  local need = Logic.teachingLogic:NeedGetRank()
  if need then
    Logic.teachingLogic:CheckGetRank()
    self:_ShowMeInfo()
  else
    self:_Refresh()
  end
end

function LeaderBoardPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.TEACHING_GetTeachRank, self._OnGetTeachRank, self)
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._OnUpdatePop, self)
end

function LeaderBoardPage:_Refresh()
  self:_ShowBoard()
  self:_ShowTip()
  self:_ShowMeInfo()
  self:_SetTipTimer()
end

function LeaderBoardPage:_OnGetTeachRank()
  self:_Refresh()
end

function LeaderBoardPage:_ShowBoard()
  self:_ShowRankRoot(true)
  local widgets = self:GetWidgets()
  local list = Logic.teachingLogic:GetTeacherList()
  if #list == 0 then
    noticeManager:ShowTip("\230\154\130\230\151\160\230\142\146\232\161\140\230\149\176\230\141\174")
  end
  local inGuild
  UIHelper.SetInfiniteItemParam(widgets.iil_rank, widgets.obj_rank, #list, function(tabParts)
    for index, luaPart in pairs(tabParts) do
      index = tonumber(index)
      local info = list[index]
      if self.m_top2img[index] then
        UIHelper.SetImage(luaPart.im_bg, self.m_top2img[index])
      else
        UIHelper.SetImage(luaPart.im_bg, "uipic_ui_teaching_bg_paihangban_qitamingci")
      end
      local icon, quality = Logic.chatLogic:GetUserHead(info)
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(info)
      UIHelper.SetImage(luaPart.obj_headFrame, headFrameInfo.icon)
      UIHelper.SetImage(luaPart.im_rankIcon, quality)
      UIHelper.SetImage(luaPart.im_girl, icon)
      UIHelper.SetText(luaPart.tx_rankNum, index)
      UIHelper.SetText(luaPart.tx_name, info.Uname)
      UIHelper.SetText(luaPart.tx_num, info.TeacherPrestige)
      inGuild = info.GuildId ~= 0
      if inGuild then
        UIHelper.SetText(luaPart.tx_dajiandui, info.GuildName)
      else
        UIHelper.SetText(luaPart.tx_dajiandui, UIHelper.GetString(2200069))
      end
      UGUIEventListener.AddButtonOnClick(luaPart.im_bg, self._OnClickItem, self, info)
      UGUIEventListener.AddButtonOnClick(luaPart.obj_dajiandui, self._OnClickGuild, self, info)
    end
  end)
end

function LeaderBoardPage:_ShowTip()
  local widgets = self:GetWidgets()
  local remain = Logic.teachingLogic:GetRankRefreshRemain()
  local tip
  if 3600 < remain then
    tip = string.format(UIHelper.GetString(2200007), time.formatTimeToHour(remain, true))
  else
    tip = string.format(UIHelper.GetString(2200007), time.getTimeStringFontDynamic(remain, true))
  end
  UIHelper.SetText(widgets.tx_tips, tip)
end

function LeaderBoardPage:_SetTipTimer()
  if self.m_rtimer then
    self:StopTimer(self.m_rtimer)
    self.m_rtimer = nil
  end
  self.m_rtimer = self:CreateTimer(function()
    self:_ShowTip()
    local remain = Logic.teachingLogic:GetRankRefreshRemain()
    if remain < 2 then
      Logic.teachingLogic:SetRankUpdateTime(0)
    end
  end, 1, -1, true)
  self:StartTimer(self.m_rtimer)
end

function LeaderBoardPage:_OnUpdatePop()
  self:_ShowMeInfo()
end

function LeaderBoardPage:_ShowMeInfo()
  local widgets = self:GetWidgets()
  local pos = Logic.teachingLogic:MyPosInRank()
  local user = Data.userData:GetUserData()
  local pop = Data.userData:GetTchRankPrestige()
  UIHelper.SetText(widgets.tx_shengwang, pop)
  widgets.obj_inrank:SetActive(0 < pos)
  widgets.obj_outrank:SetActive(pos == 0)
  UIHelper.SetText(widgets.tx_rankNum, pos)
  if Data.guildData:inGuild() then
    local name = Data.guildData:getOurGuildInfo():getName()
    UIHelper.SetText(widgets.tx_dajiandui, name)
  else
    UIHelper.SetText(widgets.tx_dajiandui, UIHelper.GetString(2200069))
  end
  UIHelper.SetText(widgets.tx_name, user.Uname)
  local icon, quality = Logic.chatLogic:GetUserHead(user)
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame(user)
  UIHelper.SetImage(widgets.obj_headFrame, headFrameInfo.icon)
  UIHelper.SetImage(widgets.im_rankIcon, quality)
  UIHelper.SetImage(widgets.im_girl, icon)
end

function LeaderBoardPage:_OnClickGuild(go, param)
  if not moduleManager:CheckFunc(FunctionID.Guild, true) then
    noticeManager:ShowTip(string.format(UIHelper.GetString(210024), "\229\133\172\228\188\154"))
    return
  end
  if param.GuildId > 0 then
    UIHelper.OpenPage("TeachingFamilyPage", param)
  else
    noticeManager:ShowTip(UIHelper.GetString(2200069))
  end
end

function LeaderBoardPage:_OnClickItem(go, param)
  UIHelper.OpenPage("TeachingMessagePage", param)
end

function LeaderBoardPage:_ShowRankRoot(enable)
  local widgets = self:GetWidgets()
  widgets.obj_rankroot:SetActive(enable)
end

function LeaderBoardPage:DoOnHide()
  self:_ShowRankRoot(false)
  self:TryStopTimer(self.m_rtimer)
end

function LeaderBoardPage:DoOnClose()
  self:TryStopTimer(self.m_rtimer)
end

function LeaderBoardPage:_GetTestParam()
  return {
    [1] = {
      Uid = 176000000577,
      Uname = "\230\181\139\232\175\149\231\142\169\229\174\182",
      Level = 10,
      Head = 10210511,
      HeadFrame = 0,
      HeadShow = 0,
      Fashioning = 0,
      GuildId = 176000000001,
      GuildName = "daoshi",
      TeacherPrestige = 100
    }
  }
end

return LeaderBoardPage
