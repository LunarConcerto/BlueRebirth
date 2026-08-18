local ActivityAnniversaryVideoPage = class("ui.page.Activity.Anniversary.ActivityAnniversaryVideoPage", LuaUIPage)

function ActivityAnniversaryVideoPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.param = nil
  self.curvideoId = 0
end

function ActivityAnniversaryVideoPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.activityId)
  self:_Refresh()
end

function ActivityAnniversaryVideoPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.GetActivityVideoMsg, self._Refresh, self)
  self:RegisterEvent(LuaEvent.GetWatchUrlVideoRet, self._CheckWatchVideoRet, self)
end

function ActivityAnniversaryVideoPage:_Refresh()
  self:_ShowActivityTime()
  self:_ShowPage()
end

function ActivityAnniversaryVideoPage:_CheckWatchVideoRet(fullPlay)
  if self.curvideoId == 0 then
    logError("\233\148\153\232\175\175\231\154\132\232\167\134\233\162\145Id:", self.curvideoId)
  end
  if fullPlay and fullPlay == "1" and not Data.activityVideoData:IsVideoWatched(self.curvideoId) then
    local tab = {
      Id = self.curvideoId
    }
    Service.activityVideoService:SetActivityVideo(tab, tab)
  end
end

function ActivityAnniversaryVideoPage:_ShowActivityTime()
  local startTime, endTime = PeriodManager:GetPeriodTime(self.actConfig.period, self.actConfig.period_area)
  startTime = time.formatTimeToMDHM(startTime)
  endTime = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.txtTime, startTime .. " - " .. endTime)
end

function ActivityAnniversaryVideoPage:_ShowPage()
  local config = {}
  local configAll = configManager.GetData("config_anniversary_video")
  for i, v in pairs(configAll) do
    table.insert(config, v)
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.itemStory, self.m_tabWidgets.contentStory, #config, function(nIndex, tabPart)
    local info = config[nIndex]
    UIHelper.SetImage(tabPart.im_storybg, info.image, true)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_start, function()
      self:_ShowVideo(info.id, info.link)
    end)
    local isOpen = info.period < 0 or PeriodManager:IsInPeriodArea(info.period, info.period_area)
    tabPart.im_storylockbg:SetActive(not isOpen)
    local startTimem, _ = PeriodManager:GetPeriodTime(info.period, info.period_area)
    startTimem = time.formatTimeToMD(startTimem)
    local strDay = string.format(configManager.GetDataById("config_language", 4810001).content, tostring(startTimem))
    UIHelper.SetText(tabPart.tx_lock, strDay)
    local haveWatched = Data.activityVideoData:IsVideoWatched(info.id)
    tabPart.tx_haveWatch.gameObject:SetActive(haveWatched)
    local isShowReward = isOpen and not haveWatched
    tabPart.im_rewardbg:SetActive(isShowReward)
    if isShowReward then
      local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
      local rewards = configManager.GetDataById("config_rewards", info.reward).rewards
      UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.rect_reward, #rewards, function(index, part)
        local data = rewards[index]
        local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
        UIHelper.SetImage(part.im_reward, itemInfo.icon)
        UIHelper.SetText(part.tx_num, data[3])
      end)
    else
    end
  end)
end

function ActivityAnniversaryVideoPage:_ShowVideo(id, str)
  local deviceWidth = platformManager:GetScreenWidth()
  local deviceHeight = platformManager:GetScreenHeight()
  local posX = 0
  local posY = 0
  if isWindows then
    deviceWidth = 700
    deviceHeight = 400
    posX = -1
    posY = -1
  end
  self.curvideoId = id
  platformManager:openCustomWebView(str, deviceWidth, deviceHeight, posX, posY, "1", nil, true)
end

return ActivityAnniversaryVideoPage
