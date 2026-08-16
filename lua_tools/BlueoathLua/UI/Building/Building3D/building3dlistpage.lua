local Building3DListPage = class("UI.Building.Building3D.Building3DListPage", LuaUIPage)

function Building3DListPage:DoInit()
end

function Building3DListPage:DoOnOpen()
  self:_Refresh()
end

function Building3DListPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
end

function Building3DListPage:_Refresh()
  local builds = self:GetParam()
  self:_ShowBuild3DList(builds)
end

function Building3DListPage:_ShowBuild3DList(builds)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_build, widgets.trans_build, #builds, function(index, tabPart)
    local data = builds[index]
    local name = Logic.buildingLogic:GetBuildName(data.Tid)
    local icon = Logic.buildingLogic:GetBuildIcon(data.Tid)
    UIHelper.SetText(tabPart.tx_name, name)
    UIHelper.SetText(tabPart.tx_level, "LV." .. data.Level)
    UIHelper.SetImage(tabPart.im_icon, icon)
    local max = Logic.buildingLogic:GetOneBuildingHeroMax(data.Tid)
    UIHelper.SetText(tabPart.tx_girlNum, #data.HeroList .. "/" .. max)
    local cur = Logic.buildingLogic:GetRewardById(data.Id)
    local max = Logic.buildingLogic:GetRewardMaxByTid(data.Tid)
    tabPart.obj_goods:SetActive(cur ~= nil)
    if cur ~= nil then
      local progress, progressStr
      local itemIcon = Logic.goodsLogic:GetIcon(cur.ConfigId, cur.Type)
      progressStr = cur.Num .. "/" .. max.Num
      progress = cur.Num / max.Num
      UIHelper.SetText(tabPart.tx_num, progressStr)
      UIHelper.SetImage(tabPart.im_itemIcon, itemIcon)
      tabPart.Slider.value = progress
    end
    UGUIEventListener.AddButtonOnClick(tabPart.im_bg, self._OnClickBuild, self, data)
  end)
end

function Building3DListPage:_OnClickBuild(go, param)
  eventManager:SendEvent(LuaEvent.BUILDING_ChangeBuildItem, param)
  self:_CloseSelf()
end

function Building3DListPage:_CloseSelf()
  UIHelper.ClosePage("Building3DListPage")
end

function Building3DListPage:DoOnHide()
end

function Building3DListPage:DoOnClose()
end

return Building3DListPage
