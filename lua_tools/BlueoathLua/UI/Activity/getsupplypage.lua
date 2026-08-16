local GetSupplyPage = class("UI.Activity.GetSupplyPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GetSupplyPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.supplyInfo = {}
  self.configInfo = nil
end

function GetSupplyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._UpdateInfo, self)
  self:RegisterEvent(LuaEvent.UpdateActivity, self._DisposeData, self)
end

function GetSupplyPage:DoOnOpen()
  self.configInfo = Logic.currencyLogic:GetSupplyconfig()
  self:_DisposeData()
end

function GetSupplyPage:_UpdateInfo()
  noticeManager:OpenTipPage(self, UIHelper.GetString(330002))
  self:_DisposeData()
end

function GetSupplyPage:_DisposeData()
  local data = Data.userData:GetUserData().GetSupplyInfo
  for _, v in pairs(data) do
    self.supplyInfo[v.Id] = v
  end
  self:_LoadSupplyItem()
end

function GetSupplyPage:_LoadSupplyItem()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trans_supply, #self.configInfo, function(nIndex, tabPart)
    local config = self.configInfo[nIndex]
    local reward = config.reward
    local quality = Logic.activityLogic:GetRewardQuality(reward[1], reward[2])
    local icon = Logic.activityLogic:GetRewardIcon(reward[1], reward[2])
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[quality])
    UIHelper.SetText(tabPart.tx_num, "x" .. reward[3])
    tabPart.txt_limit.text = config.time[1] .. ":00-" .. config.time[2] .. ":00" .. UIHelper.GetString(330008)
    local status = Logic.currencyLogic:SupplyStatus(config.time, self.supplyInfo[nIndex])
    tabPart.obj_get:SetActive(status ~= GetSupplyStatus.CANGET)
    if status == GetSupplyStatus.CANGET then
      tabPart.btn_get.gameObject:SetActive(true)
      tabPart.obj_get:SetActive(false)
      tabPart.im_got:SetActive(false)
    elseif status == GetSupplyStatus.NOTINTIME then
      tabPart.btn_get.gameObject:SetActive(false)
      tabPart.obj_get:SetActive(true)
      tabPart.im_got:SetActive(false)
    else
      tabPart.btn_get.gameObject:SetActive(false)
      tabPart.obj_get:SetActive(false)
      tabPart.im_got:SetActive(true)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_detail, self._ShowItemDetail, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, self._ClickGetSupply, self, nIndex)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_out, self._ClickGetSupplyOut)
  end)
end

function GetSupplyPage:_ClickGetSupply(go, index)
  local config = self.configInfo[index]
  local status = Logic.currencyLogic:SupplyStatus(config.time, self.supplyInfo[index])
  if status == GetSupplyStatus.CANGET then
    Service.userService:SendGetSupply(index)
  else
    noticeManager:OpenTipPage(self, UIHelper.GetString(330001))
    self:_DisposeData()
  end
end

function GetSupplyPage:_ClickGetSupplyOut()
  noticeManager:OpenTipPage(self, UIHelper.GetString(330001))
end

function GetSupplyPage:_ShowItemDetail(go, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.CURRENCY, reward[2]))
end

function GetSupplyPage:DoOnClose()
end

return GetSupplyPage
