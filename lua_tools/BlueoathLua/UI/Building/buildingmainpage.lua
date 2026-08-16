local BuildingMainPage = class("UI.Building.BuildingMainPage", LuaUIPage)
local BuildingItemInfoUI = {
  {
    name = UIHelper.GetString(3000009),
    icon = ""
  },
  {
    name = UIHelper.GetString(3000010),
    icon = ""
  },
  {
    name = UIHelper.GetString(3000012),
    icon = ""
  },
  {
    name = UIHelper.GetString(3000011),
    icon = ""
  },
  {
    name = UIHelper.GetString(3000013),
    icon = ""
  }
}
local BuildingItemInfoProgress = {
  Logic.buildingLogic.RecoverStrength,
  Logic.buildingLogic.GetBuildInfoProgress,
  Logic.buildingLogic.GetBuildHeroProgress,
  Logic.buildingLogic.GetBuildElectricProgress,
  Logic.buildingLogic.GetBuildFoodProgress
}

function BuildingMainPage:DoInit()
end

function BuildingMainPage:DoOnOpen()
  self:OpenTopPage("BuildingMainPage", 1, "\229\159\186\229\187\186", self, true)
  Logic.buildingLogic:UpdateBuildings(false)
  Logic.chatLogic:InitLockedEmoji()
  self.timerTxts = {}
  self:_Refresh()
  self:StartCountDownTimer()
  self:StartLineAnim()
  self:StartDotAnim()
  self:_Dotinfo()
end

function BuildingMainPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_tishi, self._ShowHelpTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_allgirl, self._ShowBuildingList, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_get, self._FastGet, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_bathroom, self._OnClickBathRoom, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self._Refresh, self)
  self:RegisterEvent(LuaEvent.BuildingReceiveResult, self._OnReceiveResult, self)
  self:RegisterEvent(LuaEvent.BuildingFinish, self._BuildingFinish, self)
end

function BuildingMainPage:DoOnHide()
end

function BuildingMainPage:DoOnClose()
end

function BuildingMainPage:_Refresh()
  self:_ShowItemInfo()
  self:_ShowMapInfo()
end

function BuildingMainPage:StartCountDownTimer()
  self.countDownTimer = self:CreateTimer(function()
    self:DoCountDown()
  end, 1, -1, false)
  self:StartTimer(self.countDownTimer)
  self:DoCountDown()
end

function BuildingMainPage:DoCountDown()
  local buildingDatas = Data.buildingData:GetBuildingData()
  for i, data in ipairs(buildingDatas) do
    if data.Status == BuildingStatus.Adding or data.Status == BuildingStatus.Upgrading then
      self:BuildingCountDown(data)
    elseif data.Status == BuildingStatus.Working then
      local buildingCfg = configManager.GetDataById("config_buildinginfo", data.Tid)
      if buildingCfg.type == MBuildingType.ItemFactory then
        self:ProduceItem(data)
      else
        self:Produce(data)
      end
    end
  end
  self:RecoverStrength()
end

function BuildingMainPage:BuildingCountDown(buildingData)
  local tabPart = self.timerTxts[buildingData.Id].tabPart
  local countDown = Logic.buildingLogic:GetUpgradeCountDown(buildingData)
  if 0 < countDown then
    local statusStr = Logic.buildingLogic:GetStatusStr(buildingData.Status)
    UIHelper.SetText(tabPart.tx_state, statusStr)
  else
    buildingData.Status = BuildingStatus.Working
  end
end

function BuildingMainPage:Produce(buildingData)
  local isProduceBuilding = Logic.buildingLogic:IsProduceBuilding(buildingData.Tid)
  if not isProduceBuilding then
    return
  end
  local tabPart = self.timerTxts[buildingData.Id].tabPart
  local resourceCount = Logic.buildingLogic:Produce(buildingData)
  tabPart.btn_item.gameObject:SetActive(0 < resourceCount)
  local statusStr = Logic.buildingLogic:GetStatusStr(buildingData.Status)
  UIHelper.SetText(tabPart.tx_state, statusStr)
  if tabPart.line_root then
    tabPart.line_root:SetActive(buildingData.Status == BuildingStatus.Working)
  end
end

function BuildingMainPage:RecoverStrength()
  local curStrength, maxStrength = Logic.buildingLogic:RecoverStrength()
  local txt = self.timerTxts.strength.txtStrength
  UIHelper.SetText(txt, string.format("%s/%s", curStrength, maxStrength))
  local slider = self.timerTxts.strength.slider
  slider.value = curStrength / maxStrength
end

function BuildingMainPage:ProduceItem(buildingData)
  local tabPart = self.timerTxts[buildingData.Id].tabPart
  local _, count = Logic.buildingLogic:ProduceItem(buildingData)
  tabPart.btn_item.gameObject:SetActive(0 < count)
  if 0 < count then
    local recipeId = buildingData.RecipeId
    local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
    local itemCfg = Logic.bagLogic:GetItemByTempateId(recipeCfg.item[1], recipeCfg.item[2])
    UIHelper.SetImage(tabPart.img_res, itemCfg.icon, true)
  end
  local statusStr = Logic.buildingLogic:GetStatusStr(buildingData.Status)
  UIHelper.SetText(tabPart.tx_state, statusStr)
  if tabPart.line_root then
    tabPart.line_root:SetActive(buildingData.Status == BuildingStatus.Working)
  end
end

function BuildingMainPage:_ShowItemInfo()
  local widgets = self:GetWidgets()
  local iconParam = configManager.GetDataById("config_parameter", 214).arrValue
  local nameParam = configManager.GetDataById("config_parameter", 215).arrValue
  UIHelper.CreateSubPart(widgets.obj_reso, widgets.trans_info, #BuildingItemInfoUI, function(index, tabPart)
    local ui = BuildingItemInfoUI[index]
    local prog = BuildingItemInfoProgress[index]
    UIHelper.SetText(tabPart.tx_name, UIHelper.GetString(nameParam[index]))
    UIHelper.SetImage(tabPart.im_icon, iconParam[index])
    local cur, max, progress = prog(Logic.buildingLogic)
    local color = "#ffffff"
    if cur < 0 then
      color = "#FF0000"
    end
    UIHelper.SetText(tabPart.tx_num, string.format("<color=%s>%s</color>/%s", color, cur, max))
    tabPart.Slider.value = progress
    if index == 1 then
      self.timerTxts.strength = {
        txtStrength = tabPart.tx_num,
        slider = tabPart.Slider
      }
    end
  end)
end

function BuildingMainPage:_ShowMapInfo()
  local widgets = self:GetWidgets()
  local landCfgs = configManager.GetData("config_building")
  local resouceIcons = configManager.GetDataById("config_parameter", 216).arrValue
  self.tabParts = {}
  for index = 1, #landCfgs do
    local landObjName = "land" .. index
    local tabPart = UIHelper.GetTabPart(widgets[landObjName])
    local landIndex = Logic.buildingLogic:SlotIndex2Id(index)
    local data, ok = Data.buildingData:GetBuildingByIndex(landIndex)
    local checkUnlock = Logic.buildingLogic:CheckLandUnlock(index)
    tabPart.lock:SetActive(not checkUnlock)
    tabPart.build:SetActive(checkUnlock and ok)
    tabPart.tx_available:SetActive(checkUnlock and not ok)
    if checkUnlock and ok then
      local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
      local status = Logic.buildingLogic:GetShowStatus(data, cfg)
      self.tabParts[data.Id] = tabPart
      if tabPart.line_root then
        if cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory or cfg.type == MBuildingType.ItemFactory or cfg.type == MBuildingType.DormRoom then
          tabPart.line_root:SetActive(status == BuildingStatus.Working)
          tabPart.tx_state.gameObject:SetActive(true)
          tabPart.obj_state:SetActive(true)
        else
          tabPart.line_root:SetActive(false)
          tabPart.tx_state.gameObject:SetActive(false)
          tabPart.obj_state:SetActive(false)
        end
      end
      UIHelper.SetText(tabPart.tx_name, cfg.name)
      UIHelper.SetText(tabPart.tx_state, Logic.buildingLogic:GetStatusStr(status))
      UIHelper.SetText(tabPart.tx_level, data.Level)
      UIHelper.SetText(tabPart.tx_girlNum, string.format("%s/%s", #data.HeroList, cfg.heronumber))
      UIHelper.SetImage(tabPart.im_building, cfg.typeicon)
      if tabPart.obj_arrow then
        local canLvUp = Logic.buildingLogic:CheckBuildingCanLvUp(data.Id)
        tabPart.obj_arrow:SetActive(canLvUp)
      end
      self.timerTxts[data.Id] = {tabPart = tabPart}
      if cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory then
        if cfg.type == MBuildingType.OilFactory then
          UIHelper.SetImage(tabPart.img_res, resouceIcons[1], true)
        elseif cfg.type == MBuildingType.ResourceFactory then
          UIHelper.SetImage(tabPart.img_res, resouceIcons[2], true)
        end
        local resCount = Logic.buildingLogic:Produce(data)
        if 0 < resCount then
          tabPart.btn_item.gameObject:SetActive(true)
        else
          tabPart.btn_item.gameObject:SetActive(false)
        end
      elseif cfg.type == MBuildingType.ItemFactory then
        local _, count = Logic.buildingLogic:ProduceItem(data)
        if 0 < count then
          local recipeId = data.RecipeId
          local recipeCfg = configManager.GetDataById("config_recipe", recipeId)
          local itemCfg = Logic.bagLogic:GetItemByTempateId(recipeCfg.item[1], recipeCfg.item[2])
          UIHelper.SetImage(tabPart.img_res, itemCfg.icon, true)
          tabPart.btn_item.gameObject:SetActive(true)
        else
          tabPart.btn_item.gameObject:SetActive(false)
        end
      else
        tabPart.btn_item.gameObject:SetActive(false)
      end
      if cfg.type ~= MBuildingType.BathRoom and checkUnlock and tabPart.hero_reddot then
        self:RegisterRedDot(tabPart.hero_reddot, {
          heroData = data.HeroList,
          itemCount = data.ItemCount,
          buildingType = cfg.type,
          buildingId = data.Id
        })
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._OnClickIcon, self, data.Id)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, self._OnClickSlot, self, landIndex)
  end
end

function BuildingMainPage:_OnClickBathRoom()
  moduleManager:JumpToFunc(FunctionID.BathRoom)
end

function BuildingMainPage:_OnClickSlot(go, landIndex)
  local landUnlock, errMsg = Logic.buildingLogic:CheckLandUnlock(landIndex)
  if errMsg then
    noticeManager:ShowTip(errMsg)
    return
  end
  local data, ok = Data.buildingData:GetBuildingByIndex(landIndex)
  if ok then
    local is3D = Logic.buildingLogic:Is3DBuild(data.Tid)
    if is3D then
      self:_Show3DBuildingDetail(data.Id)
    else
      self:_Show2DBuildingDetail(data)
    end
  else
    local buildingList = Logic.buildingLogic:GetBuildListByIndex(landIndex)
    if 0 < #buildingList then
      UIHelper.OpenPage("BuildingTypeListPage", {buildingList = buildingList, index = landIndex})
    end
  end
end

function BuildingMainPage:_OnClickIcon(go, buildingId)
  local buildingData = Data.buildingData:GetBuildingById(buildingId)
  local count = Logic.buildingLogic:Produce(buildingData)
  local buildingCfg = configManager.GetDataById("config_buildinginfo", buildingData.Tid)
  if buildingCfg.type == MBuildingType.ItemFactory then
    local _, count = Logic.buildingLogic:ProduceItem(buildingData)
    if 0 < count then
      Service.buildingService:ReceiveBuilding(buildingId)
    end
  else
    local checkResource, errMsg = Logic.buildingLogic:CheckReceiveResource(buildingData)
    if errMsg ~= nil then
      noticeManager:ShowTip(errMsg)
      return
    end
    local resouceCount = Logic.buildingLogic:Produce(buildingData)
    if 0 < resouceCount then
      Service.buildingService:ReceiveBuilding(buildingId)
    end
  end
end

function BuildingMainPage:StartLineAnim()
  self.lineIndex = 1
  self:StopLineAnim()
  self.lineAnimTimer = self:CreateTimer(function()
    self:DoLineAnim()
  end, 1, -1, false)
  self:StartTimer(self.lineAnimTimer)
  self:DoLineAnim()
end

function BuildingMainPage:DoLineAnim()
  local buildingDatas = Data.buildingData:GetBuildingData()
  for id, data in pairs(buildingDatas) do
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory or cfg.type == MBuildingType.ItemFactory or cfg.type == MBuildingType.DormRoom then
      local tabPart = self.tabParts[data.Id]
      for i = 1, 4 do
        tabPart["line" .. i]:SetActive(i == self.lineIndex)
      end
    end
  end
  self.lineIndex = self.lineIndex + 1
  if self.lineIndex == 5 then
    self.lineIndex = 1
  end
end

function BuildingMainPage:StopLineAnim()
  if self.lineAnimTimer then
    self:StopTimer(self.lineAnimTimer)
    self.lineAnimTimer = nil
  end
end

function BuildingMainPage:StartDotAnim()
  self.dotIndex = 1
  self:StopDotAnim()
  self.dotAnimTimer = self:CreateTimer(function()
    self:DoDotAnim()
  end, 1, -1, false)
  self:StartTimer(self.dotAnimTimer)
  self:DoDotAnim()
end

function BuildingMainPage:DoDotAnim()
  local buildingDatas = Data.buildingData:GetBuildingData()
  for id, data in pairs(buildingDatas) do
    local cfg = configManager.GetDataById("config_buildinginfo", data.Tid)
    if cfg.type == MBuildingType.OilFactory or cfg.type == MBuildingType.ResourceFactory or cfg.type == MBuildingType.ItemFactory or cfg.type == MBuildingType.DormRoom then
      local tabPart = self.tabParts[data.Id]
      for i = 1, 3 do
        tabPart["dot" .. i]:SetActive(i == self.dotIndex)
      end
    end
  end
  self.dotIndex = self.dotIndex + 1
  if self.dotIndex == 4 then
    self.dotIndex = 1
  end
end

function BuildingMainPage:StopDotAnim()
  if self.dotAnimTimer then
    self:StopTimer(self.dotAnimTimer)
    self.dotAnimTimer = nil
  end
end

function BuildingMainPage:_Show2DBuildingDetail(data)
  UIHelper.OpenPage("Building2DDetailPage", {data = data})
end

function BuildingMainPage:_Show3DBuildingDetail(buildingId)
  local task = function()
    UIHelper.OpenPage("Building3DScenePage", {buildingId = buildingId})
  end
  local param = {Task = task}
  UIHelper.OpenPage("BuildingSwitchPage", param, UILayer.ATTENTION, false)
end

function BuildingMainPage:_ShowBuildingList()
  local have = Data.buildingData:HaveBuilding()
  if not have then
    noticeManager:ShowTip(UIHelper.GetString(3002060))
    return
  end
  UIHelper.OpenPage("BuildingListPage")
end

function BuildingMainPage:_ShowHelpTip()
  UIHelper.OpenPage("HelpPage", {content = 3000008})
end

function BuildingMainPage:_FastGet()
  local oil, gold, item = Logic.buildingLogic:CheckBuildingsCanGet()
  local curOil = Data.userData:GetCurrency(CurrencyType.SUPPLY)
  local maxOil = Data.userData:GetCurrencyMax(CurrencyType.SUPPLY)
  if curOil >= maxOil and not gold and not item then
    noticeManager:ShowTip(UIHelper.GetString(3002044))
    return
  end
  if not oil and not gold and not item then
    noticeManager:ShowTip(UIHelper.GetString(3002069))
    return
  end
  Service.buildingService:ReceiveAll()
end

function BuildingMainPage:_OnReceiveResult(result)
  local tabReward = {}
  if result and result.ItemInfo and next(result.ItemInfo) ~= nil then
    Logic.rewardLogic:ShowCommonReward(result.ItemInfo, "BuildingMainPage")
    for k, v in pairs(result.ItemInfo) do
      table.insert(tabReward, {
        currencyId = v.ConfigId,
        Num = v.Num
      })
    end
  end
  local dotinfo = {
    info = "all_resource_get",
    item_num = tabReward
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function BuildingMainPage:_BuildingFinish(buildingId)
  Logic.buildingLogic:ShowBuildingFinish(buildingId)
end

function BuildingMainPage:_Dotinfo()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local allBuildingId = {}
  for k, v in pairs(buildingDatas) do
    table.insert(allBuildingId, v.Tid)
  end
  local dotinfo = {
    info = "building_info",
    building_id = allBuildingId
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

return BuildingMainPage
