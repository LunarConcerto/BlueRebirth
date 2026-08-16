local BuildShipPage = class("UI.Build.BuildShipPage", LuaUIPage)
local buildShipExplain = require("ui.page.BuildShip.BuildShipExplain")
local buildShipMainPage = require("ui.page.BuildShip.BuildShipMainPage")
local BUILDSHIP_RECURUIT_ID = 10007
local BUILDEQUIP_RECURUIT_ID = 10181
local BUILDFASHION_RECURUIT_ID = 13100
local BUILD_ONE = 1
local BUILD_TEN = 10
local TWEEN_WAIT_TIME = 4.6
local ANGLE_SETOFF = 180
local tweenParam = {
  {
    time = 2.8,
    from = 5,
    to = 0.8
  },
  {
    time = 0.09,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.08,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.07,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.06,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.05,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.04,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.03,
    from = 0.9,
    to = 0.8
  },
  {
    time = 0.5,
    from = 0.8,
    to = 0.8
  }
}

function BuildShipPage:DoInit()
  self.selectTog = -1
  self.buildConfigInfo = nil
  self.offsetY = 0
  self.offsetX = 0
  self.orderId = nil
  self.originalX = 0
  self.originalY = 0
  self.dispalyNum = 0
  self.allShip = {}
  self.spReward = {}
  self.transReward = {}
  self.dispLv = 1
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabWidgets.btn_share.gameObject:SetActive(platformManager:ShowShare())
  self.mFreeTimer = nil
  self.mIsFree = 0
  self.mDrawEquip = false
  self.OpenExploreInfo = nil
  SoundManager.Instance:PlayMusic("UI_Tween_FleetPage_0001")
  self.NewBuildId = {}
  self.uid = 0
  self.togTabPart = {}
  self.beforSelectTog = {}
end

function BuildShipPage:DoOnOpen()
  self.uid = Data.userData:GetUserUid()
  self:OpenTopPage("BuildShipPage", 1, "\230\142\162\231\180\162", self, false)
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency, {
    {5, 2},
    {
      1,
      10007,
      TopGoToPage.Shop,
      3
    },
    {
      1,
      10181,
      TopGoToPage.Shop,
      3
    },
    {
      1,
      18000,
      TopGoToPage.DailyCopy
    }
  })
  buildShipMainPage:Init(self)
  eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.INTO_TansuO_UI)
  if self.mDrawEquip or Logic.buildShipLogic:GetDisplay() or Logic.buildShipLogic:BoxRewardChooseFlg() then
    self.param = nil
  end
  self:_CreateExploreToggle()
  if Logic.buildShipLogic:GetDisplay() then
    self:_DisplayShip()
  end
  if self.param ~= nil then
    self:_BuildChangeTog(self.param)
    self.param = nil
  end
  Logic.buildShipLogic:ClearCardQuality()
  buildShipExplain:Init(self)
end

function BuildShipPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.BuildShipChangeTog, self._BuildChangeTog, self)
  self:RegisterEvent(LuaEvent.BuildFinish, self._ShowBuildRet, self)
  self:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
  self:RegisterEvent(LuaEvent.GetBuyGoodsMsg, self._ClickBuild, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.BuildShipReward, self._ShowBuildReward, self)
  self:RegisterEvent(LuaEvent.BuildShipBoxPageOpen, self._ReOpen, self)
  self:RegisterEvent(LuaEvent.BuildShipFailed, self._BuildShipFailed, self)
  self:RegisterEvent(LuaEvent.BossInfoRet, self._OnGetBossInfo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_mask, self._ClickLook, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeMap, self._ClickCloseMap, self)
  UGUIEventListener.AddButtonOnClickPosition(self.m_tabWidgets.btn_map, self._ClickMap, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeHelp, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_helpOk, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_closeTen, self._CloseTenCard, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_share, self._ClickShare, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_nGroup, self, "", self._ChangeBuild)
end

function BuildShipPage:_BuildChangeTog(buildId)
  for i, v in ipairs(self.OpenExploreInfo) do
    if v.id == buildId then
      self.selectTog = i - 1
      break
    end
  end
  self.m_tabWidgets.tog_nGroup:SetActiveToggleIndex(self.selectTog)
end

function BuildShipPage:_CreateFreshShowDesc()
  local timer = self:CreateTimer(function()
    buildShipMainPage:FreshShowDesc()
  end, 0.01, 1, false)
  self:StartTimer(timer)
end

function BuildShipPage:_ChangeBuild(index)
  self.selectTog = index
  self.buildConfigInfo = self.OpenExploreInfo[index + 1]
  buildShipMainPage:DisplayChangeByConfig(self.buildConfigInfo)
  self.dispLv = Data.buildShipData:GetDispCount(self.buildConfigInfo.id)
  if next(self.NewBuildId) ~= nil and self.NewBuildId[self.buildConfigInfo.id] then
    local periodId = Logic.buildShipLogic:GetBuildPeriodId(self.buildConfigInfo)
    PlayerPrefs.SetBool("NewBuildShipOpen" .. self.uid .. self.buildConfigInfo.id .. periodId, true)
    self.NewBuildId[self.buildConfigInfo.id] = nil
    self.togTabPart[index + 1].obj_newBuild:SetActive(false)
  end
  local showBoxRed = false
  if #self.buildConfigInfo.reward_type ~= 0 then
    showBoxRed = Logic.buildShipLogic:CheckTimesRewardById(self.buildConfigInfo)
  end
  self.togTabPart[index + 1].obj_red:SetActive(false)
  self.togTabPart[index + 1].obj_redCheck:SetActive(showBoxRed)
  if next(self.beforSelectTog) ~= nil then
    local beforShowBoxRed = false
    if #self.beforSelectTog[2].reward_type ~= 0 then
      beforShowBoxRed = Logic.buildShipLogic:CheckTimesRewardById(self.beforSelectTog[2])
    end
    self.beforSelectTog[1].obj_red:SetActive(beforShowBoxRed)
    self.beforSelectTog[1].obj_redCheck:SetActive(false)
  end
  self.beforSelectTog[1] = self.togTabPart[index + 1]
  self.beforSelectTog[2] = self.buildConfigInfo
  self:_RecuruitDate()
  self:CreateCountDown()
end

function BuildShipPage:_RecuruitDate()
  local recuruitId = 0
  local dotKey = ""
  if self.buildConfigInfo.extract_type == ExtractType.SHIP or self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
    recuruitId = BUILDSHIP_RECURUIT_ID
    dotKey = "ui_explore"
  elseif self.buildConfigInfo.extract_type == ExtractType.EQUIP then
    recuruitId = BUILDEQUIP_RECURUIT_ID
    dotKey = "build_equip"
  elseif self.buildConfigInfo.extract_type == ExtractType.FASHION then
    recuruitId = BUILDFASHION_RECURUIT_ID
    dotKey = "build_fashion"
  end
  local bagInfo = Logic.bagLogic:ItemInfoById(recuruitId)
  local itemNum = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  local dotInfo = {info = dotKey, item_num = itemNum}
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function BuildShipPage:_ClickShare()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName(), nil, nil, "BuildTenGirl")
end

function BuildShipPage:_HasSpecialInIlustrate()
  if self.buildConfigInfo.speical_ship_id == nil or #self.buildConfigInfo.speical_ship_id == 0 then
    return false
  end
  return Logic.illustrateLogic:HaveIllustrate(self.buildConfigInfo.speical_ship_id[1])
end

function BuildShipPage:_ClickBuildWithCheck(func)
  local buildFunction = func
  if self:_HasSpecialInIlustrate() == false then
    buildFunction()
  else
    local tabParam = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          buildFunction()
        end
      end
    }
    noticeManager:ShowMsgBox(1210001, tabParam)
  end
end

function BuildShipPage:_ClickBuildTen()
  local func = self:_DoClickBuildTen()
  self:_ClickBuildWithCheck(func)
end

function BuildShipPage:_DoClickBuildTen()
  return function()
    self.buildNum = BUILD_TEN
    if self.buildConfigInfo.extract_type == ExtractType.FASHION then
      local allOwn = Logic.buildShipLogic:CheckAllClothesOwn(self.buildConfigInfo)
      if allOwn then
        local tabParam = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ClickBuild()
            end
          end
        }
        noticeManager:ShowMsgBox(910009, tabParam)
        return
      end
    end
    self:_ClickBuild()
    self:buildEquipRetention()
  end
end

function BuildShipPage:_ClickBuildOne()
  local func = self:_DoClickBuildOne()
  self:_ClickBuildWithCheck(func)
end

function BuildShipPage:_DoClickBuildOne()
  return function()
    self.buildNum = BUILD_ONE
    if self.buildConfigInfo.extract_type == ExtractType.FASHION then
      local allOwn = Logic.buildShipLogic:CheckAllClothesOwn(self.buildConfigInfo)
      if allOwn then
        local tabParam = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ClickBuild()
            end
          end
        }
        noticeManager:ShowMsgBox(910009, tabParam)
        return
      end
    elseif self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
      local haveLimitShip = Logic.buildShipLogic:CheckLimitShipCount(self.buildConfigInfo)
      if not haveLimitShip then
        noticeManager:OpenTipPage(self, 1110059)
        return
      end
    end
    self:_ClickBuild()
    self:buildEquipRetention()
  end
end

function BuildShipPage:_ClickBuild()
  if not self:_CheckExpend() then
    return
  end
  if not self:CheckStatus() then
    return
  end
  if self.buildConfigInfo.extract_type == ExtractType.SHIP or self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
    local canBuild = Logic.rewardLogic:CanGotShip(self.buildNum)
    if not canBuild then
      return
    end
    RetentionHelper.SkipAllBehaviour()
    eventManager:SendEvent(LuaEvent.HomeResetModel)
    eventManager:SendEvent(LuaEvent.HomeTimerStop)
    SoundManager.Instance:PlayMusic("System|Laochuan")
    self.m_tabWidgets.obj_map:SetActive(true)
    self.m_tabWidgets.obj_close:SetActive(true)
    UIHelper.SetImage(self.m_tabWidgets.img_map, self.buildConfigInfo.explore_image[self.dispLv])
    UIHelper.SetImage(self.m_tabWidgets.img_tenBg, self.buildConfigInfo.explore_image[self.dispLv])
    eventManager:SendEvent(LuaEvent.GuideTriggerPoint, TRIGGER_TYPE.INTO_Tsansuo_MAP)
  elseif self.buildConfigInfo.extract_type == ExtractType.EQUIP then
    local needNum = self.buildNum
    local canBuild = Logic.rewardLogic:CanGotEquip(needNum)
    if not canBuild then
      return
    end
    self.mDrawEquip = true
    Service.cacheDataService:SendCacheData("buildship.BuildShip")
  elseif self.buildConfigInfo.extract_type == ExtractType.FASHION then
    Service.cacheDataService:SendCacheData("buildship.BuildShip")
  else
    return
  end
  local dotInfo = {
    info = "ui_explore_map"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function BuildShipPage:buildEquipRetention()
  if self.buildConfigInfo.extract_type == ExtractType.EQUIP then
    local dotInfo = {
      info = "ui_buildequip_way",
      item_num = self.buildNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  end
end

function BuildShipPage:_ClickMap(obj, eventData)
  self.originalX = eventData.position.x
  self.originalY = eventData.position.y
  self:_ConfirmBuild()
end

function BuildShipPage:_ConfirmBuild()
  if not self:CheckStatus() then
    return
  end
  self:StopFreeTimer()
  self.m_tabWidgets.obj_close:SetActive(false)
  Service.cacheDataService:SendCacheData("buildship.BuildShip")
end

function BuildShipPage:_CacheDataRet(ret)
  if self.buildConfigInfo.extract_type == ExtractType.SHIP or self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
    self:_BuildShipCacheDataRet(ret)
  elseif self.buildConfigInfo.extract_type == ExtractType.EQUIP then
    self:_BuildEquipCacheDataRet(ret)
  elseif self.buildConfigInfo.extract_type == ExtractType.FASHION then
    self:_BuildFashionCacheDataRet(ret)
  else
    return
  end
end

function BuildShipPage:_BuildShipCacheDataRet(ret)
  self.orderId = ret
  local dotInfo = {
    info = "ui_explore_seek"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  UIHelper.SetUILock(true)
  local vector2Pos = UIHelper.GetAdapt2DPosition(Vector2.New(self.originalX, self.originalY))
  self.m_tabWidgets.obj_target.transform.localPosition = Vector3.New(vector2Pos.x, vector2Pos.y, 0)
  self.m_tabWidgets.obj_target:SetActive(true)
  local tweenScale = self.m_tabWidgets.obj_tweenScale:GetComponent("TweenScale")
  tweenScale:ResetToBeginning()
  self:PlayGreapTween(tweenScale)
  local soucePos = self.m_tabWidgets.rect_line.anchoredPosition
  local sToLPos = CSUIHelper.ScreenPointToLocalPointInRectangle(self.m_tabWidgets.obj_map:GetComponent(RectTransform.GetClassType()), Vector2.New(self.originalX, self.originalY))
  local length = math.sqrt((sToLPos.x - soucePos.x) ^ 2 + (sToLPos.y - soucePos.y) ^ 2)
  local angle = math.atan(sToLPos.y - soucePos.y, sToLPos.x - soucePos.x) * 180 / math.pi
  self.m_tabWidgets.rect_line.gameObject:SetActive(true)
  self.m_tabWidgets.obj_girl:SetActive(true)
  self.m_tabWidgets.obj_select:SetActive(false)
  self.m_tabWidgets.rect_line.sizeDelta = Vector2.New(length, 20)
  self.m_tabWidgets.tran_line.eulerAngles = Vector3.New(0, 0, angle + ANGLE_SETOFF)
  local tweenPos = self.m_tabWidgets.tween_girlPos
  tweenPos.from = Vector3.New(soucePos.x, soucePos.y, 0)
  tweenPos.to = Vector3.New(sToLPos.x, sToLPos.y, 0)
  self:_StartTimer()
  tweenPos:Play()
  self.m_tabWidgets.tween_girlRot:Play()
end

function BuildShipPage:_BuildEquipCacheDataRet(ret)
  self.orderId = ret
  local arg = {
    Id = self.buildConfigInfo.id,
    Num = self.buildNum,
    CacheId = self.orderId
  }
  Service.buildShipService:SendBuildShipReq(arg)
end

function BuildShipPage:_BuildFashionCacheDataRet(ret)
  self.orderId = ret
  local arg = {
    Id = self.buildConfigInfo.id,
    Num = self.buildNum,
    CacheId = self.orderId
  }
  Service.buildShipService:SendBuildShipReq(arg)
end

function BuildShipPage:_TweenOver()
  self:StopTimer()
  self:_Pause()
end

function BuildShipPage:_StartTimer()
  local m_timer = self:CreateTimer(function()
    self:_TweenOver()
  end, TWEEN_WAIT_TIME, 1, false)
  self:StartTimer(m_timer)
end

function BuildShipPage:_Pause()
  UIHelper.SetUILock(false)
  self.m_tabWidgets.rect_line.gameObject:SetActive(false)
  self.m_tabWidgets.obj_target:SetActive(false)
  self.m_tabWidgets.btn_mask.gameObject:SetActive(true)
  self.m_tabWidgets.obj_girl:SetActive(false)
end

function BuildShipPage:_ClickLook()
  if not self:CheckStatus() then
    self.m_tabWidgets.tween_girlPos:ResetToBeginning()
    self.m_tabWidgets.tween_girlRot:ResetToBeginning()
    return
  end
  local dotInfo = {
    info = "ui_explore_way",
    type = self.buildNum,
    free = self.buildNum == BUILD_ONE and self.mIsFree or 0
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  UIHelper.SetUILock(true)
  local arg = {
    Id = self.buildConfigInfo.id,
    Num = self.buildNum,
    CacheId = self.orderId
  }
  Service.buildShipService:SendBuildShipReq(arg)
end

function BuildShipPage:_ClearActMap()
  self.m_tabWidgets.obj_select:SetActive(true)
  self.m_tabWidgets.btn_mask.gameObject:SetActive(false)
  self.m_tabWidgets.obj_target:SetActive(false)
  self.m_tabWidgets.obj_close:SetActive(true)
  self.orderId = nil
end

function BuildShipPage:_CheckExpend()
  if self.buildNum == BUILD_ONE and self.mIsFree == 1 then
    return true
  end
  local expend = self.buildConfigInfo.expend
  for i = 1, #expend do
    if expend[i][1] == 5 then
      local count = Data.userData:GetCurrency(expend[i][2])
      if count < expend[i][3] * self.buildNum then
        noticeManager:OpenTipPage(self, UIHelper.GetString(920000130))
        return false
      end
    elseif expend[i][1] == 1 then
      local bagInfo = Logic.bagLogic:ItemInfoById(expend[i][2])
      if not bagInfo or bagInfo.num < expend[i][3] * self.buildNum then
        if self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
          globalNoitceManager:ShowItemInfoPage(expend[i][1], expend[i][2])
          noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(1110067)))
        else
          local itemNum = bagInfo == nil and 0 or bagInfo.num
          Logic.shopLogic:BuyExpendItem(expend[i][2], self.buildNum - itemNum, UIHelper.GetString(1110010))
        end
        return false
      end
    end
  end
  return true
end

function BuildShipPage:_ClickCloseMap()
  homeEnvManager:PlayHomeBgm()
  self:_ResetMapObj()
end

function BuildShipPage:_ResetMapObj()
  self.m_tabWidgets.obj_map:SetActive(false)
  self.m_tabWidgets.obj_select:SetActive(true)
  self.m_tabWidgets.btn_mask.gameObject:SetActive(false)
  self.m_tabWidgets.obj_target:SetActive(false)
end

function BuildShipPage:_DisplayShip()
  if self.dispalyNum == #self.allShip then
    if self.buildNum == BUILD_TEN then
      self:_LoadTenCard(self.allShip)
    end
    self.dispalyNum = 0
    Logic.buildShipLogic:SetDisplay(false)
    return
  end
  self.dispalyNum = self.dispalyNum + 1
  local heroId = self.allShip[self.dispalyNum].Id
  local shipId = self.allShip[self.dispalyNum].ConfigId
  local shipInfo = Logic.shipLogic:GetShipInfoById(shipId)
  local spReward = next(self.spReward) and self.spReward[self.dispalyNum].Reward
  local transReward = next(self.transReward) and self.transReward[self.dispalyNum].Reward
  local isNew, quality = Logic.buildShipLogic:CheckShowMeet(shipId)
  if isNew or quality == HeroRarityType.SR or quality == HeroRarityType.SSR or self.buildNum == BUILD_ONE then
    UIHelper.OpenPage("ShowGirlPage", {
      girlId = shipInfo.si_id,
      HeroId = heroId,
      buildNum = self.buildNum,
      spReward = spReward,
      transReward = transReward
    })
  else
    self:_DisplayShip()
  end
  local name = Logic.shipLogic:GetName(shipInfo.si_id)
  RetentionHelper.Retention(PlatformDotType.getLog, {
    info = GetGirlWay.build,
    ship_name = name,
    type = self.buildConfigInfo.id
  })
end

function BuildShipPage:_DisplayEquip()
  Logic.buildShipLogic:SetDisplay(false)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = self.allEquips,
    Page = "BuildShipPage",
    DontMerge = true,
    ShareContent = "BuildOneEquip"
  })
end

function BuildShipPage:_LoadTenCard(shipTab)
  SoundManager.Instance:PlayMusic("System|After_expendTen")
  self.m_tabWidgets.btn_closeTen.gameObject:SetActive(true)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_cardItem, self.m_tabWidgets.trans_card, #shipTab, function(nIndex, tabPart)
    local heroId = self.allShip[nIndex].Id
    tabPart.obj_trans:SetActive(false)
    if self.transReward[nIndex].Reward ~= nil and #self.transReward[nIndex].Reward > 0 then
      tabPart.obj_trans:SetActive(true)
    end
    ShipCardItem:LoadVerticalCard(heroId, tabPart.childpart)
  end)
end

function BuildShipPage:_CloseTenCard()
  if next(self.spReward) ~= nil then
    self:_ShowSpReward()
    return
  end
  eventManager:SendEvent(LuaEvent.BuildTenShipReturn)
  homeEnvManager:PlayHomeBgm()
  self.m_tabWidgets.btn_closeTen.gameObject:SetActive(false)
end

function BuildShipPage:_ShowSpReward()
  local allReward = Logic.rewardLogic:MergeTblReward(self.spReward, self.transReward)
  UIHelper.OpenPage("GetRewardsPage", {Rewards = allReward})
  self.spReward = {}
  self.transReward = {}
  return
end

function BuildShipPage:_ShowBuildRet(serverRet)
  if self.buildConfigInfo.extract_type == ExtractType.SHIP or self.buildConfigInfo.extract_type == ExtractType.LIMIT_SHIP then
    self:_ShowShip(serverRet)
  elseif self.buildConfigInfo.extract_type == ExtractType.EQUIP then
    self:_ShowEquip(serverRet)
  elseif self.buildConfigInfo.extract_type == ExtractType.FASHION then
    self:_ShowFashion(serverRet)
  end
end

function BuildShipPage:_ShowShip(serverRet)
  self.allShip = serverRet.BuildShipResult
  self.spReward = serverRet.SpReward
  self.transReward = serverRet.TransReward
  buildShipMainPage:_ShowSurplusTimes()
  Logic.buildShipLogic:SetDisplay(true)
  Logic.buildShipLogic:DisposeCardQuality(self.allShip)
  Logic.buildShipLogic:SetHaveSSR(self.allShip, ExtractType.SHIP)
  local dotUIInfo = {
    info = "ui_explore_get"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
  UIHelper.SetUILock(false)
  self.m_tabWidgets.tween_girlPos:ResetToBeginning()
  self.m_tabWidgets.tween_girlRot:ResetToBeginning()
  self:_ResetMapObj()
  if self.buildNum == BUILD_ONE then
    self:_DisplayShip()
    return
  end
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.BUILD
  })
end

function BuildShipPage:_ShowEquip(serverRet)
  self.allEquips = serverRet.BuildShipResult
  self:GetEquipRetention(serverRet)
  buildShipMainPage:_ShowSurplusTimes()
  if self.buildNum == BUILD_TEN then
    Logic.buildShipLogic:SetExtractReward(self.allEquips)
  end
  Logic.buildShipLogic:SetHaveSSR(self.allEquips, ExtractType.EQUIP)
  if self.buildNum == BUILD_ONE then
    self:_DisplayEquip()
    return
  end
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.BUILD
  })
end

function BuildShipPage:_ShowFashion(serverRet)
  buildShipMainPage:_ShowSurplusTimes()
  local params = {
    rewards = serverRet.BuildShipResult,
    pageName = "BuildShipPage",
    dontMerge = true
  }
  Logic.rewardLogic:ShowFashionAndReward(params)
end

function BuildShipPage:GetEquipRetention(serverRet)
  local equipIds = {}
  for i, reward in ipairs(serverRet.BuildShipResult) do
    table.insert(equipIds, reward.ConfigId)
  end
  local dotUIInfo = {info = "build_get", equip_id = equipIds}
  RetentionHelper.Retention(PlatformDotType.equipGetLog, dotUIInfo)
  dotUIInfo = {
    info = "ui_explore_equip_get",
    equip_id = equipIds,
    type = self.buildConfigInfo.id
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function BuildShipPage:CheckStatus()
  local isOpen = Logic.buildShipLogic:CheckServerOpenDay(self.buildConfigInfo.id)
  if not isOpen then
    noticeManager:OpenTipPage(self, UIHelper.GetString(1110047))
  else
    isOpen = Logic.buildShipLogic:CheckActIsOpen(self.buildConfigInfo.id)
    if not isOpen then
      noticeManager:OpenTipPage(self, UIHelper.GetString(1001007))
    end
  end
  if not isOpen then
    self:_ReOpen()
    return false
  end
  return true
end

function BuildShipPage:_ReOpen()
  self.m_tabWidgets.tog_nGroup:ClearToggles()
  self.selectTog = -1
  self.curSelectBuild = 1
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_nGroup, self, "", self._ChangeBuild)
  self:_ClearActMap()
  self:_ClickCloseMap()
end

function BuildShipPage:PlayGreapTween(tween)
  local co
  local agoTime = 0
  
  local function playTween(index)
    local tmp = tweenParam[index]
    tween.duration = tmp.time
    agoTime = tmp.time
    tween.from = Vector3.New(tmp.from, tmp.from, tmp.to)
    tween.to = Vector3.New(tmp.to, tmp.to, tmp.to)
    index = index + 1
    if index <= #tweenParam then
      co = coroutine.start(function()
        coroutine.wait(agoTime, co)
        coroutine.stop(co)
        co = nil
        tween:ResetToBeginning()
        playTween(index)
      end)
    end
    tween:Play()
  end
  
  playTween(1)
end

function BuildShipPage:_OpenHelp()
  self.m_tabWidgets.obj_help:SetActive(true)
  buildShipExplain:SetExplainInfo(self.buildConfigInfo)
end

function BuildShipPage:_ClickHelp()
  buildShipExplain:CloseHelp()
  self.m_tabWidgets.obj_help:SetActive(false)
end

function BuildShipPage:_ClickDropShow()
  self:OpenSubPage("FashionShowPage", self.buildConfigInfo)
end

function BuildShipPage:DoOnHide()
  self:UnregisterAllRedDotEvent()
  self:StopFreeTimer()
  self.m_tabWidgets.tog_nGroup:ClearToggles()
end

function BuildShipPage:DoOnClose()
  self:StopFreeTimer()
  self.m_tabWidgets.tog_nGroup:ClearToggles()
end

function BuildShipPage:CreateCountDown()
  local status, freeRefreshTime = Logic.buildShipLogic:GetFreeRefreshTime(self.buildConfigInfo.id, self.buildConfigInfo.free_explore_type)
  self.mIsFree = status == 0 and 1 or 0
  if freeRefreshTime <= 0 then
    self:StopFreeTimer()
    return
  end
  freeText = self.m_tabWidgets.txt_freedesc
  self.mFreeTimer = self.mFreeTimer or Timer.New()
  local timer = self.mFreeTimer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:_SetLeftTime(freeRefreshTime, freeText)
  end, 1, -1)
  timer:Start()
  self:_SetLeftTime(freeRefreshTime, freeText)
end

function BuildShipPage:_SetLeftTime(freeRefreshTime, freeText)
  local svrTime = time.getSvrTime()
  local surplusTime = freeRefreshTime - svrTime
  if surplusTime <= 0 then
    self:StopFreeTimer()
    buildShipMainPage:ShowFreeTips()
    self:CreateCountDown()
    eventManager:SendEvent(LuaEvent.BulidShipBtnFree)
  elseif self.mFreeTimer then
    freeText.text = string.format(UIHelper.GetString(1110026), UIHelper.GetCountDownStr(surplusTime))
  end
end

function BuildShipPage:StopFreeTimer()
  if self.mFreeTimer and self.mFreeTimer.running then
    self.mFreeTimer:Stop()
    self.mFreeTimer = nil
  end
end

function BuildShipPage:_ShareOver()
  self:ShareComponentShow(true)
end

function _OnGetBossInfo()
  self:_ReOpen()
end

function BuildShipPage:_BuildShipFailed(errID)
  local tabParam = {
    msgType = NoticeType.OneButton,
    callback = function(bool)
      self:_ReOpen()
    end
  }
  noticeManager:ShowMsgBox(1220000, tabParam)
end

function BuildShipPage:_ShowBuildReward(param)
  local rewards = param.BuildShipResult
  local transReward = param.TransReward
  local rewardType
  if param.IsChangeReward == true then
    rewardType = RewardType.REDAUCKLAND_CHANGE_REWARD
  end
  Logic.rewardLogic:ShowCommonReward(rewards, "BuildShipBoxPage", nil, rewardType, transReward)
  buildShipMainPage:_ShowBoxAndTimesReward()
end

function BuildShipPage:_CreateExploreToggle()
  self.OpenExploreInfo = Logic.buildShipLogic:GetOpenExplore()
  self.beforSelectTog = {}
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_nTog, self.m_tabWidgets.trans_nTog, #self.OpenExploreInfo, function(nIndex, tabPart)
    local config = self.OpenExploreInfo[nIndex]
    local _, descTime = Logic.buildShipLogic:_GetTogName(config)
    local dispLv = Data.buildShipData:GetDispCount(config.id)
    UIHelper.SetImage(tabPart.img_togBg, config.toggle_bg[dispLv])
    UIHelper.SetImage(tabPart.img_togCheckBg, config.toggle_check[dispLv])
    UIHelper.SetText(tabPart.txt_time, descTime)
    UIHelper.SetText(tabPart.txt_checkTime, descTime)
    self.m_tabWidgets.tog_nGroup:RegisterToggle(tabPart.tog_one)
    if config.id == BuildShipPageId.NewPlayer then
      tabPart.tog_one.gameObject.name = "buildShipTog"
    end
    local showBoxRed = false
    if #config.reward_type ~= 0 then
      showBoxRed = Logic.buildShipLogic:CheckTimesRewardById(config)
    end
    tabPart.obj_red:SetActive(showBoxRed)
    tabPart.obj_redCheck:SetActive(false)
    local periodId = Logic.buildShipLogic:GetBuildPeriodId(config)
    local isRecord = PlayerPrefs.GetBool("NewBuildShipOpen" .. self.uid .. config.id .. periodId, false)
    tabPart.obj_newBuild:SetActive(not isRecord)
    if not isRecord then
      self.NewBuildId[config.id] = not isRecord
    end
    table.insert(self.togTabPart, tabPart)
  end)
  if self.selectTog == -1 then
    self.selectTog = 0
  end
  self.m_tabWidgets.tog_nGroup:SetActiveToggleIndex(self.selectTog)
end

return BuildShipPage
