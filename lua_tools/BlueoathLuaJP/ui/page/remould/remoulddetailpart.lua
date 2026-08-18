local RemouldDetailPart = class("UI.Remould.RemouldDetailPart")

function RemouldDetailPart:Init(page, tabWidgets)
  self.page = page
  self.tab_Widgets = tabWidgets
end

function RemouldDetailPart:SetRemouldRare(oldSIId, newSIId, txRare, txRareup)
  local oldShipShow = Logic.shipLogic:GetShipInfoBySiId(oldSIId)
  UIHelper.SetTextColor(txRare, AllType[oldShipShow.quality], ShipQualityColor[oldShipShow.quality])
  local newShipShow = Logic.shipLogic:GetShipInfoBySiId(newSIId)
  UIHelper.SetTextColor(txRareup, AllType[newShipShow.quality], ShipQualityColor[newShipShow.quality])
end

function RemouldDetailPart:SetRemouldAttr(attrItem, transAttr, attrTab)
  UIHelper.CreateSubPart(attrItem, transAttr, #attrTab, function(nIndex, tabPart)
    local attrId = attrTab[nIndex][2]
    local attrValue = attrTab[nIndex][3]
    local str = ""
    local attributeInfo = configManager.GetDataById("config_attribute", attrId)
    UIHelper.SetImage(tabPart.img_oldIcon, attributeInfo.attr_icon)
    UIHelper.SetText(tabPart.tx_oldName, attributeInfo.attr_name)
    local value = 0
    local formula = attributeInfo.remould_prop_formula
    if formula ~= "" then
      value = load("local prop =" .. tostring(attrValue) .. "prop = " .. formula .. "return prop")()
    else
      value = attrValue
    end
    UIHelper.SetText(tabPart.tx_numup, "+" .. value)
  end)
end

function RemouldDetailPart:SetRemouldFashion(fashionId, txName, btnFashion)
  local fashionInfo = Logic.fashionLogic:GetFashionConfig(fashionId)
  UIHelper.SetText(txName, fashionInfo.name)
  UGUIEventListener.AddButtonOnClick(btnFashion, self.page._OpenFasion, self.page, {fashionId})
end

function RemouldDetailPart:SetRemouldSkill(skillId, skillIcon, skillName, skillContent)
  local name = Logic.shipLogic:GetPSkillName(skillId)
  local icon = Logic.shipLogic:GetPSkillIcon(skillId)
  local desc = Logic.shipLogic:GetPSkillDesc(skillId, 1, false)
  UIHelper.SetImage(skillIcon, icon)
  UIHelper.SetText(skillName, name)
  UIHelper.SetText(skillContent, desc)
end

function RemouldDetailPart:SetRemouldSkillUpgrade(oldSkillId, newSkillId, ImgOSkill, TxtOSkill, ImgNSkill, TxtNSkill, BtnOSkill, BtnNSkill)
  local oldSkillDisplayId = Logic.shipLogic:GetPSkillDisplayIdByGroupId(oldSkillId)
  local oldDisplayInfo = Logic.shipLogic:GetPSkillDisplayConfigById(oldSkillDisplayId)
  local newSkillDisplayId = Logic.shipLogic:GetPSkillDisplayIdByGroupId(newSkillId)
  local newDisplayInfo = Logic.shipLogic:GetPSkillDisplayConfigById(newSkillDisplayId)
  UIHelper.SetImage(ImgOSkill, oldDisplayInfo.skill_icon)
  UIHelper.SetText(TxtOSkill, oldDisplayInfo.skill_name)
  UIHelper.SetImage(ImgNSkill, newDisplayInfo.skill_icon)
  UIHelper.SetText(TxtNSkill, newDisplayInfo.skill_name)
  UGUIEventListener.AddButtonOnClick(BtnOSkill, self.page._ClickSkill, self.page, {oldSkillId, oldSkillId})
  UGUIEventListener.AddButtonOnClick(BtnNSkill, self.page._ClickSkill, self.page, {oldSkillId, newSkillId})
end

return RemouldDetailPart
