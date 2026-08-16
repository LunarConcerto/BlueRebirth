local MubarOutpostPage = class("UI.MubarOut.MubarOutpostPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function MubarOutpostPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.constNum = 10000000
  self.herProduceNum = 100
  self.constTime = 60
  self.m_firstTime = true
  self.LvStr = "Lv."
  self.m_totalBattlePower = 0
  self.m_index = 0
  self.m_outpostLevel = 0
  self.m_allOutPostDetailsInfo = nil
  self.m_outPostCurrentIndexDetailsInfo = nil
  self.m_currentoutPostInfo = nil
  self.m_isOpenAutoUseCoin = false
  self.m_currentOutPostId = nil
  self.m_isOpenBag = false
  self.m_indexChapter = {}
  self.m_showPositionNum = 0
  self.m_allChapterOutpostConfigInfo = self:GetChapterOutpostConfigInfo()
  self.m_currentLevelConfig = nil
  self.m_openBathTip = false
  self.m_openbattlePowerTip = false
end

function MubarOutpostPage:DoOnOpen()
  self.param = self:GetParam()
  if self.m_currentChapterId == nil then
    self.m_currentChapterId = self.param.chapterInfo.id
  end
  self:OpenBathTip(self.m_openBathTip)
  self:OpenBattlePowerTip(self.m_openbattlePowerTip)
  self:_UpdateOutpostInfo()
end

function MubarOutpostPage:_UpdateOutpostInfo()
  self.m_allOutPostDetailsInfo = Data.mubarOutpostData:GetOutPostData()
  self.m_currentoutPostInfo = self.m_allOutPostDetailsInfo and self.m_allOutPostDetailsInfo[self.m_currentOutPostId] or {}
  if self.m_currentoutPostInfo == nil then
    self:GetCurrentOutPostConfig(1, 0)
  end
  self:LoadChapterOutPostInfo(self.m_allChapterOutpostConfigInfo)
  self:LoadOutPostDetailsInfo(self.m_index, self.m_currentChapterId)
  self:StartOutpostTimer()
end

function MubarOutpostPage:OpenBathTip(isOpen)
  self.m_tabWidgets.obj_bathtip:SetActive(isOpen)
end

function MubarOutpostPage:OpenBattlePowerTip(isOpen)
  self.m_tabWidgets.obj_help:SetActive(isOpen)
  if isOpen then
    local drop_LevelList = self.m_currentLevelConfig.drop_level
    local levelDropInfo = ""
    local levelMsgInfo = UIHelper.GetString(4600026)
    for i = 1, #drop_LevelList do
      levelDropInfo = levelDropInfo .. string.format(levelMsgInfo, drop_LevelList[i][1], drop_LevelList[i][2] / 100)
    end
    UIHelper.SetText(self.m_tabWidgets.tx_dropLeveldesc, levelDropInfo)
  end
end

function MubarOutpostPage:StartOutpostTimer()
  self:StopAllTimer()
  local timeNow = 0
  local timer = self:CreateTimer(function()
    timeNow = timeNow + 1
    if timeNow % self.constTime == 0 or self.m_firstTime and 10 <= timeNow then
      Service.mubarOutpostService:GetOutpostInfo()
      self.m_firstTime = false
    end
  end, 1, -1, false)
  self:StartTimer(timer)
end

function MubarOutpostPage:_ReceiveOutpostRewardInfo()
end

function MubarOutpostPage:DoOnClose()
  self.param = nil
  self.m_allOutPostDetailsInfo = nil
  self.m_outPostCurrentIndexDetailsInfo = nil
  self.m_currentoutPostInfo = nil
  self.m_currentOutPostId = nil
  self.m_indexChapter = {}
  self.m_allChapterOutpostConfigInfo = nil
  self.m_currentLevelConfig = nil
  self.m_index = 0
  self.m_firstTime = true
  self:StopAllTimer()
end

function MubarOutpostPage:GetChapterIdByIndex(index)
  return self.m_indexChapter[index]
end

function MubarOutpostPage:LoadOutPostDetailsInfo(index, chapterId)
  Logic.copyLogic:SetMubarCopyOutpostSelectedIndex(chapterId)
  local outPostId
  if index == 0 then
    outPostId = Logic.mubarOutpostLogic:GetOutPostInfoByChapterId(chapterId)
  else
    outPostId = index
  end
  self.m_currentOutPostId = outPostId
  self.m_currentoutPostInfo = Data.mubarOutpostData:GetOutPostDataById(self.m_currentOutPostId)
  if self.m_currentoutPostInfo ~= nil then
    self:SetAutoUseCoinShow(self.m_currentoutPostInfo.UseCoin == 1)
    self.m_outpostLevel = self.m_currentoutPostInfo.Level
  else
    self.m_outpostLevel = 0
    self:SetAutoUseCoinShow(false)
  end
  self:SetLevel(self.m_outpostLevel)
  self:GetCurrentOutPostConfig(self.m_currentOutPostId, self.m_outpostLevel)
  self:SetBagInfo()
  self:LoadHerInfoList(self.m_currentoutPostInfo)
  self:SetChapterInfo()
end

function MubarOutpostPage:SetBagInfo()
end

function MubarOutpostPage:SetLevel(level)
  UIHelper.SetText(self.m_tabWidgets.tx_level, self.LvStr .. tostring(level))
end

function MubarOutpostPage:SetAutoUseCoinShow(isOpen)
  if isOpen then
    self.m_tabWidgets.open:SetActive(true)
    self.m_tabWidgets.unopen:SetActive(false)
  else
    self.m_tabWidgets.open:SetActive(false)
    self.m_tabWidgets.unopen:SetActive(true)
  end
end

function MubarOutpostPage:SetAutoUseCoin(isOpen)
  self.m_isOpenAutoUseCoin = isOpen
  local useCoin = 0
  if isOpen then
    useCoin = 1
    self.m_tabWidgets.open:SetActive(true)
    self.m_tabWidgets.unopen:SetActive(false)
  else
    useCoin = 0
    self.m_tabWidgets.open:SetActive(false)
    self.m_tabWidgets.unopen:SetActive(true)
  end
  local param = {
    BuildingId = self.m_currentOutPostId,
    UseCoin = useCoin
  }
  if self.m_outpostLevel ~= 0 then
    Service.mubarOutpostService:SetUseCoin(param)
  end
end

function MubarOutpostPage:GetCurrentOutPostConfig(outPostId, level)
  self.m_currentLevelConfig = Data.mubarOutpostData:GetCurrentLevelData(outPostId, level)
  self:SetMaxShowShipNum(self.m_currentLevelConfig.ship_num)
  self:SetCurrentOutPostRewardInfo(self.m_currentLevelConfig.reward_show)
  self:LevelUpCostConfig(self.m_currentLevelConfig.item_cost)
end

function MubarOutpostPage:SetMaxShowShipNum(num)
  self.m_showPositionNum = num
end

function MubarOutpostPage:LevelUpCostConfig(config)
  self.m_levelUpCost = config
end

function MubarOutpostPage:GetLevelUpCostConfig()
  return self.m_levelUpCost
end

function MubarOutpostPage:SetCurrentOutPostRewardInfo(rewards)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_CanGetquality, self.m_tabWidgets.trans_CanGetItemContent, #rewards, function(index, tabPart)
    local reward = rewards[index]
    local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[rewardInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, tostring(rewardInfo.icon))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
    end, self)
  end)
end

function MubarOutpostPage:SetBattlePowerLevel(battlePower, powerConfig)
  local rate = Logic.mubarOutpostLogic:GetDropByBattlePower(battlePower, powerConfig)
  rate = rate / 100
  UIHelper.SetText(self.m_tabWidgets.tx_combateffectivenesstip, string.format(UIHelper.GetString(4600011), rate))
end

function MubarOutpostPage:SetTotalBattlePower(value)
  UIHelper.SetText(self.m_tabWidgets.tx_combateffectiveness, string.format(UIHelper.GetString(4600009), tostring(value)))
end

function MubarOutpostPage:GetResMsgByBattlePower(battlePower)
  local rate = 10 + math.modf(self.m_totalBattlePower / 10000)
  return rate
end

function MubarOutpostPage:SetBagIsOpen(isOpen)
  self.m_isOpenBag = isOpen
  self.m_tabWidgets.obj_itembag:SetActive(isOpen)
  if isOpen then
    self:LoadPostBagInfo(self.m_currentChapterId)
  else
  end
end

function MubarOutpostPage:LoadPostBagInfo(chapterId)
end

function MubarOutpostPage:SetShowSelectIndex(index, tabParts)
  local color = "#9A9DDC"
  for i = 1, #tabParts do
    local part = tabParts[i]
    if index == i then
      part.im_chapterselect:SetActive(true)
      color = "#FFFFFF"
    else
      part.im_chapterselect:SetActive(false)
    end
  end
end

function MubarOutpostPage:GoSelectHeroPage(arg1, arg2, arg3)
  local maxSelectHeroNum = self.m_showPositionNum
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  local heroList
  if self.m_currentoutPostInfo ~= nil then
    heroList = self.m_currentoutPostInfo.HeroList
  end
  local param = {}
  if heroList then
    param = {
      outpost = true,
      buildingId = self.m_currentOutPostId,
      selectMax = maxSelectHeroNum,
      heroInfoList = tabShowHero,
      selectedHeroList = heroList,
      buildingData = nil,
      onSelect = function(buildingId, heroList)
        self:SelectHeroPageBackData(heroList)
      end
    }
  else
    param = {
      outpost = true,
      buildingId = self.m_currentOutPostId,
      selectMax = maxSelectHeroNum,
      heroInfoList = tabShowHero,
      buildingData = nil,
      onSelect = function(buildingId, heroList)
        self:SelectHeroPageBackData(heroList)
      end
    }
  end
  UIHelper.OpenPage("BuildingHeroSelectPage", param)
end

function MubarOutpostPage:SetReceiveAllBtnState(active)
  local color = "#FFFFFF"
  if not active then
    UIHelper.SetImage(self.m_tabWidgets.img_getall, "uipic_ui_outpost_bu_lv_hui")
    color = "#647b78"
  else
    UIHelper.SetImage(self.m_tabWidgets.img_getall, "uipic_ui_outpost_bu_lv")
  end
  UIHelper.SetText(self.m_tabWidgets.tx_getall, string.format("<color=%s>%s</color>", color, UIHelper.GetString(4600007)))
end

function MubarOutpostPage:SelectHeroPageBackData(heroList)
  local param = {
    BuildingId = self.m_currentOutPostId,
    HeroIdList = heroList
  }
  Service.mubarOutpostService:SetHero(param)
end

function MubarOutpostPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.Btn_back, function()
    UIHelper.ClosePage("MubarOutpostPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_combattip, function()
    self.m_openbattlePowerTip = not self.m_openbattlePowerTip
    self:OpenBattlePowerTip(self.m_openbattlePowerTip)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bathtip, function()
    self.m_openBathTip = not self.m_openBathTip
    self:OpenBathTip(self.m_openBathTip)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_unopen, function()
    if self.m_outpostLevel <= 0 then
      self:ShowMsg(4600036)
      return
    end
    local enough = Logic.mubarOutpostLogic:GetBathCoinIsEnough()
    if not enough then
      self:ShowMsg(4600019)
      return
    end
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:SetAutoUseCoin(true)
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(4600032), tabParams)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_open, function()
    self:SetAutoUseCoin(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_preset, function()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_openbag, function()
    self.m_isOpenBag = not self.m_isOpenBag
    self:SetBagIsOpen(self.m_isOpenBag)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_get, function()
    self:GetCurrentOutpostReward()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_speedup, function()
    self:ShowSpeedUpTip()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_levelup, function()
    self:UpGradeOutpost()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_leveldown, function()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_showspeedtip, function()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_getall, function()
    self:GetAllOutpostReward()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ok, function()
    local speedUpMaxNum = configManager.GetDataById("config_parameter", 407).value
    local speedUpUseNum = Data.mubarOutpostData:GetSpeedUpMaxNum()
    if speedUpMaxNum <= speedUpUseNum then
      self:ShowMsg(4600028)
      return
    end
    if self:CheckCost() then
      self:SpeedUpBtnClick()
    else
      self:ShowMsg(4600030)
    end
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, function()
    self:SetSpeedUpTipState(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_bathtipclose, function()
    self.m_openBathTip = false
    self:OpenBathTip(self.m_openBathTip)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    self:SetSpeedUpTipState(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_maskclose, function()
    self.m_openbattlePowerTip = false
    self:OpenBattlePowerTip(self.m_openbattlePowerTip)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_helpclose, function()
    self.m_openbattlePowerTip = false
    self:OpenBattlePowerTip(self.m_openbattlePowerTip)
  end)
  self:RegisterEvent(LuaEvent.UpdateOutpostInfo, self._UpdateOutpostInfo, self)
  self:RegisterEvent(LuaEvent.ReceiveOutpostRewardInfo, self._ReceiveOutpostRewardInfo, self)
end

function MubarOutpostPage:ShowMsg(id)
  local showText = UIHelper.GetString(id)
  noticeManager:OpenTipPage(self, showText)
end

function MubarOutpostPage:_GetOutpostInfoFinish()
end

function MubarOutpostPage:SpeedUpBtnClick()
  local param = {
    BuildingId = self.m_currentOutPostId
  }
  Service.mubarOutpostService:SpeedUpProduction(param)
  self:SetSpeedUpTipState(false)
end

function MubarOutpostPage:CheckCost()
  local costItem = self.m_currentLevelConfig.speedup_cost
  if costItem then
    local own = Logic.bagLogic:GetConsumeCurrNum(costItem[1], costItem[2])
    if own < costItem[3] then
      return false
    end
  end
  return true
end

function MubarOutpostPage:ShowSpeedUpTip()
  if not self.m_currentoutPostInfo then
    self:ShowMsg(4600031)
    return
  end
  self:SetSpeedUpTipState(true)
  self:SetSpeedUpInfo()
end

function MubarOutpostPage:SetSpeedUpInfo()
  if self.m_currentLevelConfig then
    local showCostItem = self.m_currentLevelConfig.speedup_cost
    if showCostItem then
      local speedUpMaxNum = configManager.GetDataById("config_parameter", 407).value
      local speedUpUseNum = Data.mubarOutpostData:GetSpeedUpMaxNum()
      local showMsg = string.format(UIHelper.GetString(4600021), tostring(speedUpMaxNum - speedUpUseNum))
      UIHelper.SetText(self.m_tabWidgets.tx_desc, showMsg)
      local reward = showCostItem
      local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
      UIHelper.SetImage(self.m_tabWidgets.img_costQuality, QualityIcon[rewardInfo.quality])
      UIHelper.SetImage(self.m_tabWidgets.img_costIcon, tostring(rewardInfo.icon))
      UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_costReward, function()
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
      end, self)
      UIHelper.SetText(self.m_tabWidgets.tx_costNum, reward[3])
    end
  end
end

function MubarOutpostPage:SetSpeedUpTipState(isShow)
  self.m_tabWidgets.obj_speedup:SetActive(isShow)
end

function MubarOutpostPage:GetCurrentOutpostReward()
  if not self.m_currentOutpostReward or not self.m_currentoutPostInfo then
    self:ShowMsg(4600017)
    return
  end
  local param = {
    BuildingId = self.m_currentOutPostId
  }
  Service.mubarOutpostService:ReceiveItem(param)
end

function MubarOutpostPage:GetAllOutpostReward()
  if not self.m_allOutpostReward then
    self:ShowMsg(4600017)
    return
  end
  Service.mubarOutpostService:ReceiveAll()
end

function MubarOutpostPage:LoadChapterOutPostInfo(infoDatas)
  self.m_temPart = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.item_chapter, self.m_tabWidgets.Content_chapter, #infoDatas, function(index, tabpart)
    self.m_temPart[index] = tabpart
    local info = infoDatas[index]
    local chapterInfo = configManager.GetDataById("config_chapter", info.chapter_id)
    UIHelper.SetText(tabpart.tx_chaptername, chapterInfo.show_name)
    UIHelper.SetImage(tabpart.im_chapter, info.image)
    if not Logic.copyLogic:IsChapterPassByChapterId(info.chapter_id) then
      tabpart.im_lockbg:SetActive(true)
      UGUIEventListener.AddButtonOnClick(tabpart.btn_lockbg, function()
        noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(4600002), chapterInfo.show_name))
      end)
      tabpart.go_rewards:SetActive(false)
      tabpart.obj_state:SetActive(false)
    else
      tabpart.im_lockbg:SetActive(false)
      UGUIEventListener.AddButtonOnClick(tabpart.btn_rewards, function()
        local param = {BuildingId = index}
        Service.mubarOutpostService:ReceiveItem(param)
      end)
      local chapterId = info.chapter_id
      tabpart.go_rewards:SetActive(true)
      tabpart.obj_state:SetActive(true)
      UGUIEventListener.AddButtonOnClick(tabpart.btn_chapter, function()
        self.m_currentChapterId = info.chapter_id
        self.m_index = index
        self:LoadOutPostDetailsInfo(self.m_index, self.m_currentChapterId)
      end)
    end
  end)
end

function MubarOutpostPage:SetChapterInfo()
  local data = Data.mubarOutpostData:GetOutPostData()
  self.m_allOutpostReward = false
  self.m_currentOutpostReward = false
  for i = 1, #self.m_allChapterOutpostConfigInfo do
    local outpostId = Logic.mubarOutpostLogic:GetOutPostInfoByChapterId(self.m_allChapterOutpostConfigInfo[i].chapter_id)
    local currentData
    for j = 1, #data do
      if data[j].Id == outpostId then
        currentData = data[j]
        break
      end
    end
    local chapterInfo = configManager.GetDataById("config_chapter", self.m_allChapterOutpostConfigInfo[i].chapter_id)
    local stateMsdId
    local Color = "#9A9DDC"
    if data and currentData and outpostId and outpostId == currentData.Id then
      local outpostData = currentData
      local chapterIndex = currentData.Id
      if outpostData.State == 0 then
        stateMsdId = 4600006
      elseif outpostData.State == 1 then
        stateMsdId = 4600005
      else
        stateMsdId = 4600004
      end
      local showReward = false
      if outpostData.ItemInfo then
        for j = 1, #outpostData.ItemInfo do
          if 1 <= outpostData.ItemInfo[j].Num then
            if outpostData.ItemInfo[j].ConfigId ~= 1 and outpostData.ItemInfo[j].Type ~= 5 then
              showReward = true
            end
            self.m_allOutpostReward = true
            if self.m_currentOutPostId == chapterIndex then
              self.m_currentOutpostReward = true
            end
          end
        end
      end
      self.m_temPart[chapterIndex].go_rewards:SetActive(showReward)
    else
      Color = "#9A9DDC"
      stateMsdId = 4600004
      self.m_temPart[i].go_rewards:SetActive(false)
    end
    if self.m_currentOutPostId == outpostId then
      Color = "#FFFFFF"
    end
    UIHelper.SetText(self.m_temPart[i].tx_state, string.format("<color=%s>%s</color>", Color, UIHelper.GetString(stateMsdId)))
    UIHelper.SetText(self.m_temPart[i].tx_chaptername, string.format("<color=%s>%s</color>", Color, chapterInfo.show_name))
  end
  self:SetReceiveAllBtnState(self.m_allOutpostReward)
  self:SetShowSelectIndex(self.m_currentOutPostId, self.m_temPart)
end

function MubarOutpostPage:LoadHerInfoList(infoData)
  if infoData ~= nil then
    infoData = infoData.HeroList
  end
  self.m_totalBattlePower = 0
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_ShipItem, self.m_tabWidgets.jianniang, 6, function(index, tabpart)
    if infoData == nil or index > #infoData then
      self:CreateEmpty(index, tabpart)
    else
      self:CreateShip(index, tabpart)
      local heroId = self.m_currentoutPostInfo.HeroList[index]
      local heroAttr = Logic.attrLogic:GetBattlePower(heroId, FleetType.Normal, nil)
      self.m_totalBattlePower = self.m_totalBattlePower + heroAttr
      tabpart.im_zhanli:SetActive(true)
      UIHelper.SetText(tabpart.tx_zhanli, string.format(UIHelper.GetString(4600010), heroAttr))
    end
  end)
  self:SetTotalBattlePower(self.m_totalBattlePower)
  self:SetBattlePowerLevel(self.m_totalBattlePower, self.m_currentLevelConfig.drop_level)
end

function MubarOutpostPage:GetResMesByConfig()
end

function MubarOutpostPage:CreateEmpty(index, tabpart)
  tabpart.noHero:SetActive(true)
  tabpart.haveHero:SetActive(fasle)
  tabpart.im_zhanli:SetActive(false)
  if index <= self.m_showPositionNum then
    tabpart.obj_Open:SetActive(true)
    tabpart.obj_unOpen:SetActive(false)
    UGUIEventListener.AddButtonOnClick(tabpart.btn_add, function(arg1, arg2, arg3)
      self:EmptyShipItemClick()
    end)
  else
    tabpart.obj_Open:SetActive(false)
    tabpart.obj_unOpen:SetActive(true)
    UGUIEventListener.AddButtonOnClick(tabpart.lock, function(arg1, arg2, arg3)
      self:ShowMsg(4600033)
    end)
  end
end

function MubarOutpostPage:EmptyShipItemClick()
  self:GoSelectHeroPage()
end

function MubarOutpostPage:CreateShip(index, tabpart)
  tabpart.noHero:SetActive(false)
  tabpart.haveHero:SetActive(true)
  local heroId = self.m_currentoutPostInfo.HeroList[index]
  local heroData = Data.mubarOutpostData:GetHeroDataById(heroId)
  UIHelper.SetText(tabpart.Lv_num, tostring(heroData.Lvl))
  local shipInfoConfig = Logic.shipLogic:GetShipInfoById(heroData.TemplateId)
  local shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(heroId)
  local shipName = Logic.shipLogic:GetRealName(heroId)
  UIHelper.SetText(tabpart.name_Text, shipName)
  UIHelper.SetImage(tabpart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
  UIHelper.SetImage(tabpart.bg_quality, HorizontalCardQulity[shipInfoConfig.quality])
  UIHelper.SetImage(tabpart.im_girl, tostring(shipShowConfig.ship_icon1), true)
  UGUIEventListener.AddButtonOnClick(tabpart.btn_girl, function()
    self:GoSelectHeroPage()
  end)
  if tabpart.star and tabpart.trans_star then
    UIHelper.SetStar(tabpart.star, tabpart.trans_star, heroData.Advance)
  end
  if tabpart.im_mood then
    local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
    local moodInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
    if moodInfo then
      UIHelper.SetImage(tabpart.im_mood, moodInfo.mood_icon)
      tabpart.im_mood.gameObject:SetActive(moodInfo.mood_id == 1)
      tabpart.Mood_Slider.value = num / moodLimit[2]
    end
  end
end

function MubarOutpostPage:UpGradeOutpost()
  if self.m_outpostLevel >= 6 then
    self:ShowMsg(920000552)
    return
  end
  local param = {
    BuildingId = self.m_currentOutPostId,
    IsOutpost = true,
    opType = MBuildingTipType.LevelUp,
    targetLevel = self.m_outpostLevel + 1,
    UpCost = self.m_levelUpCost
  }
  UIHelper.OpenPage("OutpostGradeChangeTip", param)
end

function MubarOutpostPage:GetUpGradeResInfo()
end

function MubarOutpostPage:GetChapterOutpostConfigInfo()
  local configInfo = configManager.GetData("config_outpost_info")
  return configInfo
end

return MubarOutpostPage
