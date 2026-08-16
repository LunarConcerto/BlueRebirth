local SelectTreasurePage = class("UI.Bag.SelectTreasurePage", LuaUIPage)
local ShowType = {SelectTreasureInfo = 1, OpenTreasureItemShow = 2}
local Fashion_Treasure_Id = 13200
local Can_Batch_Open = 1

function SelectTreasurePage:DoInit()
  self.m_tabWidgets = nil
  self.m_tabParam = nil
  self.n_openNum = 0
  self.n_allNum = 0
  self.bIsTrueClose = false
  self.tabAllItemInfo = {}
  self.tab_selectedInfo = nil
  self.openMaxTreasureNum = 0
  self.nPos = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SelectTreasurePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    self:_ClickCloseFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_decreaseNum, function()
    self:_ClickDecreaseNumFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_increaseNum, function()
    self:_ClickIncreaseNumFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_maxNum, function()
    self:_ClickMaxNumFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_start, function()
    self:_ClickStartFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_mask, self._ClickCloseFun, self)
  self:RegisterEvent(LuaEvent.GetTreasureInfo, self._GetTreasureInfo, self)
end

function SelectTreasurePage:DoOnOpen()
  self.m_tabParam = self:GetParam()
  self.openMaxTreasureNum = configManager.GetDataById("config_parameter", 54).value
  self:_InitDisplay()
end

function SelectTreasurePage:_InitDisplay()
  if self.m_tabParam ~= nil then
    self.n_openNum = 1
    local bagInfo = Logic.bagLogic:ItemInfoById(self.m_tabParam.id)
    local value = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
    self.n_allNum = value
    local itemType = Logic.bagLogic:GetItemTypeByTid(self.m_tabParam.id)
    self.m_tabWidgets.obj_scrollshowItem:SetActive(false)
    self.m_tabWidgets.obj_itemInfo:SetActive(true)
    self:_ShowNormalTreasureInfo()
    self.m_tabWidgets.obj_useNum:SetActive(itemType == GoodsType.ITEM)
    if itemType == GoodsType.ITEM_SELECTED and self.m_tabParam.batch_open == Can_Batch_Open then
      self.m_tabWidgets.obj_useNum:SetActive(true)
    end
    self:_ShowDropItem()
  end
  self.m_tabWidgets.obj_getDes:SetActive(false)
end

function SelectTreasurePage:_ShowNormalTreasureInfo()
  UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, self.n_openNum .. "/" .. math.tointeger(self.n_allNum))
  UIHelper.SetImage(self.m_tabWidgets.img_icon, self.m_tabParam.icon)
  UIHelper.SetImage(self.m_tabWidgets.img_quality, QualityIcon[self.m_tabParam.quality])
  UIHelper.SetText(self.m_tabWidgets.txt_name, self.m_tabParam.name)
  UIHelper.SetText(self.m_tabWidgets.txt_desc, self.m_tabParam.description)
end

function SelectTreasurePage:_ClickDecreaseNumFun()
  if self.n_openNum > 1 then
    self.n_openNum = self.n_openNum - 1
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, math.tointeger(self.n_openNum) .. "/" .. math.tointeger(self.n_allNum))
  end
end

function SelectTreasurePage:_ClickIncreaseNumFun()
  if self.n_openNum == self.openMaxTreasureNum then
    return
  end
  if self.n_openNum < self.n_allNum then
    self.n_openNum = self.n_openNum + 1
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, math.tointeger(self.n_openNum) .. "/" .. math.tointeger(self.n_allNum))
  end
end

function SelectTreasurePage:_ClickMaxNumFun()
  if self.n_openNum == self.openMaxTreasureNum or self.n_openNum == self.n_allNum then
    return
  end
  if math.tointeger(self.n_allNum) > self.openMaxTreasureNum then
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, self.openMaxTreasureNum .. "/" .. math.tointeger(self.n_allNum))
    self.n_openNum = self.openMaxTreasureNum
  else
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, math.tointeger(self.n_allNum) .. "/" .. math.tointeger(self.n_allNum))
    self.n_openNum = self.n_allNum
  end
end

function SelectTreasurePage:_ClickStartFun()
  if self.m_tabParam.id <= 0 or 0 >= self.n_openNum then
    return
  end
  local itemType = Logic.bagLogic:GetItemTypeByTid(self.m_tabParam.id)
  if itemType == GoodsType.ITEM_SELECTED then
    UIHelper.OpenPage("SelectRandTreasurePage", {
      self.m_tabParam,
      self.n_openNum
    })
    return
  end
  local userLevel = Data.userData:GetUserData().Level
  if userLevel < self.m_tabParam.level then
    noticeManager:OpenTipPage(self, "\231\148\168\230\136\183\231\173\137\231\186\167\229\164\167\228\186\142\231\173\137\228\186\142" .. self.m_tabParam.level .. "\231\186\167\230\137\141\232\131\189\229\188\128\229\144\175\230\173\164\229\174\157\231\174\177")
  end
  local itemType = Logic.bagLogic:GetItemTypeByTid(self.m_tabParam.id)
  if itemType == GoodsType.ITEM then
    local conf = Logic.bagLogic:GetItemByConfig(self.m_tabParam.id)
    local dropNum = Logic.rewardLogic:GetDropCountByDropId(conf.drop_id)
    local tabReward = Logic.rewardLogic:GetAllRewardByDropId(conf.drop_id)
    if not Logic.rewardLogic:CanGotReward(tabReward, true, 1, 1, dropNum * self.n_openNum) then
      return
    end
    Service.bagService:SendGetNoramlTreasureItem(self.m_tabParam.id, self.n_openNum)
  end
end

function SelectTreasurePage:_ClikAllDock()
  UIHelper.OpenPage("HeroRetirePage")
end

function SelectTreasurePage:_ClickDismantlePageOk()
  UIHelper.ClosePage("SelectTreasurePage")
  UIHelper.OpenPage("DismantlePage")
end

function SelectTreasurePage:_GetTreasureInfo(serverRet)
  self:_InitDisplay()
  local bagInfo = Logic.bagLogic:ItemInfoById(self.m_tabParam.id)
  local value = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  if value == 0 then
    UIHelper.ClosePage("SelectTreasurePage")
  end
  if serverRet.treasureId == Fashion_Treasure_Id then
    Logic.rewardLogic:ShowFashionAndReward({
      rewards = serverRet.treasuresInfo,
      pageName = "BuildShipPage",
      dontMerge = true
    })
  else
    Logic.rewardLogic:ShowCommonReward(serverRet.treasuresInfo, "SelectTreasurePage", nil)
  end
  local idStr = ""
  for _, v in ipairs(serverRet.treasuresInfo) do
    if idStr ~= "" then
      idStr = idStr .. "," .. v.ConfigId
    else
      idStr = v.ConfigId
    end
  end
  local dotinfo = {
    info = "treasure_get",
    equip_id = idStr
  }
  RetentionHelper.Retention(PlatformDotType.equipGetLog, dotinfo)
end

function SelectTreasurePage:_ClickCloseFun()
  UIHelper.ClosePage("SelectTreasurePage")
end

function SelectTreasurePage:_ShowDropItem()
  local dropGoodsConf, dropItemConfig
  if self.m_tabParam.drop_id ~= 0 then
    dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByDropId(self.m_tabParam.drop_id)
  else
    dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByItemTab(self.m_tabParam.item_id)
  end
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.infinite_drop, self.m_tabWidgets.obj_dropItem, #dropItemConfig, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local goodsType = dropItemConfig[nIndex].Type
      local tId = dropItemConfig[nIndex].ConfigId
      local num = dropItemConfig[nIndex].Num
      local config = dropGoodsConf[tId]
      tabPart.tx_name.text = config.name
      tabPart.tx_num.text = "x" .. num
      local icon = config.icon_small ~= nil and config.icon_small or config.icon
      UIHelper.SetImage(tabPart.img_icon, tostring(icon))
      UIHelper.SetImage(tabPart.img_quality, QualityIcon[config.quality])
      if goodsType == GoodsType.EQUIP and tabPart.obj_skin ~= nil then
        local isHave = Logic.equipLogic:EquipIsHaveEffect(tId)
        tabPart.obj_skin:SetActive(isHave)
      elseif tabPart.obj_skin ~= nil then
        tabPart.obj_skin:SetActive(false)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_click, function()
        Logic.itemLogic:ShowItemInfo(goodsType, tId)
      end)
    end
  end)
end

function SelectTreasurePage:DoOnHide()
end

function SelectTreasurePage:DoOnClose()
end

return SelectTreasurePage
