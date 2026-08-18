local RyzaAlchemyPage = class("UI.Alchemy.RyzaAlchemyPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local scale_drag = {
  0.4,
  -0.4,
  0.3,
  -0.5
}
local ryzaShipInfoId = configManager.GetDataById("config_parameter", 422).value
local ryzaDurationTime = configManager.GetDataById("config_parameter", 424).value
local SelectFormulaAnimTab = configManager.GetDataById("config_parameter", 423).arrValue[1]
local SelectItemAnimTab = configManager.GetDataById("config_parameter", 423).arrValue[3]
local FinishAnimTab = configManager.GetDataById("config_parameter", 423).arrValue[4]
local WaitAnimTab = configManager.GetDataById("config_parameter", 423).arrValue[2]
local LineEffect = "effects/prefabs/eff2d_ryza_alchemical_line_flownlight"
local FormulaTitle = {4700002, 4700003}
local FormulaType = {Equip = 1, Item = 2}
local clickPos3 = Vector3.New(0, 0, 0)
local QualityImage = {
  "uipic_ui_ryza_fo_n",
  "uipic_ui_ryza_fo_r",
  "uipic_ui_ryza_fo_sr",
  "uipic_ui_ryza_fo_ssr",
  "uipic_ui_vow_fo_ur"
}

function RyzaAlchemyPage:DoInit()
  self.bFormulaPart = nil
  self.selectFormulaConf = nil
  self.bSChainId = 0
  self.bSItemPart = nil
  self.bSItemIndex = 0
  self.isDrag = false
  self.formulaAddItem = {}
  self.selectChainId = 0
  self.beforeEffPos = Vector3.zero
  self.clickBg = false
  self.selectEquipIdTab = {}
  self.formulaTab = {}
  self.jumpFormulaId = 0
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_girl)
  self.m_objModel = nil
  self.m_timerCallBack = nil
  self.m_timer = nil
  local tabParam = {
    freeClickDown = function(param)
      self:__onClickScreen(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function RyzaAlchemyPage:RegisterAllEvent()
  local tabTogs = {
    self.tab_Widgets.tog_equip,
    self.tab_Widgets.tog_item
  }
  for i, tog in pairs(tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  UGUIEventListener.AddOnDrag(self.tab_Widgets.img_bg, self._OnDrag, self)
  UGUIEventListener.AddOnEndDrag(self.tab_Widgets.img_bg, self._OnDragEnd, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.img_bg, self._CloseItemPart, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_start, self._ClickStart, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeComplete, self._ClickCloseComplete, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeSucc, self._AlchemySuccess, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OpenHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.obj_help, self._CloseHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._CloseHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_addAll, self._AddAllItem, self)
  self:RegisterEvent(LuaEvent.AlchemySuccess, self._ShowSuccessPart, self)
end

function RyzaAlchemyPage:__onClickScreen(pos)
  clickPos3 = pos
end

function RyzaAlchemyPage:DoOnOpen()
  local params = self:GetParam()
  if type(params) == "table" then
    self.jumpFormulaId = params.ItemId == nil and 0 or params.ItemId
  end
  local selectTog = Logic.alchemyLogic:GetSelectTog()
  if self.jumpFormulaId ~= 0 then
    selectTog = Logic.alchemyLogic:GetAlchemyFormula(self.jumpFormulaId).formula_type - 1
  end
  self.tab_Widgets.tog_group:SetActiveToggleIndex(selectTog)
  self.tab_Widgets.img_girlRender.transform.parent.gameObject:SetActive(false)
end

function RyzaAlchemyPage:_SwitchTogs(index)
  self:_ClearSelectItem()
  Logic.alchemyLogic:SetSelectTog(index)
  local formulaType = index + 1
  self.formulaTab = Logic.alchemyLogic:GetAlchemyFormulaByType(formulaType)
  self.tab_Widgets.tx_title.text = UIHelper.GetString(FormulaTitle[formulaType])
  self.tab_Widgets.tween_formula:Play(true)
  self:_ShowFormulaTab(self.formulaTab)
end

function RyzaAlchemyPage:_ShowFormulaTab(formulaTab)
  self.tab_Widgets.obj_chain:SetActive(0 < #formulaTab)
  if #formulaTab == 0 then
    self:_ClearTempRecord()
    self.tab_Widgets.obj_reward:SetActive(false)
  end
  local ownJumpFormula = false
  local selectFormulaIndex = Logic.alchemyLogic:GetSelectFormula()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_formulaItem, self.tab_Widgets.trans_formula, #formulaTab, function(nIndex, tabPart)
    local formulaConf = formulaTab[nIndex]
    local showRed = Logic.alchemyLogic:CheckShowRed(formulaConf.id)
    tabPart.im_new:SetActive(showRed)
    local materialEnough = Logic.alchemyLogic:CheckExpendNum(formulaConf.id)
    local color = materialEnough and "000000" or "FF0000"
    UIHelper.SetTextColor(tabPart.tx_name, formulaConf.name, color)
    local ownProductNum = 0
    if formulaConf.formula_type == FormulaType.Item then
      ownProductNum = Data.bagData:GetItemNum(formulaConf.product[2])
    else
      _, ownProductNum = Logic.alchemyLogic:GetEquipInfoByTid(formulaConf.product[2])
    end
    UIHelper.SetText(tabPart.tx_num, ownProductNum)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_formulaItem, self._SelectFormula, self, {
      formulaConf,
      nIndex,
      tabPart
    })
    if self.jumpFormulaId ~= 0 and self.jumpFormulaId == formulaConf.id then
      self:_SelectFormula(nil, {
        formulaConf,
        nIndex,
        tabPart
      })
      self.jumpFormulaId = 0
      self:SaveNewParam(self.jumpFormulaId)
      selectFormulaIndex = 0
      ownJumpFormula = true
    elseif selectFormulaIndex == 0 and nIndex == 1 then
      self:_SelectFormula(nil, {
        formulaConf,
        nIndex,
        tabPart
      })
    elseif selectFormulaIndex ~= 0 and selectFormulaIndex == nIndex then
      self:_SelectFormula(nil, {
        formulaConf,
        nIndex,
        tabPart
      })
    end
  end)
  if self.jumpFormulaId ~= 0 and ownJumpFormula then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4700032))
  end
end

function RyzaAlchemyPage:_SelectFormula(go, params)
  self.tab_Widgets.obj_effect:SetActive(false)
  local formulaConf = params[1]
  local index = params[2]
  local tabPart = params[3]
  tabPart.im_new:SetActive(false)
  local showRed = Logic.alchemyLogic:CheckShowRed(formulaConf.id)
  tabPart.im_new:SetActive(showRed and index == 1)
  if self.selectFormulaConf ~= nil and self.selectFormulaConf.id ~= formulaConf.id then
    self.formulaAddItem = {}
  end
  Logic.alchemyLogic:SaveClickedFormula(formulaConf.id)
  self.selectEquipIdTab = {}
  Logic.alchemyLogic:SetSelectFormula(index)
  if self.bFormulaPart ~= nil then
    self.bFormulaPart.obj_select:SetActive(false)
  end
  tabPart.obj_select:SetActive(true)
  self.bFormulaPart = tabPart
  self.selectFormulaConf = formulaConf
  self:_ClearSelectItem()
  self:_CreateFormation(formulaConf)
  self:_ShowProduct(formulaConf)
  self:_ShowAddAllItemBtn()
end

function RyzaAlchemyPage:_CreateFormation(formulaConf, isStart)
  self:_DestroyLineObj()
  local formulaItemGroup = formulaConf.item_group
  UIHelper.CreateSubPart(self.tab_Widgets.obj_chainItem, self.tab_Widgets.trans_chain, #formulaItemGroup, function(nIndex, tabPart)
    tabPart.tween_effStart:ResetToBeginning()
    local formulaItemId = formulaItemGroup[nIndex]
    local formulaItemConf = Logic.alchemyLogic:GetAlchemyItemConf(formulaItemId)
    local materialType = formulaItemConf.materials[1]
    local materialId = formulaItemConf.materials[2]
    local materialNum = formulaItemConf.materials[3]
    local materialConf = Logic.alchemyLogic:GetExpendGoodsConfig(formulaItemConf.materials)
    tabPart.obj_self.transform.localPosition = Vector3.NewFromTab(formulaItemConf.position)
    tabPart.obj_bg:SetActive(not isStart)
    tabPart.obj_effStart:SetActive(isStart)
    UIHelper.SetImage(tabPart.im_icon, materialConf.icon)
    local bgImg = Logic.alchemyLogic:GetAlchemyItemType(formulaItemConf.item_type).image_background
    UIHelper.SetImage(tabPart.im_bg, bgImg)
    local beforeFull = self:_CheckBeforeFull(formulaItemConf)
    local isLock = #formulaItemConf.pre_item ~= 0 and not beforeFull
    tabPart.im_lock:SetActive(isLock)
    local enough = Logic.alchemyLogic:CheckExpendByMaterial(formulaItemConf, self.formulaAddItem)
    tabPart.im_notenough:SetActive(not enough)
    tabPart.im_load:SetActive(self.formulaAddItem[formulaItemId] ~= nil)
    tabPart.gray_icon.Gray = self.formulaAddItem[formulaItemId] == nil
    for i = 0, tabPart.trans_effNextTab.childCount - 1 do
      local child = tabPart.trans_effNextTab:GetChild(i).gameObject
      GameObject.Destroy(child)
    end
    for i = 1, 4 do
      tabPart["obj_eff" .. i]:SetActive(i == formulaItemConf.item_type)
      tabPart["obj_bottomEff" .. i]:SetActive(i == formulaItemConf.item_type)
    end
    tabPart.obj_normalEff:SetActive(not isLock)
    tabPart.obj_bottomEff:SetActive(not isLock)
    for i, endItemId in ipairs(formulaItemConf.back_item) do
      local soucePos = formulaItemConf.position
      local endItemPos = Logic.alchemyLogic:GetAlchemyItemConf(endItemId).position
      local line = UIHelper.CreateGameObject(self.tab_Widgets.obj_line, self.tab_Widgets.trans_line)
      local rectTrans = line:GetComponent(RectTransform.GetClassType())
      line.transform.localPosition = Vector3.NewFromTab(soucePos)
      line:SetActive(true)
      if self.formulaAddItem[formulaItemId] ~= nil then
        local child = line.transform:GetChild(0).gameObject
        if child then
          child:SetActive(true)
        end
      end
      local length = math.sqrt((soucePos[1] - endItemPos[1]) ^ 2 + (soucePos[2] - endItemPos[2]) ^ 2)
      local angle = math.atan(endItemPos[1] - soucePos[1], endItemPos[2] - soucePos[2]) * 180 / math.pi
      rectTrans.sizeDelta = Vector2.New(rectTrans.sizeDelta.x, length)
      rectTrans.eulerAngles = Vector3.New(0, 0, -angle)
      if self.formulaAddItem[formulaItemId] ~= nil and self.selectChainId == formulaItemId then
        local effNext = UIHelper.CreateGameObject(tabPart.obj_effNext, tabPart.trans_effNextTab)
        local effNextTrans = effNext:GetComponent(RectTransform.GetClassType())
        effNextTrans.eulerAngles = Vector3.New(0, 0, -angle + 90)
        effNext:SetActive(true)
      end
    end
    tabPart.obj_effAdd:SetActive(self.formulaAddItem[formulaItemId] ~= nil and self.selectChainId == formulaItemId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_chain, self._SelectChain, self, {
      formulaItemConf,
      nIndex,
      tabPart,
      enough
    })
  end)
end

function RyzaAlchemyPage:_DestroyLineObj()
  self:DestroyAllEffect()
  for i = 0, self.tab_Widgets.trans_line.childCount - 1 do
    local child = self.tab_Widgets.trans_line:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
end

function RyzaAlchemyPage:_SelectChain(go, params)
  self.tab_Widgets.tween_itemList:Stop()
  local formulaItemConf = params[1]
  self.selectChainId = formulaItemConf.id
  if formulaItemConf.id ~= self.bSChainId then
    self:_ClearSelectItem()
  end
  local index = params[2]
  local tabPart = params[3]
  local itemEnough = params[4]
  self:_ClickChainPos(formulaItemConf.position)
  if not itemEnough then
    self.tab_Widgets.tween_itemList:Play(false)
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(formulaItemConf.materials[1], formulaItemConf.materials[2], true))
    return
  end
  self.tab_Widgets.tween_formula:Play(false)
  self.tab_Widgets.tween_itemList:Play(true)
  self:_ShowExpendDetails(formulaItemConf)
end

function RyzaAlchemyPage:_ShowExpendDetails(formulaItemConf)
  self.tab_Widgets.obj_itemPart:SetActive(true)
  local itemType = formulaItemConf.materials[1]
  local itemId = formulaItemConf.materials[2]
  local itemNum = 0
  local equipInfo = {}
  if itemType == GoodsType.EQUIP then
    equipInfo, itemNum = Logic.alchemyLogic:GetEquipInfoByTid(itemId)
  else
    itemNum = Data.bagData:GetItemNum(itemId)
  end
  local itemConf = Logic.alchemyLogic:GetExpendGoodsConfig(formulaItemConf.materials)
  self:_UpdateExpendBottom(formulaItemConf.materials)
  UIHelper.SetText(self.tab_Widgets.txt_itemName, itemConf.name)
  self.tab_Widgets.obj_effect:SetActive(true)
  UIHelper.SetText(self.tab_Widgets.tx_effectTitle, itemConf.name)
  self:_UpdateDetailTips(formulaItemConf, self.formulaAddItem[formulaItemConf.id] ~= nil, true)
  for formulaId, v in pairs(self.formulaAddItem) do
    if v.materialId == itemId and formulaId ~= formulaItemConf.id then
      itemNum = itemNum - 1
    end
  end
  if itemNum <= 0 then
    self.tab_Widgets.iil_item.gameObject:SetActive(false)
    return
  end
  self.tab_Widgets.iil_item.gameObject:SetActive(true)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.iil_item, self.tab_Widgets.obj_item, itemNum, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      UIHelper.CreateSubPart(tabPart.obj_type, tabPart.trans_type, #itemConf.ryza_type, function(index, part)
        local itemTypeImg = Logic.alchemyLogic:GetAlchemyItemType(itemConf.ryza_type[index]).image_on
        UIHelper.SetImage(part.im_type, itemTypeImg)
      end)
      UIHelper.SetImage(tabPart.im_icon, itemConf.icon)
      UIHelper.SetText(tabPart.tx_num, itemConf.ryza_type_num)
      if self.formulaAddItem[formulaItemConf.id] ~= nil then
        self.bSItemIndex = self.formulaAddItem[formulaItemConf.id].itemIndex
        if self.bSItemIndex > itemNum then
          self.bSItemIndex = itemNum
        end
      end
      if self.bSItemIndex == nIndex then
        self.bSItemPart = tabPart
        tabPart.obj_select:SetActive(true)
        self:_UpdateExpendBottom(formulaItemConf.materials)
      else
        tabPart.obj_select:SetActive(false)
      end
      tabPart.tx_equipLv.gameObject:SetActive(itemType == GoodsType.EQUIP)
      if itemType == GoodsType.EQUIP then
        tabPart.tx_equipLv.text = "+" .. equipInfo[nIndex].EnhanceLv
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._SelectItem, self, {
        formulaItemConf,
        tabPart,
        nIndex,
        equipInfo[nIndex]
      })
    end
  end)
end

function RyzaAlchemyPage:_SelectItem(go, params)
  local formulaItemConf = params[1]
  local tabPart = params[2]
  local itemIndex = params[3]
  local equipInfo = params[4]
  local beforeFull = self:_CheckBeforeFull(formulaItemConf)
  if #formulaItemConf.pre_item ~= 0 and not beforeFull then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4700001))
    return
  end
  if self.bSItemIndex ~= 0 and self.bSItemIndex == itemIndex and self.formulaAddItem[formulaItemConf.id] ~= nil then
    self.bSItemPart.obj_select:SetActive(false)
    self.bSItemPart = nil
    self.bSItemIndex = 0
    self.tab_Widgets.tween_itemList:Play(false)
    self:_UpdateDetailTips(formulaItemConf, false, false)
    self:_UnselectMaterial(formulaItemConf)
    self:_CreateFormation(self.selectFormulaConf)
    self:_CheckCanStart()
    return
  end
  local starPos = clickPos3
  self:_SelectItemSure(params, starPos)
end

function RyzaAlchemyPage:_SelectItemSure(params, starPos)
  local formulaItemConf = params[1]
  local tabPart = params[2]
  local itemIndex = params[3]
  local equipInfo = params[4]
  local materialId = formulaItemConf.materials[2]
  tabPart.obj_select:SetActive(true)
  if self.bSItemPart ~= nil then
    self.bSItemPart.obj_select:SetActive(false)
  end
  self.bSItemPart = tabPart
  self.bSItemIndex = itemIndex
  self:_ClickChainPos(formulaItemConf.position)
  self:_UpdateDetailTips(formulaItemConf, true, false)
  self.formulaAddItem[formulaItemConf.id] = {materialId = materialId, itemIndex = itemIndex}
  if formulaItemConf.materials[1] == GoodsType.EQUIP then
    table.insert(self.selectEquipIdTab, equipInfo.EquipId)
  end
  self:_CheckCanStart()
  local centerTmp = UIManager.uiCamera:WorldToScreenPoint(self.tab_Widgets.img_bg.gameObject.transform.position)
  self:_ShowshootingEff(starPos, centerTmp)
end

function RyzaAlchemyPage:_UpdateExpendBottom(materials)
  local itemConf = Logic.alchemyLogic:GetExpendGoodsConfig(materials)
  self.tab_Widgets.obj_selectItem:SetActive(true)
  self.tab_Widgets.tween_itemList:Play(true)
  UIHelper.SetImage(self.tab_Widgets.im_selectIcon, itemConf.icon)
  UIHelper.SetText(self.tab_Widgets.tx_selectNum, itemConf.ryza_type_num)
  for i = 1, 4 do
    self.tab_Widgets["im_type" .. i]:SetActive(table.containValue(itemConf.ryza_type, i))
  end
end

function RyzaAlchemyPage:_UpdateDetailTips(formulaItemConf, isOn, playTweeen)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_effectItem, self.tab_Widgets.trans_effect, #formulaItemConf.effect, function(nIndex, tabPart)
    local eff = formulaItemConf.effect[nIndex]
    local typeImage
    if isOn then
      typeImage = Logic.alchemyLogic:GetAlchemyItemType(eff[1]).image_on
    else
      typeImage = Logic.alchemyLogic:GetAlchemyItemType(eff[1]).image_off
    end
    UIHelper.CreateSubPart(tabPart.obj_type, tabPart.trans_type, eff[2], function(index, part)
      UIHelper.SetImage(part.im_type, typeImage)
    end)
    UIHelper.SetText(tabPart.tx_effect, eff[3])
  end)
  local timer = self:CreateTimer(function()
    self.tab_Widgets.obj_effect:SetActive(false)
    self.tab_Widgets.obj_effect:SetActive(true)
    if playTweeen and self.bSChainId ~= formulaItemConf.id then
      if not self.clickBg then
        self.tab_Widgets.tween_effect:ResetToBeginning()
      end
      self.clickBg = false
      self.tab_Widgets.tween_effect:Play()
    end
    self.bSChainId = formulaItemConf.id
  end, 0, 1, false)
  self:StartTimer(timer)
end

function RyzaAlchemyPage:_OnDrag(go, eventData)
  self.isDrag = true
  local targetTran = self.tab_Widgets.obj_chain.transform
  local delta = eventData.delta
  if not IsNil(targetTran) then
    local deviceWidth = UIManager:GetUIWidth()
    local deviceHeight = UIManager:GetUIHeight()
    local targetPos = targetTran.localPosition
    local x, y
    x = targetPos.x + delta.x
    targetPos.x = Logic.girlInfoLogic:GetNumberBetween(x, deviceWidth * scale_drag[2], deviceWidth * scale_drag[1])
    y = targetPos.y + delta.y
    targetPos.y = Logic.girlInfoLogic:GetNumberBetween(y, deviceHeight * scale_drag[4], deviceHeight * scale_drag[3])
    targetTran.localPosition = Vector3.New(targetPos.x, targetPos.y, 0)
  end
end

function RyzaAlchemyPage:_OnDragEnd()
  self.isDrag = false
end

function RyzaAlchemyPage:_ClickChainPos(params)
  local soucePos = self.tab_Widgets.obj_chain:GetComponent(RectTransform.GetClassType()).anchoredPosition
  local tweenPos = self.tab_Widgets.tween_pos
  tweenPos:ResetToBeginning()
  tweenPos.from = Vector3.New(soucePos.x, soucePos.y, 0)
  tweenPos.to = Vector3.New(-params[1], -params[2], 0)
  tweenPos:Play()
end

function RyzaAlchemyPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 940000012})
end

function RyzaAlchemyPage:_ShowProduct(formulaConf)
  self.tab_Widgets.obj_reward:SetActive(true)
  local itemType = formulaConf.product[1]
  local itemId = formulaConf.product[2]
  local itemNum = formulaConf.product[3]
  local itemConf = Logic.bagLogic:GetItemByTempateId(itemType, itemId)
  UIHelper.SetImage(self.tab_Widgets.im_rewardIcon, itemConf.icon)
  UIHelper.SetImage(self.tab_Widgets.im_rewardQuality, QualityImage[itemConf.quality], true)
  UIHelper.SetText(self.tab_Widgets.tx_rewardName, itemConf.name)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self._ClickReward, self, {itemType, itemId})
end

function RyzaAlchemyPage:_ClickReward(go, params)
  Logic.itemLogic:ShowItemInfo(params[1], params[2])
end

function RyzaAlchemyPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

function RyzaAlchemyPage:_CloseItemPart()
  if self.isDrag then
    return
  end
  self.bSChainId = 0
  self.clickBg = true
  self.tab_Widgets.tween_formula:Play(true)
  self.tab_Widgets.tween_itemList:Play(false)
  self.tab_Widgets.tween_effect:Play(false)
end

function RyzaAlchemyPage:_ClearSelectItem()
  if self.bSItemPart ~= nil then
    self.bSItemPart.obj_select:SetActive(false)
    self.bSItemIndex = 0
    self.bSItemPart = nil
  end
  self:_CheckCanStart()
end

function RyzaAlchemyPage:_CheckBeforeFull(formulaItemConf)
  local beforeFull = false
  for _, beforeId in ipairs(formulaItemConf.pre_item) do
    if self.formulaAddItem[beforeId] ~= nil then
      beforeFull = true
      break
    end
  end
  return beforeFull
end

function RyzaAlchemyPage:_UnselectMaterial(formulaItemConf)
  self.formulaAddItem[formulaItemConf.id] = nil
  local backIdTab = {}
  
  local function getBackIdTab(formulaItemId)
    local itemConf = Logic.alchemyLogic:GetAlchemyItemConf(formulaItemId)
    if #itemConf.back_item ~= 0 then
      for _, backItemId in ipairs(itemConf.back_item) do
        getBackIdTab(backItemId)
        table.insert(backIdTab, backItemId)
      end
    end
  end
  
  getBackIdTab(formulaItemConf.id)
  for _, id in ipairs(backIdTab) do
    self.formulaAddItem[id] = nil
  end
end

function RyzaAlchemyPage:_CheckCanStart()
  local fullLength = 0
  for _, v in pairs(self.formulaAddItem) do
    fullLength = fullLength + 1
  end
  local itemGroupNum = self.selectFormulaConf ~= nil and #self.selectFormulaConf.item_group or 1
  self.tab_Widgets.img_red:SetActive(itemGroupNum == fullLength)
  self:_ShowAddAllItemBtn(itemGroupNum == fullLength)
end

function RyzaAlchemyPage:_ClickStart()
  if self.selectFormulaConf.formula_type == FormulaType.Equip then
    local canGotEquip = Logic.rewardLogic:CanGotEquip(1)
    if not canGotEquip then
      return
    end
  end
  self.tab_Widgets.obj_formulaPart:SetActive(false)
  self.tab_Widgets.obj_itemPart:SetActive(false)
  self.tab_Widgets.img_red:SetActive(false)
  self.tab_Widgets.obj_effect:SetActive(false)
  self.tab_Widgets.obj_reward:SetActive(false)
  self:_CreateFormation(self.selectFormulaConf, true)
  SoundManager.Instance:PlayMusic("Effect_eff2d_ryza_alchemical_start")
  UIHelper.SetUILock(true)
  self:DestroyAllEffect()
  local startAlchemTimer2 = self:CreateTimer(function()
    UIHelper.SetUILock(false)
    self:_SendStartAlchemy()
  end, 1, 1)
  self:StartTimer(startAlchemTimer2)
end

function RyzaAlchemyPage:_SendStartAlchemy()
  if not Data.alchemyData:CheckOwnAlchemy(self.selectFormulaConf.id) then
    logError("not have formula id: ", self.selectFormulaConf.id)
  end
  Service.alchemyService:SendStartAlchemy(self.selectFormulaConf.id, self.selectEquipIdTab)
end

function RyzaAlchemyPage:_ShowSuccessPart()
  self.tab_Widgets.obj_success:SetActive(true)
  self.tab_Widgets.obj_effComplete:SetActive(true)
  local itemType = self.selectFormulaConf.product[1]
  local itemId = self.selectFormulaConf.product[2]
  local itemNum = self.selectFormulaConf.product[3]
  local itemConf = Logic.bagLogic:GetItemByTempateId(itemType, itemId)
  UIHelper.SetText(self.tab_Widgets.tx_sItem, itemConf.name)
  UIHelper.SetImage(self.tab_Widgets.im_sRewardIcon, itemConf.icon)
end

function RyzaAlchemyPage:_AlchemySuccess()
  self.tab_Widgets.obj_effect:SetActive(false)
  self.tab_Widgets.tween_itemList:Play(false)
  self.tab_Widgets.obj_formulaPart:SetActive(true)
  self.tab_Widgets.obj_itemPart:SetActive(false)
  self.tab_Widgets.tween_formula:Play(true)
  self.tab_Widgets.obj_reward:SetActive(true)
  self.tab_Widgets.obj_chain.transform.localPosition = Vector3.zero
  self:_ClearTempRecord()
  self:_ShowFormulaTab(self.formulaTab)
  self:_CreateFormation(self.selectFormulaConf)
  self.tab_Widgets.obj_success:SetActive(false)
end

function RyzaAlchemyPage:_ClearTempRecord()
  self.bSChainId = 0
  self.formulaAddItem = {}
  self.selectEquipIdTab = {}
  self:_ClearSelectItem()
end

function RyzaAlchemyPage:_ShowEquipInfo()
  self.tab_Widgets.obj_equipInfo:SetActive(self.selectFormulaConf.formula_type == FormulaType.Equip)
  if self.selectFormulaConf.formula_type ~= FormulaType.Equip then
    return
  end
  local equipId = self.selectFormulaConf.product[2]
  local shipEquipInfo = configManager.GetDataById("config_equip", equipId)
  local tabAttrInfo = Logic.equipLogic:GetEquipFinaAttr(equipId)
  local showIndex = 0
  local showCount = #tabAttrInfo / 6
  local isPlane = false
  if shipEquipInfo.ewt_id[1] == 18 or shipEquipInfo.ewt_id[1] == 19 or shipEquipInfo.ewt_id[1] == 20 then
    isPlane = true
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_prop, self.tab_Widgets.trans_prop, 6, function(nIndex, tabPart)
    local equipInfo = tabAttrInfo[nIndex + 6 * showIndex]
    tabPart.obj_prop:SetActive(equipInfo or isPlane)
    if equipInfo then
      if utf8.len(equipInfo.name) >= 3 then
        tabPart.txt_Name.text = string.format("<size=17>%s</size>", equipInfo.name)
      else
        tabPart.txt_Name.text = string.format("<size=17>%s</size>", equipInfo.name)
      end
      local attrValueShow = Logic.attrLogic:GetAttrShow(equipInfo.id, equipInfo.value)
      tabPart.txt_Value.text = attrValueShow
      UIHelper.SetImage(tabPart.img_Tag, equipInfo.icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
    elseif isPlane then
      isPlane = false
      local planeInfo = configManager.GetDataById("config_attribute", 3102)
      tabPart.txt_Name.text = planeInfo.attr_name
      tabPart.txt_Value.text = Mathf.ToInt(planeNume)
      UIHelper.SetImage(tabPart.img_Tag, planeInfo.attr_icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
    else
      tabPart.txt_Name.gameObject:SetActive(false)
      tabPart.txt_Value.gameObject:SetActive(false)
      tabPart.img_Tag.gameObject:SetActive(false)
    end
  end)
  showIndex = showIndex + 1
  if showCount < showIndex then
    showIndex = 0
  end
  local equipPskills = Logic.equipLogic:GetEquipRisePSkillById(equipId)
  self.tab_Widgets.obj_pskillTab:SetActive(0 < #equipPskills)
  if 0 < #equipPskills then
    UIHelper.CreateSubPart(self.tab_Widgets.obj_pskill, self.tab_Widgets.trans_pskill, #equipPskills, function(index, tabParts)
      local pskillId = equipPskills[index]
      local name = Logic.shipLogic:GetPSkillName(pskillId)
      local ok, info = Logic.equipLogic:CheckPSkillOpen(equipId, pskillId)
      local lvdes = ok and "Level: " .. info.PSkillLv or UIHelper.GetString(920000112)
      local lv = ok and info.PSkillLv or 1
      if common then
        ok = true
        lv = 1
        lvdes = "Level: 1"
      end
      local des = Logic.shipLogic:GetPSkillDesc(pskillId, lv)
      UIHelper.SetText(tabParts.tx_name, name)
      UIHelper.SetText(tabParts.tx_des, des)
      if ok then
        UIHelper.SetTextColor(tabParts.tx_lv, lvdes, "5e718a")
        UIHelper.SetTextColor(tabParts.tx_des, des, "5e718a")
      else
        UIHelper.SetText(tabParts.tx_lv, lvdes)
      end
    end)
  end
end

function RyzaAlchemyPage:_ClickCloseComplete()
  self.tab_Widgets.obj_complete:SetActive(false)
end

function RyzaAlchemyPage:_ShowSubtitle(content)
  UIHelper.SetText(self.tab_Widgets.txt_girl, content)
  self.tab_Widgets.obj_bgText:SetActive(true)
end

function RyzaAlchemyPage:_CloseSubtitle()
  self.tab_Widgets.obj_bgText:SetActive(false)
end

function RyzaAlchemyPage:_LoadShipModel()
  local param = {showID = ryzaShipInfoId}
  if self.m_objModel == nil then
    self.m_objModel = UIHelper.Create3DModel(param, self.tab_Widgets.img_girlRender, CamDataType.Display)
    self.m_objModel:HideMech(false)
    self.tab_Widgets.img_girlRender.gameObject:SetActive(true)
    self:_PlayBehaviour(SelectFormulaAnimTab)
  end
  self:_StartTimer()
end

function RyzaAlchemyPage:_PlayBehaviour(animTab)
  self:_StopTimer()
  local total = #animTab
  local randomNum = Mathf.Random(1, total)
  local behaviourName = animTab[randomNum]
  if self.m_objModel then
    self.m_objModel:Get3dObj():playBehaviour(behaviourName, false, function()
      self:_StartTimer()
      self.m_objModel:Get3dObj():playBehaviour("alchemical_stand", true)
    end)
  end
end

function RyzaAlchemyPage:_UnloadModel()
  if self.m_objModel ~= nil then
    UIHelper.Close3DModel(self.m_objModel)
    self.tab_Widgets.img_girlRender.gameObject:SetActive(false)
    self.m_objModel = nil
  end
end

function RyzaAlchemyPage:_StartTimer()
  if self.m_timerCallBack == nil then
    function self.m_timerCallBack()
      self:_PlayBehaviour(WaitAnimTab)
    end
  end
  if self.m_timer == nil then
    self.m_timer = self:CreateTimer(self.m_timerCallBack, ryzaDurationTime, 1, false)
  else
    self:ResetTimer(self.m_timer, self.m_timerCallBack, ryzaDurationTime, 1, false)
  end
  self:StartTimer(self.m_timer)
end

function RyzaAlchemyPage:_StopTimer()
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function RyzaAlchemyPage:_ShowshootingEff(fromPos, toPos)
  if self.endtimer then
    if self.obj_eff ~= nil then
      UIHelper.DestroyUIEffect(self.obj_eff)
      self.obj_eff = nil
    end
    self:StopTimer(self.endtimer)
  end
  if self.obj_eff == nil then
    self.obj_eff = UIHelper.CreateUIEffect("effects/prefabs/ui/eff2d_ryza_alchemical_shooting_star", self.tab_Widgets.obj_effStar.transform)
    self.obj_eff:AddComponent(UISortEffectComponent.GetClassType())
    self.obj_eff.transform.position = UIManager.uiCamera:ScreenToWorldPoint(fromPos)
    self.tab_Widgets.obj_effStar:SetActive(true)
  end
  local deltax = toPos.x - fromPos.x
  local deltay = toPos.y - fromPos.y
  local time = 0.3
  local tick = 0.05
  local stepx = deltax / time * tick
  local stepy = deltay / time * tick
  local curx = fromPos.x
  local cury = fromPos.y
  local count = 0
  self.endtimer = self:CreateTimer(function()
    if count >= time / tick then
      if self.obj_eff ~= nil then
        UIHelper.DestroyUIEffect(self.obj_eff)
        self.obj_eff = nil
      end
      self:StopTimer(self.endtimer)
      self:_CreateFormation(self.selectFormulaConf)
      SoundManager.Instance:PlayMusic("Effect_eff2d_ryza_alchemical_stars_01")
      self.tab_Widgets.obj_effStar:SetActive(false)
      self.tab_Widgets.tween_itemList:Play(false)
    else
      curx = curx + stepx
      cury = cury + stepy
      local posSW = UIManager.uiCamera:ScreenToWorldPoint(Vector3.New(curx, cury, 0))
      if self.obj_eff ~= nil then
        self.obj_eff.transform.position = posSW
      end
      count = count + 1
    end
  end, 0.05, tick, false)
  self:StartTimer(self.endtimer)
end

function RyzaAlchemyPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
  self:_UnloadModel()
end

function RyzaAlchemyPage:DoOnClose()
  inputManager:UnregisterAllInput(self)
  if self.obj_eff ~= nil then
    UIHelper.DestroyUIEffect(self.obj_eff)
    self.obj_eff = nil
  end
  self:_UnloadModel()
end

function RyzaAlchemyPage:_OpenHelp()
  self.tab_Widgets.obj_help.gameObject:SetActive(true)
end

function RyzaAlchemyPage:_CloseHelp()
  self.tab_Widgets.obj_help.gameObject:SetActive(false)
end

function RyzaAlchemyPage:_ShowAddAllItemBtn(canStart)
  canStart = canStart ~= nil and canStart or false
  local showBtn = false
  if self.selectFormulaConf ~= nil and not canStart then
    showBtn = Data.alchemyData:CheckFastAlchemy(self.selectFormulaConf.id)
  end
  self.tab_Widgets.obj_addAll:SetActive(showBtn)
end

function RyzaAlchemyPage:_AddAllItem()
  self:_CloseItemPart()
  local materialEnough, expendType, id = Logic.alchemyLogic:CheckExpendNum(self.selectFormulaConf.id)
  if not materialEnough then
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(expendType, id, true))
    return
  end
  for _, v in ipairs(self.selectFormulaConf.item_group) do
    local formulaItemId = v
    if self.formulaAddItem[formulaItemId] == nil then
      local formulaItemConf = Logic.alchemyLogic:GetAlchemyItemConf(formulaItemId)
      local materialType = formulaItemConf.materials[1]
      local materialId = formulaItemConf.materials[2]
      local materialNum = formulaItemConf.materials[3]
      local materialConf = Logic.alchemyLogic:GetExpendGoodsConfig(formulaItemConf.materials)
      self.formulaAddItem[formulaItemId] = {materialId = materialId, itemIndex = 1}
      if materialType == GoodsType.EQUIP then
        local equipInfo, _ = Logic.alchemyLogic:GetEquipInfoByTid(materialId)
        table.insert(self.selectEquipIdTab, equipInfo[1].EquipId)
      end
    end
  end
  self:_CreateFormation(self.selectFormulaConf)
  self:_CheckCanStart()
end

return RyzaAlchemyPage
