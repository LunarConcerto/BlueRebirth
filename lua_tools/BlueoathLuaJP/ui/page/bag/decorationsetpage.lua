local DecorationSetPage = class("UI.Bag.DecorationSetPage", LuaUIPage)
local closeId = 0

function DecorationSetPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function DecorationSetPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTip, self._ClickCloseFun, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Open, self._ClickOpenTheme, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Close, self._ClickCloseTheme, self)
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self.ShowButton, self)
end

function DecorationSetPage:DoOnOpen()
  self.m_tabParam = self:GetParam()
  self.m_themeId = self.m_tabParam.themeId
  self:ShowPage()
  self:ShowButton()
end

function DecorationSetPage:ShowPage()
  local themeConfig = configManager.GetDataById("config_interaction_item_bag_group", self.m_themeId)
  local furList = themeConfig.interactionitem_bag or {}
  local ownedItem = Data.interactionItemData:GetInteractionBagItemData()
  local newList = self:__SortItem(furList, ownedItem)
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  UIHelper.SetImage(self.m_tabWidgets.im_decoSetImage, themeConfig.icon)
  UIHelper.SetText(self.m_tabWidgets.txt_themeName, themeConfig.name)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_decorationName, self.m_tabWidgets.Content, #newList, function(index, tabPart)
    local furId = newList[index]
    local furInfo = configManager.GetDataById("config_interaction_item_bag", furId)
    local text = furInfo.name
    if ownedItem[furId] then
      text = "<color=#417ae3>" .. text .. "</color>"
      local isNew = PlayerPrefs.GetBool(uid .. "DecorateFurnitureBagItem" .. furId, true)
      tabPart.obj_new.gameObject:SetActive(isNew)
      PlayerPrefs.SetBool(uid .. "DecorateFurnitureBagItem" .. furId, false)
    end
    UIHelper.SetText(tabPart.tx_decorationName, text)
  end)
end

function DecorationSetPage:ShowButton()
  local curTheme = Data.interactionItemData:GetMutexFurnitureTheme()
  local isSame = curTheme == self.m_themeId
  self.m_tabWidgets.btn_Open.gameObject:SetActive(not isSame)
  self.m_tabWidgets.btn_Close.gameObject:SetActive(isSame)
end

function DecorationSetPage:__SortItem(furList, ownedItem)
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local newmap = {}
  local othermap = {}
  for i, v in pairs(furList) do
    if ownedItem[v] then
      local isNew = PlayerPrefs.GetBool(uid .. "DecorateFurnitureBagItem" .. v, true)
      if isNew then
        table.insert(newmap, v)
      else
        table.insert(othermap, v)
      end
    else
      table.insert(othermap, v)
    end
  end
  for i, v in pairs(othermap) do
    table.insert(newmap, v)
  end
  return newmap
end

function DecorationSetPage:_ClickCloseFun()
  UIHelper.ClosePage("DecorationSetPage")
end

function DecorationSetPage:_ClickOpenTheme()
  if self.m_themeId == Data.interactionItemData:GetMutexFurnitureTheme() then
    return
  end
  local tab = {
    groupType = decorateMutexType.furnitureTheme,
    SelectId = self.m_themeId
  }
  Service.interactionItemService:SetMutexBagGroupState(tab)
end

function DecorationSetPage:_ClickCloseTheme()
  if self.m_themeId ~= Data.interactionItemData:GetMutexFurnitureTheme() then
    return
  end
  local tab = {
    groupType = decorateMutexType.furnitureTheme,
    SelectId = closeId
  }
  Service.interactionItemService:SetMutexBagGroupState(tab)
end

function DecorationSetPage:DoOnHide()
end

function DecorationSetPage:DoOnClose()
  eventManager:SendEvent(LuaEvent.CloseDecorationBag)
end

return DecorationSetPage
