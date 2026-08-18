local BathTimeControl = class("UI.Bathroom.BathTimeControl")

function BathTimeControl:initialize()
end

function BathTimeControl:Init()
  self.m_timer = nil
  self.inPoolHeroTab = {}
  self.detailsHeroId = nil
  self.surplusText = nil
  self.startIndex = 0
  self.endIndex = 0
  self.tabTemp = {}
  self.isAllAuto = false
  self.limitTime = configManager.GetDataById("config_bathroom_item", 90001).time
  self:StartTimer()
  self.fleetInPool = {}
  self.fleetTimer = nil
end

function BathTimeControl:AddPoolHero(param)
  local index = param[3]
  for k, v in pairs(self.inPoolHeroTab) do
    if v.heroInPoolInfo.HeroId == param[2].HeroId then
      self.inPoolHeroTab[k] = nil
    end
  end
  self.inPoolHeroTab[index] = {
    tabPart = param[1],
    heroInPoolInfo = param[2]
  }
end

function BathTimeControl:StartTimer()
  self:CreateCountDown()
end

function BathTimeControl:StopTimer()
  if self.m_timer and self.m_timer.running then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

function BathTimeControl:CreateCountDown()
  self.m_timer = self.m_timer or Timer.New()
  local timer = self.m_timer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:_SetLeftTime()
  end, 1, -1)
  timer:Start()
  self:_SetLeftTime()
end

function BathTimeControl:_SetLeftTime()
  if self.inPoolHeroTab == nil or next(self.inPoolHeroTab) == nil then
    return
  end
  local svrTime = time.getSvrTime()
  for k, v in pairs(self.inPoolHeroTab) do
    local heroInfo = v.heroInPoolInfo
    local tabPart = self.tabTemp[k]
    if heroInfo.StartTime ~= 0 then
      local surplusTime = heroInfo.StartTime + self.limitTime - svrTime
      if heroInfo.IsAuto == 1 or self.isAllAuto then
        if surplusTime <= 0 then
          local cost = configManager.GetDataById("config_bathroom_item", 90001).price
          local currEnough = Logic.currencyLogic:CheckCurrencyEnough(13, cost)
          if currEnough then
            heroInfo.StartTime = svrTime
            surplusTime = heroInfo.StartTime + self.limitTime - svrTime
          else
            self:_BathEnd(heroInfo)
          end
        end
      elseif surplusTime <= 0 then
        self:_BathEnd(heroInfo)
      end
      if self.m_timer then
        if k >= self.startIndex and k <= self.endIndex and tabPart ~= nil then
          tabPart.tx_status.text = UIHelper.GetCountDownStr(surplusTime)
        end
        if self.detailsHeroId ~= nil and self.detailsHeroId == heroInfo.HeroId then
          self.surplusText.text = UIHelper.GetCountDownStr(surplusTime)
        end
      end
    end
  end
end

function BathTimeControl:_BathEnd(heroInfo)
  local dotinfo = {
    info = "ui_bathing_finish",
    type = 1
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self:RemovePoolHero(heroInfo.HeroId)
  Service.bathroomService:SendBathEnd(heroInfo.HeroId, heroInfo)
end

function BathTimeControl:SetDetailsTime(selectHeroInfo, surplusText)
  self:AddPoolHero({
    nil,
    selectHeroInfo,
    999
  })
  self.detailsHeroId = selectHeroInfo.HeroId
  self.surplusText = surplusText
end

function BathTimeControl:ClearDetailsTime()
  self.detailsHeroId = nil
  self.surplusText = nil
end

function BathTimeControl:SetShowItemRange(startIndex, endIndex, tabTemp)
  self.startIndex = startIndex
  self.endIndex = endIndex
  for k, v in pairs(tabTemp) do
    self.tabTemp[k] = v
  end
end

function BathTimeControl:RemovePoolHero(heroId)
  for k, v in pairs(self.inPoolHeroTab) do
    if v.heroInPoolInfo.HeroId == heroId then
      self.inPoolHeroTab[k] = nil
      return
    end
  end
end

function BathTimeControl:ClearPoolHero()
  self.inPoolHeroTab = {}
end

function BathTimeControl:CheckInPool(index)
  return self.inPoolHeroTab[index] ~= nil
end

function BathTimeControl:AllAutoInPool(isBool)
  self.isAllAuto = isBool
end

function BathTimeControl:AddFleetHero(param)
  self.fleetInPool[param[3]] = {
    tabPart = param[1],
    heroInPoolInfo = param[2]
  }
end

function BathTimeControl:FleetSurplusTime()
  self.fleetInPool = {}
  self.fleetTimer = self.fleetTimer or Timer.New()
  local timer = self.fleetTimer
  if timer.running then
    timer:Stop()
  end
  timer:Reset(function()
    self:DisposeTime()
  end, 1, -1)
  timer:Start()
  self:DisposeTime()
end

function BathTimeControl:DisposeTime()
  if self.fleetInPool == nil or next(self.fleetInPool) == nil then
    return
  end
  local svrTime = time.getSvrTime()
  for k, v in pairs(self.fleetInPool) do
    local heroInfo = v.heroInPoolInfo
    local tabPart = v.tabPart
    if heroInfo.StartTime ~= 0 then
      local surplusTime = heroInfo.StartTime + self.limitTime - svrTime
      if self.fleetTimer and 0 < surplusTime then
        tabPart.tx_status.text = UIHelper.GetCountDownStr(surplusTime)
      else
        tabPart.tx_status.text = "00:00:00"
      end
    end
  end
end

function BathTimeControl:StopFleetTimer()
  if self.fleetTimer and self.fleetTimer.running then
    self.fleetTimer:Stop()
    self.fleetTimer = nil
  end
end

return BathTimeControl
