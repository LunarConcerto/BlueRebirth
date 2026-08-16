local ChoosePage = class("UI.Guild.ChoosePage", LuaUIPage)

function ChoosePage:DoInit()
  self.m_tab_Tags = {
    {
      toggle = self.tab_Widgets.tgItem,
      tween = self.tab_Widgets.tweenItem,
      objselect = self.tab_Widgets.objSelectItem,
      objModule = self.tab_Widgets.objItem
    },
    {
      toggle = self.tab_Widgets.tgEquip,
      tween = self.tab_Widgets.tweenEquip,
      objselect = self.tab_Widgets.objSelectEquip,
      objModule = self.tab_Widgets.objEquip
    }
  }
end

function ChoosePage:DoOnOpen()
  self:OpenTopPage("ChoosePage", 1, UIHelper.GetString(920000537), self, false)
  local tabParam = self:GetParam()
  self.mDonateData = tabParam.Param.DonateData
  self.mItems = tabParam.Param.Items
  self.mTaskData = tabParam.Param.TaskData
  self.mCallback = tabParam.Param.CallBack
  self:InitSelectData()
  self:UpdateShowData()
  self.mTarDonateNum = self.mDonateData:GetTarDonateNum()
  self.tab_Widgets.tgGroup:SetActiveToggleIndex(self.mShowIndex)
  for _, tabTag in ipairs(self.m_tab_Tags) do
    self.tab_Widgets.tgGroup:RemoveToggle(tabTag.toggle)
  end
end

function ChoosePage:RegisterAllEvent()
  self.tab_Widgets.tgGroup:ClearToggles()
  for _, tabTag in ipairs(self.m_tab_Tags) do
    self.tab_Widgets.tgGroup:RegisterToggle(tabTag.toggle)
  end
  self.tab_Widgets.tgGroup:RemoveToggleUnActive(0)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroup, self, "", self._SwitchTogs)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk, self.btnOkOnClick, self)
end

function ChoosePage:DoOnHide()
end

function ChoosePage:DoOnClose()
end

function ChoosePage:_SwitchTogs(index)
  for tabindex, objTab in ipairs(self.m_tab_Tags) do
    local isSelect = tabindex == index + 1
    objTab.tween:Play(isSelect)
    objTab.objselect:SetActive(isSelect)
    objTab.objModule:SetActive(isSelect)
  end
  self.m_curSelectTog = index
  self:ShowPage()
end

function ChoosePage:ShowPage()
  local curSelectIndex = self.m_curSelectTog + 1
  if curSelectIndex == 1 then
    self:ShowItemPartial()
  else
    self:ShowEquipPartial()
  end
  local selectNum = 0
  for _, item in pairs(self.mItems) do
    if 0 < item.ItemNum then
      selectNum = selectNum + item.ItemNum
    end
  end
  UIHelper.SetText(self.tab_Widgets.txtSelectNum, selectNum .. "/" .. self.mTarDonateNum)
end

function ChoosePage:InitSelectData()
  local itemMap = self.mSelectItemMap or {}
  for _, item in ipairs(self.mItems) do
    if item.ItemNum > 0 then
      local itemNum = itemMap[item.ItemId] or 0
      itemMap[item.ItemId] = itemNum + item.ItemNum
    end
  end
  self.mSelectItemMap = itemMap
  local equipMap = self.mSelectEquipMap or {}
  for _, item in ipairs(self.mItems) do
    if item.ItemNum > 0 and item.SpecialId ~= nil and 0 < item.SpecialId then
      equipMap[item.SpecialId] = true
    end
  end
  self.mSelectEquipMap = equipMap
end

function ChoosePage:UpdateItemSelectData()
  for _, item in ipairs(self.mItems) do
    item.ItemNum = 0
  end
  local itemMap = self.mSelectItemMap or {}
  local max = #self.mItems
  local i = 1
  for itemId, itemNum in pairs(itemMap) do
    if max < i then
      break
    end
    local itemType = Logic.bagLogic:GetItemTypeByTid(itemId)
    local item = self.mItems[i]
    item.ItemType = itemType
    item.ItemId = itemId
    item.ItemNum = itemNum
    i = i + 1
  end
end

function ChoosePage:UpdateEquipSelectData()
  for _, item in ipairs(self.mItems) do
    item.ItemNum = 0
  end
  local equipMap = self.mSelectEquipMap or {}
  local max = #self.mItems
  local i = 1
  for equipid, _ in pairs(equipMap) do
    if max < i then
      break
    end
    local equipinfo = Data.equipData:GetEquipDataById(equipid)
    local item = self.mItems[i]
    item.ItemType = GoodsType.EQUIP
    item.ItemId = equipinfo.TemplateId
    item.ItemNum = 1
    item.SpecialId = equipid
    i = i + 1
  end
end

function ChoosePage:UpdateShowData()
  local dilist = Logic.guildtaskLogic:GetDonateItemList(self.mTaskData.TaskId)
  if dilist.Type == EnumDonateItemType.Item then
    self.mShowIndex = 0
    self.mShowItemlist = dilist.ItemList
  else
    self.mShowIndex = 1
    self.mShowEquiplist = dilist.EquipList
  end
end

function ChoosePage:ShowItemPartial()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentItem, self.tab_Widgets.itemItem, #self.mShowItemlist, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemPart(index, part)
    end
  end)
end

function ChoosePage:updateItemPart(index, part)
  local showitem = self.mShowItemlist[index]
  local itemcfg = Logic.bagLogic:GetItemByConfig(showitem.templateId)
  UIHelper.SetText(part.txt_goodsName, itemcfg.name)
  UIHelper.SetText(part.txt_value, "x" .. math.tointeger(showitem.num))
  local itemMap = self.mSelectItemMap or {}
  local selectnum = itemMap[showitem.templateId] or 0
  if 0 < selectnum then
    UIHelper.SetText(part.txt_value, selectnum .. "/" .. showitem.num)
    part.btnSelect.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnSelect, function()
      local itemMap = self.mSelectItemMap or {}
      local itemNum = itemMap[showitem.templateId] or 0
      if 0 < itemNum then
        itemNum = itemNum - 1
      end
      itemMap[showitem.templateId] = itemNum
      self.mSelectItemMap = itemMap
      self:UpdateItemSelectData()
      self:ShowPage()
    end)
    UGUIEventListener.AddButtonOnClick(part.btn_goods, function()
      local itemMap = self.mSelectItemMap or {}
      itemMap[showitem.templateId] = 0
      self.mSelectItemMap = itemMap
      self:UpdateItemSelectData()
      self:ShowPage()
    end)
  else
    part.btnSelect.gameObject:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btn_goods, function()
      local itemMap = self.mSelectItemMap or {}
      local maxCount = self.mTarDonateNum
      local count = 0
      for itemId, itemNum in pairs(itemMap) do
        count = count + itemNum
      end
      if maxCount > count then
        local itemNum = itemMap[showitem.templateId] or 0
        local addNum1 = maxCount - count
        local addNum2 = showitem.num - itemNum
        if addNum1 < addNum2 then
          itemNum = itemNum + addNum1
        else
          itemNum = itemNum + addNum2
        end
        itemMap[showitem.templateId] = itemNum
      end
      self.mSelectItemMap = itemMap
      self:UpdateItemSelectData()
      self:ShowPage()
    end)
  end
  part.obj_piece:SetActive(itemIndex == GoodsType.Fragment)
  if itemcfg.icon ~= nil then
    UIHelper.SetImage(part.img_goods, tostring(itemcfg.icon))
  end
  UIHelper.SetImage(part.img_quality, QualityIcon[itemcfg.quality])
end

function ChoosePage:ShowEquipPartial()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentEquip, self.tab_Widgets.itemEquip, #self.mShowEquiplist, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateEquipPart(index, part)
    end
  end)
end

function ChoosePage:updateEquipPart(index, part)
  local showequip = self.mShowEquiplist[index]
  UIHelper.SetText(part.txt_equipName, showequip.name)
  UIHelper.SetImage(part.img_goods, tostring(showequip.icon))
  UIHelper.SetImage(part.img_quality, QualityIcon[showequip.quality])
  if showequip.Num == nil then
    part.txt_num.text = "x" .. "1"
  else
    part.txt_num.text = "x" .. showequip.Num
  end
  local selectnum = 0
  local equipMap = self.mSelectEquipMap or {}
  for _, equipid in ipairs(showequip.tabEquipId) do
    if equipMap[equipid] then
      selectnum = selectnum + 1
    end
  end
  if 0 < selectnum then
    UIHelper.SetText(part.txt_num, selectnum .. "/" .. showequip.Num)
    part.btnSelect.gameObject:SetActive(true)
    UGUIEventListener.AddButtonOnClick(part.btnSelect, function()
      local equipMap = self.mSelectEquipMap or {}
      for _, equipid in ipairs(showequip.tabEquipId) do
        if equipMap[equipid] then
          equipMap[equipid] = nil
          break
        end
      end
      self:UpdateEquipSelectData()
      self:ShowPage()
    end)
    UGUIEventListener.AddButtonOnClick(part.btn_equip, function()
      local equipMap = self.mSelectEquipMap or {}
      for _, equipid in ipairs(showequip.tabEquipId) do
        equipMap[equipid] = nil
      end
      self.mSelectEquipMap = equipMap
      self:UpdateEquipSelectData()
      self:ShowPage()
    end)
  else
    part.btnSelect.gameObject:SetActive(false)
    UGUIEventListener.AddButtonOnClick(part.btn_equip, function()
      local equipMap = self.mSelectEquipMap or {}
      local max = #self.mItems
      for _, equipid in ipairs(showequip.tabEquipId) do
        if max <= table.nums(equipMap) then
          break
        end
        equipMap[equipid] = true
      end
      self.mSelectEquipMap = equipMap
      self:UpdateEquipSelectData()
      self:ShowPage()
    end)
  end
  if showequip.EnhanceLv == 0 then
    part.txt_lv.gameObject:SetActive(false)
  else
    part.txt_lv.gameObject:SetActive(true)
    part.txt_lv.text = "+" .. math.tointeger(showequip.EnhanceLv)
  end
  UIHelper.SetStar(part.obj_star, part.trans_star, showequip.Star)
  part.obj_towerlock:SetActive(false)
  part.obj_girl:SetActive(false)
end

function ChoosePage:btnOkOnClick()
  if self.mCallback ~= nil then
    self.mCallback(self.mItems)
  end
  UIHelper.ClosePage("ChoosePage")
end

return ChoosePage
