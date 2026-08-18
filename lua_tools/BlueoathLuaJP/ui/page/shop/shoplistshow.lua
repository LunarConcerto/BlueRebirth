local ShopListShow = class("ui.page.Shop.ShopListShow")
local MAXGOODSNUM = 5
local ShelfLoadImp = {
  [ShopShelfType.ShopShelf] = function(self)
    self:_LoadShopShelfList()
  end,
  [ShopShelfType.SupplyShelf] = function(self)
    self:_LoadSupplyShelfList()
  end
}

function ShopListShow:initialize(parent)
  self.tab_Widgets = parent.tab_Widgets
  self.parent = parent
end

function ShopListShow:Show(param)
  self.m_shopShowList = Logic.shopLogic:GetShowShopShelfInfo()
  self:_RegisterAllEvent()
  eventManager:SendEvent(LuaEvent.TopUpdateCurrency)
end

function ShopListShow:_RegisterAllEvent()
  eventManager:RegisterEvent(LuaEvent.GetShopsInfoMsg, self._ShopsInfoCallBack, self)
end

function ShopListShow:ChangeShelf(shelfType)
  ShelfLoadImp[shelfType](self)
end

function ShopListShow:Close()
  self:_UnRegisterAllEvent()
end

function ShopListShow:_UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.GetShopsInfoMsg, self._ShopsInfoCallBack)
end

function ShopListShow:_ShopsInfoCallBack()
  local shelfType = self.parent.shelfType
  ShelfLoadImp[shelfType](self)
end

function ShopListShow:_LoadSupplyShelfList()
  self:_ShowListImp(self.m_shopShowList[ShopShelfType.SupplyShelf])
end

function ShopListShow:_LoadShopShelfList()
  self:_ShowListImp(self.m_shopShowList[ShopShelfType.ShopShelf])
end

function ShopListShow:_ShowListImp(showList)
  local nCount = GetTableLength(showList)
  self.tab_tabparts = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_shopItem, self.tab_Widgets.trans_shopContent, nCount, function(index, tabPart)
    table.insert(self.tab_tabparts, tabPart)
    tabPart.gameObject:SetActive(false)
    local tabShopInfo = showList[index]
    tabPart.txt_shopName.text = tabShopInfo.name
    tabPart.obj_redPoint:SetActive(false)
    local strShopState = self:_GetShopState(tabShopInfo)
    UIHelper.SetImage(tabPart.im_shopBg, tabShopInfo.bg)
    UIHelper.SetImage(tabPart.im_icon, tabShopInfo.icon, true)
    UIHelper.SetImage(tabPart.im_iconBig, tabShopInfo.icon_2, true)
    tabPart.txt_openType.text = tabShopInfo.open_type
    UGUIEventListener.AddButtonOnClick(tabPart.btn_shop, self._ClickShopBtn, self, showList[index])
    if index == nCount then
      self:_PlayAnim(self.tab_tabparts)
    end
  end)
end

function ShopListShow:_ClickShopBtn(go, tabShopInfo)
  local shopId = tabShopInfo.id
  local strShopState = self:_GetShopState(tabShopInfo)
  if strShopState == "level_lock" then
    noticeManager:OpenTipPage(self, tabShopInfo.level_deblocking .. "\231\186\167\229\188\128\230\148\190")
  elseif strShopState == "open" then
    if tabShopInfo.functionid > 0 then
      moduleManager:JumpToFunc(tabShopInfo.functionid)
    else
      self.parent:ChangeShopShow(true, shopId)
    end
  end
end

function ShopListShow:_GetShopState(tblShopInfo, tblRefreshData)
  local userLv = Data.userData:GetUserData().Level
  if userLv < tblShopInfo.level_deblocking then
    return "level_lock"
  end
  if not Logic.shopLogic:IsOpenByShopId(tblShopInfo.id, false) then
    return "close"
  end
  return "open"
end

function ShopListShow:_PlayAnim(tab_tabparts)
  if tab_tabparts then
    for i, v in ipairs(tab_tabparts) do
      tab_tabparts[i].gameObject:SetActive(false)
    end
  end
  local num = #self.tab_tabparts
  local aNum = num > MAXGOODSNUM and MAXGOODSNUM or num
  local curIndex = 1
  
  function PlayAnim()
    self.anim_delay = 0
    tab_tabparts[curIndex].tween_alpha:SetOnFinished(function()
      if curIndex < aNum then
        curIndex = curIndex + 1
        PlayAnim()
      elseif num > aNum then
        for i = aNum + 1, num do
          tab_tabparts[i].gameObject:SetActive(true)
        end
      end
    end)
    tab_tabparts[curIndex].tween_alpha:ResetToBeginning()
    tab_tabparts[curIndex].tween_scale:ResetToBeginning()
    tab_tabparts[curIndex].gameObject:SetActive(true)
    tab_tabparts[curIndex].tween_scale:Play(true)
    tab_tabparts[curIndex].tween_alpha:Play(true)
  end
  
  if self.anim_delay > 0 then
    local anim_timer = self.parent:CreateTimer(PlayAnim, self.anim_delay, 1, false)
    self.parent:StartTimer(anim_timer)
  else
    PlayAnim()
  end
end

return ShopListShow
