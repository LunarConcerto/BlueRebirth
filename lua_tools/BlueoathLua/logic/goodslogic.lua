local GoodsLogic = class("logic.GoodsLogic")

function GoodsLogic:initialize()
end

function GoodsLogic:ResetData()
  self.isFirstIn = true
  self.equipOpen = false
end

function GoodsLogic:GetLogic(goodsType)
  local t = {
    [GoodsType.SHIP] = Logic.shipLogic,
    [GoodsType.ITEM] = Logic.itemLogic,
    [GoodsType.EQUIP] = Logic.equipLogic,
    [GoodsType.CURRENCY] = Logic.currencyLogic,
    [GoodsType.EQUIP_ENHANCE_ITEM] = Logic.equipEnhanceItemLogic,
    [GoodsType.TALENT_UPGRADE_ITEM] = Logic.talentUpgradeItemLogic,
    [GoodsType.ITEM_SELECTED] = Logic.itemSelectLogic,
    [GoodsType.MEDAL] = Logic.medalLogic,
    [GoodsType.COMMAND] = Logic.assistNewLogic,
    [GoodsType.WISH] = Logic.wishLogic,
    [GoodsType.Fragment] = Logic.fragmentLogic,
    [GoodsType.FASHION] = Logic.fashionLogic
  }
  return t[goodsType]
end

function GoodsLogic:GetIcon(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetIcon(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.icon
  end
end

function GoodsLogic:GetSmallIcon(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetSmallIcon(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.icon_small
  end
end

function GoodsLogic:GetName(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetName(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.name
  end
end

function GoodsLogic:GetDesc(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetDesc(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.description
  end
end

function GoodsLogic:GetQuality(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetQuality(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.quality
  end
end

function GoodsLogic:GetFrame(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetFrame(goodsId)
  else
    return "", ""
  end
end

function GoodsLogic:GetTexIcon(goodsId, goodsType)
  if goodsType == GoodsType.SHIP then
    goodsId = Logic.shipLogic:GetShipInfoId(goodsId)
  end
  if GoodsLogic:GetLogic(goodsType) then
    return GoodsLogic:GetLogic(goodsType):GetTexIcon(goodsId)
  else
    local configItem = self:GetConfigByTypeAndId(goodsId, goodsType)
    return configItem.icon
  end
end

function GoodsLogic:GetConfigByTypeAndId(goodsId, goodsType)
  if goodsType == GoodsType.RECHARGE then
    goodsType = GoodsType.CURRENCY
    goodsId = CurrencyType.DIAMOND
  end
  local config = configManager.GetDataById("config_table_index", goodsType)
  return configManager.GetDataById(config.file_name, goodsId)
end

function GoodsLogic.AnalyGoodsList(args)
  local arrDisplay = {}
  for i, data in ipairs(args) do
    table.insert(arrDisplay, GoodsLogic.AnalyGoods(data))
  end
  return arrDisplay
end

function GoodsLogic.AnalyGoods(args)
  local Type = args.Type
  local ConfigId = args.ConfigId
  local display = {}
  display.Type = Type
  display.ConfigId = ConfigId
  display.Num = args.Num
  display.iconSprite, display.iconAtlas = GoodsLogic:GetIcon(ConfigId, Type)
  display.texIcon = GoodsLogic:GetTexIcon(ConfigId, Type)
  display.name = GoodsLogic:GetName(ConfigId, Type)
  display.frameSprite, display.frameAtlas = GoodsLogic:GetFrame(ConfigId, Type)
  display.quality = GoodsLogic:GetQuality(ConfigId, Type)
  display.desc = GoodsLogic:GetDesc(ConfigId, Type)
  return display
end

return GoodsLogic
