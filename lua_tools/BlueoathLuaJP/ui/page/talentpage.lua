local TalentPage = class("UI.TalentPage", LuaUIPage)

function TalentPage:DoInit()
  self.selectType = 1
  self.selectTalentTab = {}
  self.selectTalent = 1
end

function TalentPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_unlock, self.OnBtnUnlockClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_levelUp, self.OnBtnLvUpClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bg, self.OnBtnBgClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self.OnBtnHelpClick, self)
  self:RegisterEvent(LuaEvent.UpdateTalentChange, self.UpdateTalentChange, self)
  self:RegisterEvent(LuaEvent.UpdateTalentSuccess, self.UpdateTalentSuccess, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.UpdateTalentCost, self)
end

function TalentPage:DoOnOpen()
  self.tab_Widgets.tween_talentInfo:ResetToBeginning()
  self:OpenTopPage("TalentPage", 1, UIHelper.GetString(3703006), self, false)
  self:CreateTalentTypeTogs()
end

function TalentPage:DoOnHide()
  self.selectTalent = 0
  self:ResetPageData()
end

function TalentPage:DoOnClose()
  self.selectTalent = 0
end

function TalentPage:ResetPageData()
  self.tab_Widgets.tween_talentInfo:Play(false)
end

function TalentPage:CreateTalentTypeTogs()
  self.tab_Widgets.group_typeTog:ClearToggles()
  local talentMainCfgs = configManager.GetData("config_talentmain")
  UIHelper.CreateSubPart(self.tab_Widgets.obj_typeTog, self.tab_Widgets.trans_typeTog, #talentMainCfgs, function(index, uiPart)
    local cfg = talentMainCfgs[index]
    UIHelper.SetText(uiPart.txt_type, cfg.name)
    UIHelper.SetText(uiPart.txt_check, cfg.name)
    self.tab_Widgets.group_typeTog:RegisterToggle(uiPart.tog_type)
    if index == self.selectType then
      uiPart.tog_type.isOn = true
    end
    if #cfg.talentlist <= 0 then
      self.tab_Widgets.group_typeTog:ResigterToggleUnActive(index - 1, function()
        noticeManager:OpenTipPage(self, 3703007)
      end)
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_typeTog, self, "", self.SwitchTypeTogs)
  self.tab_Widgets.group_typeTog:SetActiveToggleIndex(self.selectType - 1)
end

function TalentPage:SwitchTypeTogs(index)
  local index = index + 1
  self.selectType = index
  self.selectTalent = 1
  self:OnBtnBgClick()
  self:CreateSkillTalent()
end

function TalentPage:CreateSkillTalent()
  local talentMainCfg = configManager.GetDataById("config_talentmain", self.selectType)
  if talentMainCfg.background ~= "" then
    UIHelper.SetImage(self.tab_Widgets.img_skillBg, talentMainCfg.background)
  end
  self.selectTalentTab = {}
  self.tab_Widgets.group_skillTog:ClearToggles()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_skillItem, self.tab_Widgets.trans_skillTog, #talentMainCfg.talentlist, function(index, uiPart)
    local mainId = talentMainCfg.talentlist[index]
    local curId = Data.talentData:GetCurSubTalentId(mainId)
    local curTalentData = Data.talentData:GetCurTalentBySubTalentId(curId)
    self.selectTalentTab[index] = curId
    local talentCfg = configManager.GetDataById("config_talent", curId)
    uiPart.tog_skill.gameObject.transform.localPosition = Vector3.New(talentCfg.positioninfo[1], talentCfg.positioninfo[2], 0)
    UIHelper.SetImage(uiPart.img_max, talentCfg.iconmax)
    uiPart.img_max.gameObject:SetActive(0 >= talentCfg.nexttalent and 0 < curTalentData.IsOperate)
    if not curTalentData or 0 < curTalentData.IsOperate then
      UIHelper.SetImage(uiPart.img_normal, talentCfg.iconcheck)
    else
      UIHelper.SetImage(uiPart.img_normal, talentCfg.icon)
    end
    self.tab_Widgets.group_skillTog:RegisterToggle(uiPart.tog_skill)
    if index == self.selectTalent then
      uiPart.tog_skill:Set(true)
    else
      uiPart.tog_skill:Set(false)
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_skillTog, self, "", self.SwitchTalentTogs)
  self.tab_Widgets.group_skillTog:SetActiveToggleIndex(self.selectTalent - 1)
end

function TalentPage:SwitchTalentTogs(index)
  local index = index + 1
  self.selectTalent = index
  self:ShowSelectTalentData()
  self.tab_Widgets.tween_talentInfo:Play(true)
end

function TalentPage:ShowSelectTalentData()
  local curId = self.selectTalentTab[self.selectTalent]
  local talentCfg = configManager.GetDataById("config_talent", curId)
  UIHelper.SetImage(self.tab_Widgets.img_talentIcon, talentCfg.talenticon)
  UIHelper.SetText(self.tab_Widgets.txt_skillName, talentCfg.name)
  local maxLv = Logic.talentLogic:GetMainTalentMaxLv(talentCfg.belongtalent)
  if talentCfg.belongtalent == 0 then
    maxLv = Logic.talentLogic:GetMainTalentMaxLv(talentCfg.id)
  end
  local curLv = Logic.talentLogic:GetSubTalentLv(curId)
  local lvStr = curLv .. "/" .. maxLv
  UIHelper.SetText(self.tab_Widgets.txt_skillLv, lvStr)
  UIHelper.SetText(self.tab_Widgets.txt_skillDes, talentCfg.desc)
  self.tab_Widgets.btn_unlock.gameObject:SetActive(false)
  self.tab_Widgets.btn_levelUp.gameObject:SetActive(true)
  local nextTalentData = Data.talentData:GetCurTalentBySubTalentId(curId)
  local precondition = talentCfg.precondition
  local isMaxLv = false
  local costItems = {}
  if nextTalentData then
    if nextTalentData.IsOperate == 0 then
      self.tab_Widgets.btn_unlock.gameObject:SetActive(true)
      self.tab_Widgets.btn_levelUp.gameObject:SetActive(false)
      self.tab_Widgets.obj_imgArrow:SetActive(false)
      UIHelper.SetText(self.tab_Widgets.txt_nextDes, "")
      costItems = talentCfg.levelup
    else
      UIHelper.CreateSubPart(self.tab_Widgets.obj_costItem, self.tab_Widgets.trans_costList, 0, nil)
      self.tab_Widgets.btn_levelUp.gameObject:SetActive(false)
      self.tab_Widgets.obj_imgArrow:SetActive(false)
      UIHelper.SetText(self.tab_Widgets.txt_nextDes, "")
      precondition = {}
      isMaxLv = true
      self.tab_Widgets.obj_textTitle2:SetActive(false)
      UIHelper.SetText(self.tab_Widgets.txt_condition, "")
    end
  else
    nextTalentData = Data.talentData:GetCurTalentBySubTalentId(talentCfg.nexttalent)
    self.tab_Widgets.obj_imgArrow:SetActive(true)
    local nextTalentCfg = configManager.GetDataById("config_talent", talentCfg.nexttalent)
    UIHelper.SetText(self.tab_Widgets.txt_nextDes, nextTalentCfg.desc)
    precondition = nextTalentCfg.precondition
    costItems = nextTalentCfg.levelup
  end
  self.tab_Widgets.obj_max:SetActive(isMaxLv)
  if not isMaxLv then
    local unlockStr = ""
    local unColor = configManager.GetDataById("config_parameter", 529)
    for _, conditionId in pairs(precondition) do
      local conditionCfg = configManager.GetDataById("config_talentcondition", conditionId)
      if unlockStr ~= "" then
        unlockStr = unlockStr .. "\n"
      end
      local isActive = self:CheckPreCondition(conditionId, nextTalentData.PreCondition)
      if isActive then
        unlockStr = unlockStr .. conditionCfg.desc
      else
        unlockStr = unlockStr .. string.format("<color=#%s>%s</color>", unColor.arrValue[1], conditionCfg.desc)
      end
    end
    self.tab_Widgets.obj_textTitle2:SetActive(unlockStr ~= "")
    UIHelper.SetText(self.tab_Widgets.txt_condition, unlockStr)
    UIHelper.CreateSubPart(self.tab_Widgets.obj_costItem, self.tab_Widgets.trans_costList, #costItems, function(index, uiPart)
      local costData = costItems[index]
      local itemType = costData[1]
      local itemId = costData[2]
      local icon = Logic.goodsLogic:GetIcon(itemId, itemType)
      local quality = Logic.goodsLogic:GetQuality(itemId, itemType)
      local str = ""
      local data = {type = itemType, id = itemId}
      local _, ownNum = Logic.itemLogic:GetItemOwnCount(data)
      if itemType == GoodsType.CURRENCY then
        str = ownNum >= costData[3] and costData[3] or "<color=#FF1E1E>" .. costData[3] .. "</color>"
      else
        str = ownNum >= costData[3] and ownNum .. "/" .. costData[3] or "<color=#FF1E1E>" .. ownNum .. "</color>/" .. costData[3]
      end
      UIHelper.SetImage(uiPart.img_icon, icon)
      UIHelper.SetImageByQuality(uiPart.img_quality, quality)
      UIHelper.SetText(uiPart.txt_num, str)
      
      local function clickFunc()
        Logic.itemLogic:ShowItemInfo(itemType, itemId, true)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart.btn_Item, clickFunc)
    end)
  end
end

function TalentPage:UpdateTalentChange()
  self:CreateSkillTalent()
end

function TalentPage:UpdateTalentSuccess(param)
  local talentId = param.TalentId
  local cfg = configManager.GetDataById("config_talent", talentId)
  if cfg.specialtalent == 1 then
    UIHelper.OpenPage("TalentOpenPage", {talentId = talentId})
  elseif param.Type == 0 then
    noticeManager:ShowTipById(3703003)
  else
    noticeManager:ShowTipById(3703002)
  end
end

function TalentPage:OnBtnUnlockClick()
  local curId = self.selectTalentTab[self.selectTalent]
  if not self:CheckLvUpCondition(curId) then
    noticeManager:ShowTipById(3703004)
    return
  end
  if not self:CheckLvUpCost(curId) then
    noticeManager:ShowTipById(3703001)
    return
  end
  Service.talentService:SendUnLockTalent(curId)
end

function TalentPage:OnBtnLvUpClick()
  local curId = self.selectTalentTab[self.selectTalent]
  local talentCfg = configManager.GetDataById("config_talent", curId)
  if talentCfg.nexttalent == 0 then
    return
  end
  if not self:CheckLvUpCondition(talentCfg.nexttalent) then
    noticeManager:ShowTipById(3703005)
    return
  end
  if not self:CheckLvUpCost(talentCfg.nexttalent) then
    noticeManager:ShowTipById(3703001)
    return
  end
  Service.talentService:SendUpgradeTalent(talentCfg.nexttalent)
end

function TalentPage:OnBtnBgClick()
  self.tab_Widgets.tween_talentInfo:Play(false)
end

function TalentPage:OnBtnHelpClick()
  UIHelper.OpenPage("HelpPage", {content = 3703008})
end

function TalentPage:CheckLvUpCost(talentId)
  local talentCfg = configManager.GetDataById("config_talent", talentId)
  for _, v in pairs(talentCfg.levelup) do
    local data = {
      type = v[1],
      id = v[2]
    }
    local _, value = Logic.itemLogic:GetItemOwnCount(data)
    if value < v[3] then
      return false
    end
  end
  return true
end

function TalentPage:CheckLvUpCondition(talentId)
  local talentCfg = configManager.GetDataById("config_talent", talentId)
  local talentData = Data.talentData:GetCurTalentBySubTalentId(talentId)
  if talentData == nil then
    return false
  end
  for _, v in pairs(talentCfg.precondition) do
    if not self:CheckPreCondition(v, talentData.PreCondition) then
      return false
    end
  end
  return true
end

function TalentPage:CheckPreCondition(id, data)
  for _, v in pairs(data) do
    if v == id then
      return true
    end
  end
  return false
end

function TalentPage:UpdateTalentCost()
  self:ShowSelectTalentData()
end

return TalentPage
