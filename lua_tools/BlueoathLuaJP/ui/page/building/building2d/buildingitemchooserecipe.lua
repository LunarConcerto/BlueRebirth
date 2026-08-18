local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BuildingItemChooseRecipe = class("UI.Building.Building2D.BuildingItemChooseRecipe", LuaUIPage)
local BuildingRecipes = {
  [1] = "recipe",
  [2] = "recipe_compose"
}
local FunctionTogs = {
  [1] = {
    name = 910000257,
    normalColor = "#3F5064",
    clickColor = "#3F5064"
  },
  [2] = {
    name = 3200011,
    normalColor = "#3F5064",
    clickColor = "#3F5064"
  }
}

function BuildingItemChooseRecipe:DoInit()
  self.BuildingIndex = 1
end

function BuildingItemChooseRecipe:DoOnOpen()
  self.onSelect = self:GetParam().onSelect
  local widgets = self:GetWidgets()
  self.BuildingIndex = self:GetParam().Index
  self.temFunctionPart = {}
  self.recipeTypes = Logic.buildingLogic:GetBuildingRecipes()
  self:ShowFuncTog()
end

function BuildingItemChooseRecipe:ShowFuncTog()
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.item_shengchan, widgets.trans_top, #FunctionTogs, function(index, tabPart)
    local togInfo = FunctionTogs[index]
    UIHelper.SetText(tabPart.tx_mission, UIHelper.GetString(togInfo.name))
    UIHelper.SetText(tabPart.tx_select, UIHelper.GetString(togInfo.name))
    widgets.tog_top_group:RegisterToggle(tabPart.shengchan)
    self.temFunctionPart[index] = tabPart
  end)
  widgets.tog_top_group:SetActiveToggleIndex(self.BuildingIndex - 1)
end

function BuildingItemChooseRecipe:ChangeFuncTogIndex(funIndex)
  local widgets = self:GetWidgets()
  local buildingType = self.recipeTypes[BuildingRecipes[funIndex]]
  UIHelper.CreateSubPart(widgets.obj_type, widgets.trans_type, #buildingType, function(index, tabPart)
    local recipeType = buildingType[index]
    UIHelper.SetText(tabPart.tx_name, recipeType.typename)
    tabPart.im_icon.gameObject:SetActive(false)
    widgets.tog_group:RegisterToggle(tabPart.tog_tag)
  end)
  widgets.tog_group:SetActiveToggleIndex(0)
end

function BuildingItemChooseRecipe:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_group, self, nil, self._OnTypeChanged)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tog_top_group, self, nil, self.FuncTogValuesChanged)
end

function BuildingItemChooseRecipe:FuncTogValuesChanged(index)
  self.BuildingIndex = index + 1
  self:ChangeFuncTogIndex(self.BuildingIndex)
  self:SetFunctionBtnClickColor(self.BuildingIndex)
end

function BuildingItemChooseRecipe:SetFunctionBtnClickColor(index)
  for i = 1, #self.temFunctionPart do
    local part = self.temFunctionPart[i]
    if index == i then
      part.obj_select:SetActive(true)
    else
      part.obj_select:SetActive(false)
    end
  end
end

function BuildingItemChooseRecipe:_OnTypeChanged(index)
  index = index + 1
  local recipeIds = self.recipeTypes[BuildingRecipes[self.BuildingIndex]][index].recipeIds
  self:UpdateRight(recipeIds)
end

function BuildingItemChooseRecipe:UpdateRight(recipeIds)
  local buildingTid = self:GetParam().buildingTid
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local widgets = self:GetWidgets()
  UIHelper.SetInfiniteItemParam(widgets.iil_list, widgets.obj_item, #recipeIds, function(tabParts)
    for istr, tabPart in pairs(tabParts) do
      local index = tonumber(istr)
      local configName = "config_" .. BuildingRecipes[self.BuildingIndex]
      local recipeCfg = configManager.GetDataById(configName, recipeIds[index])
      if recipeCfg.time then
        local time = time.getHoursString(recipeCfg.time)
        tabPart.obj_time:SetActive(true)
        UIHelper.SetText(tabPart.tx_time, time)
      else
        tabPart.obj_time:SetActive(false)
      end
      local item = recipeCfg.item
      local tableIndex = configManager.GetDataById("config_table_index", item[1])
      local itemCfg = configManager.GetDataById(tableIndex.file_name, item[2])
      tabPart.obj_lock:SetActive(recipeCfg.unlocklevel > buildingCfg.level)
      UIHelper.SetImage(tabPart.img_icon, itemCfg.icon)
      UIHelper.SetImage(tabPart.img_frame, QualityIcon[itemCfg.quality])
      UIHelper.SetText(tabPart.txt_name, itemCfg.name)
      if self.BuildingIndex == 2 then
        tabPart.im_diban:SetActive(true)
        UIHelper.SetText(tabPart.tx_getnum, "x" .. item[3])
      else
        tabPart.im_diban:SetActive(false)
      end
      local str = string.format(UIHelper.GetString(3001002), recipeCfg.unlocklevel)
      UIHelper.SetText(tabPart.tx_lock, str)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._OnClickItem, self, recipeCfg.id)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_lock, self._OnClickLock, self, recipeCfg.unlocklevel)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, self._OnClickIcon, self, recipeCfg.id)
      self:_OnPeiFangItem(recipeCfg, tabPart)
    end
  end)
end

function BuildingItemChooseRecipe:_OnPeiFangItem(recipeCfg, tabPart)
  local tabRecipe = {}
  if next(recipeCfg.rawmaterial1) ~= nil then
    table.insert(tabRecipe, recipeCfg.rawmaterial1)
  end
  if next(recipeCfg.rawmaterial2) ~= nil then
    table.insert(tabRecipe, recipeCfg.rawmaterial2)
  end
  if next(recipeCfg.rawmaterial3) ~= nil then
    table.insert(tabRecipe, recipeCfg.rawmaterial3)
  end
  UIHelper.CreateSubPart(tabPart.obj_pfItem, tabPart.trans_peifang, #tabRecipe, function(index, tabPart)
    local rawmaterialCfg = Logic.bagLogic:GetItemByTempateId(tabRecipe[index][1], tabRecipe[index][2])
    UIHelper.SetImage(tabPart.im_pfIicon, rawmaterialCfg.icon)
    UIHelper.SetImage(tabPart.rawmaterial, QualityIcon[rawmaterialCfg.quality])
    UIHelper.SetText(tabPart.tx_pfNum, "x" .. tabRecipe[index][3])
  end)
end

function BuildingItemChooseRecipe:_OnClickIcon(go, recipeId)
  local recipeCfg = configManager.GetDataById("config_" .. BuildingRecipes[self.BuildingIndex], recipeId)
  local item = recipeCfg.item
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(item[1], item[2]))
end

function BuildingItemChooseRecipe:_OnClickItem(go, recipeId)
  if self.onSelect then
    self.onSelect(recipeId, self.BuildingIndex)
  end
  self:_CloseSelf()
end

function BuildingItemChooseRecipe:_CloseSelf()
  UIHelper.ClosePage("BuildingItemChooseRecipe")
end

function BuildingItemChooseRecipe:_OnClickLock(go, level)
  str = string.format(UIHelper.GetString(3001002), level)
  noticeManager:ShowTip(str)
end

function BuildingItemChooseRecipe:DoOnHide()
end

function BuildingItemChooseRecipe:DoOnClose()
end

return BuildingItemChooseRecipe
