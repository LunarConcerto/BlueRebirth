local EquipBindReturnPage = class("UI.EquipBindReturnPage", LuaUIPage)

function EquipBindReturnPage:DoInit()
  self.m_tabWidgets = self:GetWidgets()
  self.rootPage = nil
  self.equipInfo = {}
end

function EquipBindReturnPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_True, self.ClickSure, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Cancel, self.ClickClose, self)
end

function EquipBindReturnPage:DoOnOpen()
  self.m_openParam = self:GetParam()
  self.equipInfo = self.m_openParam.equipInfo
  self.rootPage = self.m_openParam.showEquipPage
  local curLevel = self.equipInfo.EnhanceLv
  local initialLevel = Logic.equipLogic:GetEquipMaxLv(self.equipInfo.TemplateId)
  local curLevelStr = "+" .. curLevel
  if curLevel > initialLevel then
    curLevelStr = UIHelper.SetColor(curLevelStr, "A2D5FF")
  else
    curLevelStr = UIHelper.SetColor(curLevelStr, "FFFFFF")
  end
  UIHelper.SetText(self.m_tabWidgets.txt_level1, curLevelStr)
  UIHelper.SetText(self.m_tabWidgets.txt_level2, "+" .. initialLevel)
  local offLevel = curLevel - initialLevel
  local equipCfg = configManager.GetDataById("config_equip", self.equipInfo.TemplateId)
  local consumes = {}
  local equipLevelBreakConfs = {}
  if equipCfg.quality ~= ItemQuality.UR then
    consumes = Logic.equipIntensifyLogic:GetBindIntensifyItems(LvBreakType.Normal)
    equipLevelBreakConfs = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.Normal)
  else
    consumes = Logic.equipIntensifyLogic:GetBindIntensifyItems(LvBreakType.UR)
    equipLevelBreakConfs = configManager.GetDataById("config_equip_levelbreak_item", LvBreakType.UR)
  end
  local itemConf = configManager.GetDataById("config_item_info", equipLevelBreakConfs.unlock_item[1])
  UIHelper.SetText(self.m_tabWidgets.txt_name, itemConf.name)
  UIHelper.SetText(self.m_tabWidgets.txt_num, tostring(equipLevelBreakConfs.unlock_item[2]))
  UIHelper.CreateSubPart(self.m_tabWidgets.goods.gameObject, self.m_tabWidgets.goods_base, #consumes, function(index, uiPart)
    local consume = consumes[index]
    UIHelper.SetImage(uiPart.im_icon, tostring(consume.icon))
    UIHelper.SetText(uiPart.tx_exp, "x" .. tostring(consume.num * offLevel))
    UGUIEventListener.AddButtonOnClick(uiPart.im_icon, function()
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(consume.type, consume.id))
    end)
  end)
end

function EquipBindReturnPage:ClickSure()
  self.rootPage:CloseSubPage("EquipBindReturnPage")
  self.rootPage:sureUnBinding()
end

function EquipBindReturnPage:ClickClose()
  self.rootPage:CloseSubPage("EquipBindReturnPage")
end

function EquipBindReturnPage:DoOnHide()
end

function EquipBindReturnPage:DoOnClose()
end

return EquipBindReturnPage
