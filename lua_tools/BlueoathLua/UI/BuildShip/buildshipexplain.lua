local BuildShipExplain = class("UI.BuildShip.BuildShipExplain")
local IndexTab = {
  4,
  3,
  2,
  1
}

function BuildShipExplain:Init(parent)
  self.tab_Widgets = parent.tab_Widgets
  self.parent = parent
  self.dropTab = {}
  self.timer = nil
end

function BuildShipExplain:SetExplainInfo(buildConfig)
  local titleIdTab = buildConfig.helpinfo_title
  local explainInfo = Logic.buildShipLogic:GetDisplayInfo(buildConfig)
  self.tab_Widgets.obj_upDrop:SetActive(explainInfo.TimeLimitUp ~= nil)
  self.tab_Widgets.obj_normalDrop:SetActive(explainInfo.DropInfo ~= nil)
  self.tab_Widgets.obj_addition:SetActive(explainInfo.Addition ~= nil)
  if explainInfo.TimeLimitUp then
    self.tab_Widgets.txt_upTitle.text = UIHelper.GetString(titleIdTab[1])
    UIHelper.CreateSubPart(self.tab_Widgets.obj_upItem, self.tab_Widgets.trans_up, #explainInfo.TimeLimitUp, function(index, tabPart)
      local info = explainInfo.TimeLimitUp[index]
      UIHelper.SetTextColor(tabPart.txt_value, info.value, ShipQualityColor[IndexTab[index]])
      UIHelper.SetTextColor(tabPart.txt_title, info.title, ShipQualityColor[IndexTab[index]])
      UIHelper.SetText(tabPart.txt_name, info.dropNameStr)
    end)
  end
  if explainInfo.DropInfo then
    self.tab_Widgets.txt_noramlTitle.text = UIHelper.GetString(titleIdTab[2])
    UIHelper.CreateSubPart(self.tab_Widgets.obj_normalItem, self.tab_Widgets.trans_normal, #explainInfo.DropInfo, function(index, tabPart)
      local info = explainInfo.DropInfo[index]
      UIHelper.SetTextColor(tabPart.txt_value, info.value, ShipQualityColor[IndexTab[index]])
      UIHelper.SetTextColor(tabPart.txt_title, info.title, ShipQualityColor[IndexTab[index]])
      local str = self:GetDropNameStr(info.dropNameTab)
      UIHelper.SetText(tabPart.txt_name, str)
    end)
  end
  if explainInfo.Addition then
    self.tab_Widgets.txt_addTitle.text = UIHelper.GetString(titleIdTab[3])
    self.tab_Widgets.txt_addDesc.text = explainInfo.Addition
  end
  self.timer = self.parent:CreateTimer(function()
    self.tab_Widgets.obj_helpContent:SetActive(false)
    self.tab_Widgets.obj_helpContent:SetActive(true)
  end, 0, -1)
  self.parent:StartTimer(self.timer)
end

function BuildShipExplain:GetDropNameStr(dropNames)
  local str = ""
  local nameList = {}
  local types = {}
  local typeCount = 0
  for i, namePair in ipairs(dropNames) do
    local name = namePair.name
    local tname = namePair.tname
    nameList[tname] = nameList[tname] or {}
    table.insert(nameList[tname], name)
    if not types[tname] then
      types[tname] = true
      typeCount = typeCount + 1
    end
  end
  for tname, names in pairs(nameList) do
    local typeStr = tname .. "\239\188\154"
    local count = #names
    for i, name in ipairs(names) do
      if i == count then
        typeStr = typeStr .. name
      else
        typeStr = typeStr .. name .. "/"
      end
    end
    if typeCount == 1 then
      str = str .. typeStr
    else
      str = str .. typeStr .. "\n"
    end
    typeCount = typeCount - 1
  end
  return str
end

function BuildShipExplain:CloseHelp()
  self.tab_Widgets.scroll_help.verticalNormalizedPosition = 1
  if self.timer ~= nil then
    self.parent:StopTimer(self.timer)
    self.timer = nil
  end
end

return BuildShipExplain
