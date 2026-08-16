local BuildShipGirlPage = class("UI.Build.BuildShipPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local HeroRarity = {
  [1] = "N",
  [2] = "R",
  [3] = "SR",
  [4] = "SSR"
}

function BuildShipGirlPage:DoInit()
  UIHelper.SetUILock(true)
  self.tab_Widgets.tween_left:SetOnFinished(self.SetUILock)
  self.tab_Widgets.tween_left:Play(true)
  self.tabTogs = {
    self.tab_Widgets.tog_build,
    self.tab_Widgets.tog_quene,
    self.tab_Widgets.tog_notes
  }
  self.tabTween = {
    self.tab_Widgets.tween_build,
    self.tab_Widgets.tween_quene,
    self.tab_Widgets.tween_notes
  }
  self.tabSelectTween = {
    self.tab_Widgets.tween_build_selected,
    self.tab_Widgets.tween_quene_selected,
    self.tab_Widgets.tween_notes_selected
  }
  self.tabNotesTogs = {
    self.tab_Widgets.tog_all,
    self.tab_Widgets.tog_ssr,
    self.tab_Widgets.tog_sr,
    self.tab_Widgets.tog_r
  }
  self.tabSortIndex = {
    "\229\133\168\233\131\168",
    "SSR",
    "SR",
    "R/N"
  }
  self.num = {}
  self.index = 1
  self.girlNum = 1
  self.res1 = {}
  self.res2 = {}
  self.res3 = {}
  self.sequeData = {}
  self.m_timer = nil
  self.buildedNum = 0
  self.buildingNum = 0
  self.waitingNum = 0
  self.maxBuild = 1
  self.isTrue = true
  self.awardGang = {}
  self.awardLv = {}
  self.awardQuick = {}
  self.tabNotesInfo = {}
  self.notesIndex = 1
  self.isFirst = true
end

function BuildShipGirlPage:_toTable(res)
  local tmp = {
    numBai = math.modf(res / 100),
    numTen = math.modf(res / 10 % 10),
    numOne = res % 10
  }
  return tmp
end

function BuildShipGirlPage:DoOnOpen()
  self.userInfo = Data.userData:GetUserData()
  self.isFirst = Logic.buildLogic:GetIsFirst()
  if self.isFirst then
    self.isFirst = false
    Service.buildService:SendBuildNotesInfo()
    Logic.buildLogic:SetIsFirst(self.isFirst)
  end
  self.uid = tostring(self.userInfo.Uid)
  local index = PlayerPrefs.GetInt(self.uid .. "JumpHomeRightPage", 0)
  if index ~= 0 then
    eventManager:SendEvent(LuaEvent.HomePlayTween, true)
  end
  eventManager:SendEvent(LuaEvent.HomePageOtherPageOpen, LeftOpenInde.Build)
  for i, tog in ipairs(self.tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  local isHaveRedDot = Logic.buildLogic:IsHaveRedDot()
  if isHaveRedDot then
    Logic.buildLogic:SetTogLastIndex(BuildShipGirl.Quene)
  end
  local index = Logic.buildLogic:GetTogLastIndex()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(index)
  self.tab_Widgets.txt_girlNum.text = self.girlNum
  self.res1 = configManager.GetDataById("config_parameter", 98).arrValue
  self.res2 = configManager.GetDataById("config_parameter", 99).arrValue
  self.res3 = configManager.GetDataById("config_parameter", 100).arrValue
  self.quickRes = configManager.GetDataById("config_parameter", 101).arrValue
  self.num[BuildShipResource.Gold] = self:_toTable(self.res1[1])
  self.num[BuildShipResource.Gang] = self:_toTable(self.res2[3])
  self.num[BuildShipResource.Lv] = self:_toTable(self.res3[3])
  self:_UserHaveResource()
  local gang = configManager.GetDataById("config_item_info", self.res2[2])
  local lv = configManager.GetDataById("config_item_info", self.res3[2])
  self.awardGang = {
    self.res2[1],
    self.res2[2]
  }
  self.awardLv = {
    self.res3[1],
    self.res3[2]
  }
  self.awardQuick = {
    self.quickRes[1],
    self.quickRes[2]
  }
  UIHelper.SetImage(self.tab_Widgets.im_gang, gang.icon_small)
  UIHelper.SetImage(self.tab_Widgets.im_lv, lv.icon_small)
  self.sequeData = Data.buildData:GetData()
  self.maxBuild = configManager.GetDataById("config_parameter", 103).value
  self.m_timer = self:CreateTimer(function()
    self:_TickCharge()
  end, 1, -1, false)
  self:StartTimer(self.m_timer)
  self:_SequeInfo()
  self:_LoadGoodsInfo()
  self:_LoadGirlInfo()
  self:_TickCharge()
  self.userData = Data.userData:GetUserData()
  for i, tog in ipairs(self.tabNotesTogs) do
    self.tab_Widgets.obj_togRarity:RegisterToggle(tog)
  end
  self.tab_Widgets.obj_togRarity:SetActiveToggleIndex(1)
end

function BuildShipGirlPage:_UserHaveResource(...)
  local gangNum = Logic.bagLogic:ItemInfoById(self.res2[2])
  local lvNum = Logic.bagLogic:ItemInfoById(self.res3[2])
  if gangNum == nil then
    self.gangNum = 0
  else
    self.gangNum = gangNum.num
  end
  if lvNum == nil then
    self.lvNum = 0
  else
    self.lvNum = lvNum.num
  end
  if self.gangNum <= 99999 then
    self.tab_Widgets.txt_gang.text = math.modf(self.gangNum)
  else
    self.tab_Widgets.txt_gang.text = "99999+"
  end
  if self.lvNum <= 99999 then
    self.tab_Widgets.txt_lv.text = math.modf(self.lvNum)
  else
    self.tab_Widgets.txt_lv.text = "99999+"
  end
end

function BuildShipGirlPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseBuildPage, self)
  self:RegisterEvent(LuaEvent.CloseLeftPage, self._CloseBuildPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_gang, function()
    self:_ShowItemInfo(self, self.awardGang)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_lv, function()
    self:_ShowItemInfo(self, self.awardLv)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_quickFinsh, function()
    self:_ShowItemInfo(self, self.awardQuick)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_startBuild, self._ClickStartBuildFun, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_peiFang, self._ClickPeiFangFun, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_maxNum, self._RightMax, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_increaseNum, self._IncreaseNum, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_decreaseNum, self._DecreaseNum, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
  self:RegisterEvent(LuaEvent.UpadateBuildGirlData, self._UpdataSeque, self)
  self:RegisterEvent(LuaEvent.GetBuildShipId, self._GetBuildShipId, self)
  self:RegisterEvent(LuaEvent.GetQuicklyFinish, self._GetQuicklyFinish, self)
  self:RegisterEvent(LuaEvent.GetBuildingByFormula, self._GetBuildingByFormula, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self._UserHaveResource, self)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.obj_togRarity, self, "", self._SwitchNotesTogs)
  self:RegisterEvent(LuaEvent.UpdateNotesInfo, self._UpdataNotesInfo, self)
end

function BuildShipGirlPage:_SwitchTogs(index)
  self.tab_Widgets.obj_build:SetActive(index == BuildShipGirl.Build)
  self.tab_Widgets.obj_quene:SetActive(index == BuildShipGirl.Quene)
  self.tab_Widgets.obj_notes:SetActive(index == BuildShipGirl.Notes)
  self.tab_Widgets.tog_build.gameObject:SetActive(index ~= BuildShipGirl.Build)
  self.tab_Widgets.tog_quene.gameObject:SetActive(index ~= BuildShipGirl.Quene)
  self.tab_Widgets.tog_notes.gameObject:SetActive(index ~= BuildShipGirl.Notes)
  self.tab_Widgets.obj_togRarity:SetActiveToggleIndex(1)
  if self.maxBuild - self.girlNum - (self.buildedNum + self.buildingNum + self.waitingNum) < 0 then
    UIHelper.SetImage(self.tab_Widgets.im_startBuild, "uipic_ui_common_bu_tongyonganniu")
  else
    UIHelper.SetImage(self.tab_Widgets.im_startBuild, "uipic_ui_common_bu_tongyonganniu_02")
  end
  self.tabTween[index + 1]:ResetToBeginning()
  self.tabSelectTween[index + 1]:ResetToBeginning()
  self.tabTween[index + 1]:Play(true)
  self.tabSelectTween[index + 1]:Play(true)
  self.girlNum = 1
  self.tab_Widgets.txt_girlNum.text = self.girlNum
  local isHaveRedDot = Logic.buildLogic:IsHaveRedDot()
  if isHaveRedDot then
    Logic.buildLogic:SetTogLastIndex(BuildShipGirl.Quene)
  else
    Logic.buildLogic:SetTogLastIndex(index)
  end
end

function BuildShipGirlPage:_UpadateBuildGirl()
end

function BuildShipGirlPage:_SequeInfo()
  local quickTool = configManager.GetDataById("config_parameter", 101).arrValue
  local quickData = configManager.GetDataById("config_item_info", quickTool[2])
  local quickNum = Logic.bagLogic:ItemInfoById(10031)
  if quickNum == nil then
    self.quickNum = 0
  else
    self.quickNum = quickNum.num
  end
  UIHelper.SetImage(self.tab_Widgets.im_quickIcon, quickData.icon_small)
  if self.quickNum <= 99999 then
    self.tab_Widgets.tx_quickNum.text = math.modf(self.quickNum)
  else
    self.tab_Widgets.tx_quickNum.text = "99999+"
  end
end

function BuildShipGirlPage:_LoadGoodsInfo()
  local tabInfo = {}
  local icon = {}
  if self.maxBuild - self.girlNum - (self.buildedNum + self.buildingNum + self.waitingNum) < 0 then
    UIHelper.SetImage(self.tab_Widgets.im_startBuild, "uipic_ui_common_bu_tongyonganniu")
  else
    UIHelper.SetImage(self.tab_Widgets.im_startBuild, "uipic_ui_common_bu_tongyonganniu_02")
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_goodsInfo, self.tab_Widgets.trans_goodsInfo, 3, function(index, tabPart)
    tabPart.txt_numBai.text = self.num[index].numBai
    tabPart.txt_numTen.text = self.num[index].numTen
    tabPart.txt_numOne.text = self.num[index].numOne
    local showIcon = {}
    if index == BuildShipResource.Gold then
      icon = Logic.currencyLogic:GetTexIcon(1)
      showIcon = {5, 1}
    elseif index == BuildShipResource.Gang then
      icon = Logic.itemLogic:GetIcon(self.res2[2])
      showIcon = {
        self.res2[1],
        self.res2[2]
      }
    elseif index == BuildShipResource.Lv then
      icon = Logic.itemLogic:GetIcon(self.res3[2])
      showIcon = {
        self.res3[1],
        self.res3[2]
      }
    end
    UIHelper.SetImage(tabPart.im_icon, icon)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_addBai, function()
      self:_AddBai(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_addTen, function()
      self:_AddTen(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_addOne, function()
      self:_AddOne(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reduceBai, function()
      self:_ReduceBai(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reduceTen, function()
      self:_ReduceTen(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reduceOne, function()
      self:_ReduceOne(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_max, function()
      self:_LeftMax(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reset, function()
      self:_LeftReset(self, index)
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      self:_ShowItemInfo(self, showIcon)
    end)
  end)
  self.needGold = self.num[BuildShipResource.Gold].numBai * 100 + self.num[BuildShipResource.Gold].numTen * 10 + self.num[BuildShipResource.Gold].numOne
  self.needGang = self.num[BuildShipResource.Gang].numBai * 100 + self.num[BuildShipResource.Gang].numTen * 10 + self.num[BuildShipResource.Gang].numOne
  self.needlv = self.num[BuildShipResource.Lv].numBai * 100 + self.num[BuildShipResource.Lv].numTen * 10 + self.num[BuildShipResource.Lv].numOne
end

function BuildShipGirlPage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award[1], award[2]))
end

function BuildShipGirlPage:_CloseBuildPage()
  eventManager:SendEvent(LuaEvent.HomePageOtherPageClose)
  UIHelper.ClosePage("BuildShipGirlPage")
end

function BuildShipGirlPage:_AddBai(go, index)
  if self.num[index].numBai == 9 then
    self.num[index].numBai = 0
  else
    self.num[index].numBai = self.num[index].numBai + 1
  end
  self:_CheckNum(index)
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_AddTen(go, index)
  if self.num[index].numTen == 9 then
    self.num[index].numTen = 0
  else
    self.num[index].numTen = self.num[index].numTen + 1
  end
  self:_CheckNum(index)
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_AddOne(go, index)
  if self.num[index].numOne == 9 then
    self.num[index].numOne = 0
  else
    self.num[index].numOne = self.num[index].numOne + 1
  end
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_ReduceBai(go, index)
  if self.num[index].numBai == 0 then
    self.num[index].numBai = 9
  else
    self.num[index].numBai = self.num[index].numBai - 1
  end
  self:_CheckNum(index)
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_ReduceTen(go, index)
  if self.num[index].numBai == 0 and self.num[index].numTen <= 3 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(440006))
    return
  end
  if self.num[index].numTen == 0 then
    self.num[index].numTen = 9
  else
    self.num[index].numTen = self.num[index].numTen - 1
  end
  self:_CheckNum(index)
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_ReduceOne(go, index)
  if self.num[index].numOne == 0 then
    self.num[index].numOne = 9
  else
    self.num[index].numOne = self.num[index].numOne - 1
  end
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_CheckNum(index)
  if self.num[index].numBai == 0 and self.num[index].numTen < 3 then
    self.num[index].numTen = 3
    self.num[index].numOne = 0
  end
end

function BuildShipGirlPage:_LeftReset(go, index)
  local str, name
  if index == BuildShipResource.Gold then
    self.num[index] = {
      numBai = math.modf(self.res1[1] / 100),
      numTen = math.modf(self.res1[1] / 10 % 10),
      numOne = self.res1[1] % 10
    }
  elseif index == BuildShipResource.Gang then
    self.num[index] = {
      numBai = math.modf(self.res2[3] / 100),
      numTen = math.modf(self.res2[3] / 10 % 10),
      numOne = self.res2[3] % 10
    }
  elseif index == BuildShipResource.Lv then
    self.num[index] = {
      numBai = math.modf(self.res3[3] / 100),
      numTen = math.modf(self.res3[3] / 10 % 10),
      numOne = self.res3[3] % 10
    }
  end
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_LeftMax(go, index)
  local num = 999
  if index == BuildShipResource.Gold then
    num = Data.userData:GetCurrency(CurrencyType.GOLD)
  elseif index == BuildShipResource.Gang then
    num = self.gangNum
  elseif index == BuildShipResource.Lv then
    num = self.lvNum
  end
  num = math.min(999, num)
  num = math.max(30, num)
  self.num[index] = {
    numBai = math.modf(num / 100),
    numTen = math.modf(num / 10 % 10),
    numOne = math.modf(num % 10)
  }
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_RightMax()
  local goldMax = math.modf(self.userData.Gold / self.needGold)
  local gangMax = math.modf(self.gangNum / self.needGang)
  local lvMax = math.modf(self.lvNum / self.needlv)
  local minNum = math.min(goldMax, gangMax)
  minNum = math.min(minNum, lvMax)
  self.girlNum = self.maxBuild - (self.buildedNum + self.buildingNum + self.waitingNum)
  self.girlNum = math.min(minNum, self.girlNum)
  if self.girlNum > 0 then
    self.tab_Widgets.txt_girlNum.text = self.girlNum
  end
  if self.girlNum == 0 then
    self.girlNum = 1
  end
end

function BuildShipGirlPage:_IncreaseNum(...)
  local max = self.maxBuild - (self.buildedNum + self.buildingNum + self.waitingNum)
  if max > self.girlNum then
    self.girlNum = self.girlNum + 1
    self.tab_Widgets.txt_girlNum.text = self.girlNum
  end
end

function BuildShipGirlPage:_DecreaseNum(...)
  if self.girlNum > 1 then
    self.girlNum = self.girlNum - 1
    self.tab_Widgets.txt_girlNum.text = self.girlNum
  end
end

function BuildShipGirlPage:_ClickStartBuildFun()
  self.userData = Data.userData:GetUserData()
  self.needGold = self.needGold > 999 and 999 or self.needGold
  self.needGang = 999 < self.needGang and 999 or self.needGang
  self.needlv = 999 < self.needlv and 999 or self.needlv
  local TBuildItem1 = {}
  local TBuildItem2 = {}
  local TBuildProject = {}
  local TBuildItem1 = {
    ResId = self.res2[2],
    Count = self.needGang
  }
  local TBuildItem2 = {
    ResId = self.res3[2],
    Count = self.needlv
  }
  local Items = {}
  local TBuildItem = {}
  local tabBuild = {}
  local tabProject = {}
  local nameRes, str
  local goldId = 1
  if self.userData.Gold < self.needGold * self.girlNum then
    nameRes = configManager.GetDataById("config_currency", goldId)
    str = string.format(UIHelper.GetString(440002), nameRes.name)
    noticeManager:OpenTipPage(self, str)
    globalNoitceManager:ShowItemInfoPage(GoodsType.CURRENCY, CurrencyType.GOLD)
  elseif self.needGold < self.res1[1] then
    nameRes = configManager.GetDataById("config_currency", goldId)
    str = string.format(UIHelper.GetString(440001), nameRes.name)
    noticeManager:OpenTipPage(self, str)
  elseif self.gangNum < self.needGang * self.girlNum then
    nameRes = configManager.GetDataById("config_item_info", self.res2[2])
    str = string.format(UIHelper.GetString(440002), nameRes.name)
    noticeManager:OpenTipPage(self, str)
    globalNoitceManager:ShowItemInfoPage(self.res2[1], self.res2[2])
  elseif self.needGang < self.res2[3] then
    nameRes = configManager.GetDataById("config_item_info", self.res2[2])
    str = string.format(UIHelper.GetString(440001), nameRes.name)
    noticeManager:OpenTipPage(self, str)
  elseif self.lvNum < self.needlv * self.girlNum then
    nameRes = configManager.GetDataById("config_item_info", self.res3[2])
    str = string.format(UIHelper.GetString(440002), nameRes.name)
    noticeManager:OpenTipPage(self, str)
    globalNoitceManager:ShowItemInfoPage(self.res3[1], self.res3[2])
  elseif self.needlv < self.res3[3] then
    nameRes = configManager.GetDataById("config_item_info", self.res3[2])
    str = string.format(UIHelper.GetString(440001), nameRes.name)
    noticeManager:OpenTipPage(self, str)
  elseif self.maxBuild - self.girlNum - (self.buildedNum + self.buildingNum + self.waitingNum) < 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(440003))
  else
    table.insert(TBuildItem, TBuildItem1)
    table.insert(TBuildItem, TBuildItem2)
    TBuildProject.Gold = self.needGold
    table.insert(Items, TBuildItem[1])
    table.insert(Items, TBuildItem[2])
    TBuildProject.Items = Items
    for i = 1, self.girlNum do
      table.insert(tabProject, TBuildProject)
    end
    tabBuild.Project = tabProject
    Service.buildService:SendBuildingByFormula(tabBuild)
  end
end

function BuildShipGirlPage:_ClickPeiFangFun()
  local last = Data.buildData:GetData().BuildedLast
  if last == nil or last.Project.Gold == 0 then
    noticeManager:ShowMsgBox(UIHelper.GetString(440007))
    return
  end
  self.num[BuildShipResource.Gold] = self:_toTable(last.Project.Gold)
  for k, v in pairs(last.Project.Items) do
    if v.ResId == self.res2[2] then
      self.num[BuildShipResource.Gang] = self:_toTable(v.Count)
    elseif v.ResId == self.res3[2] then
      self.num[BuildShipResource.Lv] = self:_toTable(v.Count)
    end
  end
  self:_LoadGoodsInfo()
end

function BuildShipGirlPage:_LoadGirlInfo()
  self.sequeData = Data.buildData:GetData()
  local timeServer = time.getSvrTime()
  self.tab_tabPart = {}
  if self.sequeData.BuildedList ~= nil then
    self.buildedNum = #self.sequeData.BuildedList
  end
  if self.sequeData.BuildingList ~= nil then
    self.buildingNum = #self.sequeData.BuildingList
  end
  if self.sequeData.WaitingList ~= nil then
    self.waitingNum = #self.sequeData.WaitingList
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_girlInfo, self.tab_Widgets.trans_girlInfo, self.buildedNum + self.buildingNum + self.waitingNum, function(index, tabPart)
    tabPart.obj_building:SetActive(false)
    UIHelper.SetText(tabPart.tx_num, index)
    if index <= self.buildedNum then
      tabPart.obj_noBuilding:SetActive(true)
      tabPart.obj_waiting:SetActive(false)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_anniu, function()
        self:_ClickScucess(self, index)
      end)
      UIHelper.SetImage(tabPart.im_bg, "uipic_ui_formulabuild_bg_jianzaowancheng")
    elseif index <= self.buildedNum + self.buildingNum then
      UIHelper.SetImage(tabPart.im_bg, "uipic_ui_formulabuild_bg_jianzaozhong")
      local nIdex = index - self.buildedNum
      tabPart.obj_noBuilding:SetActive(false)
      tabPart.obj_waiting:SetActive(false)
      local tabBuilding = self.sequeData.BuildingList[nIdex]
      local timeFinish = tabBuilding.EndTime
      local deltaTime = math.modf(timeFinish - timeServer)
      tabTimeInfo = {tabPart = tabPart, deltaTime = deltaTime}
      table.insert(self.tab_tabPart, tabTimeInfo)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_building, function()
        self:_ClickQuickTool(self, nIdex)
      end)
      UIHelper.SetText(tabPart.txt_time, time.formatTimerToHMSColonZeroTime(deltaTime, true))
      tabPart.obj_building:SetActive(true)
    elseif index <= self.buildedNum + self.buildingNum + self.waitingNum then
      UIHelper.SetImage(tabPart.im_bg, "uipic_ui_formulabuild_bg_weikaishi")
      tabPart.obj_noBuilding:SetActive(false)
      tabPart.obj_waiting:SetActive(true)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_anniu, function()
        self:_ClickWaiting()
      end)
    end
  end)
end

function BuildShipGirlPage:_ClickScucess(go, index)
  local sum = Logic.shipLogic:GetBaseShipNum()
  local size = Data.heroData:GetHeroData()
  local num = {}
  for v, k in pairs(size) do
    table.insert(num, v)
  end
  if sum <= #num then
    noticeManager:OpenTipPage(self, UIHelper.GetString(110012))
  else
    local buildedList = self.sequeData.BuildedList
    local girlData = buildedList[index]
    UIHelper.SetUILock(true)
    Service.buildService:SendBuildReceive(index, girlData)
  end
end

function BuildShipGirlPage:_ClickQuickTool(go, index)
  if self.quickNum > 0 then
    self:_SequeInfo()
    local param = {
      msgType = NoticeType.TwoButton,
      timeFinish = timeFinish,
      callback = function(bool)
        if bool then
          if self.sequeData.BuildingList[index] then
            local tabBuilding = self.sequeData.BuildingList[index]
            local timeFinish = tabBuilding.EndTime
            local timeServer = time.getSvrTime()
            if timeFinish <= timeServer then
              noticeManager:OpenTipPage(self, "\229\187\186\233\128\160\229\183\178\231\187\143\229\174\140\230\136\144\229\149\166")
            else
              Service.buildService:SendBuildIndex(index)
            end
          elseif self.sequeData.BuildingList[index - 1] then
            local tabBuilding = self.sequeData.BuildingList[index - 1]
            local timeFinish = tabBuilding.EndTime
            local timeServer = time.getSvrTime()
            if timeFinish <= timeServer then
              noticeManager:OpenTipPage(self, "\229\187\186\233\128\160\229\183\178\231\187\143\229\174\140\230\136\144\229\149\166")
            else
              Service.buildService:SendBuildIndex(index - 1)
            end
          else
            noticeManager:OpenTipPage(self, "\229\187\186\233\128\160\229\183\178\231\187\143\229\174\140\230\136\144\229\149\166")
          end
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(440004), param)
  else
    globalNoitceManager:_OpenGoShopBox(10031)
  end
end

function BuildShipGirlPage:_GetBuildShipId(param)
  UIHelper.SetUILock(false)
  local tabGirl = param.info.reward
  local reward = {}
  if next(param.info.SpReward) ~= nil then
    reward = param.info.SpReward[1].Reward
  end
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(tabGirl[1].ConfigId)
  local gangNum = 0
  local lvNum = 0
  for v, k in pairs(param.state.Project.Items) do
    if k.ResId == 10029 then
      gangNum = k.Count
    elseif k.ResId == 10030 then
      lvNum = k.Count
    end
  end
  local gold = param.state.Project.Gold
  local formula = {
    gold,
    gangNum,
    lvNum
  }
  UIHelper.OpenPage("ShowGirlPage", {
    girlId = si_id,
    HeroId = tabGirl[1].Id,
    getWay = GetGirlWay.girl,
    buildNum = tabGirl[1].Num,
    formula = formula,
    spReward = reward
  })
end

function BuildShipGirlPage:_GetQuicklyFinish(err)
  UIHelper.SetUILock(false)
  if err ~= 0 then
    noticeManager:OpenTipPage(self, err)
  else
    local dotinfo = {
      info = "ui_formulabuild_accelerate"
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    self:_SequeInfo()
  end
end

function BuildShipGirlPage:_GetBuildingByFormula(err)
  if err == 0 then
    local dotinfo = {
      info = "ui_formulabuild_start",
      cost_num = {
        self.needGold,
        self.needGang,
        self.needlv
      },
      build_num = self.girlNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
    self.tab_Widgets.tog_group:SetActiveToggleIndex(BuildShipGirl.Quene)
    Logic.buildLogic:SetTogLastIndex(BuildShipGirl.Quene)
  end
end

function BuildShipGirlPage:_ClickWaiting()
  noticeManager:OpenTipPage(self, "\232\175\183\231\173\137\229\190\133")
end

function BuildShipGirlPage:_TickCharge()
  for v, k in pairs(self.tab_tabPart) do
    UIHelper.SetText(k.tabPart.txt_time, time.formatTimerToHMSColonZeroTime(k.deltaTime, true))
    if k.deltaTime <= 0 then
      Service.buildService:SendBuildGirlInfo()
    else
      k.deltaTime = k.deltaTime - 1
    end
  end
end

function BuildShipGirlPage:_UpdataSeque(err)
  if err == 0 then
    self:_LoadGoodsInfo()
    self:_LoadGirlInfo()
    self:_SequeInfo()
  end
end

function BuildShipGirlPage:_UpdataNotesInfo()
  if self.tabNotesInfo ~= nil then
    self.tabNotesInfo = Data.buildData:GetNotesData()
    if self.tabNotesInfo.List ~= nil then
      local notesInfo = Logic.buildLogic:FilterAndSort(self.tabNotesInfo.List, self.notesIndex)
      self:_LoadNotes(notesInfo)
    end
  end
end

function BuildShipGirlPage:_SwitchNotesTogs(index)
  self.notesIndex = index + 1
  self:_UpdataNotesInfo()
end

function BuildShipGirlPage:_LoadNotes(notesInfo)
  local userInfo = Data.userData:GetUserData()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.ill_noteItem, self.tab_Widgets.obj_notesInfo, #notesInfo, function(luaPart)
    for index, tabPart in pairs(luaPart) do
      index = tonumber(index)
      local goldIcon = Logic.currencyLogic:GetTexIcon(1)
      local gangIcon = Logic.itemLogic:GetSmallIcon(self.res2[2])
      local lvIcon = Logic.itemLogic:GetSmallIcon(self.res3[2])
      UIHelper.SetImage(tabPart.im_notesGoldIcon, goldIcon)
      UIHelper.SetImage(tabPart.im_notesGangIcon, gangIcon)
      UIHelper.SetImage(tabPart.im_notesLvIcon, lvIcon)
      UIHelper.SetText(tabPart.tx_notesGoldNum, math.modf(notesInfo[index].BuildedInfo.Project.Gold))
      for v, k in pairs(notesInfo[index].BuildedInfo.Project.Items) do
        if k.ResId == self.res2[2] then
          UIHelper.SetText(tabPart.tx_notesGangNum, math.modf(k.Count))
        elseif k.ResId == self.res3[2] then
          UIHelper.SetText(tabPart.tx_notesLvNum, math.modf(k.Count))
        end
      end
      local shipShow = Logic.shipLogic:GetShipShowById(notesInfo[index].BuildedInfo.HeroId)
      local shipInfo = Logic.shipLogic:GetShipInfoById(notesInfo[index].BuildedInfo.HeroId)
      UIHelper.SetText(tabPart.tx_quality, HeroRarity[shipInfo.quality])
      UIHelper.SetText(tabPart.tx_type, HeroTypeContent[shipInfo.ship_type])
      UIHelper.SetText(tabPart.tx_name, shipInfo.ship_name)
      UIHelper.SetImage(tabPart.im_girl, shipShow.ship_icon5)
      UIHelper.SetImage(tabPart.im_quality, QualityIcon[shipInfo.quality])
      UIHelper.SetText(tabPart.tx_userName, notesInfo[index].Name)
      local endTimeFormat = time.formatTimeToYMDHM(notesInfo[index].BuildedInfo.EndTime)
      UIHelper.SetText(tabPart.tx_time, endTimeFormat)
      UIHelper.SetText(tabPart.tx_zanNum, math.modf(notesInfo[index].Count))
      tabPart.im_zan.gameObject:SetActive(false)
      for v, k in pairs(userInfo.BuildNotesList) do
        if k.Htid == notesInfo[index].BuildedInfo.HeroId and k.Time == notesInfo[index].BuildedInfo.EndTime then
          tabPart.im_zan.gameObject:SetActive(true)
          break
        else
          tabPart.im_zan.gameObject:SetActive(false)
        end
      end
      local awardGirl = {
        3,
        notesInfo[index].BuildedInfo.HeroId
      }
      UGUIEventListener.AddButtonOnClick(tabPart.btn_zan, self._ClickZan, self, notesInfo[index].BuildedInfo)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_girl, self._ShowItemInfo, self, awardGirl)
      UGUIEventListener.AddButtonOnClick(tabPart.obj_use, self._Use, self, notesInfo[index].BuildedInfo)
    end
  end)
end

function BuildShipGirlPage:_ClickZan(go, heroInfo)
  noticeManager:OpenTipPage(self, 140224)
  Service.buildService:SendBuildHeroLike(heroInfo.HeroId)
end

function BuildShipGirlPage:_Use(go, info)
  self.num[BuildShipResource.Gold] = self:_toTable(info.Project.Gold)
  for v, k in pairs(info.Project.Items) do
    if k.ResId == self.res2[2] then
      self.num[BuildShipResource.Gang] = self:_toTable(k.Count)
    elseif k.ResId == self.res3[2] then
      self.num[BuildShipResource.Lv] = self:_toTable(k.Count)
    end
  end
  self:_LoadGoodsInfo()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(BuildShipGirl.Build)
end

function BuildShipGirlPage:SetUILock()
  UIHelper.SetUILock(false)
end

function BuildShipGirlPage:DoOnHide()
  self.tab_Widgets.tog_group:ClearToggles()
  self.tab_Widgets.obj_togRarity:ClearToggles()
end

function BuildShipGirlPage:DoOnClose()
  self.tab_Widgets.tog_group:ClearToggles()
  self.tab_Widgets.obj_togRarity:ClearToggles()
  UIHelper.SetUILock(false)
end

return BuildShipGirlPage
