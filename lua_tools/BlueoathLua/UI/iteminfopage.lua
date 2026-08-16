local ItemInfoPage = class("UI.ItemInfoPage", LuaUIPage)
local DropPath = require("ui.page.Common.DropPath")
local shopItemInfoPage = require("ui.page.Shop.ShopItemInfoPage")
local btnColor = {
  gray = "uipic_ui_common_bu_fang_hui"
}
local TotalBuyNum = 1
local ONCE_MAX_NUM = 10
local ONCE_MIN_NUM = 1

function ItemInfoPage:DoInit()
end

function ItemInfoPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_closeTreasure, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_gray, self._ClickGray, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_blue, self._ClickBlue, self)
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self._ShowItemVisible, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._ShowItemLeft, self)
  UGUIEventListener.AddButtonToggleChanged(widgets.tog_sale, function()
    shopItemInfoPage:_UseDiscount()
  end)
  self:RegisterEvent(LuaEvent.SetBuildTips, self._SetBuildTips, self)
end

function ItemInfoPage:DoOnOpen()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self:_Display()
end

function ItemInfoPage:_Display()
  self:_DisplayBasic()
  self:_DisplayExtra()
  self:_DisplayDrop()
end

function ItemInfoPage:_DisplayDrop()
  local data = self:GetParam()
  self.m_tabWidgets.drop:SetActive(data.showDropPath == true)
  if data.showDropPath ~= true then
    return
  end
  DropPath:_DisplayDrop(self.m_tabWidgets, data.drop_path, self)
end

function ItemInfoPage:_DisplayBasic()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  local isNpc = data.isNpc
  UIHelper.SetText(widgets.txt_title, data.title_cn)
  if data.nameColor then
    UIHelper.SetTextColor(widgets.txt_name, data.name, data.nameColor)
  else
    UIHelper.SetText(widgets.txt_name, data.name)
  end
  UIHelper.SetImage(widgets.img_icon, data.icon)
  widgets.img_quality.gameObject:SetActive(data.quality)
  if data.quality then
    UIHelper.SetImage(widgets.img_quality, QualityIcon[data.quality])
  end
  widgets.obj_svdes:SetActive(data.infolist == nil)
  widgets.obj_svdeslist:SetActive(data.infolist ~= nil)
  if data.infolist then
    self:_ShowContentList(data.infolist)
  else
    UIHelper.SetText(widgets.txt_desc, data.desc)
  end
  if isNpc then
    widgets.trans_grid.gameObject:SetActive(false)
  else
    UIHelper.CreateSubPart(widgets.obj_button, widgets.trans_grid, #data.buttonList, function(index, part)
      local buttonData = data.buttonList[index]
      UIHelper.SetText(part.txt_name, buttonData.name)
      if buttonData.color ~= nil then
        UIHelper.SetImage(part.img_btn, buttonData.color)
      else
        UIHelper.SetImage(part.img_btn, "uipic_ui_common_bu_fang_lan")
      end
      UGUIEventListener.AddButtonOnClick(part.button, function()
        buttonData.func(buttonData.target)
      end)
    end)
  end
  self:_ShowItemLeft()
  self:_ShowItemVisible()
end

function ItemInfoPage:_ShowItemLeft()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  local showObj, value = Logic.itemLogic:GetItemOwnCount(data)
  widgets.txt_repertory.gameObject:SetActive(showObj)
  widgets.txt_repertory.text = "\229\186\147\229\173\152\239\188\154" .. value
end

function ItemInfoPage:_ShowItemVisible()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  local itemMap = Data.interactionItemData:GetInteractionBagItemData()
  local state = itemMap[data.id]
  local Own = state ~= nil
  local isOther = false
  if data.type == GoodsType.INTERACTION_BAG_ITEM then
    local config = configManager.GetDataById("config_interaction_item_bag", data.id)
    isOther = config.interactionitem_bag_group == 0 and config.type == InteractionBagItemType.Other
  end
  widgets.btn_gray.gameObject:SetActive(state == VisibleState.NO and data.type == GoodsType.INTERACTION_BAG_ITEM and Own and isOther)
  widgets.btn_blue.gameObject:SetActive(state == VisibleState.YES and data.type == GoodsType.INTERACTION_BAG_ITEM and Own and isOther)
end

function ItemInfoPage:_ShowContentList(infolist)
  local widgets = self:GetWidgets()
  local temp
  UIHelper.CreateSubPart(widgets.obj_desitem, widgets.trans_desitem, #infolist, function(index, tabPart)
    temp = infolist[index]
    UIHelper.SetText(tabPart.tx_name, temp.name)
    UIHelper.SetText(tabPart.tx_des, temp.des)
  end)
  local timer = FrameTimer.New(function()
    local widgets = self:GetWidgets()
    LayoutRebuilder.ForceRebuildLayoutImmediate(widgets.trans_desitem)
  end, 1, 1)
  timer:Start()
end

function ItemInfoPage:_ClickBlue()
  local data = self:GetParam()
  local itemMap = Data.interactionItemData:GetInteractionBagItemData()
  local state = itemMap[data.id]
  if state ~= VisibleState.YES then
    return
  end
  local interactionItemTab = {
    interactionItem = data.id,
    visibleState = VisibleState.NO
  }
  Service.interactionItemService:SetBagItemVisible(interactionItemTab)
end

function ItemInfoPage:_ClickGray()
  local data = self:GetParam()
  local itemMap = Data.interactionItemData:GetInteractionBagItemData()
  local state = itemMap[data.id]
  if state ~= VisibleState.NO then
    return
  end
  local interactionItemTab = {
    interactionItem = data.id,
    visibleState = VisibleState.YES
  }
  Service.interactionItemService:SetBagItemVisible(interactionItemTab)
end

function ItemInfoPage:_ClickClose()
  local data = self:GetParam()
  UIHelper.ClosePage("ItemInfoPage")
  if type(data.closeFunc) == "function" then
    data.closeFunc()
  end
end

function ItemInfoPage:_DisplayExtra()
  local widgets = self:GetWidgets()
  local data = self:GetParam()
  if data.limitInfo then
    UIHelper.SetText(widgets.txt_limit, data.limitInfo)
  end
  if data.attrlist then
    widgets.trans_base.gameObject:SetActive(true)
    local num = #data.attrlist > 6 and 6 or #data.attrlist
    UIHelper.CreateSubPart(widgets.obj_attr, widgets.trans_base, num, function(index, tabPart)
      local temp = data.attrlist[index]
      UIHelper.SetText(tabPart.txt_Name, temp.name)
      UIHelper.SetText(tabPart.txt_Value, temp.value)
      UIHelper.SetImage(tabPart.img_Tag, temp.icon)
    end)
  end
  if data.tag then
    UIHelper.SetText(widgets.tx_equipTag, data.tag)
  end
  if data.getWay then
    UIHelper.SetText(widgets.txt_getWay, data.getWay)
    widgets.obj_getWay:SetActive(true)
  else
    widgets.obj_getWay:SetActive(false)
  end
  if data.shopId then
    shopItemInfoPage:Init(self, widgets)
    shopItemInfoPage:ShowItemInfo(data)
  else
    widgets.obj_price:SetActive(false)
  end
  widgets.obj_ringEff:SetActive(data.id == 10180)
  if data.fashionHero then
    widgets.txt_fitGirl.gameObject:SetActive(true)
    UIHelper.SetText(widgets.txt_fitGirl, "\233\128\130\231\148\168\230\136\152\229\167\172\239\188\154" .. data.fashionHero)
  end
  widgets.obj_drop:SetActive(data.prefabType == 2)
  if data.prefabType == 2 then
    self:_ShowDropItem(data)
  end
  self.tab_Widgets.obj_im_valentineGift:SetActive(data.type == GoodsType.VALENTINE_GIFT)
  widgets.txt_getTime.gameObject:SetActive(data.acquiredTime ~= nil and data.acquiredTime ~= 0)
  if data.acquiredTime ~= nil and data.acquiredTime ~= 0 then
    widgets.txt_getTime.text = time.formatTimerToYMD(data.acquiredTime)
  end
end

function ItemInfoPage:_ShowDropItem(data)
  local widgets = self:GetWidgets()
  local dropGoodsConf, dropItemConfig
  if data.dropId and data.dropId ~= 0 then
    dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByDropId(data.dropId)
  elseif data.itemTab and #data.itemTab ~= 0 then
    dropGoodsConf, dropItemConfig = Logic.itemLogic:GetConfByItemTab(data.itemTab)
  else
    widgets.obj_drop:SetActive(false)
    return
  end
  widgets.obj_btnClose:SetActive(false)
  widgets.obj_treasure:SetActive(true)
  widgets.obj_back:SetActive(false)
  widgets.trans_top.anchoredPosition = Vector2.New(-27.5, 67.61)
  widgets.obj_price.transform.anchoredPosition = Vector2.New(-49, -198.56)
  widgets.trans_grid.anchoredPosition = Vector2.New(-27, -96.25)
  widgets.trans_goodsNum.anchoredPosition = Vector2.New(-75, 273)
  widgets.trans_selectNum.anchoredPosition = Vector2.New(8.5, -105.5)
  widgets.trans_getConditon.anchoredPosition = Vector2.New(-26, -55)
  UIHelper.SetInfiniteItemParam(widgets.infinite_drop, widgets.obj_dropItem, #dropItemConfig, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      local goodsType = dropItemConfig[nIndex].Type
      local tId = dropItemConfig[nIndex].ConfigId
      local num = dropItemConfig[nIndex].Num
      local config = dropGoodsConf[tId]
      tabPart.tx_name.text = config.name
      tabPart.tx_num.text = "x" .. num
      local icon = config.icon_small ~= nil and config.icon_small or config.icon
      UIHelper.SetImage(tabPart.img_icon, tostring(icon))
      UIHelper.SetImage(tabPart.img_quality, QualityIcon[config.quality])
      if goodsType == GoodsType.EQUIP and tabPart.obj_skin ~= nil then
        local isHave = Logic.equipLogic:EquipIsHaveEffect(tId)
        tabPart.obj_skin:SetActive(isHave)
      elseif tabPart.obj_skin ~= nil then
        tabPart.obj_skin:SetActive(false)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_click, function()
        if goodsType == GoodsType.EQUIP then
          UIHelper.OpenPage("ShowEquipPage", {
            templateId = tId,
            showEquipType = ShowEquipType.Simple
          })
        else
          UIHelper.OpenPage("SpecialDetailPage", ItemInfoPage.GenDisplayData(goodsType, tId))
        end
      end)
    end
  end)
end

function ItemInfoPage.GenDisplayData(dType, ...)
  if ItemInfoPage.GenerateFunc[dType] then
    return ItemInfoPage.GenerateFunc[dType](...)
  else
    return ItemInfoPage.GenDisplayDataDefault(dType, ...)
  end
end

function ItemInfoPage.GetEquipDisPlayData(tid, showDropPath)
  local equipInfo = configManager.GetDataById("config_equip", tid)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  data.name = equipInfo.name
  data.quality = equipInfo.quality
  data.icon = equipInfo.icon
  data.drop_path = equipInfo.drop_path
  data.showDropPath = showDropPath
  data.desc = ""
  data.id = tid
  data.tag = Logic.equipLogic:GetEquipTag(equipInfo.ewt_id)
  data.attrlist = {}
  local equipAttr = Logic.equipLogic:GetCurEquipFinaAttrByLv(tid)
  for i, v in ipairs(equipAttr) do
    local temp = {}
    temp.name = v.name
    temp.icon = v.icon
    temp.value = v.value
    table.insert(data.attrlist, temp)
  end
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenShipDisplayData(templateId, showDropPath)
  local shipShow = Logic.shipLogic:GetShipShowById(templateId)
  local shipInfo = Logic.shipLogic:GetShipInfoById(templateId)
  local config = configManager.GetDataById("config_ship_main", templateId)
  local data = {}
  data.title_cn = "\232\167\146\232\137\178\232\175\166\230\131\133"
  data.name = shipInfo.ship_name
  data.desc = shipShow.desc
  data.quality = shipInfo.quality
  data.icon = shipShow.ship_icon5
  data.drop_path = config.drop_path
  data.showDropPath = showDropPath
  data.type = GoodsType.SHIP
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenDropDisplayData(Tid, showDropPath)
  local dropInfo = configManager.GetDataById("config_drop_info", Tid)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  local singleDrop = dropInfo.item_info[1]
  local itemInfo = Logic.bagLogic:GetItemByTempateId(singleDrop[1], singleDrop[2])
  data.name = itemInfo.name
  data.desc = itemInfo.desc
  data.quality = itemInfo.quality
  data.icon = itemInfo.icon
  data.drop_path = itemInfo.drop_path
  data.showDropPath = showDropPath
  data.buttonList = {}
  data.id = itemInfo.id
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenSelectItemDisplayData(Tid, showDropPath)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  local itemConf = Logic.bagLogic:GetItemByConfig(Tid)
  data.name = itemConf.name
  data.desc = itemConf.description
  data.icon = itemConf.icon
  data.quality = itemConf.quality
  data.drop_path = itemConf.drop_path
  data.showDropPath = showDropPath
  data.id = Tid
  data.dropId = itemConf.drop_id
  data.itemTab = itemConf.item_id
  data.buttonList = {}
  data.prefabType = itemConf.prefab_type == nil and 0 or itemConf.prefab_type
  
  function data.closeFunc()
    if UIPageManager:IsExistPage("SelectRandTreasurePage") then
      UIHelper.ClosePage("SelectRandTreasurePage")
    end
  end
  
  if not UIPageManager:IsExistPage("SelectRandTreasurePage") or UIPageManager:IsExistPage("GetRewardsPage") then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1430024),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
      end
    })
  else
    table.insert(data.buttonList, {
      name = "\230\137\147\229\188\128",
      func = function()
        if itemConf.type == SelectRandItem.RandShip then
          local canOpen = Logic.rewardLogic:CanGotShip(1)
          if not canOpen then
            return
          end
        elseif itemConf.type == SelectRandItem.RandEquip then
          local canOpen = Logic.rewardLogic:CanGotEquip(1)
          if not canOpen then
            return
          end
        end
        if Logic.bagLogic:IsRandSelectItem(Tid) then
          Service.bagService:SendGetSelectTreasureItem(Tid, 0)
        else
          eventManager:SendEvent(LuaEvent.GetTreasureInfo)
        end
        UIHelper.ClosePage("ItemInfoPage")
      end
    })
  end
  return data
end

function ItemInfoPage.GenHeadFrameDisplayData(Tid, showDropPath)
  local itemInfo0 = configManager.GetDataById("config_player_head_frame", Tid)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  local itemInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.PLAYER_HEAD_FRAME, Tid)
  data.name = itemInfo.name
  data.desc = itemInfo.desc
  data.quality = itemInfo.quality
  data.icon = itemInfo.icon
  data.drop_path = itemInfo.drop_path
  data.showDropPath = false
  data.buttonList = {}
  data.id = itemInfo.id
  data.type = GoodsType.PLAYER_HEAD_FRAME
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenInteractionBagItemDisplayData(Tid, showDropPath)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  local itemInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.INTERACTION_BAG_ITEM, Tid)
  data.name = itemInfo.name
  data.desc = itemInfo.desc
  data.quality = itemInfo.quality
  data.icon = itemInfo.icon
  data.drop_path = itemInfo.drop_path
  data.showDropPath = false
  data.buttonList = {}
  data.id = itemInfo.id
  data.type = GoodsType.INTERACTION_BAG_ITEM
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenDisplayDataDefault(typ, Tid, showDropPath)
  local itemInfo = Logic.goodsLogic:GetConfigByTypeAndId(Tid, typ)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  data.name = itemInfo.name
  data.desc = itemInfo.description
  data.quality = itemInfo.quality
  data.icon = typ == GoodsType.FASHION and itemInfo.icon_small or itemInfo.icon
  data.icon_small = itemInfo.icon_small
  data.drop_path = itemInfo.drop_path
  data.showDropPath = showDropPath
  data.id = Tid
  data.buttonList = {}
  data.type = typ
  local _, value = Logic.itemLogic:GetItemOwnCount(data)
  local dropCfg
  if typ == GoodsType.ITEM then
    dropCfg = configManager.GetDataById("config_item_info", Tid)
    data.dropId = dropCfg.drop_id
    data.prefabType = dropCfg.prefab_type == nil and 0 or dropCfg.prefab_type
  end
  if dropCfg ~= nil and dropCfg.open_type == 1 then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(7100000),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
        UIHelper.OpenPage("NationItemPage", Tid)
      end
    })
  elseif dropCfg ~= nil and dropCfg.open_type == 2 then
    local _, _, bagToBall = Logic.interactionItemLogic:GetBallAndToyPositionId()
    local interId = bagToBall[Tid]
    if 0 < value then
      table.insert(data.buttonList, {
        name = UIHelper.GetString(7100000),
        func = function()
          UIHelper.ClosePage("ItemInfoPage")
          UIHelper.OpenPage("ValentineCrystalPage", {BallId = interId})
        end
      })
    end
  elseif typ == GoodsType.VALENTINE_GIFT then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(7100000),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
        UIHelper.OpenPage("ValentineLoveLetterPage", {ItemId = Tid})
      end
    })
  elseif typ == GoodsType.DISCOUNT and value ~= 0 and itemInfo.activity_id ~= 0 then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1300070),
      func = function()
        local activityCfg = configManager.GetDataById("config_activity", itemInfo.activity_id)
        local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
        local svrTime = time.getSvrTime()
        local isOpen = Logic.activityLogic:IsOpenActivityFurnitureDecoration(itemInfo.activity_id)
        if startTime > svrTime then
          noticeManager:ShowTip(UIHelper.GetString(1300071))
        elseif isOpen then
          UIHelper.ClosePage("ItemInfoPage")
          Data.activityData:SetTag(itemInfo.activity_id)
          UIHelper.OpenPage("ActivityPage")
        else
          noticeManager:ShowTip(UIHelper.GetString(1300069))
        end
      end
    })
  elseif dropCfg ~= nil and dropCfg.open_type == 3 and Logic.bagLogic:GetBagItemNum(Tid) and UIPageManager:IsExistPage("BagPage") then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(920000200),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
        local arg = {ItemId = Tid}
        Service.activitychristmasshopService:OpenSpecialBlindBox(arg)
      end
    })
  else
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1430024),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
      end
    })
  end
  if typ == GoodsType.FASHION then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(920000173),
      func = function()
        local previewHero = Logic.fashionLogic:GetHeroByFashionId(Tid)
        local heroId = previewHero and previewHero.HeroId
        UIHelper.ClosePage("ItemInfoPage")
        UIHelper.OpenPage("FashionPage", {
          isPreview = true,
          fashionId = Tid,
          heroId = heroId
        })
      end
    })
  end
  return data
end

function ItemInfoPage.GenPSkillData(pskillId, heroId)
  if type(pskillId) == "table" then
    return ItemInfoPage.GenPSkillsData(pskillId, heroId)
  end
  local data = {}
  data.title_cn = UIHelper.GetString(190007)
  data.name = Logic.shipLogic:GetPSkillName(pskillId)
  local tType = Logic.shipLogic:GetPSkillType(pskillId)
  data.nameColor = TalentColor[tType]
  local pskillLv = math.tointeger(Logic.shipLogic:GetHeroPSkillLv(heroId, pskillId))
  data.desc = Logic.shipLogic:GetPSkillDesc(pskillId, pskillLv)
  data.icon = Logic.shipLogic:GetPSkillIcon(pskillId)
  local bUnlock
  bUnlock, data.limitInfo = Logic.shipLogic:CheckHeroPSkillActive(heroId, pskillId)
  data.buttonList = {}
  if not bUnlock then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1430024),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
      end
    })
  else
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1430024),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
      end
    })
    if not Logic.shipLogic:CheckHeroPSkillReachMax(heroId, pskillId) then
      table.insert(data.buttonList, {
        name = UIHelper.GetString(190011),
        func = function()
          UIHelper.ClosePage("ItemInfoPage")
          if Logic.studyLogic:CheckHeroAlreadyStudy(heroId) then
            noticeManager:ShowTip(UIHelper.GetString(180011))
            return
          end
          if Logic.studyLogic:GetStudyMargin() <= 0 then
            noticeManager:ShowTip(UIHelper.GetString(160015))
            local StudyPage = require("ui.page.Study.StudyPage")
            UIHelper.OpenPage("StudyPage", StudyPage.GenDisplayData())
            return
          end
          if #Logic.bagLogic:GetItemArrByItemType(BagItemType.SHIP_TALENT_UPGRADE) == 0 then
            local skillBookId = Logic.shipLogic:GetRecommendSkillBookId(pskillId)
            globalNoitceManager:ShowItemInfoPage(GoodsType.TALENT_UPGRADE_ITEM, skillBookId)
            noticeManager:ShowTip(UIHelper.GetString(160016))
            return
          end
          if moduleManager:JumpToFunc(FunctionID.Study) then
            local flow = Logic.studyLogic:GetStudyFlow()
            flow:Input(flow.InputType.AddNewStudy, nil)
            flow:Input(flow.InputType.Confirm, {heroId})
            flow:Input(flow.InputType.Confirm, {pskillId})
          end
        end
      })
    end
  end
  return data
end

function ItemInfoPage.GenPSkillsData(pskillIds, heroId, tid)
  local data = {}
  data.title_cn = UIHelper.GetString(190007)
  data.name = Logic.shipLogic:GetPSkillName(pskillIds)
  data.icon = Logic.shipLogic:GetPSkillIcon(pskillIds, tid)
  local tType = Logic.shipLogic:GetPSkillType(pskillIds)
  data.nameColor = TalentColor[tType]
  data.infolist = {}
  for _, id in ipairs(pskillIds) do
    local temp = {}
    temp.name = Logic.shipLogic:GetPSkillName(id)
    temp.des = Logic.shipLogic:GetPSkillShowDesc(id, heroId, tid)
    table.insert(data.infolist, temp)
  end
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.GenMaxPSkillData(pskillId, tid)
  if type(pskillId) == "table" then
    return ItemInfoPage.GenPSkillsData(pskillId, nil, tid)
  end
  local data = {}
  data.title_cn = UIHelper.GetString(190007)
  data.name = Logic.shipLogic:GetPSkillName(pskillId)
  local tType = Logic.shipLogic:GetPSkillType(pskillId)
  data.nameColor = TalentColor[tType]
  local pskillLv = 10
  data.desc = Logic.shipLogic:GetPSkillDesc(pskillId, pskillLv)
  data.icon = Logic.shipLogic:GetPSkillIcon(pskillId, tid)
  local bUnlock
  bUnlock, data.limitInfo = true, ""
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage:BuyShopItemPage(shopId, buyNum, goodsInfo, goodData, dotInfo, isBatch, gridId)
  local data = {}
  data.title_cn = goodData.goods[1] == GoodsType.SHIP and "\232\167\146\232\137\178\232\175\166\230\131\133" or UIHelper.GetString(190004)
  data.type = goodData.goods[1]
  data.name = goodsInfo.name
  local shipId = goodData.goods[2]
  if goodData.goods[1] == GoodsType.SHIP then
    local shipInfo = Logic.shipLogic:GetShipShowById(shipId)
    data.desc = shipInfo.desc
  else
    data.desc = goodsInfo.desc
  end
  data.icon = goodsInfo.icon
  data.quality = goodsInfo.quality
  data.id = goodsInfo.id
  data.buyNum = buyNum
  data.isBatch = isBatch
  data.shopId = shopId
  data.goodsId = goodData.id
  data.goodData = goodData
  data.buttonList = {}
  data.gridId = gridId
  data.dropId = goodsInfo.drop_id
  data.itemTab = goodsInfo.item_id and goodsInfo.item_id or nil
  data.goodsSerData = goodSerData
  local itemConf = Logic.bagLogic:GetConfig(goodData.goods[1], goodsInfo.id)
  data.prefabType = itemConf.prefab_type == nil and 0 or itemConf.prefab_type
  data.totalBuyNum = 1
  data.discountId = nil
  if not isBatch then
    table.insert(data.buttonList, {
      name = UIHelper.GetString(1430025),
      func = function()
        UIHelper.ClosePage("ItemInfoPage")
      end,
      color = btnColor.gray
    })
    table.insert(data.buttonList, {
      name = UIHelper.GetString(190012),
      func = function()
        shopItemInfoPage:ClickBuyGoods(data)
      end
    })
    if goodData.goods[1] == GoodsType.SHIP then
      local shipInfoId = Logic.shipLogic:GetShipInfoIdByTid(shipId)
      table.insert(data.buttonList, {
        name = UIHelper.GetString(190005),
        func = function()
          UIHelper.OpenPage("IllustrateInfo", shipInfoId)
        end
      })
    end
  end
  return data
end

function ItemInfoPage:_ClickDismantlePageOk()
  UIHelper.ClosePage("ItemInfoPage")
  UIHelper.OpenPage("DismantlePage")
end

function ItemInfoPage.ShowItemInfo(goodInfo)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  data.name = goodInfo.name
  data.desc = goodInfo.desc
  data.icon = goodInfo.icon
  data.quality = goodInfo.quality
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage.ShowRechargeInfo(goodInfo, buyCallback)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  data.name = goodInfo.name
  data.desc = goodInfo.desc
  data.icon = goodInfo.icon
  data.quality = goodInfo.quality
  data.buttonList = {}
  table.insert(data.buttonList, {
    name = UIHelper.GetString(160007),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end,
    color = btnColor.gray
  })
  table.insert(data.buttonList, {
    name = UIHelper.GetString(190012),
    func = buyCallback
  })
  return data
end

function ItemInfoPage.GenMedalData(Tid, medalTab)
  local itemInfo = Logic.goodsLogic:GetConfigByTypeAndId(Tid, GoodsType.MEDAL)
  local data = {}
  data.title_cn = UIHelper.GetString(190004)
  data.name = itemInfo.name
  data.desc = itemInfo.description
  data.quality = itemInfo.quality
  data.icon = itemInfo.icon
  data.icon_small = itemInfo.icon_small
  data.drop_path = itemInfo.drop_path
  data.showDropPath = showDropPath
  data.id = Tid
  data.buttonList = {}
  data.type = GoodsType.MEDAL
  if medalTab then
    local acquiredTime = Logic.userLogic:GetMedalAcquiredTime(Tid, medalTab)
    data.acquiredTime = acquiredTime
  end
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430024),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end
  })
  return data
end

function ItemInfoPage:GenFashionData(shopId, buyNum, fashionCfg, goodData, gridId, hasPreview)
  local data = {}
  data.title_cn = UIHelper.GetString(910015)
  data.name = fashionCfg.name
  local fashionId = goodData.goods[2]
  local fashionCfg = configManager.GetDataById("config_fashion", fashionId)
  data.desc = fashionCfg.description
  data.icon = fashionCfg.icon_small
  data.quality = fashionCfg.quality
  data.id = fashionCfg.id
  data.buyNum = buyNum
  data.isBatch = isBatch
  data.shopId = shopId
  data.goodsId = goodData.id
  data.goodData = goodData
  data.buttonList = {}
  data.type = GoodsType.FASHION
  data.gridId = gridId
  data.totalBuyNum = 1
  data.discountId = nil
  local shipName = Logic.fashionLogic:GetFashionShipName(fashionId)
  data.fashionHero = shipName
  table.insert(data.buttonList, {
    name = UIHelper.GetString(1430025),
    func = function()
      UIHelper.ClosePage("ItemInfoPage")
    end,
    color = btnColor.gray
  })
  table.insert(data.buttonList, {
    name = UIHelper.GetString(190012),
    func = function()
      shopItemInfoPage:ClickBuyGoods(data)
    end
  })
  if hasPreview then
    table.insert(data.buttonList, {
      name = "\233\162\132\232\167\136",
      func = function()
        local previewHero = Logic.fashionLogic:GetHeroByFashionId(fashionId)
        local heroId = previewHero and previewHero.HeroId
        UIHelper.ClosePage("ItemInfoPage")
        UIHelper.OpenPage("FashionPage", {
          isPreview = true,
          fashionId = fashionId,
          heroId = heroId
        })
      end
    })
  end
  return data
end

function ItemInfoPage:_SetBuildTips(str)
  local widgets = self:GetWidgets()
  if str then
    widgets.txt_getConditon.gameObject:SetActive(true)
    widgets.txt_getConditon.text = str
    widgets.trans_grid.gameObject:SetActive(false)
  end
end

ItemInfoPage.GenerateFunc = {
  [GoodsType.EQUIP] = ItemInfoPage.GetEquipDisPlayData,
  [GoodsType.SHIP] = ItemInfoPage.GenShipDisplayData,
  [GoodsType.DROP] = ItemInfoPage.GenDropDisplayData,
  [GoodsType.ITEM_SELECTED] = ItemInfoPage.GenSelectItemDisplayData,
  [GoodsType.PLAYER_HEAD_FRAME] = ItemInfoPage.GenHeadFrameDisplayData,
  [GoodsType.MEDAL] = ItemInfoPage.GenMedalData
}
return ItemInfoPage
