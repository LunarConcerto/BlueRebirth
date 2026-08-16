DropRewardsHelper = {}
local m_hasGirl = {}

function DropRewardsHelper.RecordsHasGirl()
  m_hasGirl = Logic.shipLogic:GetAllHeroSfId()
end

function DropRewardsHelper.DropGirls(rewards)
  if rewards then
    local sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(rewards)
    if sm_id then
      local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
      local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
      if m_hasGirl[sf_id] ~= nil then
        return
      end
      UIHelper.OpenPage("ShowGirlPage", {girlId = si_id, HeroId = heroId})
    end
  end
end

function DropRewardsHelper.DropGoods(rewards)
  if rewards then
    local param = {Rewards = rewards}
    UIHelper.OpenPage("GetRewardsPage", param)
  end
end

function DropRewardsHelper.GetDropDisplay(dropList)
  local tabAfterDropInfoId = {}
  for k, v in ipairs(dropList) do
    local data = configManager.GetDataById("config_drop_info", v)
    local inPeriod = true
    if data.period ~= nil and data.period > 0 then
      inPeriod = PeriodManager:IsInPeriod(data.period)
    end
    if inPeriod then
      local show_num = data.show_num
      if show_num == 0 then
        for key, value in ipairs(data.item_info) do
          local goodsInfo = Logic.bagLogic:GetItemByTempateId(value[1], value[2])
          goodsInfo.itemInfo = data
          if value[3] then
            goodsInfo.drop_num = value[3]
          end
          table.insert(tabAfterDropInfoId, goodsInfo)
        end
      elseif show_num == 1 then
        local goodsInfo = Logic.itemLogic:GetMaxQuailtyGoods(data.item_info)
        goodsInfo.itemInfo = data
        table.insert(tabAfterDropInfoId, goodsInfo)
      elseif 1 < show_num then
        for index = 1, show_num do
          local value = data.item_info[index]
          local goodsInfo = Logic.bagLogic:GetItemByTempateId(value[1], value[2])
          goodsInfo.itemInfo = data
          if value[3] then
            goodsInfo.drop_num = value[3]
          end
          table.insert(tabAfterDropInfoId, goodsInfo)
        end
      end
    end
  end
  return tabAfterDropInfoId
end

function DropRewardsHelper.GetDropDisplayCopy(dropList)
  local tabAfterDropInfoId = {}
  for k, v in ipairs(dropList) do
    local data = configManager.GetDataById("config_drop_info", v)
    local inPeriod = true
    if data.period ~= nil and data.period > 0 then
      inPeriod = PeriodManager:IsInPeriod(data.period)
    end
    if inPeriod then
      local show_num = data.out_show_num
      if show_num == 0 then
        for key, value in ipairs(data.item_info) do
          table.insert(tabAfterDropInfoId, value)
        end
      elseif 1 <= show_num then
        for index = 1, show_num do
          table.insert(tabAfterDropInfoId, data.item_info[index])
        end
      end
    end
  end
  return tabAfterDropInfoId
end
