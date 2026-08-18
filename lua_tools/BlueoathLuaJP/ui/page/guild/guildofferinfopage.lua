local GuildOfferInfoPage = class("UI.Guild.GuildOfferInfoPage", LuaUIPage)
local taskStateStr = {
  [0] = "\232\191\155\232\161\140\228\184\173",
  [1] = UIHelper.GetString(3700007),
  [2] = UIHelper.GetString(3700008),
  [3] = "\232\182\133\230\151\182"
}
local taskState = {
  Doing = 0,
  Complete = 1,
  Abondon = 2,
  TimeOut = 3
}

function GuildOfferInfoPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function GuildOfferInfoPage:DoOnOpen()
  self.param = self:GetParam()
  self.partContainer = {}
  self.userInfoContainer = {}
  self.otherUsertab = {}
  self.userDic = {}
  self.UserHadRev = false
  self.taskInfo = self.param.taskInfo
  self.config = self.param.config
  self.userId = Data.userData:GetUserUid()
  self:SetGuildOfferInfo()
  self:LoadContentInfo()
  self:CreateTaskTimer()
end

function GuildOfferInfoPage:SetGuildOfferInfo()
  UIHelper.SetText(self.m_tabWidgets.textName, self.config.desc)
  UIHelper.SetText(self.m_tabWidgets.textScoreNum, self.config.score)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.BtnAccept, function()
    local allConut, receiveCount = Data.guildOfferData:GetTaskCount()
    if #self.taskInfo.AcceptInfo >= self.config.applynum then
      self:ShowMsg(3700002)
      return
    end
    if self.UserHadRev then
      self:ShowMsg(3700017)
      return
    end
    if receiveCount < allConut then
      local curCount, maxCount = Data.guildOfferData:GetReceiveTaskCount()
      maxCount = Data.guildOfferData:GetReceiveTaskMaxCount()
      if curCount < maxCount then
        Service.guildService:SendGuildAddOffer(self.taskInfo.TaskIndex, self.taskInfo.TaskId)
      else
        self:ShowMsg(3700004)
      end
    else
      self:ShowMsg(3700002)
    end
  end, self)
  UIHelper.SetText(self.m_tabWidgets.txt_count, #self.taskInfo.AcceptInfo .. "/" .. self.config.applynum)
  UIHelper.SetText(self.m_tabWidgets.txt_receiveCount, #self.taskInfo.AcceptInfo .. "/" .. self.config.applynum)
end

function GuildOfferInfoPage:_GetOtherUserInfoCallBack(param)
  local uid = param.Uid
  if self.userDic then
    self.userDic[uid] = param
  end
  for _, v in pairs(self.userInfoContainer) do
    if self.userDic[v.uid] then
      UIHelper.SetText(v.part.textName, self.userDic[v.uid].Uname)
    end
  end
end

function GuildOfferInfoPage:LoadContentInfo()
  if self.taskInfo and self.taskInfo.AcceptInfo then
    self.userInfoContainer = {}
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trs_Content, #self.taskInfo.AcceptInfo, function(index, part)
      local StateStr = ""
      local uid = self.taskInfo.AcceptInfo[index].Uid
      if self.taskInfo.AcceptInfo[index].State == taskState.Doing then
        if self.userId == uid then
          self.UserHadRev = true
        end
        part.data = self.taskInfo.AcceptInfo[index]
        self.partContainer[index] = part
        local limitTime = self.config.limittime
        local startTime = part.data.Time
        local remainTime = startTime + limitTime - time.getSvrTime()
        local timeStr = time.getHoursString(0 < remainTime and remainTime or 0)
        UIHelper.SetText(part.textStatue, string.format(UIHelper.GetString(3700006), timeStr))
      else
        StateStr = taskStateStr[self.taskInfo.AcceptInfo[index].State]
        UIHelper.SetText(part.textStatue, StateStr)
      end
      local partData = {}
      partData.part = part
      partData.uid = uid
      self.userInfoContainer[index] = partData
      if self.userId ~= uid then
        Service.userService:SendGetOtherInfo(uid)
      else
        UIHelper.SetText(part.textName, Data.userData:GetUserName())
      end
    end)
  end
end

function GuildOfferInfoPage:ShowMsg(id)
  local showText = UIHelper.GetString(id)
  noticeManager:OpenTipPage(self, showText)
end

function GuildOfferInfoPage:CreateTaskTimer()
  if self.activityTimer ~= nil then
    self:StopTimer(self.activityTimer)
    self.activityTimer = nil
  end
  if next(self.partContainer) ~= nil then
    self.activityTimer = self:CreateTimer(function()
      local now = time.getSvrTime()
      for k, v in pairs(self.partContainer) do
        local limitTime = self.config.limittime
        local startTime = v.data.Time
        local remainTime = startTime + limitTime - now
        local timeStr = time.getHoursString(0 < remainTime and remainTime or 0)
        UIHelper.SetText(v.textStatue, string.format(UIHelper.GetString(3700006), timeStr))
      end
    end, 1, -1, false)
    self:StartTimer(self.activityTimer)
  end
end

function GuildOfferInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, function()
    UIHelper.ClosePage("GuildOfferInfoPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.BtnAccept, function()
  end)
  self:RegisterEvent(LuaEvent.UpdateUserGOTaskInfo, self.UpdatePage, self)
  self:RegisterEvent(LuaEvent.GetOtherUserInfoByUid, self._GetOtherUserInfoCallBack, self)
end

function GuildOfferInfoPage:UpdatePage()
  UIHelper.ClosePage("GuildOfferInfoPage")
end

function GuildOfferInfoPage:DoOnHide()
end

function GuildOfferInfoPage:DoOnClose()
end

return GuildOfferInfoPage
