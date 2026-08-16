local BuildingItemChooseRecipe = class("UI.Building.Building2D.BuildingItemChooseRecipe", LuaUIPage)

function BuildingItemChooseRecipe:DoInit()
end

function BuildingItemChooseRecipe:DoOnOpen()
  self.onSelect = self:GetParam().onSelect
  local widgets = self:GetWidgets()
  self.recipeTypes = Logic.buildingLogic:GetBuildingRecipes()
  UIHelper.CreateSubPart(widgets.obj_type, widgets.trans_type, #self.recipeTypes, function(index, tabPart)
    local recipeType = self.recipeTypes[index]
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
end

function BuildingItemChooseRecipe:_OnTypeChanged(index)
  index = index + 1
  local recipeIds = self.recipeTypes[index].recipeIds
  self:UpdateRight(recipeIds)
end

function BuildingItemChooseRecipe:UpdateRight(recipeIds)
  local buildingTid = self:GetParam().buildingTid
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingTid)
  local widgets = self:GetWidgets()
  UIHelper.SetInfiniteItemParam(widgets.iil_list, widgets.obj_item, #recipeIds, function(tabParts)
    for istr, tabPart in pairs(tabParts) do
      local index = tonumber(istr)
      local recipeCfg = configManager.GetDataById("config_recipe", recipeIds[index])
      local time = time.getHoursString(recipeCfg.time)
      local item = recipeCfg.item
      local tableIndex = configManager.GetDataById("config_table_index", item[1])
      local itemCfg = configManager.GetDataById(tableIndex.file_name, item[2])
      tabPart.obj_lock:SetActive(recipeCfg.unlocklevel > buildingCfg.level)
      UIHelper.SetImage(tabPart.img_icon, itemCfg.icon)
      UIHelper.SetImage(tabPart.img_frame, QualityIcon[itemCfg.quality])
      UIHelper.SetText(tabPart.txt_name, itemCfg.name)
      UIHelper.SetText(tabPart.tx_time, time)
      local str = string.format(UIHelper.GetString(3001002), recipeCfg.unlocklevel)
      UIHelper.SetText(tabPart.tx_lock, str)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._OnClickItem, self, recipeCfg.id)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_lock, self._OnClickLock, self, recipeCfg.unlocklevel)
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

function BuildingItemChooseRecipe:_OnClickItem(go, recipeId)
  if self.onSelect then
    self.onSelect(recipeId)
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
