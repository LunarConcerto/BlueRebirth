local BagShipItem = class("UI.Bag.BagShipItem")

function BagShipItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.id = nil
  self.type = nil
  self.index = 0
  self.bagNum = 0
end

function BagShipItem:Init(obj, tabPart, itemType, id, selectType, index)
  self.page = obj
  self.tabPart = tabPart
  self.id = id
  self.selectType = selectType
  self.index = index
  self.tabPart.btn_select.gameObject:SetActive(false)
  local bagInfo = Data.bagData:GetItemById(self.id)
  self.bagNum = bagInfo.num
  self:SetItemShowNum(0)
  if itemType == GoodsType.ITEM then
    tabPart.txt_goodsName.text = Logic.itemLogic:GetName(self.id)
    UIHelper.SetImage(tabPart.img_goods, Logic.itemLogic:GetIcon(self.id))
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[Logic.itemLogic:GetQuality(self.id)])
  elseif itemType == GoodsType.Fragment then
    tabPart.txt_goodsName.text = Logic.fragmentLogic:GetName(self.id)
    UIHelper.SetImage(tabPart.img_goods, Logic.fragmentLogic:GetIcon(self.id))
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[Logic.fragmentLogic:GetQuality(self.id)])
  end
  if self.selectType == EquipToBagSign.RISE_STAR_MOBO then
    self:SetRiseMuboClick()
  end
end

function BagShipItem:ResetItemNum()
  self.tabPart.txt_value.text = self.bagNum
end

function BagShipItem:SetItemShowNum(selectNum)
  if 0 < selectNum then
    self.tabPart.txt_value.text = selectNum .. "/" .. self.bagNum
  else
    self.tabPart.txt_value.text = self.bagNum
  end
end

function BagShipItem:SetRiseMuboClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_goods, function()
    self.page:ClickSelectShipItemMubo(not self.tabPart.btn_select.gameObject.activeSelf, self.index, self.id)
  end)
  UGUIEventListener.AddButtonOnClick(self.tabPart.btn_select, function()
    self.page:ClickSelectShipNumMubo(self.index, self.id)
  end)
end

return BagShipItem
