local GuildBoxPart = class("ui.page.Guild.GuildBoxPart")
local m_select_Type = {
  Share = 1,
  Task = 2,
  All = 3
}

function GuildBoxPart:initialize(page)
  self.guildPage = page
  self.widgetsTab = page.tab_Widgets.lp_GuildBox:GetLuaTableParts()
  self.rewardTimer = {}
  self.showListMax = 0
  self:OnInit()
  self:RegisterEvent()
end

function GuildBoxPart:RegisterEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_scoreReward, self.OnBtnScoreBoxClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_getAll, self.OnBtnGetAllClick, self)
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_help, self.OnBtnHelpClick, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.widgetsTab.tog_group, self, "", self.SwitchTogs)
  UGUIEventListener.AddButtonToggleChanged(self.widgetsTab.tog_hideName, self.HideName, self)
end

function GuildBoxPart:DoOnShow()
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxScoreData, self.ShowPointBoxData, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxUserData, self.ShowPointBoxData, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxShareAdd, self.UpdateShareBoxInfo, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxTaskAdd, self.UpdateTaskBoxInfo, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxShareState, self.UpdateShareBoxInfo, self)
  eventManager:RegisterEvent(LuaEvent.UpdateGuildBoxTaskState, self.UpdateTaskBoxInfo, self)
end

function GuildBoxPart:UnRegisterEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxScoreData, self.ShowPointBoxData, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxUserData, self.ShowPointBoxData, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxShareAdd, self.UpdateShareBoxInfo, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxTaskAdd, self.UpdateTaskBoxInfo, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxShareState, self.UpdateShareBoxInfo, self)
  eventManager:UnregisterEvent(LuaEvent.UpdateGuildBoxTaskState, self.UpdateTaskBoxInfo, self)
end

function GuildBoxPart:StopAllTimer()
  for _, v in pairs(self.rewardTimer) do
    v:Stop()
  end
  self.rewardTimer = {}
end

function GuildBoxPart:OnInit()
  self.m_Toggle_IndexCfg = {
    [1] = {
      fun = function()
        self:ShowShareBoxInfo()
      end,
      index = 1
    },
    [2] = {
      fun = function()
        self:ShowTaskBoxInfo()
      end,
      index = 2
    }
  }
end

function GuildBoxPart:SwitchTogs(index)
  self:StopAllTimer()
  local realIndex = index + 1
  self.FunToggleIndex = realIndex
  self.m_Toggle_IndexCfg[realIndex].fun()
end

function GuildBoxPart:HideName(go, isOn)
  if isOn then
    Service.guildService:SendGuildBoxAnonymous(1)
  else
    Service.guildService:SendGuildBoxAnonymous(0)
  end
end

function GuildBoxPart:Show()
  self:StopAllTimer()
  local boxData = Data.guildData:GetGuildBoxData()
  boxData:RefreshRewardList(m_select_Type.All)
  self.showListMax = configManager.GetDataById("config_parameter", 520).value
  self:DoOnShow()
  self:ShowPointBoxData()
  self.widgetsTab.tog_group:SetActiveToggleIndex(0)
end

function GuildBoxPart:ShowPointBoxData()
  local scoreCfg = configManager.GetDataById("config_guildboxscore", 1)
  local boxData = Data.guildData:GetGuildBoxData()
  local isHideName = boxData:GetAnonymous()
  self.widgetsTab.tog_hideName.isOn = isHideName == 1
  local boxNum = boxData:GetPointsBoxCount()
  if boxNum > scoreCfg.maxnum then
    LogError("\231\167\175\229\136\134\229\174\157\231\174\177\230\149\176\233\135\143\232\182\133\228\184\138\233\153\144\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129boxNum:", boxNum)
    boxNum = scoreCfg.maxnum
  end
  self.widgetsTab.obj_imgNumBG:SetActive(0 < boxNum)
  UIHelper.SetText(self.widgetsTab.txt_scoreReward, boxNum)
  local img = Logic.guildLogic:GetPointsBoxImgByCount(boxNum)
  UIHelper.SetImage(self.widgetsTab.img_Box, img)
  local curScore = boxData:GetScoreProgress()
  self.widgetsTab.sl_scoreReward.value = curScore / scoreCfg.score
  local text = curScore .. "/" .. scoreCfg.score
  UIHelper.SetText(self.widgetsTab.txt_boxNum, text)
end

function GuildBoxPart:ShowShareBoxInfo()
  local boxData = Data.guildData:GetGuildBoxData()
  local shareBoxList = boxData:GetShareBoxList()
  self.widgetsTab.btn_getAll.gameObject:SetActive(false)
  self:CreateGuildBoxInfo(shareBoxList)
end

function GuildBoxPart:ShowTaskBoxInfo()
  local boxData = Data.guildData:GetGuildBoxData()
  local taskBoxList = boxData:GetTaskBoxList()
  local canGet = boxData:CheckCanGetTaskBox()
  self.widgetsTab.btn_getAll.gameObject:SetActive(canGet)
  self:CreateGuildBoxInfo(taskBoxList)
end

function GuildBoxPart:CreateGuildBoxInfo(guildBoxList)
  local showCount = #guildBoxList
  if showCount > self.showListMax then
    showCount = self.showListMax
  end
  self.widgetsTab.obj_nothing:SetActive(showCount <= 0)
  UIHelper.SetInfiniteItemParam(self.widgetsTab.scr_rewardsList, self.widgetsTab.obj_item, showCount, function(parts)
    for k, part in pairs(parts) do
      if #part.gameObject.name > 1 then
        part.gameObject.name = k
      end
      local index = tonumber(k)
      self:UpdateRewardItemPart(index, part, guildBoxList[index])
    end
  end)
end

function GuildBoxPart:UpdateRewardItemPart(index, part, rewardData)
  local realIndex = part.gameObject.name
  local uid = Data.userData:GetUserUid()
  part.img_bg:SetActive(uid ~= rewardData.boxUid)
  part.img_bgself:SetActive(uid == rewardData.boxUid)
  local name = UIHelper.GetString(3701000)
  if rewardData.boxUid ~= 0 then
    local ourGuild = Data.guildData:getOurGuildInfo()
    name = ourGuild:GetGuildMemberNameByUid(rewardData.boxUid)
  end
  local descId = 3701001
  if rewardData.type == 2 then
    descId = 3701002
  end
  local showStr = string.format(UIHelper.GetString(descId), name, rewardData.rewardName)
  UIHelper.SetText(part.txt_desc, showStr)
  if rewardData.isPick then
    part.btn_getReward.gameObject:SetActive(false)
    part.obj_get:SetActive(true)
    if self.rewardTimer[realIndex] ~= nil then
      self.rewardTimer[realIndex]:Stop()
      self.rewardTimer[realIndex] = nil
    end
    UIHelper.SetText(part.txt_time, "")
  else
    part.btn_getReward.gameObject:SetActive(true)
    part.obj_get:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btn_getReward, self.btnGetRewardOnClick, self, rewardData.boxId)
    local starTime = time.getSvrTime()
    local remainTime = rewardData.endTime - starTime
    if 0 <= remainTime then
      local function func()
        local curTime = time.getSvrTime()
        
        local curRemainTime = rewardData.endTime - curTime
        if 0 < curRemainTime then
          local timeRemainStr = time.getTimeStringFontDynamic(curRemainTime, true)
          timeRemainStr = string.format(UIHelper.GetString(3701005), timeRemainStr)
          UIHelper.SetText(part.txt_time, timeRemainStr)
        else
          self:closeTargetTimer(realIndex)
        end
      end
      
      if self.rewardTimer[realIndex] ~= nil then
        self.rewardTimer[realIndex]:Stop()
        self.rewardTimer[realIndex] = nil
      end
      self.rewardTimer[realIndex] = Timer.New(func, 1, -1, false)
      self.rewardTimer[realIndex]:Start()
    else
      self:closeTargetTimer(realIndex)
    end
  end
end

function GuildBoxPart:closeTargetTimer(index)
  noticeManager:ShowTipById(3701004)
  if self.rewardTimer[index] ~= nil then
    self.rewardTimer[index]:Stop()
    self.rewardTimer[index] = nil
  end
  local boxData = Data.guildData:GetGuildBoxData()
  boxData:RefreshRewardList(self.FunToggleIndex)
  self:SwitchTogs(self.FunToggleIndex - 1)
end

function GuildBoxPart:btnGetRewardOnClick(go, param)
  if self.FunToggleIndex == m_select_Type.Share then
    Service.guildService:SendGuildBoxPickShare(param)
  elseif self.FunToggleIndex == m_select_Type.Task then
    Service.guildService:SendGuildBoxPickTask(param)
  end
end

function GuildBoxPart:OnBtnScoreBoxClick()
  local boxData = Data.guildData:GetGuildBoxData()
  local boxNum = boxData:GetPointsBoxCount()
  if boxNum <= 0 then
    return
  end
  Service.guildService:SendGuildBoxPickPoints()
end

function GuildBoxPart:OnBtnGetAllClick()
  local boxData = Data.guildData:GetGuildBoxData()
  local canGet = boxData:CheckCanGetTaskBox()
  if canGet then
    Service.guildService:SendGuildBoxPickAllTaskBox()
  end
end

function GuildBoxPart:OnBtnHelpClick()
  UIHelper.OpenPage("HelpPage", {content = 3701009})
end

function GuildBoxPart:UpdateShareBoxInfo()
  local boxData = Data.guildData:GetGuildBoxData()
  boxData:RefreshRewardList(m_select_Type.Share)
  if self.FunToggleIndex == m_select_Type.Share then
    self:ShowShareBoxInfo()
  end
end

function GuildBoxPart:UpdateTaskBoxInfo()
  local boxData = Data.guildData:GetGuildBoxData()
  boxData:RefreshRewardList(m_select_Type.Task)
  if self.FunToggleIndex == m_select_Type.Task then
    self:ShowTaskBoxInfo()
  end
end

function GuildBoxPart:OnHide()
  self:UnRegisterEvent()
  self:StopAllTimer()
end

function GuildBoxPart:OnClose()
  self:UnRegisterEvent()
  self:StopAllTimer()
end

return GuildBoxPart
