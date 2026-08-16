local ActivityPage = class("UI.Activity.ActivityPage", LuaUIPage)
local activityLogic = Logic.activityLogic

function ActivityPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.openID = nil
end

function ActivityPage:RegisterAllEvent()
end

function ActivityPage:DoOnOpen()
  local params = self:GetParam() or {}
  local activityId = params.activityId
  local showType = params.showType or 0
  self.custom = params.custom
  self.jumpParam = params.jumpParam
  local gotoParam = params.GotoParam
  if gotoParam ~= nil and 0 < #gotoParam then
    activityId = gotoParam[1]
  end
  if activityId == nil and params.showType == nil then
    activityId = Data.activityData:GetTag()
  end
  if activityId ~= nil and 0 < activityId then
    local cfg = configManager.GetDataById("config_activity", activityId)
    showType = cfg.show_type
  end
  self:OpenTopPage("ActivityPage", 1, "\230\180\187\229\138\168", self, true)
  self:_IsOpenNewPlayer(showType)
  if self.activityInfo == nil or #self.activityInfo == 0 then
    noticeManager:ShowTipById(270022)
    return
  end
  local tagTmp = activityId or Data.activityData:GetTag()
  local tag = self:GetIndex(tagTmp) - 1
  if #self.activityInfo < tag + 1 then
    tag = 0
  end
  local config = self.activityInfo[tag + 1]
  local para = {}
  self:SaveNewParam(para)
  UIHelper.OpenPage("RewardTipPage")
  if not Logic.activityLogic:CheckActivityOpenById(config.id) then
    tag = 0
  end
  if not activityLogic.IsOpenDaysActivity() then
    UIHelper.ClosePage("NewPlayerPage")
  end
  if not activityLogic.IsOpenBigActivity() then
    UIHelper.ClosePage("BigActivityPage")
  end
  if not activityLogic.IsOpenDailyLogin() then
    UIHelper.ClosePage("DailyLoginPage")
  end
  self.m_tabWidgets.tog_leftGroup:SetActiveToggleIndex(tag)
end

function ActivityPage:_IsOpenNewPlayer(showType)
  local widgets = self:GetWidgets()
  self.activityInfo = Logic.activityLogic:GetActivityShow(showType)
  widgets.tog_leftGroup:ClearToggles()
  UIHelper.CreateSubPart(widgets.obj, widgets.content, #self.activityInfo, function(index, tabPart)
    local config = self.activityInfo[index]
    UIHelper.SetText(tabPart.text_on, config.name)
    UIHelper.SetText(tabPart.text_off, config.name)
    widgets.tog_leftGroup:RemoveToggle(tabPart.tg)
    widgets.tog_leftGroup:RegisterToggle(tabPart.tg)
    self:RegisterRedDotById(tabPart.reddot, self.activityInfo[index].red_dot, config.id)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_leftGroup, self, "", self._SwitchTogs)
end

function ActivityPage:_SwitchTogs(index)
  self:_LoadTopPage(index + 1)
  self:_LoadRightPage(index + 1)
  Data.activityData:SetTag(self.activityInfo[index + 1].id)
  self:Look(self.activityInfo[index + 1].id)
end

function ActivityPage:_LoadTopPage(index)
  local config = self.activityInfo[index]
  self:CloseTopPage()
  self:OpenTopPage("ActivityPage", 1, config.activity_top, self, true)
end

function ActivityPage:_LoadRightPage(index)
  local config = self.activityInfo[index]
  local widgets = self:GetWidgets()
  UIHelper.SetImage(widgets.im_bg, config.padding_image)
  local isOpen = UIHelper.IsPageOpen(config.banner_gotopage_activity)
  if not isOpen then
    self:OpenSubPage(config.banner_gotopage_activity, {
      activityType = config.type,
      activityId = config.id,
      custom = self.custom,
      jumpParam = self.jumpParam
    }, widgets.obj_subParent)
  else
    eventManager:SendEvent(LuaEvent.OpenActivityPage, config.id)
  end
end

function ActivityPage:DoOnClose()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

function ActivityPage:DoOnHide()
  self.m_tabWidgets.tog_leftGroup:ClearToggles()
end

function ActivityPage:GetIndex(tag)
  for i, v in pairs(self.activityInfo) do
    if tag == v.id then
      return i
    end
  end
  return 1
end

function ActivityPage:Look(aid)
  local playerPrefsKey = PlayerPrefsKey.ActivityLookPrefix .. aid
  local haslook = PlayerPrefs.GetBool(playerPrefsKey, false)
  if not haslook then
    PlayerPrefs.SetBool(playerPrefsKey, true)
    PlayerPrefs.Save()
    eventManager:SendEvent(LuaEvent.ActivityPage_LookRefresh)
  end
end

return ActivityPage
