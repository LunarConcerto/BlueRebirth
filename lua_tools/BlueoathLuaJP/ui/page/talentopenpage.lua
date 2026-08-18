local TalentOpenPage = class("UI.TalentPage", LuaUIPage)

function TalentOpenPage:DoInit()
end

function TalentOpenPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self.OnBtnOkClick, self)
end

function TalentOpenPage:DoOnOpen()
  local param = self:GetParam()
  local talentId = param.talentId
  self:ShowTalentInfo(talentId)
end

function TalentOpenPage:ShowTalentInfo(talentId)
  local cfg = configManager.GetDataById("config_talent", talentId)
  UIHelper.SetImage(self.tab_Widgets.img_icon, cfg.talenticon)
  UIHelper.SetText(self.tab_Widgets.txt_desc, cfg.desc)
  UIHelper.SetText(self.tab_Widgets.txt_name, cfg.name)
end

function TalentOpenPage:OnBtnOkClick()
  UIHelper.ClosePage("TalentOpenPage")
end

function TalentOpenPage:DoOnHide()
end

function TalentOpenPage:DoOnClose()
end

return TalentOpenPage
