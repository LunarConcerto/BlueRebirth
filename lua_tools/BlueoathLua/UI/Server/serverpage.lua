local ServerPage = class("UI.Server.ServerPage", LuaUIPage)
local SERVER_TAB_TYPE = {
  ROLE = 1,
  RECOMMEND = 2,
  LIST = 3
}
local GROUP_NUM = 10

function ServerPage:DoInit()
  self.mTabIndex = 1
  self.mServerInfoMap = {}
  self.mTabInfoList = {}
  self.mLastServerMap = {}
end

function ServerPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose.gameObject, self.btnCloseOnClick, self)
end

function ServerPage:DoOnOpen()
  self:initTabInfoList()
  self:ShowTabPartial()
  self:ShowTabContentPartial()
end

function ServerPage:initTabInfoList()
  local lastServer = platformManager:lastServer() or {}
  local serverList = platformManager:getServiceList() or {}
  self.mTabIndex = 1
  self.mTabInfoList = {}
  self.mServerInfoMap = {}
  for _, serverData in ipairs(serverList) do
    self.mServerInfoMap[serverData.groupid] = serverData
  end
  self.mLastServerMap = {}
  for _, ldata in ipairs(lastServer) do
    self.mLastServerMap[ldata.groupid] = ldata
  end
  local roleList = {}
  local preserverlist = {}
  for _, ldata in ipairs(lastServer) do
    local data = {}
    data.lastData = ldata
    data.serverData = self.mServerInfoMap[ldata.groupid]
    local isRepeated = preserverlist[ldata.groupid] or false
    if data.serverData ~= nil and not isRepeated then
      preserverlist[ldata.groupid] = true
      table.insert(roleList, data)
    else
      logWarning("server is nil . ", ldata.groupid)
    end
  end
  if 0 < #roleList then
    local tabInfo = {}
    tabInfo.ShowType = SERVER_TAB_TYPE.ROLE
    tabInfo.ShowIndex = 1
    tabInfo.ShowData_Role = roleList
    table.insert(self.mTabInfoList, tabInfo)
  end
  local recommendlist = {}
  for _, serverData in ipairs(serverList) do
    local data = serverData.Data
    if 0 < data.recommend_weight then
      table.insert(recommendlist, serverData)
    elseif 0 < data.ready_open_weight then
      table.insert(recommendlist, serverData)
    end
  end
  table.sort(recommendlist, function(a, b)
    local da = a.Data
    local db = b.Data
    if da.recommend_weight ~= db.recommend_weight then
      return da.recommend_weight > db.recommend_weight
    end
    if da.ready_open_weight ~= db.ready_open_weight then
      return da.ready_open_weight > db.ready_open_weight
    end
    if da.serverIndex ~= db.serverIndex then
      return da.serverIndex < db.serverIndex
    end
    return false
  end)
  if 0 < #recommendlist then
    local tabInfo = {}
    tabInfo.ShowType = SERVER_TAB_TYPE.RECOMMEND
    tabInfo.ShowIndex = 1
    tabInfo.ShowData_Recommend = recommendlist
    table.insert(self.mTabInfoList, tabInfo)
  end
  local serverGroupMap = {}
  for _, serverData in ipairs(serverList) do
    local data = serverData.Data
    local serverIndex = data.serverIndex
    local showIndex = math.ceil(serverIndex / GROUP_NUM)
    local list = serverGroupMap[showIndex] or {}
    table.insert(list, serverData)
    serverGroupMap[showIndex] = list
  end
  for showIndex, list in pairs(serverGroupMap) do
    table.sort(list, function(a, b)
      local serverindex_a = a.Data.serverIndex
      local serverindex_b = b.Data.serverIndex
      if serverindex_a ~= serverindex_b then
        return serverindex_a < serverindex_b
      end
      return false
    end)
    local tabInfo = {}
    tabInfo.ShowType = SERVER_TAB_TYPE.LIST
    tabInfo.ShowIndex = showIndex
    tabInfo.ShowData_Server = list
    table.insert(self.mTabInfoList, tabInfo)
  end
  table.sort(self.mTabInfoList, function(a, b)
    if a.ShowType ~= b.ShowType then
      return a.ShowType < b.ShowType
    end
    if a.ShowIndex ~= b.ShowIndex then
      return a.ShowIndex > b.ShowIndex
    end
    return false
  end)
end

function ServerPage:btnCloseOnClick()
  UIHelper.ClosePage("ServerPage")
end

function ServerPage:DoOnHide()
end

function ServerPage:DoOnClose()
  eventManager:SendEvent(LuaEvent.ServerPageClose)
end

function ServerPage:_ChooseServer(serverInfo)
  eventManager:SendEvent(LuaEvent.ChangeServer, serverInfo)
  UIHelper.ClosePage("ServerPage")
end

function ServerPage:ShowTabPartial()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.content, self.tab_Widgets.item, #self.mTabInfoList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateTabPart(index, part)
    end
  end)
end

function ServerPage:updateTabPart(index, part)
  local tabInfo = self.mTabInfoList[index]
  if tabInfo.ShowType == SERVER_TAB_TYPE.ROLE then
    UIHelper.SetText(part.txtLabelName, "\229\183\178\230\156\137\232\167\146\232\137\178")
  elseif tabInfo.ShowType == SERVER_TAB_TYPE.RECOMMEND then
    UIHelper.SetText(part.txtLabelName, "\230\142\168   \232\141\144")
  elseif tabInfo.ShowType == SERVER_TAB_TYPE.LIST then
    local startServerIndex = tabInfo.ShowIndex * 10 - 9
    local endServerIndex = tabInfo.ShowIndex * 10
    local labelName = startServerIndex .. "-" .. endServerIndex .. "\230\156\141"
    UIHelper.SetText(part.txtLabelName, labelName)
  else
    logError("Undefined ShowType ", tabInfo.ShowType)
  end
  part.objImgSelect:SetActive(self.mTabIndex == index)
  UGUIEventListener.AddButtonOnClick(part.btnLabel, self.btnLabelOnClick, self, {Info = tabInfo, Index = index})
end

function ServerPage:btnLabelOnClick(go, param)
  self.mTabIndex = param.Index
  self:ShowTabPartial()
  self:ShowTabContentPartial()
end

function ServerPage:ShowTabContentPartial()
  local tabInfo = self.mTabInfoList[self.mTabIndex]
  if tabInfo.ShowType == SERVER_TAB_TYPE.ROLE then
    self.tab_Widgets.objExistingRoleList:SetActive(true)
    self.tab_Widgets.objServerList:SetActive(false)
    UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentRole, self.tab_Widgets.itemRoleCard, #tabInfo.ShowData_Role, function(parts)
      for k, part in pairs(parts) do
        local index = tonumber(k)
        self:updateItemRolePart(index, part, tabInfo.ShowData_Role[index])
      end
    end)
  elseif tabInfo.ShowType == SERVER_TAB_TYPE.RECOMMEND then
    self.tab_Widgets.objExistingRoleList:SetActive(false)
    self.tab_Widgets.objServerList:SetActive(true)
    local parentTrans = self.tab_Widgets.itemServer.transform.parent.transform
    UIHelper.CreateSubPart(self.tab_Widgets.itemServer, parentTrans, #tabInfo.ShowData_Recommend, function(index, part)
      self:updateItemServerPart(index, part, tabInfo.ShowData_Recommend[index])
    end)
  elseif tabInfo.ShowType == SERVER_TAB_TYPE.LIST then
    self.tab_Widgets.objExistingRoleList:SetActive(false)
    self.tab_Widgets.objServerList:SetActive(true)
    local parentTrans = self.tab_Widgets.itemServer.transform.parent.transform
    UIHelper.CreateSubPart(self.tab_Widgets.itemServer, parentTrans, #tabInfo.ShowData_Server, function(index, part)
      self:updateItemServerPart(index, part, tabInfo.ShowData_Server[index])
    end)
  else
    logError("Undefined ShowType ", tabInfo.ShowType)
  end
end

local QualityIcon = {
  "uipic_ui_girllist_bg_baisebeijing_n_da",
  "uipic_ui_girllist_bg_lansebeijing_r_da",
  "uipic_ui_girllist_bg_zisebeijing_sr_da",
  "uipic_ui_girllist_bg_jinsebeijing_ssr_da"
}

function ServerPage:updateItemRolePart(index, part, partData)
  local changeNameTime = partData.lastData.ChangeNameTimes or 0
  if 0 < changeNameTime then
    UIHelper.SetText(part.txtName, partData.lastData.uname)
  else
    UIHelper.SetLocText(part.txtName, 5100001)
  end
  UIHelper.SetText(part.txtLevel, "Lv." .. partData.lastData.level)
  UIHelper.SetText(part.txtServer, partData.serverData.name)
  local secretary = partData.lastData.secretary
  if secretary ~= nil then
    local cfg = Logic.shipLogic:GetShipShowById(secretary)
    local shipInfo = Logic.shipLogic:GetShipInfoById(secretary)
    local secretaryFashion = partData.lastData.secretary_fashion
    if secretaryFashion ~= nil then
      local cfgFashion = Logic.shipLogic:GetShipShowByFashionId(secretaryFashion)
      if cfgFashion ~= nil then
        cfg = cfgFashion
      end
    end
    local icon = cfg.ship_icon2
    local qualityicon = QualityIcon[shipInfo.quality]
    UIHelper.SetImage(part.imgQuality, qualityicon)
    UIHelper.SetImage(part.imGirl, icon)
  end
  local isMarry = partData.lastData.secretary_is_marry or false
  part.objMarry:SetActive(isMarry)
  UGUIEventListener.AddButtonOnClick(part.btnCard, self.btnChooseServerOnClick, self, partData.serverData)
end

function ServerPage:btnChooseServerOnClick(go, param)
  self:_ChooseServer(param)
end

function ServerPage:updateItemServerPart(index, part, partData)
  local data = partData.Data
  UIHelper.SetText(part.txtOpenServer, data.name)
  UIHelper.SetText(part.txtCloseServer, data.name)
  part.objImgNew:SetActive(data.ready_open_weight > 0)
  part.objImgRecommend:SetActive(0 < data.recommend_weight)
  part.objImgRole:SetActive(self.mLastServerMap[data.groupid] ~= nil)
  local isHot = false
  local isFluent = false
  local isMaintenance = false
  if data.status == 1 then
    if 0 < data.hot then
      isHot = true
    else
      isFluent = true
    end
  else
    isMaintenance = true
  end
  part.objImgHot:SetActive(isHot)
  part.objImgFluent:SetActive(isFluent)
  part.objImgMaintenance:SetActive(isMaintenance)
  if isMaintenance then
    part.objImgOpen:SetActive(false)
    part.objImgClose:SetActive(true)
  else
    part.objImgOpen:SetActive(true)
    part.objImgClose:SetActive(false)
  end
  UGUIEventListener.AddButtonOnClick(part.btnServer, self.btnChooseServerOnClick, self, partData)
end

return ServerPage
