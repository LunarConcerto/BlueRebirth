local PerformPage = class("UI.Illustrate.PerformPage", LuaUIPage)
local AttrNameMap = {
  [1] = UIHelper.GetString(920000248),
  [2] = UIHelper.GetString(920000249),
  [3] = UIHelper.GetString(920000250),
  [4] = UIHelper.GetString(920000251),
  [5] = UIHelper.GetString(920000252),
  [6] = UIHelper.GetString(920000253)
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
  local ship_country = Logic.illustrateLogic:GetIllustrateCountry(illustrateId)
  local isMubar = false
  if ship_country == HeroCampType.Mubar then
    isMubar = true
  end
  local displayArr = {}
  for i, pskillId in ipairs(skillInfo) do
    local displayData = {}
    displayData.pskillId = pskillId
    displayData.name = Logic.shipLogic:GetPSkillName(pskillId)
    displayData.icon = Logic.shipLogic:GetPSkillIcon(pskillId, sm_id)
    displayData.lv = isMubar and 20 or 10
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
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenMaxPSkillData(data.pskillId, sm_id, isMubar))
    end)
  end)
end

function PerformPage:_ShowTeZhi(illustrateId)
  local sm_id = Logic.illustrateLogic:GetIllustrateTid(illustrateId)
  local widgets = self:GetWidgets()
  local charId, charLv
  local shipCharacter = configManager.GetDataById("config_ship_main", sm_id).character
  local charactermaxlevel = configManager.GetDataById("config_ship_main", sm_id).charactermaxlevel
  local chars, charLvs = Logic.shipLogic:GetHeroCharcater(sm_id)
  UIHelper.CreateSubPart(widgets.obj_teZhi, widgets.trans_teZhi, #shipCharacter, function(index, tabPart)
    local characterId = shipCharacter[index]
    local data = configManager.GetDataById("config_character", characterId)
    local descList = Logic.buildingLogic:GetCharacterAdditionStr(characterId, charactermaxlevel[index][2])
    local desc = string.format(UIHelper.GetString(descList[1].strId), descList[1].value)
    UIHelper.SetText(tabPart.tx_title, data.name)
    charId, charLv = chars[index], charLvs[index]
    local str = desc .. "("
    local mimaLv = Logic.shipLogic:GetHeroCharcaterMaxLevel(sm_id)
    for i = mimaLv[index][1], mimaLv[index][2] do
      local desc1 = Logic.buildingLogic:GetCharacterAdditionStr(characterId, i)
      local value = desc1[1].value
      if i <= charLv then
        if i == mimaLv[index][2] then
          str = str .. "%)"
        else
          str = str .. value .. "%/"
        end
      elseif i == mimaLv[index][2] then
        str = str .. value .. "%)"
      else
        str = str .. value .. "%/"
      end
    end
    UIHelper.SetText(tabPart.tx_desc, str)
  end)
end

function PerformPage:DoOnHide()
  self.m_tabWidgets.tween_PerformPage:Stop()
end

function PerformPage:DoOnClose()
end

return PerformPage
