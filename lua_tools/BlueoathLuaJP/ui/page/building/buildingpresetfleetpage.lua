local BuildingPresetFleetPage = class("UI.Building.BuildingPresetFleetPage", LuaUIPage)
local BuildingPresetItem = require("ui.page.Building.BuildingPresetItem")

function BuildingPresetFleetPage:DoOnOpen()
  self.param = self:GetParam()
  self.buildingId = self.param.buildingId
  self.buildingData = Data.buildingData:GetBuildingById(self.buildingId)
  self.defaultName = UIHelper.GetString(1900020)
  if not self.init then
    self.init = true
    self:_Refresh()
  end
end

function BuildingPresetFleetPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.ClosePresetFleetPage, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self._Refresh, self)
  self:RegisterEvent(LuaEvent.ChangeFleetNameError, self.ChangeNameError, self)
  self:RegisterEvent(LuaEvent.UpdateBuildingHero, self.OnUseTacticFinish, self)
end

function BuildingPresetFleetPage:_Refresh()
  self.buildingData = Data.buildingData:GetBuildingById(self.buildingId)
  self.presetDatas = Data.buildingData:GetPresetById(self.buildingId)
  self.buildingTactics = Logic.buildingLogic:GetPresetData()
  self:_ShowPresetFleets(self.presetDatas)
end

function BuildingPresetFleetPage:GetDefaultName(index)
  return string.format("%s%d", self.defaultName, index)
end

function BuildingPresetFleetPage:_ShowPresetFleets(datas)
  local curCount = #datas
  local widgets = self:GetWidgets()
  self.presetItems = self.presetItems or {}
  local maxCount = configManager.GetDataById("config_parameter", 302).value
  UIHelper.SetInfiniteItemParam(widgets.iil_obj_fleet, widgets.item_Fleet, maxCount, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local tabPart = part
      local presetData = datas[index]
      presetData = presetData or {
        Name = self:GetDefaultName(index),
        HeroList = {},
        BuildingId = self.buildingId,
        Empty = true
      }
      if self.presetItems[index] then
        self.presetItems[index]:Init({
          context = self,
          data = presetData,
          index = index,
          widgets = tabPart
        })
        self.presetItems[index]:Show()
      else
        local presetItem = BuildingPresetItem:new()
        presetItem:Init({
          context = self,
          data = presetData,
          index = index,
          widgets = tabPart
        })
        presetItem:Show()
        self.presetItems[index] = presetItem
      end
    end
  end)
end

function BuildingPresetFleetPage:OnRecord(index)
  local presetData = self.presetDatas[index]
  local curPresetCount = #self.presetDatas
  local count = #self.buildingData.HeroList
  if 0 < count then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(ok)
        if ok then
          self:Record(index)
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(1900018), tabParams)
  else
    noticeManager:ShowTip(UIHelper.GetString(1900019))
  end
end

function BuildingPresetFleetPage:Record(index)
  local heroList = self.buildingData.HeroList
  if #heroList == 0 then
    noticeManager:showTips(UIHelper.GetString(1900013))
    return
  end
  local tactic = self:GetTactic(index)
  tactic.HeroList = clone(heroList)
  self:SaveTacticList()
end

function BuildingPresetFleetPage:FixIndex(index)
  local curPresetCount = #self.presetDatas
  if index > curPresetCount then
    index = curPresetCount + 1
  end
  return index
end

function BuildingPresetFleetPage:GetTactic(index)
  index = self:FixIndex(index)
  local buildingId = self.buildingId
  self.buildingTactics = self.buildingTactics or {}
  self.buildingTactics[buildingId] = self.buildingTactics[buildingId] or {}
  self.buildingTactics[buildingId][index] = self.buildingTactics[buildingId][index] or {
    Index = index,
    BuildingId = buildingId,
    Name = self:GetDefaultName(index),
    HeroList = {},
    Faked = true
  }
  return self.buildingTactics[buildingId][index]
end

function BuildingPresetFleetPage:OnAdd(index)
  local heroList = self.presetDatas[index] and clone(self.presetDatas[index].HeroList) or {}
  local max = Logic.buildingLogic:GetOneBuildingHeroMax(self.buildingData.Tid)
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  UIHelper.OpenPage("BuildingHeroSelectPage", {
    heroInfoList = tabShowHero,
    selectMax = max,
    buildingData = self.buildingData,
    selectedHeroList = heroList,
    onSelect = function(buildingId, heroList)
      for i = #heroList, 1 do
        if heroList[i] == 0 then
          table.remove(heroList, i)
        end
      end
      local tactic = self:GetTactic(index)
      tactic.HeroList = heroList
      self:SaveTacticList()
    end
  })
end

function BuildingPresetFleetPage:OnDelete(index)
  local data = self.buildingTactics[self.buildingId][index]
  if not data then
    return
  end
  if data.Empty then
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        if data.Faked then
          table.remove(self.buildingTactics[self.buildingId], index)
          self:_ShowPresetFleets(self.buildingTactics[buildingId] or {})
        else
          Service.buildingService:RemoveTactic(self.buildingId, index - 1)
        end
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(1900016), tabParams)
end

function BuildingPresetFleetPage:OnUseTactic(index)
  local tactic = self:GetTactic(index)
  if #tactic.HeroList == 0 then
    noticeManager:ShowTip(UIHelper.GetString(1900015))
    return
  end
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        local ok, errmsg = Logic.buildingLogic:CheckAndSendBuildHero(tactic.HeroList, self.buildingData, function()
          Service.buildingService:SendSetHero(self.buildingId, tactic.HeroList)
        end)
        if errmsg then
          noticeManager:ShowTip(errmsg)
        end
      end
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(1900017), tabParams)
end

function BuildingPresetFleetPage:OnUseTacticFinish()
  noticeManager:ShowTip(UIHelper.GetString(1900014))
end

function BuildingPresetFleetPage:OnChangeName(index, buildingId, oldName)
  if not self.buildingTactics[buildingId][index] then
    return
  end
  UIHelper.OpenPage("ChangeNamePage", {
    1,
    oldName,
    oldName,
    ChangeNameType.BuildingPreset,
    onChange = function(newName)
      local tactic = self.buildingTactics[buildingId][index]
      if newName ~= tactic.Name then
        tactic.Name = newName
        self:SaveTacticList()
      end
    end
  })
end

function BuildingPresetFleetPage:ChangeNameError()
  if err == 1010 then
    noticeManager:ShowTip(UIHelper.GetString(1900011))
  elseif err == 1005 then
    noticeManager:ShowTip(UIHelper.GetString(1900012))
  end
end

function BuildingPresetFleetPage:ClosePresetFleetPage()
  UIHelper.ClosePage("BuildingPresetFleetPage")
end

function BuildingPresetFleetPage:SaveTacticList()
  local list = {}
  for bid, tacticList in pairs(self.buildingTactics) do
    for i, tactic in ipairs(tacticList) do
      t = clone(tactic)
      t.Index = i - 1
      table.insert(list, t)
    end
  end
  Service.buildingService:SaveTactic(list)
end

function BuildingPresetFleetPage:DoOnClose()
  self:SaveTacticList()
end

return BuildingPresetFleetPage
