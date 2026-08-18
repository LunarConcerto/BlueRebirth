local UPEquipInfoPage = class("UI.BuildShip.UPEquipInfoPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function UPEquipInfoPage:DoInit()
end

function UPEquipInfoPage:DoOnOpen()
  self.buildConfig = self:GetParam()
  self:_DisplayGoods()
end

function UPEquipInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_mask, self._ClickClose, self)
end

function UPEquipInfoPage:_DisplayGoods()
  local gotNumTab = Logic.buildShipLogic:GetUpCountByBuildId(self.buildConfig.id)
  local upList = self.buildConfig.up_list
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.rect_content, #upList, function(nIndex, tabPart)
    local goodsId = upList[nIndex]
    local goodsInfo
    if self.buildConfig.extract_reset_type == BuildUpType.Equip then
      goodsInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.EQUIP, goodsId)
      UIHelper.SetImage(tabPart.im_quality, QualityIcon[goodsInfo.quality])
    elseif self.buildConfig.extract_reset_type == BuildUpType.Ship then
      goodsInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.SHIP, goodsId)
      UIHelper.SetImage(tabPart.im_quality, EquipQualityIcon[goodsInfo.quality])
    end
    tabPart.obj_get:SetActive(0 < gotNumTab[goodsId])
    UIHelper.SetImage(tabPart.im_icon, goodsInfo.icon)
    tabPart.tx_name.text = goodsInfo.name
    UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, self._ShowItemInfo, self, goodsInfo)
  end)
  local equipNameTab = {}
  if table.nums(upList) > 0 then
    for i, v in ipairs(upList) do
      equipNameTab[i] = Logic.equipLogic:GetEquipConfigById(v).name
    end
  end
  if #equipNameTab == 4 then
    local equipStr = UIHelper.GetString(910002047)
    local equipInfo = string.format(equipStr, equipNameTab[1], equipNameTab[2], equipNameTab[3], equipNameTab[4], equipNameTab[1], equipNameTab[2], equipNameTab[3], equipNameTab[4])
    UIHelper.SetText(self.tab_Widgets.txt_rule, equipInfo)
  else
    logError("\233\133\141\231\189\174\232\161\168extract_ship.up_list\229\173\151\230\174\181\228\191\161\230\129\175\228\184\141\229\175\185")
  end
end

function UPEquipInfoPage:_ShowItemInfo(go, info)
  Logic.itemLogic:ShowItemInfo(info.tabIndex, info.id)
end

function UPEquipInfoPage:_ClickClose()
  UIHelper.ClosePage("UPEquipInfoPage")
end

function UPEquipInfoPage:DoOnHide()
end

function UPEquipInfoPage:DoOnClose()
end

return UPEquipInfoPage
