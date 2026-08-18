local GoodsDamagePage = class("UI.GoodsCopy.GoodsDamagePage", LuaUIPage)

function GoodsDamagePage:DoOnOpen()
  self:InitUI()
end

function GoodsDamagePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._OnBtnClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bg, self._OnBtnClose, self)
end

function GoodsDamagePage:InitUI()
  local widgets = self:GetWidgets()
  local goodsDamageData = Logic.goodsCopyLogic:GetGoodsCopyDamages()
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #goodsDamageData, function(index, tabPart)
    local data = goodsDamageData[index]
    local copyDisplayCfg = configManager.GetDataById("config_copy_display", data.CopyId)
    local copyBattleCfg = configManager.GetDataById("config_goods_battle", data.CopyId)
    UIHelper.SetText(tabPart.txt_name, copyBattleCfg.name)
    UIHelper.SetText(tabPart.txt_damage, data.TodayMaxDamage)
  end)
end

function GoodsDamagePage:_OnBtnClose()
  self:CloseSelf()
end

return GoodsDamagePage
