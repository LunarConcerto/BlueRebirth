local BuildingTypeListPage = class("UI.Building.BuildingTypeListPage", LuaUIPage)
local scrollViewWidth = 1132.2
local itemWidth = 304
local itemSpacing = -8

function BuildingTypeListPage:DoInit()
end

function BuildingTypeListPage:DoOnOpen()
  self:_Refresh()
end

function BuildingTypeListPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
end

function BuildingTypeListPage:_Refresh()
  local params = self:GetParam()
  self:_ShowBuildTypeList(params.buildingList)
end

function BuildingTypeListPage:_ShowBuildTypeList(builds)
  local widgets = self:GetWidgets()
  local count = #builds
  UIHelper.CreateSubPart(widgets.obj_build, widgets.trans_build, count, function(index, tabPart)
    local data = builds[index]
    local tid = data.tid
    local cfg = configManager.GetDataById("config_buildinginfo", tid)
    local icon = Logic.buildingLogic:GetBuildIcon(tid)
    UIHelper.SetText(tabPart.tx_name, cfg.name)
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetText(tabPart.tx_desc, UIHelper.GetString(cfg.desc))
    local color = data.curCount < data.maxCount and "#1ac13a" or "#FF0000"
    UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s/%s</color>", color, data.curCount, data.maxCount))
    local errMsg = Logic.buildingLogic:CheckUpgradeCost(data.tid, 1)
    if data.curCount >= data.maxCount or errMsg ~= nil then
      tabPart.btn_build.interactable = false
    end
    local type = Logic.buildingLogic:GetBuildType(tid)
    local cost = Logic.buildingLogic:GetBuldingCostItem(type, 1)
    self:_setCostItem(cost, tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_build, self._OnClickBuild, self, data)
  end)
  if count < 4 then
    local contentWidth = self:GetContentWidth(count)
    local sizeDelta = widgets.list_root.sizeDelta
    sizeDelta.x = contentWidth
    widgets.list_root.sizeDelta = sizeDelta
  end
end

function BuildingTypeListPage:GetContentWidth(count)
  local width = itemWidth * count + (count - 1) * itemSpacing
  return width
end

function BuildingTypeListPage:GetLeftPadding(count)
  if 4 <= count then
    return 0
  end
  local leftPadding = (scrollViewWidth - itemWidth * count + (count - 1) * itemSpacing) / 2
  return leftPadding
end

function BuildingTypeListPage:_setCostItem(data, widgets)
  UIHelper.CreateSubPart(widgets.obj_good, widgets.trans_good, #data, function(index, tabPart)
    local temp = data[index]
    local icon = Logic.goodsLogic:GetIcon(temp.ConfigId, temp.Type)
    local quality = Logic.goodsLogic:GetQuality(temp.ConfigId, temp.Type)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[quality])
    local curNum = Logic.bagLogic:GetConsumeCurrNum(temp.Type, temp.ConfigId)
    UIHelper.SetImage(tabPart.img_icon, icon)
    if curNum < temp.Num then
      UIHelper.SetTextColor(tabPart.txt_num, curNum .. "/" .. temp.Num, "d72828")
    else
      UIHelper.SetText(tabPart.txt_num, curNum .. "/" .. temp.Num)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, self._OnClickItem, self, temp)
  end)
end

function BuildingTypeListPage:_OnClickBuild(go, data)
  local index = self:GetParam().index
  if not data.canBuild then
    local landCfg = configManager.GetDataById("config_building", index)
    local buildingType = landCfg.buildinggroup_id[1] - 1
    noticeManager:ShowTip(UIHelper.GetLocString(3002021, Logic.buildingLogic:GetBuildingTypeName(buildingType)))
    return
  end
  if data.curCount >= data.maxCount then
    local nextOfficeLevel = Logic.buildingLogic:GetBuildingUnlockLevel(data.tid, data.curCount)
    if 0 < nextOfficeLevel then
      noticeManager:ShowTip(UIHelper.GetLocString(3002023, nextOfficeLevel))
    else
      noticeManager:ShowTip(UIHelper.GetString(3002022))
    end
    return
  end
  local errMsg = Logic.buildingLogic:CheckUpgradeCost(data.tid, 1)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  Service.buildingService:AddBuilding(data.tid, index)
  UIHelper.ClosePage("BuildingTypeListPage")
end

function BuildingTypeListPage:_OnClickItem(go, item)
  globalNoitceManager:ShowItemInfoPage(item.Type, item.ConfigId)
end

function BuildingTypeListPage:_CloseSelf()
  UIHelper.ClosePage("BuildingTypeListPage")
end

function BuildingTypeListPage:DoOnHide()
end

function BuildingTypeListPage:DoOnClose()
end

return BuildingTypeListPage
