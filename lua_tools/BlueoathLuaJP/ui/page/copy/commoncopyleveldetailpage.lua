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
  self.constTime = 60
  self.m_firstTime = true
end

function CommonCopyLevelDetailPage:Init(page, param, tabWidgets)
  self.tabWidgets = tabWidgets
  self.page = page
  self.param = param
  self.copyType = self.param.copyType
  self.nCopyId = self.param.tabSerData.BaseId
  self.tabSerData = self.param.tabSerData
  self.actId = self.param.actId
  if self.param and self.param.pointInfo then
    Service.guildService:SendGetGuildWarHeroLockInfo()
    self:StartGuildWarTimer()
  end
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
    tabPart.obj_firstReward:SetActive(itemInfo.type == RewardType.FIRSTPASS)
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
  self.tabWidgets.obj_bossHP:SetActive(self.tabSerData.LBPoint < AllLBPoint and 0 < AllLBPoint - self.tabSerData.LBPoint and self.dispConfig.is_boss_copy == 1 or self.page.m_fleetType == FleetType.GuildWar)
  self.tabWidgets.obj_challenge_num.gameObject:SetActive(self.page.m_fleetType == FleetType.GuildWar)
  if self.tabSerData.LBPoint < AllLBPoint and self.dispConfig.is_boss_copy == 1 or self.page.m_fleetType == FleetType.GuildWar then
    local effect_boss = self.tabWidgets.obj_bossHP.transform:Find(self.dispConfig.details_boss .. "(Clone)")
    if effect_boss == nil then
      local bossPath = "effects/prefabs/ui/" .. self.dispConfig.details_boss
      if self.dispConfig.details_boss == "" then
        logError("\230\163\128\230\159\165\233\133\141\231\189\174\228\184\173details_boss\230\152\175\229\144\166\233\133\141\231\189\174\239\188\129")
        return
      end
      self.bossObj = self.page:CreateUIEffect(bossPath, self.tabWidgets.obj_bossHP.transform)
    end
    if self.bossObj ~= nil then
      local im_bossHp = self.bossObj.transform:Find("im_slider01").gameObject:GetComponent(UIImage.GetClassType())
      local im_bossHpDi = self.bossObj.transform:Find("im_slider").gameObject:GetComponent(UIImage.GetClassType())
      local bossNum = self.bossObj.transform:Find("Text").gameObject:GetComponent(UIText.GetClassType())
      if im_bossHp ~= nil then
        local percent = 1
        if self.page.m_fleetType == FleetType.GuildWar then
          if self.m_guildWarData then
            self:_UpdateGuildWarInfo(self.m_guildWarData)
            percent = self.m_guildWarData.CurBossHp / self.m_guildWarData.BossFirstHp
          end
        else
          percent = (AllLBPoint - self.tabSerData.LBPoint) / AllLBPoint
        end
        im_bossHp.fillAmount = percent
        im_bossHpDi.fillAmount = percent
        bossNum.text = math.ceil(percent * 100) .. "%"
      else
        noticeManager:ShowMsgBox(UIHelper.GetString(920000178))
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

function CommonCopyLevelDetailPage:StartGuildWarTimer()
  self.page:CreateGuildWarTimer()
end

function CommonCopyLevelDetailPage:StopGuildWarTimer()
  self.page:StopGuildWarTimer()
end

function CommonCopyLevelDetailPage:_UpdateGuildWarInfo(data)
  if data then
    local StageName = {
      [1] = "\226\133\160",
      [2] = "\226\133\161",
      [3] = "\226\133\162",
      [4] = "\226\133\163",
      [5] = "\226\133\164",
      [6] = "\226\133\165"
    }
    UIHelper.SetText(self.tabWidgets.tx_challenge_num, data.CurPlayerCount)
    local stage = string.format(UIHelper.GetString(810001), StageName[data.CurStageId])
    local section = string.format(UIHelper.GetString(810002), data.CurSectionId)
    self.tabWidgets.txt_dituName.text = stage .. section
    self.tabWidgets.obj_con_nandu.gameObject:SetActive(true)
    UIHelper.SetText(self.tabWidgets.tx_nanduxishu_shuzi, data.StageLevel)
  end
end

function CommonCopyLevelDetailPage:_RefreshPageInfo(data)
  self.param.nCopyId = data.CopyId
  self.m_displayConfig = Logic.copyLogic:GetCopyDesConfig(self.param.nCopyId)
  self.page.copyImp:Init(self, self.param, self.m_tabWidgets)
  self:UpdateInfo()
end

function CommonCopyLevelDetailPage:StartAttack()
  logError("anim mode before attack:" .. CacheUtil.GetUseSimpleAnim())
  if Logic.copyLogic:IsCurrCopyNvN() then
    Logic.copyLogic:SetTempAnimMode(CacheUtil.GetUseSimpleAnim())
    CacheUtil.SetUseSimpleAnim(0)
  end
  Service.cacheDataService:SendCacheData("copy.StartBase", "CommonCopyLevelDetailPage")
end

function CommonCopyLevelDetailPage:GetGuildWarBaseData(baseId)
  Service.guildService:SendGetGuildWarBaseInfo(baseId)
end

function CommonCopyLevelDetailPage:SetGuildWarInfo(data)
  self.m_guildWarData = data
  self:UpdateInfo()
end

function CommonCopyLevelDetailPage:SetGuildWarTicketInfo()
  if self.m_dirty and self:CheckBattleCondition() then
    self:SendStartBaseReq(self.cacheId)
  end
  self.m_dirty = false
end

function CommonCopyLevelDetailPage:CacheDataRet(cacheId, isPvePtMode)
  if self.m_dirty then
    self.cacheId = cacheId
    Service.guildService:SendGuildWarInfo()
  else
    self:SendStartBaseReq(cacheId, isPvePtMode)
  end
end

function CommonCopyLevelDetailPage:SendStartBaseReq(cacheId, isPvePtMode)
  self.nBattleFleetId = self.page:GetBattleFleetId()
  Service.copyService:SendStartBase(self.nChapterId, self.nCopyId, self.page.bIsRunning, self.nBattleFleetId, cacheId, -1, nil, self.page.m_battleMode, nil, nil, isPvePtMode)
  self.page:UnregisterEvent(LuaEvent.CacheDataRet, self.page._CacheDataRet, self)
end

function CommonCopyLevelDetailPage:CheckBattleCondition()
  if self.page.m_fleetType == FleetType.GuildWar and self.page.m_battleMode ~= BattleMode.Exercises then
    if not self:CheckGuildWarFleetCanBattle() then
      noticeManager:ShowMsgBox(UIHelper.GetString(810029))
      return false
    end
    local guildData = Data.guildData:GetGuildWarData()
    if guildData and guildData.curChallangeCount < 1 then
      noticeManager:ShowMsgBox(UIHelper.GetString(810030))
      return false
    end
  end
  self.m_dirty = self.page.m_fleetType == FleetType.GuildWar and true or false
  return true
end

function CommonCopyLevelDetailPage:CheckGuildWarFleetCanBattle()
  local index = TowerFleetIndex
  local fleetData = clone(self.page.m_tabFleetData[index])
  for i = 1, #fleetData.heroInfo do
    local heroId = fleetData.heroInfo[i]
    if Logic.fleetLogic:CheckHeroHadGuildWar(heroId) then
      return false
    end
  end
  for i = 1, #fleetData.exHeroInfo do
    local heroId = fleetData.exHeroInfo[i]
    if Logic.fleetLogic:CheckHeroHadGuildWar(heroId) then
      return false
    end
  end
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
  temData.CacheId = self.page.m_cacheId
  temData.RoomId = self.page.m_roomId
  Service.copyService:SendStartBasePve(temData.ChapterId, temData.CopyId, temData.IsRunningFight, temData.TacticId, temData.CacheId, -1, nil, temData.BattleMode, nil, temData.RoomId)
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
  elseif Logic.copyLogic:IsGuildWarCopy(self.tabChapter) then
    self:CreateGuildWarFleet()
  else
    self.page:_InitFleet()
  end
end

function CommonCopyLevelDetailPage:CreateTowerFleet()
  self.tabWidgets.trans_leftGroup.gameObject:SetActive(false)
  self.tabWidgets.obj_towerFleet:SetActive(#self.page.m_tabFleetData[TowerFleetIndex].heroInfo == 0)
  self.page:_CreateFleetInfo(TowerFleetIndex, false)
end

function CommonCopyLevelDetailPage:CreateGuildWarFleet()
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
