local PaperPage = class("UI.Bag.PaperPage", LuaUIPage)

function PaperPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tabParam = nil
  self.n_openNum = 1
  self.userData = nil
  self.openMaxNum = 0
  self.gold_max = 0
  self.paper_max = 0
  self.n_openPaperMaxNum = 0
  self.showIndex = 0
  self.userData = nil
end

function PaperPage:RegisterAllEvent(...)
  self:RegisterEvent(LuaEvent.GetPaperInfo, self._GetPaperInfo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, function()
    self:_ClickCloseFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_cancel, function()
    self:_ClickCloseFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_confirm, function()
    self:_ClickConfirm()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_decreaseNum, function()
    self:_ClickDecreaseNumFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_increaseNum, function()
    self:_ClickIncreaseNumFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_maxNum, function()
    self:_ClickMaxNumFun()
  end)
end

function PaperPage:DoOnOpen(...)
  self.m_tabParam = self:GetParam()
  self.userData = Data.userData:GetUserData()
  self.openMaxNum = configManager.GetDataById("config_parameter", 81).value
  self.equipItemId = Logic.equipLogic:GetItemId(self.m_tabParam.id)
  self.tabAttrInfo = Logic.equipLogic:GetCurEquipPropertyByTid(self.m_tabParam.item_id[2])
  self.showCount = #self.tabAttrInfo / 6
  self:_ShowInformation()
  self:_ShowEquipInfo()
  local dotinfo = {
    info = "ui_composite"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function PaperPage:_ShowInformation()
  UIHelper.SetImage(self.m_tabWidgets.im_icon, self.m_tabParam.icon)
  UIHelper.SetImage(self.m_tabWidgets.img_quality, QualityIcon[self.m_tabParam.quality])
  UIHelper.SetText(self.m_tabWidgets.txt_itemName, self.m_tabParam.name)
  self.userData = Data.userData:GetUserData()
  self.m_tabWidgets.txt_goldNum.text = math.tointeger(self.userData.Gold) .. "/" .. self.m_tabParam.coin * self.n_openNum
  self.m_tabWidgets.txt_paperNum.text = math.tointeger(self.m_tabParam.num) .. "/" .. self.m_tabParam.amount * self.n_openNum
  self.m_tabWidgets.txt_treasureNum.text = self.n_openNum
  self.gold_max = math.floor(self.userData.Gold / self.m_tabParam.coin)
  self.paper_max = math.floor(self.m_tabParam.num / self.m_tabParam.amount)
  if self.gold_max <= self.paper_max and self.gold_max < self.openMaxNum then
    self.n_openPaperMaxNum = self.gold_max
  elseif self.gold_max > self.paper_max and self.paper_max < self.openMaxNum then
    self.n_openPaperMaxNum = self.paper_max
  else
    self.n_openPaperMaxNum = self.openMaxNum
  end
  if self.n_openPaperMaxNum < 1 then
    self.n_openPaperMaxNum = 1
  end
end

function PaperPage:_ClickDecreaseNumFun()
  if self.n_openNum > 1 then
    self.n_openNum = self.n_openNum - 1
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, self.n_openNum)
  end
  self:_ShowInformation()
end

function PaperPage:_ClickIncreaseNumFun()
  if self.n_openNum == self.n_openPaperMaxNum then
    return
  end
  if self.n_openNum < self.n_openPaperMaxNum then
    self.n_openNum = self.n_openNum + 1
    UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, self.n_openNum)
  end
  self:_ShowInformation()
end

function PaperPage:_ClickMaxNumFun()
  self.n_openNum = self.n_openPaperMaxNum
  UIHelper.SetText(self.m_tabWidgets.txt_treasureNum, self.n_openNum)
  self:_ShowInformation()
end

function PaperPage:_ShowEquipInfo()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_Property, self.m_tabWidgets.trans_Property, 12, function(nIndex, tabPart)
    local equipInfo = self.tabAttrInfo[nIndex + 6 * self.showIndex]
    if equipInfo then
      if utf8.len(equipInfo.name) >= 3 then
        tabPart.txt_Name.text = string.format("<size=16>%s</size>", equipInfo.name)
      else
        tabPart.txt_Name.text = string.format("<size=20>%s</size>", equipInfo.name)
      end
      local attrValueShow = Logic.attrLogic:GetAttrShow(equipInfo.id, equipInfo.value)
      tabPart.txt_Value.text = attrValueShow
      UIHelper.SetImage(tabPart.img_Tag, equipInfo.icon)
      tabPart.img_Tag.gameObject:SetActive(true)
      tabPart.txt_Name.gameObject:SetActive(true)
      tabPart.txt_Value.gameObject:SetActive(true)
    else
      tabPart.txt_Name.gameObject:SetActive(false)
      tabPart.txt_Value.gameObject:SetActive(false)
      tabPart.img_Tag.gameObject:SetActive(false)
    end
    tabPart.obj_prop:SetActive(equipInfo)
  end)
  self.showIndex = self.showIndex + 1
  if self.showIndex > self.showCount then
    self.showIndex = 0
  end
end

function PaperPage:_ClickCloseFun()
  UIHelper.ClosePage("PaperPage")
end

function PaperPage:_GetPaperInfo(err)
  local GetRewards = {}
  local information = {
    ConfigId = self.m_tabParam.item_id[2],
    Num = self.n_openNum,
    Type = self.equipItemId[1]
  }
  table.insert(GetRewards, information)
  local params = {Rewards = GetRewards, Page = "PaperPage"}
  if err == 0 then
    local dotinfo = {
      info = "ui_composite_succss",
      equip_num = {
        [tostring(self.m_tabParam.item_id[2])] = self.n_openNum
      }
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    UIHelper.ClosePage("PaperPage")
    UIHelper.OpenPage("GetRewardsPage", params)
  else
    noticeManager:OpenTipPage(self, "\230\151\160\230\179\149\229\144\136\230\136\144")
  end
end

function PaperPage:_ClickConfirm()
  local size = Logic.equipLogic:GetEquipOccupySize()
  local equipSize = Data.equipData:GetEquipBagSize()
  local equip = {
    tid = self.m_tabParam.id,
    num = self.n_openNum
  }
  if self.userData.Gold < self.m_tabParam.coin * self.n_openNum then
    noticeManager:OpenTipPage(self, "\233\135\145\229\184\129\230\149\176\233\135\143\228\184\141\232\182\179\239\188\140\230\151\160\230\179\149\229\144\136\230\136\144\232\175\165\232\163\133\229\164\135")
  elseif self.m_tabParam.num < self.m_tabParam.amount * self.n_openNum then
    noticeManager:OpenTipPage(self, "\231\162\142\231\137\135\230\149\176\233\135\143\228\184\141\232\182\179\239\188\140\230\151\160\230\179\149\229\144\136\230\136\144\232\175\165\232\163\133\229\164\135")
  elseif equipSize < size + self.n_openNum then
    noticeManager:OpenTipPage(self, "\232\131\140\229\140\133\229\174\185\233\135\143\228\184\141\232\182\179")
  else
    Service.bagService:SendComposite(equip)
  end
end

function PaperPage:DoOnClose(...)
end

function PaperPage:DoOnHide(...)
end

return PaperPage
