local BuildEquipPage = class("UI.Build.BuildEquipPage", LuaUIPage)
local RECURUIT_ID = 10181
local EXPEND_COUNT = 2
local BUILD_ONE = 1
local BUILD_TEN = 10
local EQUIP_TYPE = 3
local Quality = {
  "ssr",
  "sr",
  "r",
  "n"
}

function BuildEquipPage:DoInit()
  self.buildType = EQUIP_TYPE
end

function BuildEquipPage:DoOnOpen()
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local index = PlayerPrefs.GetInt(uid .. "JumpHomeRightPage", 0)
  if index ~= 0 then
    eventManager:SendEvent(LuaEvent.HomePlayTween, true)
  end
  eventManager:SendEvent(LuaEvent.HomePageOtherPageOpen, LeftOpenInde.BuildShip)
  local buildId = configManager.GetDataById("config_parameter", 169).value
  self.buildConfigInfo = configManager.GetDataById("config_extract_ship", buildId)
  self:_ShowExpend()
  self:_ShowOwnItem()
  self:_ShowSurplusTimes()
  self:SetBuildToggle()
  self:SetDropRate()
  local bagInfo = Logic.bagLogic:ItemInfoById(RECURUIT_ID)
  local itemNum = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  local dotInfo = {
    info = "build_equip",
    item_num = itemNum
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
  if not UIPageManager:IsExistPage("TopPage") then
    self:OpenTopPage(nil, 0, nil, self)
  end
end

function BuildEquipPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.CloseLeftPage, self._CloseBuildPage, self)
  self:RegisterEvent(LuaEvent.CacheDataRet, self._CacheDataRet, self)
  self:RegisterEvent(LuaEvent.BuildFinish, self._ShowEquip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closePage, self._CloseBuildPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ship, self._ToBuildShip, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_build, self._ClickBuildOne, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ten, self._ClickBuildTen, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_helpOk, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeHelp, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OpenHelp, self)
end

function BuildEquipPage:_ToBuildShip()
  UIHelper.OpenPage("BuildShipPage")
  UIHelper.ClosePage(self:GetName())
end

function BuildEquipPage:SetBuildToggle()
  self.tab_Widgets.obj_ship_selected:SetActive(false)
  self.tab_Widgets.obj_equip_selected:SetActive(true)
end

function BuildEquipPage:_ShowSurplusTimes()
  local normalCount = Data.buildShipData:GetEquipCount()
  local limitCount = self.buildConfigInfo.special_num
  local times = limitCount - normalCount % limitCount
  self.tab_Widgets.obj_tenTimes:SetActive(times ~= 1)
  self.tab_Widgets.obj_oneTimes:SetActive(times == 1)
  self.tab_Widgets.txt_times.text = math.tointeger(times)
end

function BuildEquipPage:_ShowOwnItem()
  local bagInfo = Logic.bagLogic:ItemInfoById(RECURUIT_ID)
  local itemNum = bagInfo == nil and 0 or math.tointeger(bagInfo.num)
  self.tab_Widgets.txt_itemNum.text = "x" .. itemNum
end

function BuildEquipPage:_ShowExpend()
  local expend = self.buildConfigInfo.expend
  if #expend > EXPEND_COUNT then
    logError("expend err")
    return
  end
  local expendType = {}
  local itemInfo = {}
  for i = 1, #expend do
    expendType = configManager.GetDataById("config_table_index", tonumber(expend[i][1]))
    itemInfo = configManager.GetDataById(expendType.file_name, tonumber(expend[i][2]))
    if expend[i][2] == RECURUIT_ID then
      UIHelper.SetImage(self.tab_Widgets["img_expend" .. tostring(i)], "uipic_ui_icon_build_tuijianxin_xiao")
    else
      UIHelper.SetImage(self.tab_Widgets["img_expend" .. tostring(i)], tostring(itemInfo.icon))
    end
    self.tab_Widgets["txt_expend" .. tostring(i)].text = "x" .. expend[i][3]
  end
  for i = 1, #expend do
    expendType = configManager.GetDataById("config_table_index", tonumber(expend[i][1]))
    itemInfo = configManager.GetDataById(expendType.file_name, tonumber(expend[i][2]))
    if expend[i][2] == RECURUIT_ID then
      UIHelper.SetImage(self.tab_Widgets["img_expendTen" .. tostring(i)], "uipic_ui_icon_build_tuijianxin_xiao")
    else
      UIHelper.SetImage(self.tab_Widgets["img_expendTen" .. tostring(i)], tostring(itemInfo.icon))
    end
    self.tab_Widgets["txt_expendTen" .. tostring(i)].text = "x" .. expend[i][3] * 10
  end
  UIHelper.SetLocText(self.tab_Widgets.txt_desc, 1200003)
end

function BuildEquipPage:SetDropRate()
  UIHelper.SetLocText(self.tab_Widgets.txt_title, 1200002)
  local dropRate = configManager.GetDataById("config_parameter", 170).arrValue
  for i, rate in pairs(dropRate) do
    if rate <= 0 then
      self.tab_Widgets["obj_" .. Quality[i]]:SetActive(false)
      UIHelper.SetText(self.tab_Widgets["txt_" .. Quality[i]], "")
    else
      UIHelper.SetText(self.tab_Widgets["txt_" .. Quality[i]], rate .. "%")
    end
  end
end

function BuildEquipPage:_ClickBuildTen()
  self.buildNum = BUILD_TEN
  self:_ClickBuild()
end

function BuildEquipPage:_ClickBuildOne()
  self.buildNum = BUILD_ONE
  self:_ClickBuild()
end

function BuildEquipPage:_ClickBuild()
  if not self:_CheckExpend() then
    return
  end
  local bagFree = Logic.buildShipLogic:GetEquipBagFree()
  local needNum = self.buildNum * 2
  if bagFree < needNum then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          UIHelper.ClosePage("NoticePage")
          UIHelper.OpenPage("DismantlePage")
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(170016), tabParams)
    return
  end
  Service.cacheDataService:SendCacheData("buildship.BuildShip")
end

function BuildEquipPage:_CheckExpend()
  local limit = {}
  local expend = self.buildConfigInfo.expend
  for i = 1, #expend do
    if expend[i][1] == 5 then
      local count = Data.userData:GetCurrency(expend[i][2])
      if count < expend[i][3] * self.buildNum then
        noticeManager:OpenTipPage(self, "\233\135\145\229\184\129\228\184\141\232\182\179")
        return false
      end
    elseif expend[i][1] == 1 then
      local bagInfo = Logic.bagLogic:ItemInfoById(expend[i][2])
      if not bagInfo or bagInfo.num < expend[i][3] * self.buildNum then
        globalNoitceManager:_OpenGoShopBox(expend[i][2])
        return false
      end
    end
  end
  return true
end

function BuildEquipPage:_CloseBuildPage()
  eventManager:SendEvent(LuaEvent.HomePageOtherPageClose)
  UIHelper.ClosePage(self:GetName())
end

function BuildEquipPage:_CacheDataRet(ret)
  self.orderId = ret
  local arg = {
    BuildShipType = self.buildType,
    BuildShipNum = self.buildNum,
    CacheId = self.orderId
  }
  Service.buildShipService:SendBuildShipReq(arg)
end

function BuildEquipPage:_makeRewardShowData(rewards)
  local showDatas = {}
  for k, reward in pairs(rewards) do
    local show = {}
    show.ConfigId = reward.TemplateId
    show.Type = reward.TypeId
    show.Num = reward.Num
    table.insert(showDatas, show)
  end
  return showDatas
end

function BuildEquipPage:_ShowEquip(rewards)
  self:_ShowSurplusTimes()
  self:_ShowOwnItem()
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards.BuildShipResult,
    Page = "BuildEquipPage"
  })
end

function BuildEquipPage:_OpenHelp()
  self.tab_Widgets.obj_help:SetActive(true)
end

function BuildEquipPage:_ClickHelp()
  self.tab_Widgets.obj_help:SetActive(false)
end

return BuildEquipPage
