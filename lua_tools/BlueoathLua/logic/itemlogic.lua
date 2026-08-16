local ItemLogic = class("logic.ItemLogic")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ItemLogic:GetIcon(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.icon
end

function ItemLogic:GetSmallIcon(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.icon_small
end

function ItemLogic:GetName(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.name
end

function ItemLogic:GetDesc(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.description
end

function ItemLogic:GetQuality(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.quality
end

function ItemLogic:GetFrame(id)
  return "", ""
end

function ItemLogic:GetTexIcon(id)
  local config = configManager.GetDataById("config_item_info", id)
  return config.icon
end

function ItemLogic:GetMaxQuailtyGoods(itemInfo)
  local goodInfo
  for _, v in ipairs(itemInfo) do
    local temp = Logic.bagLogic:GetItemByTempateId(v[1], v[2])
    if not goodInfo then
      goodInfo = temp
    else
      goodInfo = temp.quality > goodInfo.quality and temp or goodInfo
    end
  end
  return goodInfo
end

function ItemLogic:ShowItemInfo(tabIndex, itemId)
  if tabIndex == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = itemId,
      showEquipType = ShowEquipType.Simple
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(tabIndex, itemId))
  end
end

function ItemLogic:GetConfByDropId(dropId)
  local dropInfo = {}
  local rewardList = Logic.rewardLogic:GetAllShowRewardByDropId(dropId)
  for _, v in ipairs(rewardList) do
    local goodsType = v.Type
    local tId = v.ConfigId
    dropInfo[tId] = Logic.bagLogic:GetItemByTempateId(goodsType, tId)
  end
  return dropInfo, rewardList
end

function ItemLogic:GetItemOwnCount(data)
  local value = 0
  local showObj = false
  if data.type and data.type == GoodsType.ITEM then
    local tableInfo = Logic.bagLogic:GetItemByConfig(data.id)
    if tableInfo.show_type and tableInfo.show_type ~= 0 then
      showObj = false
      return showObj, value
    end
  end
  if data.type and data.type == GoodsType.INTERACTION_BAG_ITEM then
    showObj = false
    return showObj, value
  end
  if data.type and data.type == GoodsType.CURRENCY then
    value = Data.userData:GetCurrency(data.id)
    if data.id == CurrencyType.ShipExp or data.id == CurrencyType.UserExp then
      showObj = false
    else
      showObj = true
    end
  elseif data.type and (data.type == GoodsType.SHIP or data.type == GoodsType.FASHION or data.type == GoodsType.MEDAL) then
    showObj = false
  elseif data.id then
    local tabIndex = Logic.bagLogic:GetItemTypeByTid(data.id)
    if 0 < tabIndex then
      local tableInfo = Logic.shopLogic:GetTableIndexConfById(tabIndex)
      if tableInfo.bag_index == 1 then
        local bagInfo = Logic.bagLogic:ItemInfoById(data.id)
        value = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
      end
      showObj = true
    end
  end
  return showObj, value
end

function ItemLogic:GetConfByItemTab(itemTab)
  local dropInfo = {}
  local rewardList = {}
  for _, v in ipairs(itemTab) do
    table.insert(rewardList, {
      Type = v[1],
      ConfigId = v[2],
      Num = v[3]
    })
    dropInfo[v[2]] = Logic.bagLogic:GetItemByTempateId(v[1], v[2])
  end
  return dropInfo, rewardList
end

function ItemLogic:GetDiscountConfig(id)
  return configManager.GetDataById("config_discount_item", id)
end

return ItemLogic
