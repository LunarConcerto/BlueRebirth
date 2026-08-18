local PVECopyDetailPage = class("UI.Pve.PVECopyDetailPage", LuaUIPage)
local DropInfoType = {firstPassReward = 3}

function PVECopyDetailPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_singleCopy = {}
  self.m_mulitCopy = {}
  self.m_openCount = 0
end

function PVECopyDetailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_instruction, self.OpenInstruction, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_shop, self.OpenShop, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_fleet, self.OpenPresetFleet, self)
  self:RegisterEvent(LuaEvent.CreatePveRoom, self.BackCreateRoom, self)
  self:RegisterEvent(LuaEvent.RefreshRoomInfo, self.BackCreateRoom, self)
end

function PVECopyDetailPage:DoOnOpen()
  self.m_singleCopy = {}
  self.m_mulitCopy = {}
  local param = self:GetParam()
  self:SplitCopy(param)
  self:OpenTopPage("PVECopyDetailPage", 1, UIHelper.GetString(6100059), self, true)
  eventManager:SendEvent(LuaEvent.TopShowPvePt)
  self:GetCellConfigData()
  self:CreateCopyInfo()
end

function PVECopyDetailPage:GetCellConfigData()
  self.m_copyCellDelta = configManager.GetDataById("config_parameter", 458).value
  self.m_matchModeCellDelta = configManager.GetDataById("config_parameter", 459).value
end

function PVECopyDetailPage:SplitCopy(param)
  if param and param.level_list ~= nil then
    for index = 1, #param.level_list do
      if index % 2 == 0 then
        table.insert(self.m_mulitCopy, param.level_list[index])
      else
        table.insert(self.m_singleCopy, param.level_list[index])
      end
    end
  end
end

function PVECopyDetailPage:CopyIdClick(index, copyId)
  logError("CopyIdClick:", copyId, ",index:", index)
end

function PVECopyDetailPage:BackCreateRoom(errCode)
  if errCode == nil or errCode == 0 then
    UIHelper.OpenPage("PVERoomPage", self.m_mulitCopy)
  else
    self:ShowMsgByLanguageId(6100032)
  end
end

function PVECopyDetailPage:SingleBattleBtnClick(copyId)
  self.m_tabServiceData = Data.copyData:GetCopyInfo()
  local isHasFleet = Logic.fleetLogic:IsHasFleet(FleetType.Normal)
  if not isHasFleet then
    noticeManager:ShowMsgBox(110007)
    return
  end
  if Data.copyData:GetCopyInfoById(copyId) == nil then
    logError("\229\188\130\229\184\184 \229\189\147\229\137\141\229\133\179\229\141\161\230\178\161\230\156\137\230\149\176\230\141\174!!!\239\188\140copyId\239\188\154", copyId)
    return
  end
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = Data.copyData:GetCopyInfoById(copyId),
    chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId),
    IsRunningFight = false,
    copyId = copyId,
    battleMode = BattleMode.Normal
  }
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function PVECopyDetailPage:MulitBattleBtnClick(copyId)
  copyId = Logic.copyLogic:GetCopyIdByCopy_DisplayId(copyId)
  if copyId == 0 then
    self:ShowMsgByLanguageId(6100022)
    return
  end
  local presetFleet = Logic.pveRoomLogic:PresetFleetShowTip(copyId)
  if not presetFleet then
    return
  end
  if not Logic.pveRoomLogic:CheckCanJoinRoom() then
    return
  end
  Service.pveRoomService:SendCreateRoom(copyId)
end

function PVECopyDetailPage:RoomListBtnClick(copyId)
  local presetFleet = Logic.pveRoomLogic:PresetFleetShowTip(copyId)
  if not presetFleet then
    return
  end
  copyId = Logic.copyLogic:GetCopyIdByCopy_DisplayId(copyId)
  UIHelper.OpenPage("PveRoomListPage", copyId)
end

function PVECopyDetailPage:CreateCopyInfo()
  self.m_openCount = self.m_openCount + 1
  UIHelper.CreateSubPart(self.m_tabWidgets.item_copy, self.m_tabWidgets.trans_content, #self.m_singleCopy, function(index, part)
    local copyId = self.m_singleCopy[index]
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local recommondInfo = copyConfig.recommend_info
    if recommondInfo and 2 <= #recommondInfo then
      UIHelper.SetText(part.txt_battle, recommondInfo[1])
      UIHelper.SetText(part.txt_level, recommondInfo[2])
    end
    local pos = part.obj_child_copy.transform.localPosition
    if index % 2 == 0 and self.m_openCount == 1 then
      part.obj_child_copy.transform.localPosition = Vector3.New(pos.x + self.m_copyCellDelta, pos.y, 0)
    end
    UIHelper.SetImage(part.img_bg, copyConfig.copy_thumbnail_before)
    UIHelper.SetText(part.txt_copyname, copyConfig.name)
    local dropId = copyConfig.drop_info_id
    self:_CreateDropItem(dropId, part, copyId)
    local Undone = false
    if self.m_singleCopy[index - 1] ~= nil then
      Undone = Logic.copyLogic:_CheckUndoneId(self.m_singleCopy[index - 1])
    end
    part.obj_lock:SetActive(Undone)
    self:_CreateBattleModeItem(index, part)
  end, self)
end

function PVECopyDetailPage:_CreateDropItem(dropId, part, copyId)
  local tabDropInfo = Logic.copyLogic:GetDropInfo()
  self.tabSerData = Data.copyData:GetCopyInfoById(copyId)
  local tabDropInfoId = dropId
  for i, v in ipairs(tabDropInfoId) do
    if tabDropInfo[v].type == DropInfoType.firstPassReward and self.tabSerData and self.tabSerData.FirstPassTime ~= 0 then
      table.remove(tabDropInfoId, i)
      break
    end
  end
  tabDropInfoId = Logic.copyLogic:FilterDropId(tabDropInfoId)
  local tabAfterDropInfoId = DropRewardsHelper.GetDropDisplay(tabDropInfoId)
  UIHelper.CreateSubPart(part.item_drop, part.trans_drop, #tabAfterDropInfoId, function(nIndex, tabPart)
    local displayInfo = tabAfterDropInfoId[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(tabPart.img_item, displayInfo.icon)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    UIHelper.SetText(tabPart.tx_dropRate, itemInfo.drop_rate)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_dropitem.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, tabDropInfoId)
    end)
  end)
end

function PVECopyDetailPage:GetCopyCostById(copyid, isSingle)
  local config = Logic.copyLogic:GetCopyDesConfig(copyid)
  local cost = 0
  if isSingle then
    cost = config.total_supple_num[1]
  else
    cost = config.pvept_cost
  end
  return cost
end

function PVECopyDetailPage:_CreateBattleModeItem(index, part)
  local copyId = self.m_singleCopy[index]
  local mutilCopyId = self.m_mulitCopy[index]
  local BattleModeInfo = {
    [1] = {
      UIHelper.GetString(6100040),
      Logic.currencyLogic:GetIcon(CurrencyType.SUPPLY),
      PVECopyDetailPage:GetCopyCostById(copyId, true)
    },
    [2] = {
      UIHelper.GetString(6100041),
      Logic.currencyLogic:GetIcon(CurrencyType.PVEPT),
      PVECopyDetailPage:GetCopyCostById(mutilCopyId, false)
    },
    [3] = {
      UIHelper.GetString(6100042),
      Logic.currencyLogic:GetIcon(CurrencyType.PVEPT),
      PVECopyDetailPage:GetCopyCostById(mutilCopyId, false)
    }
  }
  UIHelper.CreateSubPart(part.item_mode, part.trans_container, #BattleModeInfo, function(n_index, n_part)
    local position = n_part.trans_obj.localPosition
    if self.m_openCount == 1 then
      n_part.trans_obj.localPosition = Vector3.New(position.x - (n_index - 1) * self.m_matchModeCellDelta, position.y, position.z)
    end
    UIHelper.SetText(n_part.txt_modetxt, BattleModeInfo[n_index][1])
    UIHelper.SetText(n_part.txt_cost, BattleModeInfo[n_index][3])
    UIHelper.SetImage(n_part.img_cost, BattleModeInfo[n_index][2])
    UGUIEventListener.AddButtonOnClick(n_part.btn_solo, function()
      if n_index == 1 then
        self:SingleBattleBtnClick(copyId)
      elseif n_index == 2 then
        self:MulitBattleBtnClick(mutilCopyId)
      elseif n_index == 3 then
        self:RoomListBtnClick(mutilCopyId)
      end
    end, self)
  end, self)
end

function PVECopyDetailPage:OpenShop()
  UIHelper.OpenPage("ShopPage", {
    shopId = ShopId.PveRoomShop
  })
end

function PVECopyDetailPage:OpenInstruction()
  UIHelper.OpenPage("HelpPage", {content = 6100022})
end

function PVECopyDetailPage:ShowMsgByLanguageId(id)
  noticeManager:OpenTipPage(self, UIHelper.GetString(id))
end

function PVECopyDetailPage:OpenPresetFleet()
  UIHelper.OpenPage("PresetFleetPage", {
    presetFleetType = PresetFleetType.MatchDetail
  })
end

return PVECopyDetailPage
