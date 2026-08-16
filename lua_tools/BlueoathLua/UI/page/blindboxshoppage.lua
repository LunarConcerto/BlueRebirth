local BlindBoxShopPage = class("ui.page.BlindBoxShopPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function BlindBoxShopPage:DoInit()
end

function BlindBoxShopPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self:ShowPage()
end

function BlindBoxShopPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ACShop_RefreshData, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnExchange, function()
    UIHelper.OpenPage("ChristmasChangePage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelp, function()
    local toylist = Data.activitychristmasshopData:GetToyList()
    local toycount = #toylist
    local cangettoylist = Data.activitychristmasshopData:GetCanGetToyList()
    local toycountMax = #cangettoylist
    local content = UIHelper.GetLocString(1300040, toycount, toycountMax)
    UIHelper.OpenPage("HelpPage", {content = content})
  end)
  self:RegisterEvent(LuaEvent.ACShop_GetToy, function(handler, toyId)
    self:OpenEffect(toyId)
  end)
end

function BlindBoxShopPage:DoOnHide()
end

function BlindBoxShopPage:DoOnClose()
  if self.m_sprayObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
    self.m_sprayObj = nil
  end
end

function BlindBoxShopPage:Check()
  local isGive = Data.activitychristmasshopData:IsGiveCrystalBall()
  if not isGive then
    Service.activitychristmasshopService:SendGiveMeCrystalBall()
  end
end

function BlindBoxShopPage:ShowPage()
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, BLINDBOX_CUR_ID)
  UIHelper.SetImage(self.tab_Widgets.imgCur, display.icon)
  local owncount = Data.bagData:GetItemNum(BLINDBOX_CUR_ID)
  UIHelper.SetLocText(self.tab_Widgets.textCurNum, 710082, owncount)
  local boxLimit = configManager.GetDataById("config_parameter", 314).value
  UIHelper.CreateSubPart(self.tab_Widgets.itemBox, self.tab_Widgets.rectContent, boxLimit, function(index, part)
    local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, BLINDBOX_CUR_ID)
    UIHelper.SetImage(part.imgMoney, display.icon_small)
    local cost = configManager.GetDataById("config_parameter", 313).value
    UIHelper.SetLocText(part.textNum, 710082, cost)
    UGUIEventListener.AddButtonOnClick(part.btnItem, function()
      local ownBlindCur = Data.bagData:GetItemNum(BLINDBOX_CUR_ID)
      local costBlindCur = configManager.GetDataById("config_parameter", 313).value
      if ownBlindCur < costBlindCur then
        noticeManager:ShowTipById(1300041)
        return
      end
      Service.activitychristmasshopService:SendBuyBlindBox({
        Index = index,
        BuyShop = ACS_BUY_SHOP.NEW
      })
    end)
  end)
  self.tab_Widgets.btnExchange.gameObject:SetActive(Data.userData:GetUserData().Level >= 50)
end

function BlindBoxShopPage:OpenEffect(param)
  local toyId = param.ToyId
  local repeated = param.repeated
  local shipGirlConfig = configManager.GetDataById("config_interaction_figurte", toyId)
  local shipGrilModelPath = shipGirlConfig.figure_name
  local ModelPathELISA = "modelsq/" .. shipGrilModelPath .. "/" .. shipGrilModelPath
  if self.m_sprayObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
    self.m_sprayObj = nil
  end
  self.m_sprayObj = GR.objectPoolManager:LuaGetGameObject(ModelPathELISA, self.tab_Widgets.trans)
  local itemPosition = configManager.GetDataById("config_parameter", 328).arrValue
  self.m_sprayObj.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  self.m_sprayObj.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  self.m_sprayObj.transform.localScale = Vector3.New(itemPosition[3][1], itemPosition[3][2], itemPosition[3][3])
  UIHelper.SetLayer(self.m_sprayObj, LayerMask.NameToLayer("UI"))
  self.tab_Widgets.objEffect:SetActive(true)
  self.tab_Widgets.tx_Repeated.gameObject:SetActive(repeated)
end

return BlindBoxShopPage
