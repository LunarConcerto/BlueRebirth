local PerformPage = class("UI.Illustrate.PerformPage", LuaUIPage)
local AttrNameMap = {
  [1] = "\232\128\144\228\185\133",
  [2] = "\233\163\158\230\156\186",
  [3] = "\230\156\186\229\138\168",
  [4] = "\233\155\183\229\135\187",
  [5] = "\231\129\171\231\130\174",
  [6] = "\233\152\178\231\169\186"
}

function PerformPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function PerformPage:DoOnOpen()
  local illustrateId = self:GetParam()
  self:_ShowPerform(illustrateId)
end

function PerformPage:_ShowPerform(illustrateId)
  self:_ShowPerformInfo(illustrateId)
  self:_ShowSkill(illustrateId)
  self:_ShowTeZhi(illustrateId)
end

local factorScaleMap = {
  [1] = 1,
  [2] = 1.76,
  [3] = 2.5,
  [4] = 3.2,
  [5] = 3.71
}

function PerformPage:_ShowPerformInfo(illustrateId)
  local radarInfo = Logic.illustrateLogic:GetIllustrateAttr(illustrateId)
  local widgets = self:GetWidgets()
  local aArg = {}
  for i, v in pairs(radarInfo) do
    UIHelper.SetText(widgets["tx_attr" .. i], AttrNameMap[i])
    UIHelper.SetText(widgets["tx_level" .. i], v.level)
    aArg[i] = v.id
  end
  aArg = self:_GetScaleByFactor(aArg)
  widgets.rader_ship.gameObject:SetActive(false)
  widgets.rader_ship:SetFactor(aArg[1], aArg[2], aArg[3], aArg[4], aArg[5], aArg[6])
  widgets.rader_ship.gameObject:SetActive(true)
end

function PerformPage:_GetScaleByFactor(factorArr)
  local res = {}
  for i, v in pairs(factorArr) do
    res[i] = factorScaleMap[v]
  end
  return res
end

function PerformPage:_ShowSkill(illustrateId)
  local widgets = self:GetWidgets()
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  local skillInfo = Logic.illustrateLogic:GetShipSkillByIllustrateId(illustrateId)
  local displayArr = {}
  for i, pskillId in ipairs(skillInfo) do
    local displayData = {}
    displayData.pskillId = pskillId
    displayData.name = Logic.shipLogic:GetPSkillName(pskillId)
    displayData.icon = Logic.shipLogic:GetPSkillIcon(pskillId, sm_id)
    displayData.lv = 10
    displayData.desc = Logic.shipLogic:GetPSkillDesc(pskillId, displayData.lv)
    displayData.type = Logic.shipLogic:GetPSkillType(pskillId)
    local bUnlock, msg = true, ""
    displayData.lock, displayData.lockInfo = not bUnlock, msg
    displayData.empty = false
    displayArr[i] = displayData
  end
  UIHelper.CreateSubPart(widgets.obj_pskillItem, widgets.trans_pskillGrid, #displayArr, function(index, tabPart)
    local data = displayArr[index]
    UIHelper.SetTextColor(tabPart.txt_name, data.name, TalentColor[data.type])
    UIHelper.SetTextColor(tabPart.txt_lv, "Level:  " .. math.tointeger(data.lv), TalentColor[data.type])
    UIHelper.SetImage(tabPart.img_icon, data.icon)
    tabPart.obj_lock:SetActive(data.lock)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_click, function()
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenMaxPSkillData(data.pskillId, sm_id))
    end)
  end)
end

function PerformPage:_ShowTeZhi(illustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  local widgets = self:GetWidgets()
  local shipCharacter = configManager.GetDataById("config_ship_main", sm_id).character
  local charactermaxlevel = configManager.GetDataById("config_ship_main", sm_id).charactermaxlevel
  UIHelper.CreateSubPart(widgets.obj_teZhi, widgets.trans_teZhi, #shipCharacter, function(index, tabPart)
    local characterId = shipCharacter[index]
    local data = configManager.GetDataById("config_character", characterId)
    local descList = Logic.buildingLogic:GetCharacterAdditionStr(characterId, charactermaxlevel[index][2])
    local desc = string.format(UIHelper.GetString(descList[1].strId), descList[1].value)
    UIHelper.SetText(tabPart.tx_title, data.name)
    UIHelper.SetText(tabPart.tx_desc, desc)
  end)
end

function PerformPage:DoOnHide()
  self.m_tabWidgets.tween_PerformPage:Stop()
end

function PerformPage:DoOnClose()
end

return PerformPage
