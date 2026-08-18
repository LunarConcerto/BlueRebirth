local CommonGoodsItem = class("UI.Repaire.CommonGoodsItem")

function CommonGoodsItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.info = {}
  self.index = nil
  self.likeTab = nil
end

function CommonGoodsItem:Init(obj, tabPart, data, index, likeTab)
  self.page = obj
  self.tabPart = tabPart
  self.info = data
  self.index = index
  self.likeTab = likeTab
  self:_SetGoodsInfo()
end

function CommonGoodsItem:_SetGoodsInfo()
  self.tabPart.txt_goodsName.text = self.info.name
  self.tabPart.obj_like:SetActive(self.likeTab[self.info.id] ~= nil)
  UIHelper.SetImage(self.tabPart.img_goods, self.info.icon)
  self.tabPart.txt_goodsNum.text = self.info.price[3]
  local config = Logic.bagLogic:GetItemByTempateId(self.info.price[1], self.info.price[2])
  UIHelper.SetImage(self.tabPart.img_costIcon, config.icon)
  UIHelper.SetImage(self.tabPart.obj_quality, FleetSmallCardQualityImg[self.info.quality])
  self:_AddClick()
  self.tabPart.objMask:SetActive(false)
  self.tabPart.objGolden:SetActive(false)
end

function CommonGoodsItem:_AddClick()
  UGUIEventListener.AddButtonOnClick(self.tabPart.btnDrag, function()
    self.page:_ClickGift(self.tabPart, self.info)
  end)
end

return CommonGoodsItem
