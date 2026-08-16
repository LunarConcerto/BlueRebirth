local ChristmasDecoratePage = class("UI.Activity.Christmas.ChristmasDecoratePage", LuaUIPage)

function ChristmasDecoratePage:DoInit()
end

function ChristmasDecoratePage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.mActivityId = params.activityId
  self:ShowPage()
end

function ChristmasDecoratePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self._AddIntreactionItemRef, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._AddIntreactionItemRef, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_go, self._ClickGoBattle, self)
end

function ChristmasDecoratePage:ShowPage()
  local widgets = self.tab_Widgets
  if self.mActivityId == nil then
    logError("\230\180\187\229\138\168\230\156\170\229\188\128\229\144\175\239\188\129")
  end
  local configData = configManager.GetDataById("config_activity", self.mActivityId)
  local currency = configData.p3[1]
  local startTime, endTime = PeriodManager:GetPeriodTime(configData.period, configData.p1)
  UIHelper.SetText(self.tab_Widgets.tx_time, time.formatTimeToMDHM(startTime) .. "-" .. time.formatTimeToMDHM(endTime))
  self.tab_Widgets.btn_go.gameObject:SetActive(configData.period > 0 and PeriodManager:IsInPeriodArea(configData.period, configData.p1))
  local myCurSnowCion = Data.bagData:GetItemNum(currency)
  UIHelper.SetText(widgets.tx_snowNum, myCurSnowCion)
  local allChristmasFurniture = configData.p4
  local ownedChristmasFurniture = Data.interactionItemData:GetInteractionBagItemData()
  UIHelper.CreateSubPart(widgets.im_item, widgets.rect_content, #allChristmasFurniture, function(index, tabParts)
    if allChristmasFurniture[index] == nil then
      logError("can not be nil", allChristmasFurniture, index)
      return
    end
    local furnitureInfo = configData.p4[index]
    local bagItemId = furnitureInfo[FurnitureActivityTable.furnitureId]
    local bagItemConfig = configManager.GetDataById("config_interaction_item_bag", bagItemId)
    local furnitureItemConfig = configManager.GetDataById("config_interaction_item", bagItemConfig.interactionitem)
    UIHelper.SetImage(tabParts.im_item, furnitureItemConfig.interaction_item_pic)
    UIHelper.SetText(tabParts.tx_num, furnitureInfo[FurnitureActivityTable.furnitureCost])
    local isGot = ownedChristmasFurniture[bagItemId] ~= nil
    tabParts.im_black:SetActive(isGot)
    UGUIEventListener.AddButtonOnClick(tabParts.btn_item, function()
      if not isGot then
        UIHelper.OpenPage("FurnitureInfoPage", {
          teamId = index,
          actId = self.mActivityId
        })
      end
    end)
  end)
end

function ChristmasDecoratePage:_AddIntreactionItemRef()
  self:ShowPage()
end

function ChristmasDecoratePage:_ClickGoBattle()
  local configData = configManager.GetDataById("config_activity", self.mActivityId)
  local Act_JumpToFunc = configData.p6[1]
  moduleManager:JumpToFunc(Act_JumpToFunc)
end

function ChristmasDecoratePage:DoOnHide()
end

function ChristmasDecoratePage:DoOnClose()
end

return ChristmasDecoratePage
