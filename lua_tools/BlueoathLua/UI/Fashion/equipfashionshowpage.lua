local EquipFashionShowPage = class("UI.Fashion.EquipFashionShowPage", LuaUIPage)

function EquipFashionShowPage:DoInit()
end

function EquipFashionShowPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.CloseWebView, self._UnmuteMusic, self)
end

function EquipFashionShowPage:DoOnOpen()
  local fashionId = self:GetParam()
  self:_LoadItemInfo(fashionId)
end

function EquipFashionShowPage:_LoadItemInfo(fashionId)
  local fashionTabId = configManager.GetDataById("config_fashion", fashionId).skill_fashion_id
  UIHelper.CreateSubPart(self.tab_Widgets.obj_effectItem, self.tab_Widgets.trans_effectItem, #fashionTabId, function(index, tabPart)
    local skillFashion = configManager.GetDataById("config_skill_fashion", fashionTabId[index])
    UIHelper.SetText(tabPart.tx_name, skillFashion.skill_fashion_name)
    UIHelper.SetImage(tabPart.im_icon, skillFashion.show_picture)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_play, self._PlayAdvio, self, fashionTabId[index])
  end)
end

function EquipFashionShowPage:_PlayAdvio(go, effectId)
  local funcOpen = moduleManager:CheckFunc(FunctionID.EquipEffect, true)
  if not funcOpen then
    return
  end
  SoundManager.Instance:PlayMusic("Role_unlock")
  Logic.equipLogic:_PlayAdvio(effectId)
end

function EquipFashionShowPage:_ClickClose()
  UIHelper.ClosePage("EquipFashionShowPage")
end

function EquipFashionShowPage:_UnmuteMusic()
  SoundManager.Instance:PlayMusic("Role_unlock_finish")
end

function EquipFashionShowPage:DoOnHide()
end

function EquipFashionShowPage:DoOnClose()
end

return EquipFashionShowPage
