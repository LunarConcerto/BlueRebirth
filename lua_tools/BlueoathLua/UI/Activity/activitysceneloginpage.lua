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
local fakeIndex = 1

function ActivitySceneLoginPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function ActivitySceneLoginPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fin_letter, self._ClickFinLetter, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_fin_close, self._ClickFinLetterClose, self)
end

function ActivitySceneLoginPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  local userInfo = Data.userData:GetUserData()
  self.uid = tostring(userInfo.Uid)
  local curTime = time.getSvrTime()
  PlayerPrefs.SetInt(self.uid .. "ActivitySceneLogin", curTime)
  eventManager:SendEvent(LuaEvent.OpenActivitySceneLoginPage)
  self.m_isFake = PlayerPrefs.GetBool(self.uid .. "ActivitySceneLoginFake", true)
  self:ShowPage()
end

function ActivitySceneLoginPage:ShowPage()
  local widgets = self.tab_Widgets
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local allItem = actData.p1
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
    UIHelper.SetText(tabParts.tx_anum, data[3])
    UIHelper.SetText(tabParts.tx_bnum, dateInfo)
    local owned = ownedItem[allItem[index]] ~= nil
    if self.m_isFake then
      tabParts.im_get.gameObject:SetActive(false)
      tabParts.im_missing.gameObject:SetActive(false)
    else
      tabParts.im_get.gameObject:SetActive(owned)
      tabParts.im_missing.gameObject:SetActive(not owned)
    end
    tabParts.im_bg_available.gameObject:SetActive(self.m_isFake and index == fakeIndex)
    UGUIEventListener.AddButtonOnClick(tabParts.im_missing, function()
      self:_ShowItemInfo(data[1], data[2])
    end)
    UGUIEventListener.AddButtonOnClick(tabParts.btn_item, function()
      if self.m_isFake and index == fakeIndex then
        self:_ClickTrick()
      else
        self:_ShowItemInfo(data[1], data[2])
      end
    end)
  end)
  self:_ShowReceivedProgress()
  self:_ShowFinState()
end

function ActivitySceneLoginPage:_ShowReceivedProgress()
  local widgets = self.tab_Widgets
  local allItem = configManager.GetDataById("config_activity", self.mActivityId).p1
  local ownedItem = Data.interactionItemData:GetClickedChildSignGift()
  local canGetList = {}
  for i, v in pairs(allItem) do
    local itemPeriodId = configManager.GetDataById("config_interaction_item", v).item_display_period
    local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(itemPeriodId)
    local now = time.getSvrTime()
    if startTime < now then
      table.insert(canGetList, v)
    end
  end
  local getList = {}
  for i, v in pairs(ownedItem) do
    table.insert(getList, v)
  end
  local Get = #getList
  local CanGet = #canGetList
  local str = Get .. "/" .. CanGet
  UIHelper.SetText(widgets.tx_count, tostring(str))
end

function ActivitySceneLoginPage:_ShowFinState()
  local widgets = self.tab_Widgets
  local allItem = configManager.GetDataById("config_activity", self.mActivityId).p1
  local ownedItem = Data.interactionItemData:GetClickedChildSignGift()
  local collectedAll = true
  for i, v in pairs(allItem) do
    if not ownedItem[v] then
      collectedAll = false
    end
  end
  if self.m_isFake then
    widgets.obj_letters:SetActive(false)
  else
    widgets.obj_letters:SetActive(not collectedAll)
  end
  widgets.btn_fin_letter.gameObject:SetActive(collectedAll)
end

function ActivitySceneLoginPage:_ClickFinLetter()
  self.tab_Widgets.obj_finish_letter.gameObject:SetActive(true)
end

function ActivitySceneLoginPage:_ClickFinLetterClose()
  self.tab_Widgets.obj_finish_letter.gameObject:SetActive(false)
end

function ActivitySceneLoginPage:_ClickTrick()
  self.m_isFake = false
  self:ShowPage()
  PlayerPrefs.SetBool(self.uid .. "ActivitySceneLoginFake", false)
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
end

function ActivitySceneLoginPage:_ShowItemInfo(typ, id)
  if typ == GoodsType.EQUIP or Typ == GoodsType.EQUIP_ENHANCE_ITEM then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = id,
      showEquipType = ShowEquipType.Simple
    })
  else
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(typ, id))
  end
end

function ActivitySceneLoginPage:DoOnClose()
  if self.m_isFake == false then
    eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
  end
end

return ActivitySceneLoginPage
