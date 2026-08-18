local PveRoomLogic = class("logic.PveRoomLogic")

function PveRoomLogic:initialize()
  self:SetCopyList()
  self.isAutoCounting = false
  self.inviteTimeData = {}
end

function PveRoomLogic:SetCopyList()
  self.copyList = {}
  local chapterList = configManager.GetDataById("config_parameter", 528).arrValue
  for _, v in pairs(chapterList) do
    local chapterCfg = configManager.GetDataById("config_chapter", v)
    for _, copyId in pairs(chapterCfg.level_list) do
      local copyCfg = configManager.GetDataById("config_copy_display", copyId)
      if copyCfg.is_match ~= 3 then
        table.insert(self.copyList, copyId)
      end
    end
  end
  table.sort(self.copyList, function(data1, data2)
    return data1 < data2
  end)
end

function PveRoomLogic:ResetData()
  self.pveTacticFleetMax = 4
  self.timer = nil
  self.counting = 0
  self.countingTime = configManager.GetDataById("config_parameter", 456).value
  self.pageWidgets = {}
  self.inPveRoom = false
  self.bAutoRepaire = true
end

function PveRoomLogic:RegisterEvent()
  eventManager:RegisterEvent(LuaEvent.UpdatePveRoomInfo, self._CheckAutoStart, self)
  self.inPveRoom = true
end

function PveRoomLogic:UnregisterEvent()
  eventManager:UnregisterEvent(LuaEvent.UpdatePveRoomInfo, self._CheckAutoStart, self)
  self.inPveRoom = false
end

function PveRoomLogic:GetInRoomState()
  return self.inPveRoom
end

function PveRoomLogic:SetPageWidgets(widgets)
  self.pageWidgets = widgets
  self.isAutoCounting = false
end

function PveRoomLogic:GetPveCopyDisplay(copyId)
  local copy = configManager.GetDataById("config_copy", copyId)
  local copyDisInfo = Logic.copyLogic:GetCopyDesConfig(copy.copy_id)
  return copyDisInfo
end

function PveRoomLogic:SetPveTacticNum(copyId)
  local copyDisplay = self:GetPveCopyDisplay(copyId)
  self.pveTacticFleetMax = copyDisplay.assist_fleet_num
end

function PveRoomLogic:GetPveTacticNum()
  return self.pveTacticFleetMax
end

function PveRoomLogic:GetRoomPlayerMax(copyId)
  local copy = configManager.GetDataById("config_copy", copyId)
  return copy.match_player_num
end

function PveRoomLogic:GetRandeRoomId(roomList, copyId)
  local pveRoomPlayerMax = self:GetRoomPlayerMax(copyId)
  for _, v in ipairs(roomList) do
    if v.RoomId > 0 and pveRoomPlayerMax > #v.RoomUsers then
      return v.RoomId
    end
  end
  return 0
end

function PveRoomLogic:CheckCanJoinRoom(roomId)
  if self:CheckExpend() and self:CheckPresetFleet() and self:CheckUserBagFull() and self:CheckEquipBagFull() then
    return true
  else
    return false
  end
end

function PveRoomLogic:CheckExpend()
  local pvePtOwnNum = Data.userData:GetCurrency(CurrencyType.PVEPT)
  if pvePtOwnNum <= 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(6100023))
    return false
  end
  return true
end

function PveRoomLogic:CheckPresetFleet()
  local presetFleetData = Data.presetFleetData:GetPresetFleetData()
  if #presetFleetData == 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(6100027))
    return false
  end
  return true
end

function PveRoomLogic:CheckUserBagFull()
  if Logic.copyLogic:CheckDockFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("HeroRetirePage")
        end
      end,
      nameOk = UIHelper.GetString(180029)
    }
    noticeManager:ShowMsgBox(110012, tabParams)
    return false
  end
  return true
end

function PveRoomLogic:CheckEquipBagFull()
  if Logic.copyLogic:CheckEquipBagFull() then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("DismantlePage")
        end
      end
    }
    noticeManager:ShowMsgBox(1000014, tabParams)
    return false
  end
  return true
end

function PveRoomLogic:GetOwnerName(roomInfo)
  local ownerId = roomInfo.OwnerId
  if roomInfo.RoomUsers == nil then
    return ""
  end
  for _, v in ipairs(roomInfo.RoomUsers) do
    if v.Uid == ownerId then
      return v.Name
    end
  end
end

function PveRoomLogic:CheckIsOwner(roomInfo)
  local userId = Data.userData:GetUserUid()
  local ownerId = roomInfo.OwnerId
  return userId == ownerId
end

function PveRoomLogic:GetPveCopyName(copyId)
  local copy = configManager.GetDataById("config_copy", copyId)
  local copyDisInfo = Logic.copyLogic:GetCopyDesConfig(copy.copy_id)
  return copyDisInfo.name
end

function PveRoomLogic:SortRoomUsers(roomUsers)
  table.sort(roomUsers, function(data1, data2)
    return data1.EnterTime < data2.EnterTime
  end)
  return roomUsers
end

function PveRoomLogic:GetExitUserName(roomInfoTab)
  local refreshBeforeData = Data.pveRoomData:GetRefreshBeforeData()
  local beforeUserTab = refreshBeforeData.RoomUsers
  local nowUserTab = roomInfoTab.RoomUsers
  local tempMap = {}
  for _, v in ipairs(nowUserTab) do
    tempMap[v.Uid] = v.Name
  end
  for _, y in ipairs(beforeUserTab) do
    local contain = table.containKey(tempMap, y.Uid)
    if not contain then
      return y.Name
    end
  end
  return ""
end

function PveRoomLogic:GetOperationUserId(roomInfoTab)
  local refreshBeforeData = Data.pveRoomData:GetRefreshBeforeData()
  local beforeUserTab = refreshBeforeData.RoomUsers
  local nowUserTab = roomInfoTab.RoomUsers
  local tempMap = {}
  for _, v in ipairs(nowUserTab) do
    tempMap[v.Uid] = v.Uid
  end
  for _, y in ipairs(beforeUserTab) do
    local contain = table.containV(tempMap, y.Uid)
    if not contain then
      return y.Uid
    end
  end
  return ""
end

function PveRoomLogic:CheckUserReady(roomInfoTab)
  for _, v in ipairs(roomInfoTab.RoomUsers) do
    if v.Uid ~= roomInfoTab.OwnerId and not v.IsReady then
      return false
    end
  end
  return true
end

function PveRoomLogic:PresetFleetShowTip()
  local presetFleetData = Data.presetFleetData:GetPresetFleetData()
  if #presetFleetData == 0 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.OpenPage("PresetFleetPage", {
            presetFleetType = PresetFleetType.MatchDetail
          })
        end
      end,
      nameOk = UIHelper.GetString(6100061)
    }
    noticeManager:ShowMsgBox(6100027, tabParams)
    return false
  end
  return true
end

function PveRoomLogic:CheckUpCardAct()
  local actOpen = Logic.activityLogic:CheckOpenActivityByType(ActivityType.ActDropUpCard)
  return actOpen
end

function PveRoomLogic:CheckUpRewardCopy(copyType)
end

function PveRoomLogic:CheckRewardsUp(param)
  local actOpen = self:CheckUpCardAct()
  if not actOpen then
    return false
  end
  local actId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActDropUpCard)
  local actConfig = configManager.GetDataById("config_activity", actId)
  local chapterType = Logic.copyLogic:GetChapterTypeByCopyId(param.copyInfo.id)
  if actConfig.p3[1] ~= chapterType then
    return false
  end
  local fleetShipId = {}
  for _, v in ipairs(param.myFleetList[1]) do
    fleetShipId[v.si_id] = v.si_id
  end
  for _, shipId in ipairs(actConfig.p1) do
    if fleetShipId[shipId] ~= nil then
      return true
    end
  end
  return false
end

function PveRoomLogic:_CheckAutoStart()
  local roomInfoTab = Data.pveRoomData:GetPveRoomData()
  local pveRoomPlayerMax = self:GetRoomPlayerMax(roomInfoTab.CopyId)
  if pveRoomPlayerMax == #roomInfoTab.RoomUsers and roomInfoTab.Reason == UpdatePveRoom.RoomReady then
    if Logic.pveRoomLogic:CheckUserReady(roomInfoTab) then
      Logic.pveRoomLogic:StartBattleTimer()
    end
  else
    if roomInfoTab.Reason == UpdatePveRoom.RoomUploadTactic or roomInfoTab.Reason == UpdatePveRoom.RoomSwitchRoomPublicState then
      return
    end
    Logic.pveRoomLogic:StopCounting()
  end
end

function PveRoomLogic:StartBattleTimer()
  if self.timer == nil then
    self.timer = Timer.New(function()
      self.counting = self.counting + 1
      self.pageWidgets.txt_startTimer.gameObject:SetActive(true)
      self.pageWidgets.txt_startTimer.text = string.format(UIHelper.GetString(6100039), self.countingTime - self.counting)
      if self.counting == self.countingTime then
        self:StopCounting()
        UIHelper.ClosePage("CommonSelectPage")
        UIHelper.ClosePage("SuperStrategyPage")
        UIHelper.ClosePage("PresetFleetPage")
        if Logic.pveRoomLogic:CheckIsOwner(Data.pveRoomData:GetPveRoomData()) then
          eventManager:SendEvent(LuaEvent.PveRoomStart)
        end
        return
      end
    end, 1, -1, false)
  end
  self.timer:Start()
  self.isAutoCounting = true
end

function PveRoomLogic:StopCounting()
  if self.timer ~= nil then
    self.timer:Stop()
    self.counting = 0
    self.timer = nil
    self.pageWidgets.txt_startTimer.gameObject:SetActive(false)
    self.isAutoCounting = false
  end
end

function PveRoomLogic:GetAutoCountingState()
  return self.isAutoCounting
end

function PveRoomLogic:GetAutoRepaireInfo()
  return self.bAutoRepaire
end

function PveRoomLogic:SetAutoRepaireInfo(isAuto)
  self.bAutoRepaire = isAuto
end

function PveRoomLogic:GetAllCopyList()
  return self.copyList
end

function PveRoomLogic:SetInviteTime(roomid, time)
  if not self.inviteTimeData[roomid] then
    self.inviteTimeData = {}
    self.inviteTimeData[roomid] = time
  else
    self.inviteTimeData[roomid] = time
  end
end

function PveRoomLogic:GetInviteTime(roomid)
  return self.inviteTimeData[roomid]
end

return PveRoomLogic
