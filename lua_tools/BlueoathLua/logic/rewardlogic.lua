local RewardLogic = class("logic.RewardLogic")

function RewardLogic:CanGotReward(tabReward, showMsg, equipNum, heroNum, totalNum)
  totalNum = totalNum ~= nil and totalNum or 1
  if tabReward == nil or #tabReward == 0 then
    return true
  end
  local equipCount = 0
  local heroCount = 0
  for i = 1, #tabReward do
    if #tabReward[i] == 3 then
      local itemType = tonumber(tabReward[i][1])
      if itemType == GoodsType.EQUIP then
        equipCount = equipCount + tonumber(tabReward[i][3])
        if equipNum ~= nil and equipNum <= equipCount then
          break
        end
      elseif itemType == GoodsType.SHIP then
        heroCount = heroCount + tonumber(tabReward[i][3])
        if heroNum ~= nil and heroNum <= heroCount then
          break
        end
      end
    end
  end
  if 0 < equipCount then
    local currCount = Logic.equipLogic:GetEquipOccupySize()
    local maxCount = Data.equipData:GetEquipBagSize()
    equipCount = equipCount * totalNum
    if maxCount < equipCount + currCount then
      if showMsg then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ClickDismantlePageOk()
            end
          end,
          nameOk = "\230\139\134\232\167\163"
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(170016), tabParams)
      end
      return false
    end
  end
  if 0 < heroCount then
    local currCount = Logic.dockLogic:GetCurrShipCount()
    local maxCount = Logic.shipLogic:GetBaseShipNum()
    if maxCount < heroCount + currCount then
      if showMsg then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              self:_ClikDockPageOk()
            end
          end,
          nameOk = "\233\128\128\229\189\185"
        }
        noticeManager:ShowMsgBox(110012, tabParams)
      end
      return false
    end
  end
  return true
end

function RewardLogic:_ClickDismantlePageOk()
  UIHelper.ClosePage("ItemInfoPage")
  UIHelper.OpenPage("DismantlePage")
end

function RewardLogic:_ClikDockPageOk()
  UIHelper.OpenPage("HeroRetirePage")
end

function RewardLogic:_countRewardListByDropId(dropId, isShow)
  local rewardList = {}
  local conf = configManager.GetDataById("config_drop_item", dropId)
  if conf == nil then
    return rewardList
  end
  local f = function(drop, count)
    for i = 1, #drop do
      local tableIndex = drop[i][1]
      local configId = drop[i][2]
      local minNum = drop[i][3] * count
      local maxNum = drop[i][4] * count
      local weight = drop[i][5]
      local limiTimeIsOk = true
      if 6 <= #drop[i] and time.getSvrTime() < drop[i][6] then
        limiTimeIsOk = false
      end
      if weight ~= 0 and limiTimeIsOk then
        if tableIndex == GoodsType.DROP then
          local arr = self:_countRewardListByDropId(configId, isShow)
          for j = 1, #arr do
            table.insert(rewardList, arr[j])
          end
        else
          local num = minNum .. "~" .. maxNum
          if minNum == maxNum then
            num = minNum
          end
          if isShow then
            table.insert(rewardList, {
              Type = tableIndex,
              ConfigId = configId,
              Num = num
            })
          else
            table.insert(rewardList, {
              tableIndex,
              configId,
              maxNum
            })
          end
        end
      end
    end
  end
  if conf.drop_rate > 0 then
    f(conf.drop, 1)
  end
  if 0 < conf.drop_alone_count then
    f(conf.drop_alone, 1)
  end
  return rewardList
end

function RewardLogic:GetAllRewardByDropId(dropId)
  return self:_countRewardListByDropId(dropId, false)
end

function RewardLogic:GetAllShowRewardByDropId(dropId)
  return self:_countRewardListByDropId(dropId, true)
end

function RewardLogic:GetDropCountByDropId(dropId)
  local conf = configManager.GetDataById("config_drop_item", dropId)
  if conf == nil or conf.drop_rate == 0 then
    return 0
  end
  return conf.drop_count
end

local dotMap = {
  SignPage = "sign_get",
  SelectRandTreasurePage = "treasure_get",
  SelectTreasurePage = "treasure_get"
}
local get = {
  PlotPage = GetGirlWay.plot
}

function RewardLogic:ShowCommonReward(rewards, pageName, closeCallBack, rewardType, transReward)
  local params = {
    Rewards = rewards,
    Page = pageName,
    RewardType = rewardType
  }
  local isHero, siIdTab, heroIdTab = self:_CheckHeroInReward(rewards)
  local isFashion, ssIdTab, fashionIdTab = self:_CheckFashionInReward(rewards)
  
  function params.callBack()
    if closeCallBack then
      local plotCheck = get[pageName] == GetGirlWay.plot and isHero
      if not plotCheck then
        closeCallBack()
      end
    end
    if isHero then
      local param = {
        girlId = siIdTab,
        HeroId = heroIdTab,
        getWay = get[pageName],
        transReward = transReward
      }
      if param.getWay == GetGirlWay.plot then
        param.callback = closeCallBack
      end
      UIHelper.OpenPage("ShowGirlPage", param)
      if dotMap[pageName] then
        local name = self:_DotGetHeroReward(siIdTab)
        local dotinfo = {
          info = dotMap[pageName],
          ship_name = name
        }
        RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      end
    elseif isFashion then
      local param = {
        girlId = ssIdTab,
        showType = ShowGirlType.Fashion,
        fashionTab = fashionIdTab
      }
      UIHelper.OpenPage("ShowGirlPage", param)
    end
  end
  
  UIHelper.OpenPage("GetRewardsPage", params)
end

function RewardLogic:_DotGetHeroReward(si_ids)
  local res = {}
  for _, id in ipairs(si_ids) do
    table.insert(res, Logic.shipLogic:GetName(id))
  end
  return res
end

function RewardLogic:_CheckHeroInReward(rewards)
  local isHero = false
  local si_idTab = {}
  local heroIdTab = {}
  for _, reward in ipairs(rewards) do
    if reward.Type == GoodsType.SHIP then
      isHero = true
      local si_id = Logic.shipLogic:GetShipInfoId(reward.ConfigId)
      table.insert(si_idTab, si_id)
      table.insert(heroIdTab, reward.Id)
    end
  end
  return isHero, si_idTab, heroIdTab
end

function RewardLogic:FormatReward(rewards)
  local res = {}
  for k, v in ipairs(rewards) do
    local temp = {}
    temp.Type = v[1]
    temp.ConfigId = v[2]
    temp.Num = v[3]
    table.insert(res, temp)
  end
  return res
end

function RewardLogic:FormatRewardById(rewardId)
  if rewardId == 0 then
    return {}
  end
  local rewardConf = configManager.GetDataById("config_rewards", rewardId)
  if rewardConf == nil or next(rewardConf) == nil then
    logError("reward id not in reward config. id:" .. rewardId)
    return {}
  end
  return self:FormatReward(rewardConf.rewards)
end

function RewardLogic:FormatRewardParam(...)
  local param = {
    ...
  }
  self:FormatRewardByIds(param)
end

function RewardLogic:FormatRewardByIds(rewardIds)
  local res = {}
  for _, rewardId in pairs(rewardIds) do
    local reward = self:FormatRewardById(rewardId)
    if next(reward) ~= nil then
      table.insert(res, self:FormatRewardById(rewardId))
    end
  end
  return res
end

function RewardLogic:FormatRewards(rewardIds)
  local map = {}
  for _, rewardId in pairs(rewardIds) do
    local rewardConf = configManager.GetDataById("config_rewards", rewardId)
    for k, v in pairs(rewardConf.rewards) do
      local temp = {}
      temp.Type = v[1]
      temp.ConfigId = v[2]
      temp.Num = v[3]
      if map[temp.Type] == nil then
        map[temp.Type] = {}
      end
      if map[temp.Type][temp.ConfigId] then
        map[temp.Type][temp.ConfigId].Num = temp.Num + map[temp.Type][temp.ConfigId].Num
      else
        map[temp.Type][temp.ConfigId] = temp
      end
    end
  end
  local res = {}
  for typ, rewardInfo in pairs(map) do
    for configId, item in pairs(rewardInfo) do
      table.insert(res, item)
    end
  end
  return res
end

function RewardLogic:CanGotShip(shipCount)
  local currCount = Logic.dockLogic:GetCurrShipCount()
  local maxCount = Logic.shipLogic:GetBaseShipNum()
  if maxCount < shipCount + currCount then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClikDockPageOk()
        end
      end,
      nameOk = "\233\128\128\229\189\185"
    }
    noticeManager:ShowMsgBox(110012, tabParams)
    return false
  end
  return true
end

function RewardLogic:CanGotEquip(equipCount)
  if Logic.equipLogic:IsEquipBagFullAfterAdd(equipCount) then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_ClickDismantlePageOk()
        end
      end,
      nameOk = "\230\139\134\232\167\163"
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(170016), tabParams)
    return false
  end
  return true
end

function RewardLogic:OnClickDropItem(itemInfo, dropInfoIds)
  if itemInfo.type == 2 then
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.DROP, itemInfo.id))
  else
    local tabInfo = {ItemInfo = itemInfo, TabCopyDropInfo = dropInfoIds}
    UIHelper.OpenPage("DropInfoPage", tabInfo)
  end
end

function RewardLogic:Test_MergeSameItem()
  local test_param = {
    {
      Type = 1,
      ConfigId = 10000,
      Num = 10
    },
    {
      Type = 3,
      ConfigId = 30003,
      Num = 100
    },
    {
      Type = 6,
      ConfigId = 60002,
      Num = 500
    },
    {
      Type = 11,
      ConfigId = 110002,
      Num = 20
    },
    {
      Type = 2,
      ConfigId = 20000,
      Num = 10
    },
    {
      Type = 2,
      ConfigId = 20000,
      Num = 150
    },
    {
      Type = 1,
      ConfigId = 10000,
      Num = 256
    },
    {
      Type = 7,
      ConfigId = 70002,
      Num = 15
    },
    {
      Type = 1,
      ConfigId = 10000,
      Num = 10
    }
  }
  Logic.rewardLogic:MergeSameItem(test_param)
end

function RewardLogic:MergeSameItem(items)
  if #items <= 1 then
    return items
  end
  local middle = {}
  for _, v in ipairs(items) do
    local temp = {
      Type = v.Type,
      ConfigId = v.ConfigId,
      Num = v.Num
    }
    table.insert(middle, temp)
  end
  items = middle
  table.sort(items, function(data1, data2)
    if data1.Type ~= data2.Type then
      return data1.Type < data2.Type
    elseif data1.ConfigId ~= data2.ConfigId then
      return data1.ConfigId < data2.ConfigId
    else
      return data1.Num < data2.Num
    end
  end)
  local res = {}
  local pole = items[1]
  local sum = pole.Num
  table.insert(res, pole)
  for i = 2, #items do
    if self:IsSame(pole, items[i]) then
      sum = sum + items[i].Num
      res[#res].Num = sum
    else
      pole = items[i]
      sum = pole.Num
      table.insert(res, pole)
    end
  end
  return res
end

function RewardLogic:IsSame(item1, item2)
  return item1.Type == item2.Type and item1.ConfigId == item2.ConfigId
end

function RewardLogic:MergeTblReward(...)
  local allReward = {}
  local mergeAllReward = {
    ...
  }
  for _, mergeReward in ipairs(mergeAllReward) do
    for i = 1, #mergeReward do
      local rewardList = mergeReward[i].Reward
      for m = 1, #rewardList do
        local isHave = false
        for n = 1, #allReward do
          if allReward[n].Type == rewardList[m].Type and allReward[n].ConfigId == rewardList[m].ConfigId then
            isHave = true
            allReward[n].Num = allReward[n].Num + rewardList[m].Num
            break
          end
        end
        if not isHave then
          table.insert(allReward, rewardList[m])
        end
      end
    end
  end
  return allReward
end

function RewardLogic:ShowFashionAndReward(showParam)
  local rewards = showParam.rewards
  local pageName = showParam.pageName
  local dontMerge = showParam.dontMerge ~= nil and showParam.dontMerge or false
  local rewardParams = {
    Rewards = rewards,
    Page = pageName,
    DontMerge = dontMerge
  }
  local isFashion, ssIdTab, fashionIdTab = Logic.rewardLogic:_CheckFashionInReward(rewards)
  if isFashion then
    local fashionParam = {
      girlId = ssIdTab,
      showType = ShowGirlType.Fashion,
      fashionTab = fashionIdTab
    }
    
    function fashionParam.callback()
      UIHelper.OpenPage("GetRewardsPage", rewardParams)
    end
    
    UIHelper.OpenPage("ShowGirlPage", fashionParam)
  else
    UIHelper.OpenPage("GetRewardsPage", rewardParams)
  end
end

function RewardLogic:_CheckFashionInReward(rewards)
  local isFashion = false
  local ss_idTab = {}
  local fashionIdTab = {}
  for _, reward in ipairs(rewards) do
    if reward.Type == GoodsType.FASHION then
      isFashion = true
      local ss_id = configManager.GetDataById("config_fashion", reward.ConfigId).ship_show_id
      table.insert(ss_idTab, ss_id)
      table.insert(fashionIdTab, reward.ConfigId)
    end
  end
  return isFashion, ss_idTab, fashionIdTab
end

function RewardLogic:ShowFashion(showParam)
  local rewards = showParam.rewards
  local isFashion, ssIdTab, fashionTabId = Logic.rewardLogic:_CheckFashionInReward(rewards)
  if isFashion then
    local fashionParam = {
      girlId = ssIdTab,
      showType = ShowGirlType.Fashion,
      fashionTab = fashionTabId
    }
    UIHelper.OpenPage("ShowGirlPage", fashionParam)
  end
end

function RewardLogic:GetPossessNum(typ, id)
  if typ == GoodsType.EQUIP then
    return Logic.equipLogic:GetEquipCanCostNum(id)
  elseif typ == GoodsType.SHIP then
    return Data.heroData:GetHeroCountByTemplateId(id)
  elseif typ == GoodsType.CURRENCY then
    return Data.userData:GetCurrency(id)
  else
    return Logic.bagLogic:GetBagItemNum(id)
  end
end

function RewardLogic:ShowReward(typ, id)
  if typ == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = id,
      showEquipType = ShowEquipType.Simple
    })
  else
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(typ, id))
  end
end

function RewardLogic:MedalReplaceReward(rewards)
  local showReplace = false
  local showReward = {}
  local medalId = 0
  if rewards == nil or next(rewards) == nil then
    return showReplace, showReward
  end
  for _, v in ipairs(rewards) do
    if v.Type == GoodsType.MEDAL then
      showReplace = true
      medalId = v.ConfigId
      break
    end
  end
  if not showReplace then
    return showReplace, showReward
  end
  local medalReplaceReward = Data.userData:GetMedalReplaceReward().MedalReplaceReward
  if medalReplaceReward == nil then
    local userInfo = Data.userData:GetUserData()
    local data = Logic.userLogic:GetMedalIdTab(userInfo.MedalAcquiredTime)
    local isFind = false
    for _, v in ipairs(data) do
      if v == medalId then
        isFind = true
      end
    end
    if not isFind then
      return false, showReward
    end
    local config = configManager.GetDataById("config_medal", medalId)
    showReward = RewardLogic:FormatRewardById(config.reward)
  elseif next(medalReplaceReward) ~= nil then
    for _, v in ipairs(medalReplaceReward) do
      for _, reward in ipairs(v.Reward) do
        table.insert(showReward, reward)
      end
    end
  end
  return showReplace, showReward
end

return RewardLogic
