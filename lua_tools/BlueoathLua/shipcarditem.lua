local ShipCardItem = class("ShipCardItem")
local QualityType = {
  VerCardQualityImg,
  HorizontalCardQulity,
  FleetSmallCardQualityImg,
  FleetBottomCardQulity,
  FleetLevelDetsCardQulity
}

function ShipCardItem:LoadVerticalCard(heroId, tabPart, mType, addMarriageEffCB, fleetType)
  fleetType = fleetType or FleetType.Normal
  tabPart = tabPart:GetLuaTableParts()
  local shipInfo = Data.heroData:GetHeroById(heroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoById(shipInfo.TemplateId)
  local shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(heroId)
  if tabPart.tx_lv then
    tabPart.tx_lv.text = shipInfo.Lvl
  end
  if tabPart.star and tabPart.trans_star then
    UIHelper.SetStar(tabPart.star, tabPart.trans_star, shipInfo.Advance)
  end
  local ship_name = Logic.shipLogic:GetRealName(heroId)
  UIHelper.SetText(tabPart.tx_name, ship_name)
  if mType == nil then
    mType = VerCardType.Normal
    UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
    UIHelper.SetImage(tabPart.bg_quality, QualityType[mType][shipInfo.quality])
  else
    UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
    UIHelper.SetImage(tabPart.bg_quality, QualityType[mType][shipInfo.quality])
  end
  if shipShowConfig.ship_icon2 ~= "1" and shipShowConfig.ship_icon2_po ~= "1" then
    local maxHp = Logic.shipLogic:GetHeroMaxHp(heroId, fleetType)
    local curHp = Logic.shipLogic:GetHeroHp(heroId, fleetType)
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, maxHp)
    if mType == VerCardType.FleetBottom or mType == VerCardType.LevelDetails then
      if hpStatus < DamageLevel.MiddleDamage then
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon2)
      else
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon2_po)
      end
    elseif mType == VerCardType.Normal then
      if hpStatus < DamageLevel.MiddleDamage then
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon2)
      else
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon2_po)
      end
    elseif mType == VerCardType.FleetSmall then
      if hpStatus < DamageLevel.MiddleDamage then
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon1_back)
      else
        UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon1_po_back)
      end
    elseif hpStatus < DamageLevel.MiddleDamage then
      UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon1)
    else
      UIHelper.SetImage(tabPart.im_girl, shipShowConfig.ship_icon1_po)
    end
  end
  if not npcAssistFleetMgr:IsNpcHeroId(heroId) then
    if tabPart.im_mood then
      local moodInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
      if moodInfo then
        UIHelper.SetImage(tabPart.im_mood, moodInfo.mood_icon)
        tabPart.im_mood.gameObject:SetActive(moodInfo.mood_id == 1)
      end
      if tabPart.tx_mood then
        UIHelper.SetText(tabPart.tx_mood, "\229\191\131\230\131\133" .. num)
      end
    end
    if tabPart.im_love then
      local loveInfo, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
      if loveInfo then
      end
      local isCanLove = Logic.marryLogic:isCanMarry(heroId)
      tabPart.im_love.gameObject:SetActive(isCanLove)
      if tabPart.obj_canMarry then
        tabPart.obj_canMarry:SetActive(isCanLove)
        tabPart.im_love.gameObject:SetActive(false)
      end
    end
    if tabPart.im_kuang then
      local marryInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if marryInfo.MarryTime then
        tabPart.im_kuang.gameObject:SetActive(marryInfo.MarryTime ~= 0)
      end
    end
    local loveInfo1, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
    if tabPart.tx_love then
      UIHelper.SetText(tabPart.tx_love, "\229\165\189\230\132\159\229\186\166" .. num1)
    end
    if tabPart.obj_eff then
      local effInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if effInfo.MarryTime then
        tabPart.obj_eff.gameObject:SetActive(effInfo.MarryTime ~= 0)
        if effInfo.MarryTime ~= 0 and addMarriageEffCB then
          addMarriageEffCB()
        end
      end
    end
  else
    if tabPart.im_mood then
      tabPart.im_mood.gameObject:SetActive(false)
    end
    if tabPart.im_love then
      tabPart.im_love.gameObject:SetActive(false)
    end
    if tabPart.im_kuang then
      tabPart.im_kuang.gameObject:SetActive(false)
    end
    if tabPart.obj_eff then
      tabPart.obj_eff.gameObject:SetActive(false)
    end
  end
end

function ShipCardItem:LoadHorizontalCard(heroId, tabPart)
  tabPart = tabPart:GetLuaTableParts()
  local tabShipInfo = Data.heroData:GetHeroById(heroId)
  local shipInfoConfig = Logic.shipLogic:GetShipInfoById(tabShipInfo.TemplateId)
  local shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(heroId)
  local shipInfo = Data.heroData:GetHeroById(heroId)
  UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
  UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
  UIHelper.SetImage(tabPart.bg_quality, HorizontalCardQulity[shipInfo.quality])
  if tabPart.tx_name then
    local ship_name = Logic.shipLogic:GetRealName(heroId)
    UIHelper.SetText(tabPart.tx_name, ship_name)
  end
  if shipShowConfig.ship_icon1 ~= "1" and shipShowConfig.ship_icon1_po ~= "1" then
    local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(tabShipInfo.HeroId)
    local curHp = Logic.shipLogic:GetHeroHp(tabShipInfo.HeroId)
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
    if hpStatus < DamageLevel.MiddleDamage then
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon1), true)
    else
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon1_po), true)
    end
  end
  if not npcAssistFleetMgr:IsNpcHeroId(heroId) then
    if tabPart.im_mood then
      local moodInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
      if moodInfo then
        UIHelper.SetImage(tabPart.im_mood, moodInfo.mood_icon)
        tabPart.im_mood.gameObject:SetActive(moodInfo.mood_id == 1)
      end
      if tabPart.tx_mood then
        UIHelper.SetText(tabPart.tx_mood, "\229\191\131\230\131\133" .. num)
      end
    end
    if tabPart.im_love then
      local loveInfo, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
      if loveInfo then
      end
      local isCanLove = Logic.marryLogic:isCanMarry(heroId)
      tabPart.im_love.gameObject:SetActive(isCanLove)
      if tabPart.obj_canMarry then
        tabPart.obj_canMarry:SetActive(isCanLove)
        tabPart.im_love.gameObject:SetActive(false)
      end
    end
    if tabPart.im_kuang then
      local marryInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if marryInfo.MarryTime then
        tabPart.im_kuang.gameObject:SetActive(marryInfo.MarryTime ~= 0)
      end
    end
    local loveInfo1, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
    if tabPart.tx_love then
      UIHelper.SetText(tabPart.tx_love, "\229\165\189\230\132\159\229\186\166" .. num1)
    end
    if tabPart.obj_eff then
      local effInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if effInfo.MarryTime then
        tabPart.obj_eff.gameObject:SetActive(effInfo.MarryTime ~= 0)
      end
    end
  else
    if tabPart.im_mood then
      tabPart.im_mood.gameObject:SetActive(false)
    end
    if tabPart.im_love then
      tabPart.im_love.gameObject:SetActive(false)
    end
    if tabPart.im_kuang then
      tabPart.im_kuang.gameObject:SetActive(false)
    end
    if tabPart.obj_eff then
      tabPart.obj_eff.gameObject:SetActive(false)
    end
  end
end

function ShipCardItem:LoadFightRightCard(params, tabPart)
  tabPart = tabPart:GetLuaTableParts()
  local shipShowConfig = Logic.shipLogic:GetShipShowByInfoId(params.si_id)
  UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipShowConfig.ship_type])
  if shipShowConfig.ship_icon7 ~= "1" and shipShowConfig.ship_icon7_po ~= "1" then
    if params.status < DamageLevel.MiddleDamage then
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7))
    else
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7_po))
    end
  end
end

function ShipCardItem:LoadFightLeftCard(heroId, si_id, tabPart)
  tabPart = tabPart:GetLuaTableParts()
  local shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(heroId)
  UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipShowConfig.ship_type])
  if heroId == 0 then
    UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7))
    return
  end
  local tabShipInfo = Data.heroData:GetHeroById(heroId)
  if shipShowConfig.ship_icon7 ~= "1" and shipShowConfig.ship_icon7_po ~= "1" then
    local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(tabShipInfo.HeroId)
    local curHp = Logic.shipLogic:GetHeroHp(tabShipInfo.HeroId)
    local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
    if hpStatus < DamageLevel.MiddleDamage then
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7))
    else
      UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7_po))
    end
  end
  if tabPart.tx_name then
    local ship_name = Logic.shipLogic:GetRealName(heroId)
    UIHelper.SetText(tabPart.tx_name, ship_name)
  end
  if not npcAssistFleetMgr:IsNpcHeroId(heroId) then
    if tabPart.im_mood then
      local moodInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
      if moodInfo then
        UIHelper.SetImage(tabPart.im_mood, moodInfo.mood_icon)
        tabPart.im_mood.gameObject:SetActive(moodInfo.mood_id == 1)
      end
      if tabPart.tx_mood then
        UIHelper.SetText(tabPart.tx_mood, "\229\191\131\230\131\133" .. num)
      end
    end
    if tabPart.im_love then
      local loveInfo, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
      if loveInfo then
      end
      local isCanLove = Logic.marryLogic:isCanMarry(heroId)
      tabPart.im_love.gameObject:SetActive(isCanLove)
      if tabPart.obj_canMarry then
        tabPart.obj_canMarry:SetActive(isCanLove)
        tabPart.im_love.gameObject:SetActive(false)
      end
    end
    if tabPart.im_kuang then
      local marryInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if marryInfo.MarryTime then
        tabPart.im_kuang.gameObject:SetActive(marryInfo.MarryTime ~= 0)
      end
    end
    local loveInfo1, num1 = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
    if tabPart.tx_love then
      UIHelper.SetText(tabPart.tx_love, "\229\165\189\230\132\159\229\186\166" .. num1)
    end
    if tabPart.obj_eff then
      local effInfo = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Kuang)
      if effInfo.MarryTime then
        tabPart.obj_eff.gameObject:SetActive(effInfo.MarryTime ~= 0)
      end
    end
  else
    if tabPart.im_mood then
      tabPart.im_mood.gameObject:SetActive(false)
    end
    if tabPart.im_love then
      tabPart.im_love.gameObject:SetActive(false)
    end
    if tabPart.im_kuang then
      tabPart.im_kuang.gameObject:SetActive(false)
    end
    if tabPart.obj_eff then
      tabPart.obj_eff.gameObject:SetActive(false)
    end
  end
end

return ShipCardItem
