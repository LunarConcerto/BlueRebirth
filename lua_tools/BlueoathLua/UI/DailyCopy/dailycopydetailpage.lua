local DailyCopyDetailPage = class("UI.DailyCopy.DailyCopyDetailPage", LuaUIPage)

function DailyCopyDetailPage:DoInit()
  self.openIndex = 0
end

function DailyCopyDetailPage:DoOnOpen()
  self:OpenTopPage("DailyCopyDetailPage", 1, "\230\175\143\230\151\165", self, true)
  local info = configManager.GetData("config_daily_chapter")
  local param = self:GetParam()
  self.dailyGroupId = param.dailyGroupId
  self.dailyGroupInfo = configManager.GetDataById("config_daily_group", self.dailyGroupId)
  self.copyInfo = Logic.dailyCopyLogic:GetDailyChapterInfo(self.dailyGroupInfo)
  self.levelList = Logic.dailyCopyLogic:GetDailyCopyLevelList(self.copyInfo.id)
  self.playerLevel = self.copyInfo.player_level
  self:_InitInfo()
  self:ShowShopButtons()
  local BuildShipId, BuildShipReward = Logic.dailyCopyLogic:GetBuildShipInfo()
  if BuildShipId and 0 < BuildShipId then
    UIHelper.OpenPage("GetRewardsPage", {
      RewardType = RewardType.EXTRA_SHIP
    })
  end
end

function DailyCopyDetailPage:ShowShopButtons()
  local widgets = self:GetWidgets()
  local shopList = self.dailyGroupInfo.go_shopid
  local shopNameList = self.dailyGroupInfo.shop_name
  widgets.ShopButtonList.gameObject:SetActive(0 < #shopList)
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
  local chapterData = Logic.dailyCopyLogic:GetPassCopy(chapterId)
  UIHelper.CreateSubPart(widgets.buttonTemplate, widgets.ShopButtonList, #shopList, function(nIndex, part)
    local buttonInfo = shopList[nIndex]
    local condition = self.dailyGroupInfo.show_draw_button[nIndex]
    part.obj:SetActive(condition <= #chapterData)
    UIHelper.SetText(part.text, shopNameList[nIndex])
    UGUIEventListener.AddButtonOnClick(part.button, function()
      moduleManager:JumpToFunc(buttonInfo[1], buttonInfo[2])
    end, self)
  end)
end

function DailyCopyDetailPage:clickShop(go, shopId)
  UIHelper.OpenPage("ShopPage", {shopId = shopId})
end

function DailyCopyDetailPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_instruction, self.btn_instruction, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_chapter, self.btn_chapter, self)
end

function DailyCopyDetailPage:_InitInfo()
  self.openIndex = self.openIndex + 1
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
  local chapterData = Logic.dailyCopyLogic:GetPassCopy(chapterId)
  self.indexMax = #chapterData + 1
  self.indexMax = math.min(self.indexMax, #self.levelList)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyItem, self.tab_Widgets.trans_copys, #self.levelList, function(nIndex, tabPart)
    self:_CreateCopyItem(nIndex, tabPart)
  end)
  local index = #chapterData - 1
  if index < 0 then
    index = 0
  end
  self.tab_Widgets.trans_copys.localPosition = Vector3.New(0, 130, 0) * index
  local rewardTotalTimes = Logic.dailyCopyLogic:GetRewardTotalTimes(self.dailyGroupInfo)
  local rewardTimesLeft = Logic.dailyCopyLogic:GetRewardTimesLeft(self.dailyGroupInfo)
  UIHelper.SetLocText(self.tab_Widgets.text_challengeTimes, 410018, rewardTimesLeft)
  self.tab_Widgets.text_challengeTimes.gameObject:SetActive(0 < rewardTimesLeft)
  self.tab_Widgets.obj_extraReward:SetActive(0 < rewardTimesLeft)
  local widgets = self:GetWidgets()
  UIHelper.SetImage(widgets.img_bg, self.dailyGroupInfo.copy_background)
  local chapterInfo = Logic.dailyCopyLogic:GetDailyChapterInfo(self.dailyGroupInfo)
  widgets.text_name.text = chapterInfo.name
end

function DailyCopyDetailPage:_CreateCopyItem(nIndex, tabPart)
  tabPart.btn_copy.interactable = true
  local isOpen = self:_CopyCheck(nIndex, false)
  local level = self.levelList[nIndex]
  local isSweeping = Logic.copyLogic:CurrentCopyIsSweeping(level)
  local levelInfo = configManager.GetDataById("config_copy_display", level)
  UIHelper.SetImage(tabPart.img_bg, levelInfo.copy_thumbnail_before)
  local pos = tabPart.obj_child_copy.transform.localPosition
  if nIndex % 2 == 0 and self.openIndex <= 1 then
    tabPart.obj_child_copy.transform.localPosition = Vector3.New(pos.x + self.copyInfo.copy_button_deviation, pos.y, 0)
  end
  tabPart.obj_copy:SetActive(true)
  tabPart.txt_level.gameObject:SetActive(false)
  tabPart.txt_level_black.gameObject:SetActive(false)
  tabPart.obj_black:SetActive(not isOpen)
  tabPart.txt_name.gameObject:SetActive(isOpen)
  tabPart.txt_name_black.gameObject:SetActive(not isOpen)
  local isPass = Logic.copyLogic:IsCopyPassById(level)
  tabPart.firstTips:SetActive(not isPass and isOpen)
  tabPart.obj_autobattle:SetActive(isSweeping)
  tabPart.textCondition.gameObject:SetActive(not isOpen)
  if not isOpen then
    UIHelper.SetLocText(tabPart.textCondition, 410009)
  end
  if isOpen then
    tabPart.txt_name.text = levelInfo.name
  else
    tabPart.txt_name_black.text = levelInfo.name
  end
  UGUIEventListener.AddButtonOnClick(tabPart.btn_copy.gameObject, function()
    self:_OnClickCopyBtn(nIndex, tabPart, levelInfo.stageid)
  end)
  if #self.levelList ~= #self.dailyGroupInfo.drop_info_id then
    logError("chapter levelList and daily_group drop_info_id not match")
    return
  elseif #self.levelList ~= #self.dailyGroupInfo.extra_drop_info_id then
    logError("chapter levelList and daily_group extra_drop_info_id not match")
    return
  end
  local dropList, dropItemList, baseDropIndex = Logic.dailyCopyLogic:GetDropInfo(self.dailyGroupInfo, nIndex)
  UIHelper.CreateSubPart(tabPart.obj_drop, tabPart.tran_drop, #dropItemList, function(nIndex, part)
    local displayInfo = dropItemList[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(part.img_item, displayInfo.icon)
    UIHelper.SetImage(part.imgBg, QualityIcon[displayInfo.quality])
    UIHelper.SetText(part.tx_dropRate, itemInfo.drop_rate)
    part.obj_extra:SetActive(nIndex > baseDropIndex)
    UGUIEventListener.AddButtonOnClick(part.btn_item.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, dropList)
    end)
  end)
  self:_showShopGoods(nIndex, tabPart)
  self:_showShipInfo(nIndex, tabPart)
end

function DailyCopyDetailPage:_showShopGoods(nIndex, tabPart)
  local shopGoods = self.dailyGroupInfo.shopgoods_list[nIndex]
  local shopId = self.dailyGroupInfo.shop_id[nIndex]
  tabPart.GirlDrop:SetActive(0 < shopGoods)
  if 0 < shopGoods then
    local goodsConfig = configManager.GetDataById("config_shop_goods", shopGoods)
    local goodInfo = goodsConfig.goods
    local type = goodInfo[1]
    local templateId = goodInfo[2]
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local display = ItemInfoPage.GenDisplayData(type, templateId)
    UIHelper.SetImage(tabPart.imgGirl, display.icon)
    UIHelper.SetImageByQuality(tabPart.imgQuality, display.quality)
    local copyId = self.levelList[nIndex]
    local isOpen = Logic.copyLogic:IsCopyPassById(copyId)
    tabPart.Unlock:SetActive(isOpen)
    tabPart.lock:SetActive(not isOpen)
    UGUIEventListener.AddButtonOnClick(tabPart.btnGood, function()
      if isOpen then
        UIHelper.OpenPage("ShopPage", {shopId = shopId})
      else
        local level = self.levelList[nIndex]
        local levelInfo = configManager.GetDataById("config_copy_display", level)
        noticeManager:ShowTipById(410016, levelInfo.name)
      end
    end)
  end
end

function DailyCopyDetailPage:_showShipInfo(nIndex, tabPart)
  local ship_reward = self.dailyGroupInfo.unlock_ship_reward[nIndex]
  local extract_ship_id = self.dailyGroupInfo.unlock_extract_ship_id[nIndex]
  local copyId = self.levelList[nIndex]
  local isOpen = Logic.copyLogic:IsCopyPassById(copyId)
  local flag = 0 < extract_ship_id
  tabPart.DrawDrop:SetActive(flag)
  local items = Logic.rewardLogic:FormatRewardById(ship_reward)
  for index = 1, #items do
    local displayInfo = items[index]
    local type = displayInfo.Type
    local templateId = displayInfo.ConfigId
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    local display = ItemInfoPage.GenDisplayData(type, templateId)
    local part = tabPart["Girl" .. index]:GetLuaTableParts()
    UIHelper.SetImage(part.imgGirl, display.icon)
    UIHelper.SetImageByQuality(part.imgQuality, display.quality)
    UGUIEventListener.AddButtonOnClick(part.button, function()
      if isOpen then
        moduleManager:JumpToFunc(FunctionID.BuildShip, extract_ship_id)
      else
        local levelInfo = configManager.GetDataById("config_copy_display", copyId)
        noticeManager:ShowTipById(410020, levelInfo.name)
      end
    end)
  end
  if flag then
    tabPart.DrawUnlock:SetActive(isOpen)
    tabPart.DrawLock:SetActive(not isOpen)
  end
end

function DailyCopyDetailPage:_OnClickCopyBtn(nIndex, tabPart, stageid)
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  local serData = Data.copyData:GetDailyCopyByCopyId(self.levelList[nIndex])
  if self:_CopyCheck(nIndex, true) then
    local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
    local areaConfig = {
      copyType = CopyType.DAILYCOPY,
      dailyChapterId = self.copyInfo.id,
      chapterId = chapterId,
      copyId = self.levelList[nIndex],
      copyInfo = self.copyInfo,
      dailyGroupId = self.dailyGroupInfo.id,
      tabSerData = serData
    }
    UIHelper.OpenPage("LevelDetailsPage", areaConfig)
  end
end

function DailyCopyDetailPage:_CopyCheck(nIndex, noti)
  if not Logic.dailyCopyLogic:CheckDailyCopyPeriod(self.dailyGroupInfo, noti) then
    return false
  end
  if not self:_CheckLevelLimit(nIndex, noti) then
    return false
  end
  if not self:_CheckCopyOpen(nIndex, noti) then
    return false
  end
  return true
end

function DailyCopyDetailPage:_CheckCopyPass(nIndex, noti)
  local copyId = self.levelList[nIndex]
  if copyId <= 0 then
    return true
  end
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  if copyConfig.sea_area_unlock == 0 then
    return true
  end
  local isPass = Logic.copyLogic:IsCopyPassById(copyConfig.sea_area_unlock)
  if isPass == false and noti then
    local copyName = Logic.copyLogic:GetNameByCopyId(copyConfig.sea_area_unlock)
    noticeManager:ShowTipById(410015, copyName)
  end
  return isPass
end

function DailyCopyDetailPage:_CheckLevelLimit(nIndex, noti)
  local copyId = self.levelList[nIndex]
  local needLevel = configManager.GetDataById("config_copy_display", copyId).level_limit
  local playLevel = Data.userData:GetUserLevel()
  if needLevel > playLevel and noti then
    noticeManager:ShowTipById(410002, needLevel)
  end
  return needLevel <= playLevel
end

function DailyCopyDetailPage:_CheckCopyOpen(nIndex, noti)
  local result = false
  if 1 < nIndex then
    local lastLevel = self.levelList[nIndex - 1]
    local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
    local passCopy = Logic.dailyCopyLogic:GetPassCopy(chapterId)
    local lastPass = false
    for k, v in pairs(passCopy) do
      if v == lastLevel then
        lastPass = true
        break
      end
    end
    result = lastPass
  else
    result = true
  end
  if result == false and noti then
    noticeManager:ShowTipById(410009)
  end
  return result
end

function DailyCopyDetailPage:DoOnHide()
end

function DailyCopyDetailPage:DoOnClose()
end

function DailyCopyDetailPage:btn_chapter()
  UIHelper.OpenPage("ChapterInfoPage")
end

function DailyCopyDetailPage:btn_instruction()
  UIHelper.OpenPage("InstructionPage")
end

return DailyCopyDetailPage
