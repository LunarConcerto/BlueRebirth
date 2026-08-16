local ResumePage = class("UI.ResumePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local configTab = {
  {
    "GetHeroCount",
    UIHelper.GetString(240001)
  },
  {
    "CollectionRate",
    UIHelper.GetString(240002)
  },
  {
    "AttackCount",
    UIHelper.GetString(240003)
  },
  {
    "MarriedNum",
    UIHelper.GetString(240004)
  },
  {
    "DrilsNum",
    UIHelper.GetString(240005)
  },
  {
    "SectionTimes",
    UIHelper.GetString(240006)
  }
}

function ResumePage:DoInit()
  self.m_tabWidgets = nil
  self.m_userInfo = nil
  self.m_displayData = {}
  self.m_showData = {}
  self.index = 1
  self.xunZhangInfo = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function ResumePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self._ClickRight, self)
end

function ResumePage:DoOnOpen()
  self.m_userInfo = self:GetParam()
  self.xunZhangInfo = Logic.userLogic:GetMedalIdTab(self.m_userInfo.MedalAcquiredTime)
  self:_ShowXunZhang()
  self:_LeftInfo()
  self:_ProcessData()
  self:_LoadRightItem()
end

function ResumePage:_LeftInfo()
  self.m_tabWidgets.txt_level.text = "LV." .. math.tointeger(self.m_userInfo.Level)
  local shipShow = Logic.shipLogic:GetShipShowByFashionId(self.m_userInfo.Fashioning)
  local shipInfo = Logic.shipLogic:GetShipInfoById(self.m_userInfo.Head)
  UIHelper.SetImage(self.m_tabWidgets.img_head, tostring(shipShow.ship_icon2))
  UIHelper.SetImage(self.m_tabWidgets.img_headBg, VerCardQualityImg[shipInfo.quality], true)
  self.m_tabWidgets.txt_playerName.text = self.m_userInfo.Uname
  self.m_tabWidgets.im_kuang.gameObject:SetActive(self.m_userInfo.HeadShow == 1)
end

function ResumePage:_ShowXunZhang()
  local num = #self.xunZhangInfo - (self.index - 1) * 6
  local min
  if num < 6 then
    min = num
  elseif 6 <= num then
    min = 6
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_xunzhang, self.tab_Widgets.trans_xunzhang, min, function(nIndex, tabPart)
    local icon = Logic.medalLogic:GetIcon(self.xunZhangInfo[nIndex + (self.index - 1) * 6])
    local data = Logic.medalLogic:GetMedal(self.xunZhangInfo[nIndex + (self.index - 1) * 6])
    UIHelper.SetImage(tabPart.im_xunzhang, icon)
    UGUIEventListener.AddButtonOnClick(tabPart.btnDrag, function()
      self:_ShowMedal(self, data)
    end)
  end)
end

function ResumePage:_ShowMedal(go, medalData)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.MEDAL, medalData.id, self.m_userInfo.MedalAcquiredTime))
end

function ResumePage:_ClickLeft(...)
  if self.index > 1 then
    self.index = self.index - 1
    self:_ShowXunZhang()
  else
    self.index = self.index
  end
end

function ResumePage:_ClickRight(...)
  if self.index < math.ceil(#self.xunZhangInfo / 6) then
    self.index = self.index + 1
    self:_ShowXunZhang()
  else
    self.index = self.index
  end
end

function ResumePage:_ClickClose()
  UIHelper.ClosePage("ResumePage")
end

function ResumePage:_ProcessData()
  for i = 1, #configTab do
    local config = configTab[i]
    for k, v in pairs(self.m_userInfo) do
      if k == config[1] then
        config[3] = math.floor(v)
      end
    end
  end
end

function ResumePage:_LoadRightItem()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_item, self.m_tabWidgets.trans_gird, #configTab, function(nIndex, tabPart)
    info = configTab[nIndex]
    tabPart.txt_title.text = info[2]
    value = info[3]
    if value == nil then
      tabPart.txt_value.text = UIHelper.GetString(240007)
    else
      if nIndex == 2 then
        value = string.format("%.1f%%", value / 100)
      elseif nIndex == 6 then
        value = UIHelper.GetString(240007)
      end
      tabPart.txt_value.text = value
    end
  end)
end

return ResumePage
