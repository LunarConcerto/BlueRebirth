local TreatyBuffShowPage = class("UI.DailyCopy.Treaty.TreatyBuffShowPage", LuaUIPage)

function TreatyBuffShowPage:DoInit()
end

function TreatyBuffShowPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.obj_commom, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_true, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reset, self._ClickReset, self)
end

function TreatyBuffShowPage:DoOnOpen()
  local param = self:GetParam()
  self.selectBuff = param.buffInfo
  self.dailyGroupId = param.dailyGroupId
  self.tab_Widgets.btn_true.gameObject:SetActive(self.dailyGroupId == 0)
  self.tab_Widgets.btn_reset.gameObject:SetActive(self.dailyGroupId ~= 0)
  self:_CreateTreatyReward()
end

function TreatyBuffShowPage:_CreateTreatyReward()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_buff, #self.selectBuff, function(nIndex, tabPart)
    local buffInfo
    if type(self.selectBuff[nIndex]) ~= "table" then
      buffId = self.selectBuff[nIndex]
      buffInfo = configManager.GetDataById("config_treaty_buff", buffId)
    else
      buffInfo = self.selectBuff[nIndex]
    end
    tabPart.txt_name.text = buffInfo.name
    UIHelper.SetImage(tabPart.img_icon, buffInfo.buff_icon)
    tabPart.txt_effect.text = buffInfo.desc
  end)
end

function TreatyBuffShowPage:_ClickReset()
  UIHelper.OpenPage("TreatyPage", {
    dailyGroupId = self.dailyGroupId,
    selectBuff = self.selectBuff
  })
  self:_ClickClose()
end

function TreatyBuffShowPage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

return TreatyBuffShowPage
