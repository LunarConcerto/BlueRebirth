local BossCopyLevelDetailPage = class("ui.page.BossCopy.BossCopyLevelDetailPage")
local DropInfoType = {firstPassReward = 3}

function BossCopyLevelDetailPage:initialize()
  self.param = nil
  self.tabWidgets = nil
  self.page = nil
  self.showSupport = false
  self.m_supportTimer = nil
end

function BossCopyLevelDetailPage:Init(page, param, tabWidgets)
  self.tabWidgets = tabWidgets
  self.page = page
  self.param = param
  self.copyType = self.param.copyType
  self.nCopyId = self.param.copyId
  self.tabSerData = self.param.tabSerData
  local starLevel = self.param.tabSerData.StarLevel
  self.nChapterId = self.param.chapterId
  self.isBossPlot = self.param.isBossPlot or false
  local tempCopyId = self.nCopyId
  if self.page.bIsRunning then
    tempCopyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
  end
  local desConfInfo = Logic.copyLogic:GetCopyDesConfig(tempCopyId)
  self.page:ModifyDisplayConfig(desConfInfo, self.page.bIsRunning)
  self.page:ShowAreaInfo()
  self.tabChapter = configManager.GetDataById("config_chapter", self.nChapterId)
  UIHelper.SetImage(self.tabWidgets.im_chapter, self.tabChapter.copy_background)
  self.page:_GetCopyInfoCallback({})
  if self.nCopyId then
    self.page:CreateShowStar(starLevel)
  else
    self.page:CreateShowStar(0)
  end
  eventManager:SendEvent(LuaEvent.OpenLevelDetailsPage, self.param)
end

function BossCopyLevelDetailPage:_CreateDropItem()
  self.dispConfig = self.page:GetDisplayConfig()
  local tabDropInfo = Logic.copyLogic:GetDropInfo()
  local tabDropInfoId = clone(self.dispConfig.drop_info_id)
  for i, v in ipairs(tabDropInfoId) do
    if tabDropInfo[v].type == DropInfoType.firstPassReward and self.tabSerData.FirstPassTime ~= 0 then
      table.remove(tabDropInfoId, i)
      break
    end
  end
  tabDropInfoId = Logic.copyLogic:FilterDropId(tabDropInfoId)
  local tabAfterDropInfoId = DropRewardsHelper.GetDropDisplay(tabDropInfoId)
  UIHelper.CreateSubPart(self.tabWidgets.obj_outItem, self.tabWidgets.trans_outItem, #tabAfterDropInfoId, function(nIndex, tabPart)
    local displayInfo = tabAfterDropInfoId[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(tabPart.im_outItem, displayInfo.icon)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    tabPart.obj_firstReward:SetActive(itemInfo.type == RewardType.FIRSTPASS)
    tabPart.im_outItem:SetNativeSize()
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, tabDropInfoId)
    end)
  end)
end

function BossCopyLevelDetailPage:UpdateInfo()
  self.dispConfig = self.page:GetDisplayConfig()
  if #self.dispConfig.star_require == 0 or self.dispConfig.star_require_unlock == 1 then
    self.tabWidgets.obj_star:SetActive(false)
  end
end

function BossCopyLevelDetailPage:StartAttack()
  Service.cacheDataService:SendCacheData("copy.StartBase", "BossCopyLevelDetailPage")
end

function BossCopyLevelDetailPage:CacheDataRet(cacheId)
  self.nBattleFleetId = self.page:GetBattleFleetId()
  Service.copyService:SendStartBase(self.nChapterId, self.nCopyId, self.page.bIsRunning, self.nBattleFleetId, cacheId, -1, nil, self.page.m_battleMode)
  self.page:UnregisterEvent(LuaEvent.CacheDataRet, self.page._CacheDataRet, self)
end

function BossCopyLevelDetailPage:CheckBattleCondition()
  return true
end

function BossCopyLevelDetailPage:CheckTime()
  if self.page.m_battleMode == BattleMode.Memory then
    return true
  end
  if not Logic.copyLogic:CheckOpenByCopyId(self.nCopyId, true) then
    return false
  end
  return true
end

function BossCopyLevelDetailPage:CreateFleet()
  self.page:_InitFleet()
end

function BossCopyLevelDetailPage:SetBottomTog()
  local togs = {}
  local bossStage = Logic.bossCopyLogic:GetBossCopyStage(self.isBossPlot)
  local togs = {}
  if bossStage == BossStage.ActBattleBoss then
    togs = {
      ButtomTogType.OUTPUT,
      ButtomTogType.KILLBOSS
    }
  else
    togs = {
      ButtomTogType.OUTPUT
    }
  end
  return togs
end

function BossCopyLevelDetailPage:CreateKillBossReward()
  local rewardId = Logic.bossCopyLogic:GetKillBossReward(self.nCopyId)
  local rewardTab = Logic.rewardLogic:FormatRewardById(rewardId)
  UIHelper.CreateSubPart(self.tabWidgets.obj_outItem, self.tabWidgets.trans_outItem, #rewardTab, function(nIndex, tabPart)
    local reward = rewardTab[nIndex]
    local itemInfo = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
    UIHelper.SetImage(tabPart.im_outItem, itemInfo.icon)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[itemInfo.quality])
    tabPart.obj_firstReward:SetActive(false)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
      Logic.itemLogic:ShowItemInfo(reward.Type, reward.ConfigId)
    end)
  end)
end

return BossCopyLevelDetailPage
