local SortLogic = class("logic.SortLogic")

function SortLogic:initialize()
  self:ResetData()
end

function SortLogic:ResetData()
  self.sortParamTab = {}
end

function SortLogic:LoadBuildingSort(key)
  local userId = Data.userData:GetUserUid()
  local str = PlayerPrefs.GetString(string.format("%s%s", userId, key), "")
  if str ~= "" then
    local data = Unserialize(str)
    return data
  end
  return nil
end

function SortLogic:SaveBuildingSort(key, selectData)
  local userId = Data.userData:GetUserUid()
  local str = Serialize(selectData) or ""
  PlayerPrefs.SetString(string.format("%s%s", userId, key), str)
end

function SortLogic:InitBuildingSort()
  local selectData = self:LoadBuildingSort(BuildingSortKey.BuildingList)
  if selectData then
    self.sortParamTab[CommonHeroItem.BuildingList] = {
      sortway = selectData[1],
      sortParam = selectData[2]
    }
  else
    self.sortParamTab[CommonHeroItem.BuildingList] = {
      sortway = true,
      sortParam = {
        {},
        2
      }
    }
  end
  selectData = self:LoadBuildingSort(BuildingSortKey.BuildingHero)
  if selectData then
    self.sortParamTab[CommonHeroItem.Building] = {
      sortway = selectData[1],
      sortParam = selectData[2]
    }
  else
    self.sortParamTab[CommonHeroItem.Building] = {
      sortway = true,
      sortParam = {
        {},
        1
      }
    }
  end
end

function SortLogic:SetHeroSort(type, selectData)
  self.sortParamTab[type] = {
    sortway = selectData[1],
    sortParam = selectData[2]
  }
end

function SortLogic:GetHeroSort(type)
  local selectData = {}
  if not self.sortParamTab[CommonHeroItem.BuildingList] or not self.sortParamTab[CommonHeroItem.Building] then
    self:InitBuildingSort()
  end
  if self.sortParamTab[type] == nil then
    if type == CommonHeroItem.Fleet or type == CommonHeroItem.ChangeSecretaryFleet or type == CommonHeroItem.ShipTask then
      self.sortParamTab[type] = {
        sortway = true,
        sortParam = {
          {},
          HeroSortType.Lvl
        }
      }
    elseif type == CommonHeroItem.Picture or type == CommonHeroItem.Strengthen or type == CommonHeroItem.IllustrateEquip or type == CommonHeroItem.RemouldPic then
      self.sortParamTab[type] = {
        sortway = false,
        sortParam = {
          {},
          HeroSortType.Rarity
        }
      }
    elseif type == CommonHeroItem.ShopFashion or type == CommonHeroItem.ShopBrokenFashion then
      self.sortParamTab[type] = {
        sortway = false,
        sortParam = {
          {},
          HeroSortType.FASHION_Own,
          false
        }
      }
    else
      self.sortParamTab[type] = {
        sortway = true,
        sortParam = {
          {},
          HeroSortType.Rarity
        }
      }
    end
  end
  selectData[1] = self.sortParamTab[type].sortway
  selectData[2] = self.sortParamTab[type].sortParam
  return selectData
end

function SortLogic:SetHeroSortTemp(type, selectData)
  self.sortParamTemp = self.sortParamTemp or {}
  self.sortParamTemp[type] = {
    sortway = selectData[1],
    sortParam = selectData[2]
  }
end

function SortLogic:GetHeroSortTemp(type)
  self.sortParamTemp = self.sortParamTemp or {}
  if not next(self.sortParamTemp) or self.sortParamTemp[type] == nil then
    if type == CommonHeroItem.BathRoom then
      local sortSetting = self:GetServerSort("BathRoomSort")
      local way = sortSetting and sortSetting[1] or false
      local param = sortSetting and sortSetting[2] or {
        {},
        HeroSortType.BathFleet
      }
      self.sortParamTemp[CommonHeroItem.BathRoom] = {sortway = way, sortParam = param}
    elseif type == CommonHeroItem.TowerFleet then
      self.sortParamTemp[CommonHeroItem.TowerFleet] = {
        sortway = true,
        sortParam = {
          {},
          HeroSortType.AttackGrade
        }
      }
    end
  end
  local selectData = {
    true,
    {
      {},
      HeroSortType.Lvl
    }
  }
  if self.sortParamTemp[type] then
    selectData[1] = self.sortParamTemp[type].sortway
    selectData[2] = self.sortParamTemp[type].sortParam
  end
  return selectData
end

function SortLogic:ClearHeroSortTemp()
  self.sortParamTemp = {}
end

function SortLogic:GetServerSort(key)
  local tblValue
  local setValue = Data.guideData:GetSettingByKey(key)
  if setValue then
    tblValue = Unserialize(setValue)
  end
  return tblValue
end

return SortLogic
