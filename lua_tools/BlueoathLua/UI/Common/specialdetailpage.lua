local SpecialDetailPage = class("UI.Common.SpecialDetailPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function SpecialDetailPage:DoInit()
end

function SpecialDetailPage:DoOnOpen()
  local data = self:GetParam()
  UIHelper.SetText(self.tab_Widgets.txt_title, data.title_cn)
  UIHelper.SetText(self.tab_Widgets.txt_name, data.name)
  UIHelper.SetImage(self.tab_Widgets.img_icon, data.icon)
  UIHelper.SetImage(self.tab_Widgets.img_quality, QualityIcon[data.quality])
  UIHelper.SetText(self.tab_Widgets.txt_desc, data.desc)
  local showObj, value = Logic.itemLogic:GetItemOwnCount(data)
  self.tab_Widgets.txt_repertory.gameObject:SetActive(showObj)
  self.tab_Widgets.txt_repertory.text = "\229\186\147\229\173\152\239\188\154" .. value
  if data.dropId and data.dropId ~= 0 and data.prefabType == 2 then
    self:_ShowDropItem(data)
  end
end

function SpecialDetailPage:_ShowDropItem(data)
  local widgets = self:GetWidgets()
  widgets.obj_btnClose:SetActive(false)
  widgets.obj_treasure:SetActive(true)
  widgets.obj_back:SetActive(false)
  widgets.trans_top.anchoredPosition = Vector2.New(-27.5, 67.61)
  widgets.trans_grid.anchoredPosition = Vector2.New(-27, -96.25)
  local dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByDropId(data.dropId)
  UIHelper.SetInfiniteItemParam(widgets.infinite_drop, widgets.obj_dropItem, #dropItemConfig, function(tabParts)
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
      UGUIEventListener.AddButtonOnClick(tabPart.btn_click, function()
        if goodsType == GoodsType.EQUIP then
          UIHelper.OpenPage("ShowEquipPage", {
            templateId = tId,
            showEquipType = ShowEquipType.Simple
          })
        else
          UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(goodsType, tId))
        end
      end)
    end
  end)
end

function SpecialDetailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.img_mask, self.ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_true, self.ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTreasure, self.ClickClose, self)
end

function SpecialDetailPage:ClickClose()
  UIHelper.ClosePage("SpecialDetailPage")
end

return SpecialDetailPage
