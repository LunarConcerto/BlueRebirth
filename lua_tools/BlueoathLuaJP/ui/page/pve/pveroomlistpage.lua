local PveRoomListPage = class("UI.Pve.PveRoomListPage", LuaUIPage)

function PveRoomListPage:DoInit()
  self.roomList = {}
  self.refreshTimer = nil
  self.clickRefresh = false
  self.timerCount = 0
  self.copyId = 0
  self.showCopyList = false
end

function PveRoomListPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_random, self._ClickRandom, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_refresh, self._ClickRefresh, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickTrue, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCancel, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_noticeClose, self._ClickCloseNotice, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_Show, self.ClickBtnShow, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeSelect, self.CloseCopyList, self)
  self:RegisterEvent(LuaEvent.RefreshRoomInfo, self._PveRoomOpen, self)
  self:RegisterEvent(LuaEvent.CreatePveRoom, self._PveRoomOpen, self)
  self:RegisterEvent(LuaEvent.GetRoomList, self._RefreshRoomList, self)
  self:RegisterEvent(LuaEvent.PveRoomEnterRoom, self._SendGetList, self)
  self:RegisterEvent(LuaEvent.RefreshRoomInfo, self.BackEnterRoomInfo, self)
end

function PveRoomListPage:DoOnOpen()
  self.copyId = self:GetParam()
  self.refreshInterval = configManager.GetDataById("config_parameter", 455).value
  Service.pveRoomService:SendGetRoomList(self.copyId, "refresh")
  self:ShowCopySelect()
end

function PveRoomListPage:ShowCopySelect()
  self.tab_Widgets.obj_closeSelect:SetActive(false)
  self.tab_Widgets.obj_copyList:SetActive(false)
  local copyName = ""
  if self.copyId == 0 then
    copyName = UIHelper.GetString(4800100)
  else
    local copyDisplayCfg = configManager.GetDataById("config_copy_display", self.copyId)
    copyName = copyDisplayCfg.name
  end
  UIHelper.SetText(self.tab_Widgets.txt_name, copyName)
end

function PveRoomListPage:ShowAllCopyList()
  local copyList = Logic.pveRoomLogic:GetAllCopyList()
  self.tab_Widgets.group_copyList:ClearToggles()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyItem, self.tab_Widgets.trans_copyList, #copyList + 1, function(index, uiPart)
    local name = ""
    local copyId = 0
    if index == 1 then
      name = UIHelper.GetString(4800100)
    else
      local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyList[index - 1])
      name = copyDisplayCfg.name
      copyId = copyList[index - 1]
    end
    UIHelper.SetText(uiPart.txt_name, name)
    self.tab_Widgets.group_copyList:RegisterToggle(uiPart.tog_copy)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_copyList, self, copyList, self.SwitchTogs)
end

function PveRoomListPage:SwitchTogs(index, param)
  if index == 0 then
    self.copyId = 0
  else
    self.copyId = param[index]
  end
  Service.pveRoomService:SendGetRoomList(self.copyId, "refresh")
  local copyName = ""
  if self.copyId == 0 then
    copyName = UIHelper.GetString(4800100)
  else
    local copyDisplayCfg = configManager.GetDataById("config_copy_display", self.copyId)
    copyName = copyDisplayCfg.name
  end
  UIHelper.SetText(self.tab_Widgets.txt_name, copyName)
end

function PveRoomListPage:_RefreshRoomList(ret)
  self.roomList = ret.roomList
  self.state = ret.state
  if self.state == "randm" then
    UIHelper.SetUILock(false)
    self:_ClickRandom()
  else
    self:_CreateRoomList()
  end
end

function PveRoomListPage:_CreateRoomList()
  if #self.roomList == 0 then
    self.tab_Widgets.trans_content.gameObject:SetActive(false)
    return
  end
  self.tab_Widgets.trans_content.gameObject:SetActive(true)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_content, self.tab_Widgets.item_roominfo, #self.roomList, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for index, luaPart in pairs(tabTemp) do
      local ownerName = Logic.pveRoomLogic:GetOwnerName(self.roomList[index])
      local roomInfo = self.roomList[index]
      UIHelper.SetText(luaPart.txt_name, ownerName)
      local inRoomPlayer = roomInfo.RoomUsers
      local pveRoomPlayerMax = Logic.pveRoomLogic:GetRoomPlayerMax(self.roomList[index].CopyId)
      UIHelper.CreateSubPart(luaPart.item, luaPart.trans_team, pveRoomPlayerMax, function(nIndex, tabPart)
        local playerInfo = inRoomPlayer[nIndex]
        tabPart.im_quality.gameObject:SetActive(playerInfo ~= nil)
        tabPart.obj_empty:SetActive(playerInfo == nil)
        if playerInfo ~= nil then
          local headIcon, qualityIcon = Data.userData:GetUserHeadIcon(playerInfo)
          UIHelper.SetImage(tabPart.im_headIcon, headIcon)
          UIHelper.SetImage(tabPart.im_quality, qualityIcon)
        end
      end)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_battle, self._ClickBattle, self, self.roomList[index].RoomId)
    end
  end)
end

function PveRoomListPage:_ClickBattle(go, roomId)
  if not Logic.pveRoomLogic:CheckCanJoinRoom() then
    return
  end
  Service.pveRoomService:SendEnterRoom(roomId)
end

function PveRoomListPage:_PveRoomOpen()
  self:_ClickCloseNotice()
  self:_ClickClose()
end

function PveRoomListPage:_ClickRandom()
  if self.copyId == 0 then
    local copyList = Logic.pveRoomLogic:GetAllCopyList()
    local roomId = 0
    for _, v in pairs(copyList) do
      local getId = Logic.pveRoomLogic:GetRandeRoomId(self.roomList, v)
      if getId ~= 0 then
        roomId = getId
        break
      end
    end
    if roomId == 0 then
      self.tab_Widgets.obj_notice:SetActive(true)
    else
      self:_ClickBattle(nil, roomId)
    end
  else
    self:GetRandeRoomId(self.copyId)
  end
end

function PveRoomListPage:GetRandeRoomId(copyId)
  local roomId = Logic.pveRoomLogic:GetRandeRoomId(self.roomList, copyId)
  if roomId == 0 then
    self.tab_Widgets.obj_notice:SetActive(true)
  else
    self:_ClickBattle(nil, roomId)
  end
end

function PveRoomListPage:_ClickTrue()
  if not Logic.pveRoomLogic:CheckCanJoinRoom() then
    return
  end
  if self.copyId == 0 then
    noticeManager:ShowTipById(4800115)
    return
  end
  Service.pveRoomService:SendCreateRoom(self.copyId)
end

function PveRoomListPage:_ClickCancel()
  UIHelper.SetUILock(true)
  self:_ClickCloseNotice()
  Service.pveRoomService:SendGetRoomList(self.copyId, "randm")
end

function PveRoomListPage:_ClickCloseNotice()
  self.tab_Widgets.obj_notice:SetActive(false)
end

function PveRoomListPage:_ClickRefresh()
  if self.clickRefresh == true then
    noticeManager:OpenTipPage(self, UIHelper.GetString(6100043))
    return
  end
  self.timerCount = 0
  self.refreshTimer = self:CreateTimer(function()
    if self.refreshInterval <= self.timerCount then
      self:StopTimer(self.refreshTimer)
      self.clickRefresh = false
      self.refreshTimer = nil
      self.timerCount = 0
    else
      self.timerCount = self.timerCount + 1
    end
  end, 1, -1, false)
  self:StartTimer(self.refreshTimer)
  self.clickRefresh = true
  Service.pveRoomService:SendGetRoomList(self.copyId, "refresh")
end

function PveRoomListPage:ClickBtnShow()
  self.showCopyList = not self.showCopyList
  if self.showCopyList then
    self.tab_Widgets.obj_closeSelect:SetActive(true)
    self.tab_Widgets.obj_copyList:SetActive(true)
    self:ShowAllCopyList()
  else
    self.tab_Widgets.obj_copyList:SetActive(false)
  end
end

function PveRoomListPage:CloseCopyList()
  self.tab_Widgets.obj_closeSelect:SetActive(false)
  self.tab_Widgets.obj_copyList:SetActive(false)
end

function PveRoomListPage:_SendGetList(err)
  if err ~= 0 then
    Service.pveRoomService:SendGetRoomList(self.copyId, "refresh")
  end
end

function PveRoomListPage:BackEnterRoomInfo(errcode)
  if errcode == nil or errcode == 0 then
    UIHelper.OpenPage("PVERoomPage")
    UIHelper.ClosePage("PveRoomListPage")
  end
end

function PveRoomListPage:_ClickClose()
  UIHelper.ClosePage("PveRoomListPage")
end

function PveRoomListPage:DoOnClose()
  if self.refreshTimer ~= nil then
    self:StopTimer(self.refreshTimer)
    self.refreshTimer = nil
  end
end

return PveRoomListPage
