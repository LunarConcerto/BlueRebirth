local ActivityHalloweenEquipPage = class("ui.page.Activity.HalloweenActivity.ActivityHalloweenEquipPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ActivityHalloweenEquipPage:DoInit()
end

function ActivityHalloweenEquipPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function ActivityHalloweenEquipPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.AEQUIP_RefreshData, self.ShowPage, self)
end

function ActivityHalloweenEquipPage:DoOnHide()
end

function ActivityHalloweenEquipPage:DoOnClose()
end

function ActivityHalloweenEquipPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  self.tab_Widgets.itemEquip:SetActive(false)
  self:GetItemEquipDataList()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentEquip, self.tab_Widgets.itemEquip, #self.mItemEquipList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemEquipPart(index, part)
    end
  end)
end

function ActivityHalloweenEquipPage:GetItemEquipDataList()
  local equipBagInfo = Data.equipData:GetEquipData()
  local equipTab = Logic.equipLogic:GetEquipConfig(equipBagInfo, nil)
  local tabHeroRes, tabRes = Logic.equipLogic:EquipBagOverlay(equipTab)
  self.mItemEquipList = {}
  local tmpEquipMap = {}
  for _, res in pairs(tabHeroRes) do
    if res.activity_equip > 0 and self:CheckActEquip(res.activity_id) then
      local data = {}
      data.EquipTid = res.TemplateId
      data.EquipId = res.EquipId
      data.HeroId = res.HeroId
      table.insert(self.mItemEquipList, data)
    end
  end
  for _, res in pairs(tabRes) do
    if res.activity_equip > 0 and self:CheckActEquip(res.activity_id) then
      for _, equipid in ipairs(res.tabEquipId) do
        local data = {}
        data.EquipTid = res.TemplateId
        data.EquipId = equipid
        data.HeroId = res.HeroId
        table.insert(self.mItemEquipList, data)
      end
    end
  end
  for _, data in ipairs(self.mItemEquipList) do
    local count = tmpEquipMap[data.EquipTid] or 0
    tmpEquipMap[data.EquipTid] = count + 1
  end
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local equipTids = activityCfg.p1
  for _, equipTid in ipairs(equipTids) do
    local count = tmpEquipMap[equipTid] or 0
    if 0 < count then
      tmpEquipMap[equipTid] = count - 1
    else
      local data = {}
      data.EquipTid = equipTid
      data.EquipId = 0
      data.HeroId = 0
      table.insert(self.mItemEquipList, data)
    end
  end
  for index, data in ipairs(self.mItemEquipList) do
    data.Sindex = index
  end
  table.sort(self.mItemEquipList, function(a, b)
    local a_isCanGetReward = Logic.equipactivityLogic:IsCanGetReward(a.EquipId, a.EquipTid)
    local b_isCanGetReward = Logic.equipactivityLogic:IsCanGetReward(b.EquipId, b.EquipTid)
    if a_isCanGetReward ~= b_isCanGetReward then
      return a_isCanGetReward == true
    end
    local a_isGetReward = Data.equipactivityData:GetIsRewardByEquipId(a.EquipId)
    local b_isGetReward = Data.equipactivityData:GetIsRewardByEquipId(b.EquipId)
    if a_isGetReward ~= b_isGetReward then
      return a_isGetReward < b_isGetReward
    end
    if a.Sindex ~= b.Sindex then
      return a.Sindex < b.Sindex
    end
    return false
  end)
end

function ActivityHalloweenEquipPage:CheckActEquip(actIdList)
  for i, v in pairs(actIdList) do
    if v == self.mActivityId then
      return true
    end
  end
  return false
end

function ActivityHalloweenEquipPage:updateItemEquipPart(index, part)
  local equipData = self.mItemEquipList[index]
  local equipTid = equipData.EquipTid
  local canGetReward = false
  local equipCfg = configManager.GetDataById("config_equip", equipTid)
  UIHelper.SetImage(part.imgEquip, equipCfg.icon)
  UIHelper.SetText(part.textEquip, equipCfg.name)
  UIHelper.SetImage(part.imgQuality, QualityIcon[equipCfg.quality])
  UGUIEventListener.AddButtonOnClick(part.btnEquip, function()
    Logic.itemLogic:ShowItemInfo(GoodsType.EQUIP, equipTid)
  end)
  if equipData.EquipId > 0 then
    local power = Data.equipactivityData:GetPowerPointByEquipId(equipData.EquipId)
    part.sliderPower.value = power / equipCfg.max_energy
    UIHelper.SetText(part.textProgress, power .. "/" .. equipCfg.max_energy)
    local isReward = Data.equipactivityData:GetIsRewardByEquipId(equipData.EquipId)
    if isReward <= 0 and power >= equipCfg.max_energy then
      canGetReward = true
    end
  else
    part.sliderPower.value = 0
    UIHelper.SetText(part.textProgress, "0/" .. equipCfg.max_energy)
  end
  part.objRedDot:SetActive(canGetReward)
  UGUIEventListener.AddButtonOnClick(part.btnDetail, function()
    UIHelper.OpenPage("ActivityGiftPage", {EquipData = equipData})
  end)
  if equipData.EquipId > 0 then
    if 0 < equipData.HeroId then
      local heroInfo = Data.heroData:GetHeroById(equipData.HeroId)
      local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId)
      UIHelper.SetText(part.textSituation, "[" .. shipInfo.ship_name .. "]\232\163\133\229\164\135\228\184\173")
    else
      UIHelper.SetText(part.textSituation, "\230\156\170\232\163\133\229\164\135")
    end
  else
    UIHelper.SetText(part.textSituation, "\230\156\170\232\142\183\229\143\150")
  end
end

return ActivityHalloweenEquipPage
