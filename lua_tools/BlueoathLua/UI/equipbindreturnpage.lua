local EquipBindReturnPage = class("UI.EquipBindReturnPage", LuaUIPage)

function EquipBindReturnPage:DoInit()
  self.m_tabWidgets = self:GetWidgets()
  self.rootPage = nil
  self.equipLevelBreakConfs = configManager.GetData("config_equip_levelbreak_item")
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
  local consumes = Logic.equipIntensifyLogic:GetBindIntensifyItems()
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
