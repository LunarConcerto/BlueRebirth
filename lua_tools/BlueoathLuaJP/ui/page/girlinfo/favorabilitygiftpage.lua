local FavorabilityGiftPage = class("ui.page.GirlInfo.FavorabilityGiftPage", LuaUIPage)
local CONSTVALUE = 10000
local GREEN = "00B018"

function FavorabilityGiftPage:DoInit()
  self.tabWidgets = self:GetWidgets()
  self.curSelectId = 0
  self.curSelectNum = 0
  self.heroId = 0
end

function FavorabilityGiftPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_add, self._OnAddClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_del, self._OnDelClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_min, self._OnMinClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_max, self._OnMaxClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_sure, self._OnSureClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_cancle, self._OnCancleClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_goShop, self._OnGoShopBtnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tabWidgets.btn_selectGift, self._OnSelectGiftBtnClick, self)
  self:RegisterEvent(LuaEvent.UpdateHeroAddAffection, self._UpdateAffectionCallBack)
end

function FavorabilityGiftPage:DoOnOpen()
  self.heroId = self:GetParam().heroId
  if self.tabWidgets == nil then
    self.tabWidgets = self:GetWidgets()
  end
  self.curSelectId = 0
  self.curSelectNum = 0
  self:_InitView()
  self:_UpdateDepotView()
end

function FavorabilityGiftPage:DoOnHide()
end

function FavorabilityGiftPage:DoOnClose()
end

function FavorabilityGiftPage:_UpdateDepotView()
  local giftsTab = Logic.bagLogic:GetItemArrByItemType(GoodsType.AFFECTIONGIFTITEM)
  if 0 < #giftsTab then
    table.sort(giftsTab, function(g1, g2)
      local conf1 = configManager.GetDataById("config_affection_item", g1.templateId)
      local conf2 = configManager.GetDataById("config_affection_item", g2.templateId)
      if conf1.affection_exp ~= conf2.affection_exp then
        return conf1.affection_exp > conf2.affection_exp
      else
        return conf1.id > conf2.id
      end
    end)
    self.tabWidgets.obj_noneGift:SetActive(false)
    if self.curSelectId == 0 then
      self.curSelectId = giftsTab[1].templateId
      self.curSelectNum = 1
    else
      local needReset = true
      for _, giftInfo in pairs(giftsTab) do
        if giftInfo.templateId == self.curSelectId then
          needReset = false
          break
        end
      end
      if needReset then
        self.curSelectId = giftsTab[1].templateId
      end
      self.curSelectNum = 1
    end
  elseif #giftsTab == 0 then
    self.curSelectId = 0
    self.curSelectNum = 0
    self.tabWidgets.obj_noneGift:SetActive(true)
    UIHelper.SetText(self.tabWidgets.txt_noneGiftDesc, UIHelper.GetString(4910004))
  end
  self:_SetSelectGiftIcon()
  local virtualSliderValue = self:_GetVirtualSliderValue()
  self:_SetSliderValue(false, virtualSliderValue)
  self:_SetSliderProgressText(virtualSliderValue)
  UIHelper.SetText(self.tabWidgets.txt_giftNum, self.curSelectNum)
  local uipartTabs = {}
  UIHelper.CreateSubPart(self.tabWidgets.obj_giftItem, self.tabWidgets.trans_content, #giftsTab, function(index, uiPart)
    local giftInfo = giftsTab[index]
    uipartTabs[giftInfo.templateId] = uiPart
    local giftConf = configManager.GetDataById("config_affection_item", giftInfo.templateId)
    local icon = giftConf.icon
    local quality = giftConf.quality
    UIHelper.SetImage(uiPart.im_icon, icon)
    UIHelper.SetImageByQuality(uiPart.im_quality, quality)
    UIHelper.SetText(uiPart.tx_num, "X" .. giftInfo.num)
    UIHelper.SetText(uiPart.tx_affection, "+" .. tostring(math.floor(giftConf.affection_exp / CONSTVALUE)))
    UIHelper.SetText(uiPart.tx_name, giftConf.name)
    uiPart.obj_select:SetActive(self.curSelectId == giftInfo.templateId)
    
    local function callback()
      self:_OnDepotGiftClick(giftInfo, uipartTabs)
    end
    
    UGUIEventListener.AddButtonOnClick(uiPart.im_bg, callback)
  end)
end

function FavorabilityGiftPage:_OnDepotGiftClick(giftInfo, uipartTabs)
  if self.curSelectId == giftInfo.templateId then
    return
  end
  self.curSelectId = giftInfo.templateId
  for k, v in pairs(uipartTabs) do
    v.obj_select:SetActive(self.curSelectId == k)
  end
  self.curSelectNum = 1
  self:_SetSelectGiftIcon()
  local virtualSliderValue = self:_GetVirtualSliderValue()
  self:_SetSliderValue(false, virtualSliderValue)
  self:_SetSliderProgressText(virtualSliderValue)
  UIHelper.SetText(self.tabWidgets.txt_giftNum, self.curSelectNum)
end

function FavorabilityGiftPage:_SetSliderValue(isActual, value, time)
  local duration = time or 0
  local tweenSlider
  if not isActual then
    tweenSlider = TweenSlider.Add(self.tabWidgets.virtualSlider.gameObject, time, self.tabWidgets.virtualSlider.value, value)
  else
    tweenSlider = TweenSlider.Add(self.tabWidgets.actualSlider.gameObject, time, self.tabWidgets.actualSlider.value, value)
  end
  tweenSlider:Play(true)
end

function FavorabilityGiftPage:_SetSelectGiftIcon()
  if self.curSelectId == 0 then
    self.tabWidgets.obj_none:SetActive(true)
    self.tabWidgets.obj_have:SetActive(false)
  else
    self.tabWidgets.obj_none:SetActive(false)
    self.tabWidgets.obj_have:SetActive(true)
    local giftConf = configManager.GetDataById("config_affection_item", self.curSelectId)
    local giftIcon = giftConf.icon
    local giftQuality = giftConf.quality
    UIHelper.SetImageByQuality(self.tabWidgets.img_giftBg, giftQuality)
    UIHelper.SetImage(self.tabWidgets.img_selectGift, giftIcon)
  end
end

function FavorabilityGiftPage:_SetSliderProgressText(value)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local maxValue = self:_GetMaxAffectionValue()
  local curValue = math.floor(num / CONSTVALUE)
  local str
  local affectionValue = math.floor(value * maxValue)
  if curValue < affectionValue then
    local offset = affectionValue - curValue
    local addStr = UIHelper.SetColor("(+" .. offset .. ")", GREEN)
    str = curValue .. addStr .. "/" .. maxValue
  else
    str = curValue .. "/" .. maxValue
  end
  UIHelper.SetText(self.tabWidgets.txt_sliderProgress, str)
end

function FavorabilityGiftPage:_InitView()
  local shipInfo = Data.heroData:GetHeroById(self.heroId)
  local shipIcon = Logic.shipLogic:GetHeroSquareIcon(shipInfo.fleetId, false)
  local shipQuality = Logic.shipLogic:GetQualityByHeroId(self.heroId)
  local shipName = Logic.shipLogic:GetName(shipInfo.fleetId)
  UIHelper.SetImage(self.tabWidgets.img_shipIcon, shipIcon)
  UIHelper.SetImageByQuality(self.tabWidgets.img_shipQuality, shipQuality)
  UIHelper.SetText(self.tabWidgets.txt_shipName, shipName)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local maxValue = self:_GetMaxAffectionValue()
  local curValue = num / CONSTVALUE
  local actualSliderValue = curValue / maxValue
  self:_SetSliderValue(true, actualSliderValue)
  self:_SetSliderValue(false, 0)
  self:_SetSliderProgressText(actualSliderValue)
  UIHelper.SetText(self.tabWidgets.txt_giftNum, self.curSelectNum)
end

function FavorabilityGiftPage:_GetVirtualSliderValue()
  if self.curSelectId <= 0 then
    return 0
  end
  local giftConf = configManager.GetDataById("config_affection_item", self.curSelectId)
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local maxValue = self:_GetMaxAffectionValue()
  local curValue = num / CONSTVALUE
  local offValue = giftConf.affection_exp / CONSTVALUE
  local sliderValue = (curValue + offValue * self.curSelectNum) / maxValue
  sliderValue = Mathf.Clamp(sliderValue, 0, 1)
  return sliderValue
end

function FavorabilityGiftPage:_GetActualSliderValue()
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local maxValue = self:_GetMaxAffectionValue()
  local curValue = num / CONSTVALUE
  return curValue / maxValue
end

local OperateType = {
  ADD = 1,
  DEL = 2,
  MIN = 3,
  MAX = 4
}

function FavorabilityGiftPage:_OperateSelectGiftNum(operateType)
  if self.curSelectId == 0 then
    return
  end
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local curValue = num / CONSTVALUE
  local maxValue = self:_GetMaxAffectionValue()
  local oldSliderValue = self:_GetVirtualSliderValue()
  local newSliderValue = oldSliderValue
  local haveGiftNum = Data.bagData:GetItemNum(self.curSelectId)
  if operateType == OperateType.ADD then
    if not self:_CheckSliderValue(oldSliderValue) then
      return
    end
    if haveGiftNum <= self.curSelectNum then
      noticeManager:ShowTip(UIHelper.GetString(4800004))
      return
    end
    self.curSelectNum = self.curSelectNum + 1
  elseif operateType == OperateType.DEL then
    if 0 >= self.curSelectNum then
      return
    end
    self.curSelectNum = self.curSelectNum - 1
  elseif operateType == OperateType.MAX then
    if not self:_CheckSliderValue(oldSliderValue) then
      return
    end
    local giftConf = configManager.GetDataById("config_affection_item", self.curSelectId)
    local offValue = giftConf.affection_exp / CONSTVALUE
    local offset = math.ceil((maxValue - curValue) / offValue)
    local minNum = math.min(offset, haveGiftNum)
    self.curSelectNum = minNum
  elseif OperateType.MIN then
    if 0 >= self.curSelectNum then
      return
    end
    self.curSelectNum = 0
  end
  newSliderValue = self:_GetVirtualSliderValue()
  self:_SetSliderValue(false, newSliderValue)
  self:_SetSliderProgressText(newSliderValue)
  UIHelper.SetText(self.tabWidgets.txt_giftNum, self.curSelectNum)
end

function FavorabilityGiftPage:_OnAddClick()
  self:_OperateSelectGiftNum(OperateType.ADD)
end

function FavorabilityGiftPage:_OnDelClick()
  self:_OperateSelectGiftNum(OperateType.DEL)
end

function FavorabilityGiftPage:_OnMaxClick()
  self:_OperateSelectGiftNum(OperateType.MAX)
end

function FavorabilityGiftPage:_OnMinClick()
  self:_OperateSelectGiftNum(OperateType.MIN)
end

function FavorabilityGiftPage:_OnSureClick()
  if self.curSelectId > 0 and 0 < self.curSelectNum then
    local actualSliderValue = self:_GetActualSliderValue()
    if self:_CheckSliderValue(actualSliderValue) then
      Service.heroService:_SendAddHeroAffection({
        heroId = self.heroId,
        templateId = self.curSelectId,
        num = self.curSelectNum
      })
    end
  else
    noticeManager:ShowTip(UIHelper.GetString(4910003))
  end
end

function FavorabilityGiftPage:_OnCancleClick()
  UIHelper.ClosePage("FavorabilityGiftPage")
end

function FavorabilityGiftPage:_GetMaxAffectionValue()
  local noMarry = configManager.GetDataById("config_parameter", 155).arrValue
  local marryed = configManager.GetDataById("config_parameter", 156).arrValue
  local heroInfo = Data.heroData:GetHeroById(self.heroId)
  local max = 0
  local hasMarry = heroInfo.MarryTime ~= 0
  if not hasMarry then
    max = math.modf(noMarry[2] / CONSTVALUE)
  else
    max = math.modf(marryed[2] / CONSTVALUE)
  end
  return max, hasMarry
end

function FavorabilityGiftPage:_CheckSliderValue(curValue)
  local _, hasMarry = self:_GetMaxAffectionValue()
  if 1 <= curValue then
    local noticeStr
    if hasMarry then
      noticeStr = UIHelper.GetString(4910001)
    else
      noticeStr = UIHelper.GetString(4910002)
    end
    noticeManager:ShowTip(noticeStr)
    return false
  end
  return true
end

function FavorabilityGiftPage:_UpdateAffectionCallBack()
  local loveInfo, num = Logic.marryLogic:GetLoveInfo(self.heroId, MarryType.Love)
  local maxValue = self:_GetMaxAffectionValue()
  local curValue = num / CONSTVALUE
  self:_SetSliderValue(true, curValue / maxValue, 0.5)
  self:_UpdateDepotView()
end

function FavorabilityGiftPage:_OnGoShopBtnClick()
  local goShopId = configManager.GetDataById("config_parameter", 460).value
  UIHelper.OpenPage("ShopPage", {shopId = goShopId})
end

function FavorabilityGiftPage:_OnSelectGiftBtnClick()
  if self.curSelectId <= 0 then
    return
  end
  Logic.itemLogic:ShowItemInfo(GoodsType.AFFECTIONGIFTITEM, self.curSelectId, true)
end

return FavorabilityGiftPage
