local SkillLevelupPage = class("UI.Hero.SkillLevelupPage", LuaUIPage)
local Effect = {
  [TalentType.ATTACK] = "effect_red",
  [TalentType.DEFEND] = "effect_yellow",
  [TalentType.ASSIST] = "effect_blue"
}
local EffectNext = {
  [TalentType.ATTACK] = "effect_red_next",
  [TalentType.DEFEND] = "effect_yellow_next",
  [TalentType.ASSIST] = "effect_blue_next"
}

function SkillLevelupPage:DoInit()
end

function SkillLevelupPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btnCancel, self.btnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnClose, self.btnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnLevelUp, self.btnLevelUp, self)
  self:RegisterEvent(LuaEvent.HeroStudySkill, self.refresh, self)
end

function SkillLevelupPage:DoOnOpen()
  local params = self:GetParam()
  self.heroId = params.heroId
  self.skillId = params.skillId
  self:showContent()
end

function SkillLevelupPage:refresh()
  local widgets = self:GetWidgets()
  widgets.effectLevelUp:SetActive(false)
  widgets.effectLevelUp:SetActive(true)
  widgets.tweenPresent:SetActive(false)
  widgets.tweenPresent:SetActive(true)
  local isMax = Logic.shipLogic:CheckHeroPSkillReachMax(self.heroId, self.skillId)
  if not isMax then
    widgets.tweenNext:SetActive(false)
    widgets.tweenNext:SetActive(true)
    local typ = Logic.shipLogic:GetPSkillType(self.skillId)
    if Effect[typ] == nil then
      logError("skill type err. skillId:%s, talent_type:%s", self.skillId, typ)
      return
    end
    widgets[Effect[typ]]:SetActive(false)
    widgets[Effect[typ]]:SetActive(true)
    widgets[EffectNext[typ]]:SetActive(false)
    widgets[EffectNext[typ]]:SetActive(true)
  end
  SoundManager.Instance:PlayAudio("Effect_Eff_levelup")
  self:showContent()
end

function SkillLevelupPage:showContent()
  local showSkillId = Logic.shipLogic:GetReplaceSkillId(self.skillId, self.heroId)
  local level = Logic.shipLogic:GetHeroPSkillLv(self.heroId, self.skillId)
  local name = Logic.shipLogic:GetPSkillName(showSkillId)
  local desc = Logic.shipLogic:GetPSkillDesc(showSkillId, level, false)
  local type = Logic.shipLogic:GetPSkillType(showSkillId)
  local icon = Logic.shipLogic:GetPSkillIcon(showSkillId)
  local widgets = self:GetWidgets()
  local color = TalentColor[type]
  UIHelper.SetTextColor(widgets.txtName, name, color)
  UIHelper.SetImage(widgets.imgIcon, icon)
  UIHelper.SetText(widgets.txtDes, desc)
  local str = UIHelper.GetLocString(160022, level)
  UIHelper.SetTextColor(widgets.txtLevel, str, color)
  local isMax = Logic.shipLogic:CheckHeroPSkillReachMax(self.heroId, self.skillId)
  widgets.objNext:SetActive(not isMax)
  widgets.imgArrow.gameObject:SetActive(not isMax)
  widgets.txtLevelMax.gameObject:SetActive(isMax)
  if not isMax then
    local nextShowSkillId = self.heroId ~= nil and Logic.shipLogic:GetNextReplaceSkillId(self.skillId, level, showSkillId) or self.skillId
    local name_next = Logic.shipLogic:GetPSkillName(nextShowSkillId)
    local desc_next = Logic.shipLogic:GetPSkillDesc(nextShowSkillId, level + 1, false)
    local type_next = Logic.shipLogic:GetPSkillType(nextShowSkillId)
    local icon_next = Logic.shipLogic:GetPSkillIcon(nextShowSkillId)
    UIHelper.SetImage(widgets.imgIconNext, icon_next)
    UIHelper.SetText(widgets.txtDesNext, desc_next)
    local str = UIHelper.GetLocString(160022, level + 1)
    UIHelper.SetTextColor(widgets.txtLevelNext, str, color)
    UIHelper.SetLocText(widgets.text_level_up, 910002033)
  else
    UIHelper.SetLocText(widgets.text_level_up, 910002043)
  end
  local notfull = false
  local sortMaterial = Logic.shipSkillLogic:SortSkillMaterial(level, self.skillId)
  UIHelper.CreateSubPart(widgets.item_Book, widgets.content_Book, #sortMaterial, function(index, tabPart)
    local material = sortMaterial[index]
    local typ = material[1]
    local id = material[2]
    local num = material[3]
    local numHave = Logic.bagLogic:GetBagItemNum(id)
    local icon = Logic.goodsLogic:GetIcon(id, typ)
    local name = Logic.goodsLogic:GetName(id, typ)
    local quality = Logic.goodsLogic:GetQuality(id, typ)
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[quality])
    UIHelper.SetText(tabPart.tx_name, name)
    UIHelper.SetTextColorByBool(tabPart.tx_num, numHave .. "/" .. num, 104, 105, num > numHave and not isMax)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_Book, self.btnBook, self, material)
    if num > numHave then
      notfull = true
    end
  end)
  widgets.grayLevelUp.Gray = notfull or isMax
end

function SkillLevelupPage:btnBook(sender, material)
  local typ = material[1]
  local id = material[2]
  globalNoitceManager:ShowItemInfoPage(typ, id)
end

function SkillLevelupPage:btnClose()
  UIHelper.ClosePage("SkillLevelupPage")
end

function SkillLevelupPage:btnLevelUp()
  if not self:btnLevelUpCheck() then
    return
  end
  Service.heroService:SendStudySkill({
    HeroId = self.heroId,
    SkillId = self.skillId
  })
  self:Retention()
end

function SkillLevelupPage:Retention()
  local level = Logic.shipLogic:GetHeroPSkillLv(self.heroId, self.skillId)
  local sortMaterial = Logic.shipSkillLogic:SortSkillMaterial(level, self.skillId)
  for _, material in ipairs(sortMaterial) do
    local id = material[2]
    local num = material[3]
    local dotinfo = {
      info = "ui_skill_levelup",
      skill_id = self.skillId,
      skill_level = level + 1,
      cost_num = {id, num}
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
end

function SkillLevelupPage:btnLevelUpCheck()
  if Logic.shipLogic:CheckHeroPSkillReachMax(self.heroId, self.skillId) then
    noticeManager:ShowTipById(160020)
    return false
  end
  if not Logic.shipSkillLogic:CheckMaterials(self.heroId, self.skillId, true) then
    return false
  end
  return true
end

return SkillLevelupPage
