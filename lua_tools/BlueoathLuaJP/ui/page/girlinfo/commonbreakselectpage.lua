local CommonBreakSelectPage = class("UI.GirlInfo.CommonBreakSelectPage", LuaUIPage)

function CommonBreakSelectPage:DoInit()
  self.sureItemNum = 0
  self.tabWidgets = self:GetWidgets()
  self.heroInfo = {}
  self.breakItemId = 0
  self.breakPage = {}
end

function CommonBreakSelectPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.addBtn, self._OnAddClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.deleteBtn, self._OnSubClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_sure, self._OnSureClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_cancel, self._OnCancleClick, self)
end

function CommonBreakSelectPage:DoOnOpen()
  local param = self:GetParam()
  self.breakPage = param.breakPage
  self.heroInfo = param.heroInfo
  local shipFleetConf = Logic.shipLogic:GetShipFleetByHeroId(self.heroInfo.HeroId)
  self.breakItemId = shipFleetConf.common_break_item
  self:_ShowBreakItemIcon()
  self:UpdatePage()
end

function CommonBreakSelectPage:DoOnHide()
end

function CommonBreakSelectPage:DoOnClose()
end

function CommonBreakSelectPage:_OnSureClick()
  if self.sureItemNum <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(500011))
  end
  local items = {}
  for i = 1, self.sureItemNum do
    table.insert(items, self.breakItemId)
  end
  if self.breakPage then
    self.breakPage:SureBreakByItem(items)
  end
  UIHelper.ClosePage(self:GetName())
end

function CommonBreakSelectPage:_OnCancleClick()
  UIHelper.ClosePage(self:GetName())
end

function CommonBreakSelectPage:_OnAddClick()
  self.sureItemNum = self.sureItemNum + 1
  self:UpdatePage()
end

function CommonBreakSelectPage:_OnSubClick()
  self.sureItemNum = self.sureItemNum - 1
  self:UpdatePage()
end

function CommonBreakSelectPage:_ShowBreakItemIcon()
  if self.breakItemId ~= 0 then
    local icon = Logic.itemLogic:GetIcon(self.breakItemId)
    UIHelper.SetImage(self.tabWidgets.img_icon, icon)
    local quality = Logic.itemLogic:GetQuality(self.breakItemId)
    local qualityIcon = QualityIcon[quality]
    UIHelper.SetImage(self.tabWidgets.img_quality, qualityIcon)
    
    local function showItemInfo()
      Logic.itemLogic:ShowItemInfo(GoodsType.ITEM, self.breakItemId)
    end
    
    UGUIEventListener.AddButtonOnClick(self.tabWidgets.img_icon.gameObject, showItemInfo)
  end
end

function CommonBreakSelectPage:UpdatePage()
  local haveNum = Logic.bagLogic:GetBagItemNum(self.breakItemId)
  UIHelper.SetText(self.tabWidgets.txt_haveNum, tostring(haveNum))
  local needMaxNum = Logic.shipLogic:GetBreakItem(self.heroInfo.TemplateId)[2] - #self.breakPage:_GetSelected()
  if needMaxNum < 0 then
    needMaxNum = 0
  end
  local maxNum = math.min(haveNum, needMaxNum)
  if maxNum == 0 or 0 > self.sureItemNum then
    self.sureItemNum = 0
  elseif maxNum < self.sureItemNum then
    self.sureItemNum = maxNum
  end
  self.tabWidgets.addBtn.interactable = maxNum ~= 0 and maxNum > self.sureItemNum
  self.tabWidgets.addBtnGray.Gray = maxNum == 0 or not (maxNum > self.sureItemNum)
  self.tabWidgets.deleteBtn.interactable = maxNum ~= 0 and 0 < self.sureItemNum
  self.tabWidgets.deleteBtnGray.Gray = maxNum == 0 or not (0 < self.sureItemNum)
  UIHelper.SetText(self.tabWidgets.txt_Itemnum, self.sureItemNum)
end

return CommonBreakSelectPage
