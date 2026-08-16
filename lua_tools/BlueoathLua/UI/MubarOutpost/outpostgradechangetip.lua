local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local OutpostGradeChangeTip = class("UI.MubarOutpost.OutpostGradeChangeTip", LuaUIPage)

function OutpostGradeChangeTip:DoInit()
end

function OutpostGradeChangeTip:DoOnOpen()
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
end

function OutpostGradeChangeTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._OnClickOk, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CloseSelf, self)
end

function OutpostGradeChangeTip:_ShowTitle()
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

function OutpostGradeChangeTip:ShowOutpostEffect(params)
  local widgets = self:GetWidgets()
  local currentConfig = Data.mubarOutpostData:GetCurrentLevelData(params.BuildingId, params.targetLevel - 1)
  local levelUpConfig = Data.mubarOutpostData:GetCurrentLevelData(params.BuildingId, params.targetLevel)
  local effectCount = 1
  UIHelper.CreateSubPart(widgets.obj_effect, widgets.trans_effect, effectCount, function(index, tabPart)
    tabPart.obj_unlock:SetActive(false)
    if index == 2 then
    elseif index == 1 then
      tabPart.tx_now.gameObject:SetActive(true)
      tabPart.tx_next.gameObject:SetActive(true)
      UIHelper.SetText(tabPart.tx_title, UIHelper.GetString(4600025))
      UIHelper.SetText(tabPart.tx_now, currentConfig.ship_num)
      UIHelper.SetText(tabPart.tx_next, levelUpConfig.ship_num)
    end
  end)
end

function OutpostGradeChangeTip:ShowOutpostItems(params)
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

function OutpostGradeChangeTip:_ShowRewardInfo(go, award)
  logError("showRewardInfo:", award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function OutpostGradeChangeTip:_OnClickItem(go, item)
  logError("_OnClickItem:", item)
  globalNoitceManager:ShowItemInfoPage(item[1], item[2])
end

function OutpostGradeChangeTip:_OnClickOk()
  if self.IsOutpost then
    local chapterInfo = configManager.GetDataById("config_outpost_info", self.BuildingId)
    local pass = Logic.copyLogic:IsChapterPassByChapterId(chapterInfo.chapter_id)
    if not pass then
      local chapterDetailInfo = configManager.GetDataById("config_chapter", chapterInfo.chapter_id)
      noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(4600002), chapterDetailInfo.show_name))
      self:_CloseSelf()
      return
    end
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

function OutpostGradeChangeTip:_CloseSelf()
  UIHelper.ClosePage("OutpostGradeChangeTip")
end

return OutpostGradeChangeTip
