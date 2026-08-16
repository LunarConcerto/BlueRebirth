local EquipDismantleTip = class("UI.Common.EquipDismantleTip", LuaUIPage)
local equipItem = require("ui.page.Bag.BagEquipItem")
local equipAttrItem = require("ui.page.Bag.BagEquipAttItem")

function EquipDismantleTip:DoInit()
  self.m_tabWidgets = nil
  self.m_tabDisEquipIds = {}
  self.m_tabEquipAllInfo = {}
  self.equipIdsLen = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function EquipDismantleTip:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_sure, self._UnInstall, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, self._CloseDisPage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_sureDis, self._ClickDisEquipBtn, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_mask, self._CloseDisPage, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_select, self._TogSelectAll, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_autoDismantle, self._TogAutoDelete, self)
  self:RegisterEvent(LuaEvent.DismantleSuccess, self._ShowSuccessTips, self)
end

function EquipDismantleTip:_CloseDisPage()
  UIHelper.ClosePage("EquipDismantleTip")
end

function EquipDismantleTip:DoOnOpen()
  local tabHeroEquipIds = Logic.dockLogic:GetHeroEquipsInfo()
  local tabEquipDataInfo = Logic.dismantleLogic:GetEquipDataInfo(tabHeroEquipIds)
  local equipTab = Logic.equipLogic:GetEquipConfig(tabEquipDataInfo, nil)
  local _, equipsInfo = Logic.equipLogic:EquipBagOverlay(equipTab)
  self.m_tabEquipAllInfo = equipsInfo
  self:_AddEquipId2Table(self.m_tabDisEquipIds, self.m_tabEquipAllInfo)
  self.equipIdsLen = #tabHeroEquipIds
  self:_LoadEquipItem()
end

function EquipDismantleTip:_AddEquipId2Table(tabEquipId, tabEquipInfo)
  for k, v in ipairs(tabEquipInfo) do
    for key, value in pairs(v.tabEquipId) do
      local can = Logic.equipLogic:IsDefaultSelect(value)
      if can then
        table.insert(tabEquipId, value)
      end
    end
  end
end

function EquipDismantleTip:_AddAllEquipId2Table(tabEquipId, tabEquipInfo)
  for k, v in ipairs(tabEquipInfo) do
    for key, value in pairs(v.tabEquipId) do
      table.insert(tabEquipId, value)
    end
  end
end

function EquipDismantleTip:_LoadEquipItem()
  local screenEquipTab = self.m_tabEquipAllInfo
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_equipItem, self.m_tabWidgets.obj_equipItem, #screenEquipTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local item = equipItem:new()
      local equipInfo = screenEquipTab[nIndex]
      item:Init(self, tabPart, equipInfo, EquipToBagSign.DISMANTLE_EQUIP, nIndex)
      self:_ShowDismantleStatus(tabPart, equipInfo)
    end
  end)
  self:_ShowGetItem(self.m_tabDisEquipIds)
  self.m_tabWidgets.tog_select.isOn = #self.m_tabDisEquipIds == self.equipIdsLen
  self.m_tabWidgets.tog_autoDismantle.isOn = Logic.equipLogic:GetAutoDelete()
end

function EquipDismantleTip:_ShowDismantleStatus(tabPart, equipInfo)
  local disNum = self:_GetDismantleNum(equipInfo.tabEquipId)
  tabPart.obj_selectTag:SetActive(disNum ~= 0)
  if disNum == 0 then
    UIHelper.SetText(tabPart.txt_num, equipInfo.Num)
  else
    UIHelper.SetText(tabPart.txt_num, disNum .. "/" .. equipInfo.Num)
  end
end

function EquipDismantleTip:_IsInDismantle(equipId)
  if #self.m_tabDisEquipIds == 0 then
    return false
  end
  for k, v in ipairs(self.m_tabDisEquipIds) do
    if v == equipId then
      return true
    end
  end
  return false
end

function EquipDismantleTip:_GetDismantleNum(tabEquipId)
  local count = 0
  for k, v in ipairs(tabEquipId) do
    if self:_IsInDismantle(v) then
      count = count + 1
    end
  end
  return count
end

function EquipDismantleTip:_ShowGetItem(tabSelectEquipId)
  local tabReward = Logic.equipLogic:GetDismantleReward(tabSelectEquipId)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_get, self.m_tabWidgets.trans_getBase, #tabReward, function(index, tabPart)
    local icon = Logic.goodsLogic:GetIcon(tabReward[index][2], tabReward[index][1])
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetText(tabPart.tx_num, tabReward[index][3])
  end)
end

function EquipDismantleTip:_TogSelectAll(go, isOn)
  if isOn then
    self.m_tabDisEquipIds = {}
    self:_AddAllEquipId2Table(self.m_tabDisEquipIds, self.m_tabEquipAllInfo)
  else
    self.m_tabDisEquipIds = {}
  end
  self:_LoadEquipItem()
end

function EquipDismantleTip:_ClickDisEquipBtn()
  if #self.m_tabDisEquipIds == 0 then
    noticeManager:OpenTipPage(self, "\232\175\183\233\128\137\230\139\169\232\166\129\230\139\134\232\167\163\231\154\132\232\163\133\229\164\135")
    return
  end
  local str = ""
  local high = Logic.equipLogic:HaveHighQualityEquip(self.m_tabDisEquipIds)
  local intensify = Logic.equipLogic:HaveIntensifyEquip(self.m_tabDisEquipIds)
  if high then
    str = str .. "\231\178\190\233\148\144\229\143\138\228\187\165\228\184\138\229\147\129\232\180\168"
  end
  if intensify then
    if high then
      str = str .. "\227\128\129"
    end
    str = str .. "\231\187\143\232\191\135\229\188\186\229\140\150"
  end
  if utf8.len(str) ~= 0 then
    str = UIHelper.SetColor(str, "FF0000")
    str = string.format(UIHelper.GetString(170015), str)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Logic.equipLogic:SetDisRewardCache(self.m_tabDisEquipIds)
          Service.equipService:SendDismantleEquip(self.m_tabDisEquipIds)
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
    return
  end
  Logic.equipLogic:SetDisRewardCache(self.m_tabDisEquipIds)
  Service.equipService:SendDismantleEquip(self.m_tabDisEquipIds)
end

function EquipDismantleTip:_ShowSuccessTips(rewards)
  UIHelper.ClosePage("EquipDismantleTip")
  if 0 < #rewards then
    Logic.rewardLogic:ShowCommonReward(rewards, "EquipDismantleTip", function()
      Logic.equipLogic:ResetDisRewardCache()
    end)
  end
end

function EquipDismantleTip:_RemoveDismantleEquip(equipId)
  for k, v in ipairs(self.m_tabDisEquipIds) do
    if v == equipId then
      table.remove(self.m_tabDisEquipIds, k)
      return
    end
  end
end

function EquipDismantleTip:_ClickSubEquip(equipInfo, tabPart)
  local tabEquipId = equipInfo.tabEquipId
  local disNum = self:_GetDismantleNum(tabEquipId)
  for k, v in pairs(tabEquipId) do
    if self:_IsInDismantle(v) then
      self:_RemoveDismantleEquip(v)
      break
    end
  end
  if disNum == 1 then
    tabPart.obj_selectTag:SetActive(false)
    UIHelper.SetText(tabPart.txt_num, #tabEquipId)
  else
    UIHelper.SetText(tabPart.txt_num, disNum - 1 .. "/" .. #tabEquipId)
  end
  self:_LoadEquipItem()
end

function EquipDismantleTip:_ClickEquipDismantle(equipInfo, tabPart)
  local tabEquipId = equipInfo.tabEquipId
  local can, msg = Logic.equipLogic:CanDelect(equipInfo.TemplateId)
  if not can then
    noticeManager:ShowTip(msg)
    return
  end
  local select = false
  for _, id in ipairs(tabEquipId) do
    if table.containV(self.m_tabDisEquipIds, id) then
      select = true
      break
    end
  end
  tabPart.obj_selectTag:SetActive(select)
  if not select then
    for k, v in pairs(tabEquipId) do
      if not self:_IsInDismantle(v) then
        table.insert(self.m_tabDisEquipIds, v)
      end
    end
    UIHelper.SetText(tabPart.txt_num, #tabEquipId .. "/" .. #tabEquipId)
  else
    for k, v in pairs(tabEquipId) do
      if self:_IsInDismantle(v) then
        self:_RemoveDismantleEquip(v)
      end
    end
    UIHelper.SetText(tabPart.txt_num, #tabEquipId)
  end
  self:_LoadEquipItem()
end

function EquipDismantleTip:_TogAutoDelete(go, isOn)
  Logic.equipLogic:SetAutoDelete(isOn)
end

function EquipDismantleTip:DoOnClose()
end

function EquipDismantleTip:DoOnHide()
end

return EquipDismantleTip
