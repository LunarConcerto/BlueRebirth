local FashionShowPage = class("UI.Build.FashionShowPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local FashionQuality = {
  [3] = "uipic_ui_fashionroll_bg_zi",
  [4] = "uipic_ui_fashionroll_bg_jin"
}

function FashionShowPage:DoInit()
  self.buildConfig = nil
end

function FashionShowPage:DoOnOpen()
  self.buildConfig = self:GetParam()
  self:_DisplayDrop()
end

function FashionShowPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_return, self._ClickClose, self)
end

function FashionShowPage:_DisplayDrop()
  local clothesTab, rewardTab = Logic.buildShipLogic:DisposeClothesDrop(self.buildConfig)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_clothes, self.tab_Widgets.obj_clothesItem, #clothesTab, function(tabParts)
    for nIndex, tabPart in pairs(tabParts) do
      local clothes = clothesTab[tonumber(nIndex)]
      local fashionConfig = configManager.GetDataById("config_fashion", clothes.id)
      UIHelper.SetImage(tabPart.img_quality, FashionQuality[clothes.quality])
      UIHelper.SetImage(tabPart.img_icon, fashionConfig.icon_ka)
      tabPart.txt_name.text = clothes.name
      local showOwn = Logic.fashionLogic:CheckFashionOwn(clothes.id)
      tabPart.obj_get:SetActive(showOwn)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, self._ShowItemInfo, self, clothes)
    end
  end)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.trans_reward, self.tab_Widgets.obj_rewardItem, #rewardTab, function(tabParts)
    for nIndex, tabPart in pairs(tabParts) do
      local reward = rewardTab[tonumber(nIndex)]
      if reward.tabIndex == GoodsType.EQUIP then
        UIHelper.SetImage(tabPart.img_quality, EquipQualityIcon[reward.quality])
      elseif reward.tabIndex == GoodsType.SHIP then
        UIHelper.SetImage(tabPart.img_quality, GirlQualityBgTexture[reward.quality])
      else
        UIHelper.SetImage(tabPart.img_quality, EquipQualityIcon[reward.quality])
      end
      UIHelper.SetImage(tabPart.img_icon, reward.icon)
      tabPart.txt_name.text = reward.name
      UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, self._ShowItemInfo, self, reward)
    end
  end)
end

function FashionShowPage:_ShowItemInfo(go, info)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(info.tabIndex, info.id))
end

function FashionShowPage:_ClickClose()
  self:CloseSelf("FashionShowPage")
end

function FashionShowPage:DoOnHide()
end

function FashionShowPage:DoOnClose()
end

return FashionShowPage
