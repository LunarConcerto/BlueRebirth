local CommonSelectPage = class("UI.Common.CommonSelectPage", LuaUIPage)
local selectHeroItem = require("ui.page.Common.CommonSelect.SelectHeroItem")
local studySelect = require("ui.page.Common.CommonSelect.StudySelect")
local strengthenSelect = require("ui.page.Common.CommonSelect.StrengthenSelect")
local breakSelect = require("ui.page.Common.CommonSelect.BreakSelect")
local secretarySelect = require("ui.page.Common.CommonSelect.SecretarySelect")
local assistSelect = require("ui.page.Common.CommonSelect.AssistSelect")
local buildingSelect = require("ui.page.Common.CommonSelect.BuildingSelect")
local presetFleetSelect = require("ui.page.Common.CommonSelect.PresetFleetSelect")
local shipTestSelect = require("ui.page.Common.CommonSelect.ShipTestSelect")
local magazineSelect = require("ui.page.Common.CommonSelect.MagazineSelect")
local combinationSelect = require("ui.page.Common.CommonSelect.CombinationSelect")

function CommonSelectPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.TypeConfigTab = {
    [CommonHeroItem.Break] = {selectType = breakSelect},
    [CommonHeroItem.Strengthen] = {
      selectType = strengthenSelect,
      sortFunc = HeroSortHelper.FilterAndSort
    },
    [CommonHeroItem.Study] = {
      selectType = studySelect,
      sortFunc = HeroSortHelper.FilterAndSort1
    },
    [CommonHeroItem.ChangeSecretaryFleet] = {
      selectType = secretarySelect,
      sortFunc = HeroSortHelper.FilterAndSort
    },
    [CommonHeroItem.Assist] = {
      selectType = assistSelect,
      sortFunc = HeroSortHelper.AssistFilterAndSort
    },
    [CommonHeroItem.Building] = {
      selectType = buildingSelect,
      sortFunc = HeroSortHelper.BuildingSortHero
    },
    [CommonHeroItem.PresetFleet] = {
      selectType = presetFleetSelect,
      sortFunc = HeroSortHelper.FilterAndSort2
    },
    [CommonHeroItem.ShipTask] = {
      selectType = shipTestSelect,
      sortFunc = HeroSortHelper.FilterAndSort
    },
    [CommonHeroItem.Magazine] = {
      selectType = magazineSelect,
      sortFunc = HeroSortHelper.FilterAndSort
    },
    [CommonHeroItem.Combination] = {
      selectType = combinationSelect,
      sortFunc = HeroSortHelper.FilterAndSort
    }
  }
  self.m_sortway = true
  self.m_tabInParams = {}
  self.m_tabOutParams = {}
  self.m_tabSortHero = nil
  self.m_type = nil
  self.m_heroData = nil
  self.m_tabSelectShip = {}
  self.m_selectMax = nil
  self.m_tabTog = {}
  self.m_selectId = nil
  self.tabParams = nil
  self.m_SelectedBack = {}
  self.m_isShowProp = false
  self.m_tabChiName = {}
  self.m_tabShipInfo = {}
  self.m_tabTotalExp = {}
  self.m_beforeSelectTog = nil
  self.m_selectObj = nil
  self.m_selectFids = {}
  self.m_cachBathFids = {}
  self.m_cachBuildingFids = {}
  self.m_cachOutpostFids = {}
  self.isExHero = false
end

function CommonSelectPage:DoOnOpen()
  local param = self:GetParam()
  self.m_type = param[1]
  self.m_heroData = param[2]
  self.tabParams = param[3]
  self.m_selectMax = self.tabParams.m_selectMax
  self.magazineIndex = param.magazineIndex
  self.magazineId = param.magazineId
  self.isExHero = param.m_isExHero or false
  self:_SetBuildingData(self.tabParams.m_buildingInfo)
  self.m_strengthHeroId = self.tabParams.m_strengthHeroId
  self.m_presetIndex = self.tabParams.m_presetIndex
  local selectPage = self.TypeConfigTab[self.m_type].selectType:new()
  selectPage:Init(self, self.tabParams)
  self.m_selectObj = selectPage
  self.m_tabWidgets.obj_selectNum:SetActive(1 < self.m_selectMax)
  self.m_tabWidgets.txt_selectnum.text = #self.m_tabSelectShip .. "/<color=#677c99>" .. self.m_selectMax .. "</color>"
  self:_HeroSort()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonSelectPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.SetFleetMsg, self._SortOrder, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_sort, self._SortOrder, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_screen, self._ClickScreen, self)
  self:RegisterEvent(LuaEvent.SendHeroLock, self._OnUnlockHero)
end

function CommonSelectPage:_OnUnlockHero()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonSelectPage:_LoadHeroItem(heroTab)
  self.m_tabPart = {}
  if self.m_type == CommonHeroItem.Assist or self.m_type == CommonHeroItem.Building or self.m_type == CommonHeroItem.PresetFleet then
    self.m_selectFids = self:_GetSelectTids(self.m_tabSelectShip)
  end
  if self.m_type == CommonHeroItem.Building then
    self:_CacheBathAndBuildHero()
  end
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_girlsv, self.m_tabWidgets.obj_girlItem, #heroTab, function(tabParts)
    for nIndex, tabPart in pairs(tabParts) do
      nIndex = tonumber(nIndex)
      self.m_tabPart[nIndex] = tabPart
      local item = selectHeroItem:new()
      item:Init(self, tabPart, heroTab[nIndex], nIndex, self.m_type)
    end
  end)
end

function CommonSelectPage:_GetSelectTidsPre(herolist)
  local res = {}
  for k, v in pairs(herolist) do
    local tid = Data.heroData:GetHeroById(v).TemplateId
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    res[sf_id] = 0
  end
  return res
end

function CommonSelectPage:_GetSelectTids(herolist)
  local res = {}
  for k, v in pairs(herolist) do
    local tid = Data.heroData:GetHeroById(v).TemplateId
    local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
    local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
    res[sf_id] = 0
    local sf_config = configManager.GetDataById("config_ship_fleet", sf_id)
    for _, asid in pairs(sf_config.same_character) do
      res[asid] = 0
    end
  end
  return res
end

function CommonSelectPage:Selected(go, isOn, params)
  self.m_selectId = params.heroId
  if isOn then
    if self.m_selectMax == 1 and #self.m_tabSelectShip > 0 then
      if self.m_beforeSelectTog then
        self.m_beforeSelectTog.isOn = false
      end
      table.remove(self.m_tabSelectShip, 1)
    end
    if self.m_selectMax > 1 and #self.m_tabSelectShip >= self.m_selectMax then
      noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(110018), self.m_selectMax))
      params.tog.isOn = false
      return
    end
    if self.m_type == CommonHeroItem.Combination then
      local mainHeroFleetId = Data.heroData:GetHeroById(self.tabParams.MainHeroId).fleetId
      local selectHeroFleetId = Data.heroData:GetHeroById(self.m_selectId).fleetId
      if mainHeroFleetId == selectHeroFleetId then
        params.tog.isOn = not isOn
        self:_LoadHeroItem(self.m_tabSortHero)
        return
      end
    end
    if self.m_type == CommonHeroItem.Assist then
      local index = Logic.assistNewLogic:CheckCanSupport(self.m_tabSelectShip, self.m_selectId)
      if index then
        params.tog.isOn = not isOn
        noticeManager:OpenTipPage(self, 110009)
        return
      end
      if Logic.shipLogic:IsInCrusade(self.m_selectId) then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(971020))
        return
      end
    end
    if self.m_type == CommonHeroItem.PresetFleet then
      local index = Logic.assistNewLogic:CheckCanSupport(self.m_tabSelectShip, self.m_selectId)
      if index then
        params.tog.isOn = not isOn
        noticeManager:OpenTipPage(self, 110009)
        return
      end
      local sameCountry = Logic.fleetLogic:CheckOnFleetSameCountry(self.m_tabSelectShip, self.m_selectId, HeroCampType.Mubar)
      if sameCountry then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(990000003))
        return
      end
    end
    if self.m_type == CommonHeroItem.Building then
      local index = Logic.assistNewLogic:CheckCanSupport(self.m_tabSelectShip, self.m_selectId)
      if index then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(920000163))
        return
      end
      local bInBath = Logic.bathroomLogic:CheckInBath(self.m_selectId)
      local bathHero = Logic.buildingLogic:BathHeroWrap()
      local index = Logic.assistNewLogic:CheckCanSupport(bathHero, self.m_selectId)
      if index or bInBath then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(920000164))
        return
      end
    end
    if self.m_type == CommonHeroItem.Break then
      if Logic.shipLogic:IsSecretary(self.m_selectId) then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(180025))
        return
      end
      if Logic.shipLogic:IsInCrusade(self.m_selectId) then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(971020))
        return
      end
      if Logic.bathroomLogic:CheckInBath(self.m_selectId) then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(180019))
        return
      end
      if Logic.studyLogic:CheckHeroAlreadyStudy(self.m_selectId) then
        params.tog.isOn = not isOn
        noticeManager:ShowTip(UIHelper.GetString(180018))
        return
      end
      local lock = Logic.shipLogic:IsLock(self.m_selectId)
      local infleet = Logic.shipLogic:IsInFleet(self.m_selectId)
      if infleet then
        local fleetNum = Logic.shipLogic:GetHeroFleet(self.m_selectId)
        if fleetNum ~= 0 then
          local isSweeping = Logic.copyLogic:GetFleetIsSweeping(fleetNum)
          if isSweeping then
            params.tog.isOn = not isOn
            noticeManager:ShowTip(UIHelper.GetString(960000032))
            return
          end
        end
      end
      if lock and infleet then
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmUnlockAndRemove()
              self:_PlaySelectTween()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(180024, tabParams)
        return
      end
      if lock then
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmUnlock()
              self:_PlaySelectTween()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(180020, tabParams)
        return
      end
      if infleet then
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemove()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(200002, tabParams)
        return
      end
      local inbuild = Logic.shipLogic:IsInBuilding(self.m_selectId)
      if inbuild then
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemoveBuild()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(920000165), tabParams)
        return
      end
      local isInOutpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(self.m_selectId)
      if isInOutpost then
        local str = UIHelper.GetString(4600035)
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemoveBuild()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(str, tabParams)
        return
      end
    end
    if self.m_type == CommonHeroItem.Strengthen then
      local inbuild = Logic.shipLogic:IsInBuilding(self.m_selectId)
      if inbuild then
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemoveBuild()
              self:_LoadTotalExp(self.m_tabChiName)
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(920000165), tabParams)
        return
      end
      local isInOutpost = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(self.m_selectId)
      if isInOutpost then
        local str = UIHelper.GetString(4600035)
        params.tog.isOn = not isOn
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ConfirmRemoveBuild()
              self.m_beforeSelectTog = params.tog
            end
          end
        }
        noticeManager:ShowMsgBox(str, tabParams)
        return
      end
    end
    table.insert(self.m_tabSelectShip, self.m_selectId)
    self:_PlaySelectTween()
    self.m_beforeSelectTog = params.tog
  else
    local idPos = self:_GetSelectPos()
    table.remove(self.m_tabSelectShip, idPos)
  end
  self.m_tabWidgets.txt_selectnum.text = #self.m_tabSelectShip .. "/<color=#677c99>" .. self.m_selectMax .. "</color>"
  if self.m_type == CommonHeroItem.Strengthen then
    self:_LoadTotalExp(self.m_tabChiName)
  end
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonSelectPage:_GetSelectPos()
  for k, v in pairs(self.m_tabSelectShip) do
    if v == self.m_selectId then
      return k
    end
  end
end

function CommonSelectPage:_PlaySelectTween()
end

function CommonSelectPage:_LoadProp(tabShipInfo, obj, trans)
  local strengthHero = Data.heroData:GetHeroById(self.m_strengthHeroId).TemplateId
  local providePower = Logic.selectedShipPageLogic:GetProp(tabShipInfo.TemplateId, strengthHero)
  UIHelper.CreateSubPart(obj, trans, #providePower, function(nIndex, tabPart)
    tabPart.Tx_num.text = Mathf.ToInt(providePower[nIndex][2])
    tabPart.Tx_prop.text = self.m_tabChiName[nIndex][2]
  end)
end

function CommonSelectPage:_LoadTotalExp(tabAttrName)
  local tabTemplateId = Logic.selectedShipPageLogic:ConvertTabId(self.m_tabSelectShip, self.m_heroData)
  local sm_id = Data.heroData:GetHeroById(self.m_strengthHeroId).TemplateId
  self.m_tabTotalExp = Logic.selectedShipPageLogic:GetTotalExpNum(tabTemplateId, self.m_tabChiName, sm_id)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_totalexp, self.m_tabWidgets.trans_totalexp, #tabAttrName, function(nIndex, tabPart)
    tabPart.txt_prop.text = tabAttrName[nIndex][2]
    if #self.m_tabSelectShip ~= 0 then
      tabPart.txt_num.text = self.m_tabTotalExp[tabAttrName[nIndex][1]]
    else
      tabPart.txt_num.text = 0
    end
  end)
end

function CommonSelectPage:_ConfirmRemove()
  Logic.fleetLogic:RmvHeroinFleet(self.m_selectId)
  table.insert(self.m_tabSelectShip, self.m_selectId)
  self:_ShowSelectNum()
end

function CommonSelectPage:_ConfirmUnlock()
  Logic.shipLogic:SendHeroLockByType(self.m_selectId, false, self)
  table.insert(self.m_tabSelectShip, self.m_selectId)
  self:_ShowSelectNum()
end

function CommonSelectPage:_ConfirmUnlockAndRemove()
  Logic.fleetLogic:RmvHeroinFleet(self.m_selectId)
  Logic.shipLogic:SendHeroLockByType(self.m_selectId, false, self)
  table.insert(self.m_tabSelectShip, self.m_selectId)
  self:_ShowSelectNum()
end

function CommonSelectPage:_ConfirmRemoveBuild()
  table.insert(self.m_tabSelectShip, self.m_selectId)
  self:_LoadHeroItem(self.m_tabSortHero)
  self:_ShowSelectNum()
end

function CommonSelectPage:_ShowSelectNum()
  self.m_tabWidgets.txt_selectnum.text = #self.m_tabSelectShip .. "/<color=#677c99>" .. self.m_selectMax .. "</color>"
end

function CommonSelectPage:_CheckSelectHero(event, tabParam)
  local bBreak = false
  local bLevelUp = false
  local bIntensify = false
  local bHighQuality = false
  for i, heroId in ipairs(self.m_tabSelectShip) do
    bBreak = bBreak or Logic.shipLogic:CheckHasBreak(heroId)
    bLevelUp = bLevelUp or Data.heroData:GetHeroById(heroId).Lvl > 1
    bIntensify = bIntensify or Logic.shipLogic:CheckHasIntensify(heroId)
    bHighQuality = bHighQuality or Logic.shipLogic:CheckHighQuality(heroId)
    bRemould = bRemould or Logic.remouldLogic:CkeckHeroRemoulding(heroId)
  end
  if bBreak or bLevelUp or bIntensify or bHighQuality then
    local tblTips = {}
    if bBreak or bIntensify then
      table.insert(tblTips, UIHelper.GetString(110029))
    end
    if bLevelUp then
      table.insert(tblTips, UIHelper.GetString(110028))
    end
    if bHighQuality then
      table.insert(tblTips, UIHelper.GetString(110027))
    end
    if bRemould then
      table.insert(tblTips, UIHelper.GetString(940000002))
    end
    local strTips = string.format(UIHelper.GetString(110026), table.concat(tblTips, ","))
    local param = {
      msgType = NoticeType.TwoButton,
      target = self,
      callback = function(bool)
        if bool then
          UIHelper.Back()
          eventManager:SendEvent(event, tabParam)
        end
      end,
      guidedefineId = 113
    }
    noticeManager:ShowMsgBox(strTips, param)
  else
    UIHelper.Back()
    eventManager:SendEvent(event, tabParam)
  end
end

function CommonSelectPage:_HeroSort()
  self:_DealSortData()
  self.m_tabWidgets.txt_screen.text = HeroSortHelper.GetSortName(self.m_tabOutParams[2])
  local func = self.TypeConfigTab[self.m_type].sortFunc
  if func ~= nil then
    if self.m_type == CommonHeroItem.Building then
      local buildType = Logic.buildingLogic:GetBuildType(self.tabParams.m_buildingInfo.Tid)
      self.m_tabSortHero = func(self.m_heroData, buildType)
    else
      local custom = {
        Ships = self.tabParams.m_tids,
        Types = self.tabParams.m_type,
        IsExHero = self.isExHero
      }
      self.m_tabSortHero = func(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, custom)
    end
  else
    self.m_tabSortHero = self.m_heroData
  end
end

function CommonSelectPage:_UpdateHeroSort(tabSortParams)
  self.m_tabInParams = tabSortParams
  self.m_tabOutParams = tabSortParams
  self.m_tabWidgets.txt_screen.text = HeroSortHelper.GetSortName(self.m_tabOutParams[2])
  self:_SortOrder()
end

function CommonSelectPage:_SortOrder()
  if self.m_tabWidgets.tog_sort.isOn then
    self.m_sortway = true
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
  else
    self.m_sortway = false
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
  end
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  if self.m_type == CommonHeroItem.Study or self.m_type == CommonHeroItem.ChangeSecretaryFleet then
    self.m_tabSortHero = HeroSortHelper.FilterAndSort1(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway)
  elseif self.m_type == CommonHeroItem.Assist then
    local showHero = self.m_heroData
    if self.m_selectObj and self.m_selectObj.GetShowFleet then
      local showFleet = self.m_selectObj:GetShowFleet()
      if not showFleet then
        showHero = Logic.shipLogic:RemoveFleetShip(self.m_tabSortHero)
      end
    end
    local custom = {
      Ships = self.tabParams.m_tids,
      Types = self.tabParams.m_type
    }
    self.m_tabSortHero = HeroSortHelper.AssistFilterAndSort(showHero, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway, custom)
  else
    self.m_tabSortHero = HeroSortHelper.FilterAndSort(self.m_heroData, self.m_tabOutParams[1], self.m_tabOutParams[2], self.m_sortway)
  end
  self:_LoadHeroItem(self.m_tabSortHero)
end

function CommonSelectPage:_DealSortData()
  local tabSelectData = Logic.sortLogic:GetHeroSort(self.m_type)
  self.m_sortway = tabSelectData[1]
  if self.m_sortway then
    self.m_tabWidgets.tog_sort.isOn = true
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
  else
    self.m_tabWidgets.tog_sort.isOn = false
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
  end
  self.m_tabOutParams = tabSelectData[2]
end

function CommonSelectPage:_ClickScreen()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  UIHelper.OpenPage("SortPage", self.m_tabOutParams)
end

function CommonSelectPage:_SaveSortData()
  local tabSelectData = {}
  tabSelectData[1] = self.m_sortway
  tabSelectData[2] = self.m_tabOutParams
  Logic.sortLogic:SetHeroSort(self.m_type, tabSelectData)
end

function CommonSelectPage:_CacheBathAndBuildHero()
  local bathHero = Logic.buildingLogic:BathHeroWrap()
  local buildingHero = Data.buildingData:GetBuildingHero()
  local outpostHero = Data.mubarOutpostData:GetOutPostHeroData()
  self.m_cachBathFids = self:_GetSelectTids(bathHero)
  self.m_cachBuildingFids = self:_GetSelectTids(buildingHero)
  self.m_cachOutpostFids = self:_GetSelectTids(outpostHero)
end

function CommonSelectPage:GetBuildingTid()
  return self.m_buildingData.Tid
end

function CommonSelectPage:_GetCacheBathInfo()
  return self.m_cachBathFids
end

function CommonSelectPage:_GetCacheBuildingInfo()
  return self.m_cachBuildingFids
end

function CommonSelectPage:_GetCacheOutpostInfo()
  return self.m_cachOutpostFids
end

function CommonSelectPage:_SetBuildingData(data)
  self.m_buildingData = data
end

function CommonSelectPage:_GetBuildingData()
  return self.m_buildingData
end

function CommonSelectPage:DoOnHide()
  self:_SaveSortData()
end

function CommonSelectPage:DoOnClose()
  self:_SaveSortData()
end

return CommonSelectPage
