local CommonCopyLevelDetailPage = class("ui.page.Copy.CommonCopyLevelDetailPage")
local AllLBPoint = 10000
local tabChase = {}
local DropInfoType = {firstPassReward = 3}
local TowerFleetIndex = 1

function CommonCopyLevelDetailPage:initialize()
  self.param = nil
  self.tabWidgets = nil
  self.page = nil
  self.showSupport = false
  self.m_supportTimer = nil
end

function CommonCopyLevelDetailPage:Init(page, param, tabWidgets)
  self.tabWidgets = tabWidgets
  self.page = page
  self.param = param
  self.copyType = self.param.copyType
  self.nCopyId = self.param.tabSerData.BaseId
  self.tabSerData = self.param.tabSerData
  self.actId = self.param.actId
  if self.tabSerData.IsRunningFight then
    self.page.bIsRunning = self.param.IsRunningFight
  end
  local starLevel = self.param.tabSerData.StarLevel
  self.nChapterId = self.param.chapterId
  local tempCopyId = self.nCopyId
  if self.page.bIsRunning then
    tempCopyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
  end
  local desConfInfo = Logic.copyLogic:GetCopyDesConfig(tempCopyId)
  self.page:ModifyDisplayConfig(desConfInfo, self.page.bIsRunning)
  self.page:ShowAreaInfo()
  self.tabChapter = configManager.GetDataById("config_chapter", self.nChapterId)
  UIHelper.SetImage(self.tabWidgets.im_chapter, self.tabChapter.copy_background)
  Service.copyService:SendGetCopyInfo(tempCopyId)
  if self.nCopyId then
    self.page:CreateShowStar(starLevel)
  else
    self.page:CreateShowStar(0)
  end
  eventManager:SendEvent(LuaEvent.OpenLevelDetailsPage, self.param)
end

function CommonCopyLevelDetailPage:_CreateDropItem()
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
    tabPart.obj_firstReward:SetActive(itemInfo.type == 3)
    tabPart.im_outItem:SetNativeSize()
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, tabDropInfoId)
    end)
  end)
end

function CommonCopyLevelDetailPage:UpdateInfo()
  self.dispConfig = self.page:GetDisplayConfig()
  self:_CreateChaseFighting()
  if #self.dispConfig.star_require == 0 or Logic.towerLogic:IsTowerType(self.page.m_fleetType) or self.page.m_isGoodsCopy or self.dispConfig.star_require_unlock == 1 or self.dispConfig.class_type == ChapterType.WalkDog then
    self.tabWidgets.obj_star:SetActive(false)
  end
  self.tabWidgets.obj_bossHP:SetActive(self.tabSerData.LBPoint < AllLBPoint and 0 < AllLBPoint - self.tabSerData.LBPoint and self.dispConfig.is_boss_copy == 1)
  if self.tabSerData.LBPoint < AllLBPoint and self.dispConfig.is_boss_copy == 1 then
    local effect_boss = self.tabWidgets.obj_bossHP.transform:Find(self.dispConfig.details_boss .. "(Clone)")
    if effect_boss == nil then
      local bossPath = "effects/prefabs/ui/" .. self.dispConfig.details_boss
      local bossObj = self.page:CreateUIEffect(bossPath, self.tabWidgets.obj_bossHP.transform)
      local im_bossHp = bossObj.transform:Find("im_slider01").gameObject:GetComponent(UIImage.GetClassType())
      local im_bossHpDi = bossObj.transform:Find("im_slider").gameObject:GetComponent(UIImage.GetClassType())
      local bossNum = bossObj.transform:Find("Text").gameObject:GetComponent(UIText.GetClassType())
      if im_bossHp ~= nil then
        local percent = (AllLBPoint - self.tabSerData.LBPoint) / AllLBPoint
        im_bossHp.fillAmount = percent
        im_bossHpDi.fillAmount = percent
        bossNum.text = math.ceil(percent * 100) .. "%"
      else
        noticeManager:ShowMsgBox("\232\142\183\229\143\150\232\161\128\230\157\161\231\187\132\228\187\182\228\191\161\230\129\175\233\148\153\232\175\175")
      end
    end
  end
end

function CommonCopyLevelDetailPage:_CreateChaseFighting()
  self.tabWidgets.btn_chase.gameObject:SetActive(self.tabSerData.IsRunningFight)
  self.tabWidgets.obj_chase:SetActive(self.page.bIsRunning)
  self.tabWidgets.obj_star:SetActive(true)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_chase, function()
    local tempCopyId = self.nCopyId
    if not self.page.bIsRunning then
      tempCopyId = Logic.copyLogic:GetCopyChaseInfo(self.nChapterId, self.nCopyId)
    end
    if self.tabChapter.tactic_type == FleetType.Normal then
      Service.copyService:SendGetCopyInfo(tempCopyId)
    end
    local desConfInfo = Logic.copyLogic:GetCopyDesConfig(tempCopyId)
    self.page:ModifyDisplayConfig(desConfInfo, not self.page.bIsRunning)
    self.dispConfig = self.page:GetDisplayConfig()
    self.tabWidgets.txt_dituName.text = self.dispConfig.name
    eventManager:SendEvent(LuaEvent.CopySupply, self.dispConfig)
    self.page.bIsRunning = not self.page.bIsRunning
    self.tabWidgets.obj_chase:SetActive(self.page.bIsRunning)
    tabChase[self.nCopyId] = self.page.bIsRunning
    Logic.copyLogic:SetChase(tabChase)
    self:_CreateDropItem()
  end)
end

function CommonCopyLevelDetailPage:StartAttack()
  Service.cacheDataService:SendCacheData("copy.StartBase", "CommonCopyLevelDetailPage")
end

function CommonCopyLevelDetailPage:CacheDataRet(cacheId)
  self.nBattleFleetId = self.page:GetBattleFleetId()
  Service.copyService:SendStartBase(self.nChapterId, self.nCopyId, self.page.bIsRunning, self.nBattleFleetId, cacheId, -1, nil, self.page.m_battleMode)
  self.page:UnregisterEvent(LuaEvent.CacheDataRet, self.page._CacheDataRet, self)
end

function CommonCopyLevelDetailPage:CheckBattleCondition()
  return true
end

function CommonCopyLevelDetailPage:SetMatchTempData()
  self.nBattleFleetId = self.page:GetBattleFleetId()
  local args = {
    chapterId = self.nChapterId,
    copyId = self.nCopyId,
    isRunningFight = self.page.bIsRunning,
    tacticId = self.nBattleFleetId,
    cacheId = -1,
    heroList = -1,
    strategyId = nil
  }
  Data.copyData:SetCopyMatchTempData(args)
end

function CommonCopyLevelDetailPage:SendMatchStartBase()
  local temData = Data.copyData:GetCopyMatchTempData()
  Service.copyService:SendStartBase02(temData.ChapterId, temData.CopyId, temData.IsRunningFight, temData.TacticId, self.page.m_cacheId, -1, nil, temData.BattleMode, nil, self.page.m_roomId)
end

function CommonCopyLevelDetailPage:CheckTime()
  if self.page.m_battleMode == BattleMode.Memory then
    return true
  end
  if not Logic.copyLogic:CheckOpenByCopyId(self.nCopyId, true) then
    return false
  end
  return true
end

function CommonCopyLevelDetailPage:CreateFleet()
  if Logic.towerLogic:IsTowerType(self.tabChapter.tactic_type) then
    self:CreateTowerFleet()
  else
    self.page:_InitFleet()
  end
end

function CommonCopyLevelDetailPage:CreateTowerFleet()
  self.tabWidgets.trans_leftGroup.gameObject:SetActive(false)
  self.tabWidgets.obj_towerFleet:SetActive(#self.page.m_tabFleetData[TowerFleetIndex].heroInfo == 0)
  self.page:_CreateFleetInfo(TowerFleetIndex, false)
end

function CommonCopyLevelDetailPage:SetBottomTog()
  local togs = {
    ButtomTogType.OUTPUT
  }
  return togs
end

return CommonCopyLevelDetailPage
