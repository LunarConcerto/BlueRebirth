local MubarOutpostLogic = class("logic.MubarOutpostLogic")

function MubarOutpostLogic:initialize()
  self:ResetData()
end

function MubarOutpostLogic:ResetData()
end

function MubarOutpostLogic:GetOutPostInfoByChapterId(chapterId)
  local chapterInfo = configManager.GetDataById("config_chapter", chapterId)
  if chapterInfo ~= nil then
    local outPostId = chapterInfo.outpost_id
    if outPostId then
      return outPostId
    end
  end
  return nil
end

function MubarOutpostLogic:CheckBuildingConditionCanSelect(buildingId, selectShips)
  local canSelect = false
  local errMsg
  if not selectShips then
    return true, nil
  else
    for i = 1, #selectShips do
      if selectShips[i] then
        local isInOutPost, outpostId = self:CheckHeroIsInOutpostId(selectShips[i])
        if isInOutPost then
          if outpostId == buildingId then
          else
            errMsg = UIHelper.GetString(4600020)
            return false, -1
          end
        else
          local inBuilding = Data.buildingData:IsInBuilding(selectShips[i])
          if inBuilding then
            errMsg = UIHelper.GetString(4600018)
            return false, -2
          end
          local inBath = Logic.bathroomLogic:CheckInBath(selectShips[i])
          if inBath then
            return false, -3
          end
        end
      end
    end
  end
  return true, nil
end

function MubarOutpostLogic:CheckHeroIsInOutpost(heroId)
  local isInOutPost, _ = self:CheckHeroIsInOutpostId(heroId)
  return isInOutPost
end

function MubarOutpostLogic:CheckHeroIsInOutpostId(heroId)
  local isInOutPost = false
  local allOutpostData = Data.mubarOutpostData:GetOutPostData()
  if allOutpostData then
    for i = 1, #allOutpostData do
      if allOutpostData[i].HeroList ~= nil then
        for j = 1, #allOutpostData[i].HeroList do
          if allOutpostData[i].HeroList[j] == heroId then
            return true, allOutpostData[i].Id
          end
        end
      end
    end
  end
  return isInOutPost, nil
end

function MubarOutpostLogic:GetDropByBattlePower(power, configPower)
  local rate = 100
  for i = 1, #configPower do
    if power >= tonumber(configPower[i][1]) then
      rate = configPower[i][2]
    end
  end
  return rate
end

function MubarOutpostLogic:CheckLevelUpCondition(outpostId, level)
  local msg
  if 6 < level then
    return false, "level is cannot levelUp"
  end
  local currentLevelConfig = Data.mubarOutpostData:GetCurrentLevelData(outpostId, level - 1)
  local costConfig = currentLevelConfig.item_cost
  if costConfig then
    for i = 1, #costConfig do
      local num = Logic.bagLogic:GetConsumeCurrNum(costConfig[i][1], costConfig[i][2])
      if num < costConfig[i][3] then
        return false, "\230\157\144\230\150\153\228\184\141\232\182\179"
      end
    end
  end
  return true, nil
end

function MubarOutpostLogic:GetMubarOutpostCostBathCoin()
  local coin = 0
  local infoConfig = configManager.GetDataById("config_parameter", 406)
  if infoConfig then
    coin = infoConfig.arrValue[1]
  end
  return coin
end

function MubarOutpostLogic:GetBathCoinIsEnough()
  local cost = self:GetMubarOutpostCostBathCoin()
  local haveNum = Data.userData:GetCurrency(13)
  return cost <= haveNum
end

function MubarOutpostLogic:CheckOutpostHaveReward()
  local allOutpostData = Data.mubarOutpostData:GetOutPostData()
  if allOutpostData then
    for i = 1, #allOutpostData do
      if allOutpostData[i].ItemInfo then
        for j = 1, #allOutpostData[i].ItemInfo do
          if 1 <= allOutpostData[i].ItemInfo[j].Num and allOutpostData[i].ItemInfo[j].ConfigId ~= 1 and allOutpostData[i].ItemInfo[j].Type ~= 5 then
            return true
          end
        end
      end
    end
  end
  return false
end

return MubarOutpostLogic
