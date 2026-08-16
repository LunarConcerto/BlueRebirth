local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local BuildingGradeChangeTip = class("UI.Building.BuildingGradeChangeTip", LuaUIPage)

function BuildingGradeChangeTip:DoOnOpen()
  local params = self:GetParam()
  if params.IsOutpost then
    self.opType = params.opType
    self.IsOutpost = true
    self.BuildingId = params.BuildingId
    self.targetLevel = params.targetLevel
    local widgets = self:GetWidgets()
    UIHelper.SetText(widgets.tx_title, UIHelper.GetString(4600001) .. UIHelper.GetString(4600016))
    self:_ShowTitle()
    self:ShowOutpostEffect(params)
    self:ShowOutpostItems(params)
    return
  end
  self.opType = params.opType
  self.buildingData = params.buildingData
  self.targetLevel = params.targetLevel
  self.buildingCfg = configManager.GetDataById("config_buildinginfo", self.buildingData.Tid)
  if self.opType == MBuildingTipType.LevelUp then
    UIHelper.SetText(self.tab_Widgets.tx_title, UIHelper.GetLocString(3002019, self.buildingCfg.name))
    local levelupTid = Logic.buildingLogic:GetLvupTidByTypeLevel(self.buildingCfg.type, self.targetLevel)
    self.levelupCfg = configManager.GetDataById("config_buildinglevelup", levelupTid)
  else
    UIHelper.SetText(self.tab_Widgets.tx_title, UIHelper.GetLocString(3002020, self.buildingCfg.name))
    local levelupTid = Logic.buildingLogic:GetLvupTidByTypeLevel(self.buildingCfg.type, self.buildingCfg.level)
    self.levelupCfg = configManager.GetDataById("config_buildinglevelup", levelupTid)
  end
  self.newTid = Logic.buildingLogic:GetTidByTypeLevel(self.buildingCfg.type, params.targetLevel)
  self:_ShowTitle()
  self:_ShowEffect()
  self:_ShowItems()
end

function BuildingGradeChangeTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
end

function BuildingGradeChangeTip:_ShowTitle()
  local widgets = self:GetWidgets()
  local strEff, strItem
  if self.opType == MBuildingTipType.LevelUp then
    strEff = UIHelper.GetString(3002015)
    strItem = UIHelper.GetString(3002016)
  else
    strEff = UIHelper.GetString(3002017)
    strItem = UIHelper.GetString(3002018)
  end
  UIHelper.SetText(widgets.tx_effect, strEff)
  UIHelper.SetText(widgets.tx_item, strItem)
end

function BuildingGradeChangeTip:ShowOutpostEffect(params)
  local widgets = self:GetWidgets()
  local currentConfig = Data.mubarOutpostData:GetCurrentLevelData(params.BuildingId, params.targetLevel - 1)
  local levelUpConfig = Data.mubarOutpostData:GetCurrentLevelData(params.BuildingId, params.targetLevel)
  local effectCount = 2
  UIHelper.CreateSubPart(widgets.obj_effect, widgets.trans_effect, effectCount, function(index, tabPart)
    tabPart.obj_unlock:SetActive(false)
    tabPart.tx_now.gameObject:SetActive(true)
    tabPart.tx_next.gameObject:SetActive(true)
    if index == 1 then
      UIHelper.SetText(tabPart.tx_title, UIHelper.GetString(4600024))
      UIHelper.SetText(tabPart.tx_now, currentConfig.box_limit)
      UIHelper.SetText(tabPart.tx_next, levelUpConfig.box_limit)
    elseif index == 2 then
      UIHelper.SetText(tabPart.tx_title, UIHelper.GetString(4600025))
      UIHelper.SetText(tabPart.tx_now, currentConfig.ship_num)
      UIHelper.SetText(tabPart.tx_next, levelUpConfig.ship_num)
    end
  end)
end

function BuildingGradeChangeTip:_ShowEffect()
  local widgets = self:GetWidgets()
  local effects = Logic.buildingLogic:GetBuildingEffects(self.buildingCfg.type)
  local effectCount = #effects.LevelEffects
  local unlockDatas = Logic.buildingLogic:GetUnlockDatas(self.buildingData.Tid, self.newTid)
  local unlockCount = #unlockDatas
  UIHelper.CreateSubPart(widgets.obj_effect, widgets.trans_effect, effectCount + unlockCount, function(index, tabPart)
    if index <= effectCount then
      tabPart.obj_unlock:SetActive(false)
      tabPart.tx_now.gameObject:SetActive(true)
      tabPart.tx_next.gameObject:SetActive(true)
      local propertyName = effects.LevelEffects[index]
      local keyName, curValue, newValue = Logic.buildingLogic:GetLevelEffectStr(self.buildingData.Tid, self.newTid, propertyName)
      UIHelper.SetText(tabPart.tx_title, keyName)
      if propertyName == LevelEffect.MaxStrength then
        local curMaxStrength = Data.buildingData:GetMaxWorkerByLv(self.buildingData.Level)
        local nextMaxStrength = Data.buildingData:GetMaxWorkerByLv(self.buildingData.Level + 1)
        UIHelper.SetText(tabPart.tx_now, curMaxStrength)
        UIHelper.SetText(tabPart.tx_next, nextMaxStrength)
      elseif propertyName == LevelEffect.MoodRecover or propertyName == LevelEffect.WorkerRecover then
        curValue = curValue * BuildingBase.Float
        if curValue - math.floor(curValue) > 0.01 then
          UIHelper.SetText(tabPart.tx_now, string.format("%.2f", curValue))
        else
          UIHelper.SetText(tabPart.tx_now, string.format("%.0f", curValue))
        end
        newValue = newValue * BuildingBase.Float
        if newValue - math.floor(newValue) > 0.01 then
          UIHelper.SetText(tabPart.tx_next, string.format("%.2f", newValue))
        else
          UIHelper.SetText(tabPart.tx_next, string.format("%.0f", newValue))
        end
      elseif propertyName == LevelEffect.ProduceSpeed then
        if curValue - math.floor(curValue) > 0.1 then
          UIHelper.SetText(tabPart.tx_now, string.format("%.1f", curValue))
        else
          UIHelper.SetText(tabPart.tx_now, string.format("%.0f", curValue))
        end
        if newValue - math.floor(newValue) > 0.1 then
          UIHelper.SetText(tabPart.tx_next, string.format("%.1f", newValue))
        else
          UIHelper.SetText(tabPart.tx_next, string.format("%.0f", newValue))
        end
      else
        UIHelper.SetText(tabPart.tx_now, curValue)
        UIHelper.SetText(tabPart.tx_next, newValue)
      end
    else
      tabPart.obj_arrow:SetActive(false)
      tabPart.tx_now.gameObject:SetActive(false)
      tabPart.tx_next.gameObject:SetActive(false)
      tabPart.tx_title.gameObject:SetActive(false)
      local unlock = unlockDatas[index - effectCount]
      UIHelper.SetText(tabPart.tx_unlock, unlock.key)
      UIHelper.SetText(tabPart.tx_unlockName, unlock.value)
      tabPart.obj_unlock:SetActive(true)
    end
  end)
end

function BuildingGradeChangeTip:ShowOutpostItems(params)
  local widgets = self:GetWidgets()
  local items = {}
  if params.UpCost then
    items = params.UpCost
  end
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #items, function(index, tabPart)
    local item = items[index]
    local tableIndex = configManager.GetDataById("config_table_index", item[1])
    local itemCfg = configManager.GetDataById(tableIndex.file_name, item[2])
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
    local color = "#1ac13a"
    if self.opType == MBuildingTipType.LevelUp then
      color = ownCount < item[3] and "#ff5464" or "#1ac13a"
    end
    if self.opType ~= MBuildingTipType.LevelUp then
      color = "#1ac13a"
    end
    UIHelper.SetText(tabPart.txt_num, string.format("<color=%s>%s/%s</color>", color, ownCount, item[3]))
    UIHelper.SetImage(tabPart.img_icon, itemCfg.icon)
    UIHelper.SetText(tabPart.tx_add, itemCfg.name)
    UIHelper.SetImage(tabPart.img_frame, QualityIcon[itemCfg.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._OnClickItem, self, item)
  end)
end

function BuildingGradeChangeTip:_ShowItems()
  local widgets = self:GetWidgets()
  local levelupCfg = self.levelupCfg
  local items = {}
  if levelupCfg.costwork > 0 then
    table.insert(items, {
      GoodsType.CURRENCY,
      CurrencyType.STRENGTH,
      levelupCfg.costwork
    })
  end
  if 0 < levelupCfg.costmoney then
    table.insert(items, {
      GoodsType.CURRENCY,
      CurrencyType.GOLD,
      levelupCfg.costmoney
    })
  end
  if levelupCfg.rawmaterial1 and 0 < #levelupCfg.rawmaterial1 then
    table.insert(items, levelupCfg.rawmaterial1)
  end
  if levelupCfg.rawmaterial2 and 0 < #levelupCfg.rawmaterial2 then
    table.insert(items, levelupCfg.rawmaterial2)
  end
  if levelupCfg.rawmaterial3 and 0 < #levelupCfg.rawmaterial3 then
    table.insert(items, levelupCfg.rawmaterial3)
  end
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #items, function(index, tabPart)
    local item = items[index]
    local tableIndex = configManager.GetDataById("config_table_index", item[1])
    local itemCfg = configManager.GetDataById(tableIndex.file_name, item[2])
    local ownCount = Logic.bagLogic:GetConsumeCurrNum(item[1], item[2])
    local color = "#1ac13a"
    if self.opType == MBuildingTipType.LevelUp then
      color = ownCount < item[3] and "#FF0000" or "#1ac13a"
    end
    if self.opType ~= MBuildingTipType.LevelUp then
      color = "#1ac13a"
    end
    UIHelper.SetText(tabPart.txt_num, string.format("<color=%s>%s/%s</color>", color, ownCount, item[3]))
    UIHelper.SetImage(tabPart.img_icon, itemCfg.icon)
    UIHelper.SetText(tabPart.tx_add, itemCfg.name)
    UIHelper.SetImage(tabPart.img_frame, QualityIcon[itemCfg.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item, self._OnClickItem, self, item)
  end)
end

function BuildingGradeChangeTip:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function BuildingGradeChangeTip:_OnClickItem(go, item)
  globalNoitceManager:ShowItemInfoPage(item[1], item[2])
end

function BuildingGradeChangeTip:_OnClickOk()
  if self.IsOutpost then
    if self.opType == MBuildingTipType.LevelUp then
      local isCheck, errMsg = Logic.mubarOutpostLogic:CheckLevelUpCondition(self.BuildingId, self.targetLevel)
      if not isCheck then
        noticeManager:ShowTip(UIHelper.GetString(4600030))
        self:_CloseSelf()
        return
      end
      local levelUp = {
        BuildingId = self.BuildingId
      }
      Service.mubarOutpostService:UpdateBuilding(levelUp)
    end
    self:_CloseSelf()
    return
  end
  if self.opType == MBuildingTipType.LevelUp then
    local errMsg = Logic.buildingLogic:CheckUpgradeCost(self.buildingData.Tid, self.targetLevel)
    if errMsg ~= nil then
      noticeManager:ShowTip(errMsg)
      self:_CloseSelf()
      return
    end
    Service.buildingService:SendUpBuilding(self.buildingData.Id)
  else
    local errMsg = Logic.buildingLogic:CheckDegradeCost(self.buildingData.Tid, self.targetLevel)
    if errMsg ~= nil then
      noticeManager:ShowTip(errMsg)
      self:_CloseSelf()
      return
    end
    Service.buildingService:SendDownBuilding(self.buildingData.Id)
  end
  self:_CloseSelf()
end

function BuildingGradeChangeTip:_CloseSelf()
  UIHelper.ClosePage("BuildingGradeChangeTip")
end

function BuildingGradeChangeTip:DoOnHide()
end

function BuildingGradeChangeTip:DoOnClose()
end

return BuildingGradeChangeTip
