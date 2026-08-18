local ActivitySceneLoginPage = class("UI.Activity.ActivitySceneLoginPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local rewardFlag = 1
local DayNumImage = {
  810030001,
  810030002,
  810030003,
  810030004,
  810030005,
  810030006,
  810030007
}

function ActivitySceneLoginPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function ActivitySceneLoginPage:RegisterAllEvent()
end

function ActivitySceneLoginPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local curTime = time.getSvrTime()
  PlayerPrefs.SetInt(uid .. "ActivitySceneLogin", curTime)
  eventManager:SendEvent(LuaEvent.OpenActivitySceneLoginPage)
  self:ShowPage()
end

function ActivitySceneLoginPage:ShowPage()
  local widgets = self.tab_Widgets
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(actData.period, actData.p1)
  UIHelper.SetText(widgets.tx_time, time.formatTimeToMDHM(startTime) .. "-" .. time.formatTimeToMDHM(endTime))
  local allItem = actData.p2
  local ownedItem = Data.interactionItemData:GetClickedChildSignGift()
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_content, #allItem, function(index, tabParts)
    if allItem[index] == nil then
      return
    end
    local itemConfig = configManager.GetDataById("config_interaction_item", allItem[index])
    local rewardConfig = configManager.GetDataById("config_rewards", itemConfig.reward)
    local data = rewardConfig.rewards[rewardFlag]
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    local dateInfo = configManager.GetDataById("config_language", DayNumImage[index]).content
    UIHelper.SetImage(tabParts.im_icon, itemInfo.icon)
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabParts.tx_num, data[3])
    UIHelper.SetText(tabParts.tx_date, dateInfo)
    local owned = ownedItem[allItem[index]] ~= nil
    tabParts.im_get.gameObject:SetActive(owned)
    tabParts.im_missing.gameObject:SetActive(not owned)
    UGUIEventListener.AddButtonOnClick(tabParts.btn_item, function()
      if owned then
        self:_ShowItemInfo(data)
      end
    end)
  end)
  local collectedAll = true
  for i, v in pairs(allItem) do
    if not ownedItem[v] then
      collectedAll = false
    end
  end
  widgets.obj_letters:SetActive(not collectedAll)
end

function ActivitySceneLoginPage:_ShowItemInfo(award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award[1], award[2]))
end

function ActivitySceneLoginPage:DoOnClose()
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
end

return ActivitySceneLoginPage
