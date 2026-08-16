local CodeExchangeActivityPage = class("UI.Activity.CodeExchangeActivityPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local CommonType = 10000
local rewardFlag = 1
local SubPage = {REWARD = 1, CODE = 2}
local rate_num = configManager.GetDataById("config_parameter", 357).value

function CodeExchangeActivityPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.m_subPage = SubPage.REWARD
  self.m_isClick = false
  self.mActivityId = nil
  self.mActivityType = nil
end

function CodeExchangeActivityPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.RefreshCodeExgItem, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_switch, self._ClickSwitch, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_goto, self._ClickGoTo, self)
end

function CodeExchangeActivityPage:_ClickSwitch()
  self.m_isClick = true
  local now = self.m_subPage
  local animatorArr = self.tab_Widgets.root:GetComponentsInChildren(UnityEngine_Animator.GetClassType())
  self.m_animList = {}
  for i = 0, animatorArr.Length - 1 do
    table.insert(self.m_animList, animatorArr[i])
  end
  if now == SubPage.REWARD then
    self.m_subPage = SubPage.CODE
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("Float", 1)
    end
  else
    self.m_subPage = SubPage.REWARD
    for _, animator in ipairs(self.m_animList) do
      animator:SetFloat("Float", -1)
    end
  end
  self:ShowPage()
end

function CodeExchangeActivityPage:_ClickGoTo()
  local config = {}
  local configAll = configManager.GetData("config_home_activity_enter")
  for i, v in pairs(configAll) do
    if self.mActivityId == v.activity_id then
      config = v
    end
  end
  if config then
    moduleManager:JumpToFunc(config.jump_function, table.unpack(config.jump_para))
  end
end

function CodeExchangeActivityPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self.mExgList = {}
  self.m_timer = self:CreateTimer(function()
    self:_TickCharge()
  end, 0.5, -1, false)
  self:StartTimer(self.m_timer)
  self:ShowPage()
end

function CodeExchangeActivityPage:_TickCharge()
  if self.m_isClick == false then
    self:ShowPage()
  end
end

function CodeExchangeActivityPage:ShowPage()
  self:ShowExgCodePage()
  self:ShowExgRewardPage()
  self:ShowBtn()
end

function CodeExchangeActivityPage:ShowBtn()
  local widgets = self.tab_Widgets
  local configData = configManager.GetDataById("config_activity", self.mActivityId)
  local isInTime = configData.period > 0 and PeriodManager:IsInPeriodArea(configData.period, configData.p3)
  widgets.btn_goto.gameObject:SetActive(isInTime)
  widgets.obj_overDate.gameObject:SetActive(not isInTime)
end

function CodeExchangeActivityPage:ShowExgCodePage()
  local widgets = self.tab_Widgets
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local itemList = actData.p5
  local tmpOk = {}
  local tmpNo = {}
  for oriid, v in pairs(itemList) do
    local canExg = Logic.bagLogic:GetBagItemNum(v[1]) >= rate_num
    if canExg then
      table.insert(tmpOk, {v, oriid})
    else
      table.insert(tmpNo, {v, oriid})
    end
  end
  for i, v in pairs(tmpNo) do
    table.insert(tmpOk, v)
  end
  local rect = widgets.rect_exgContent
  local item = widgets.item_exg
  UIHelper.CreateSubPart(item, rect, #tmpOk, function(index, tabParts)
    local team = tmpOk[index][1]
    local consume = team[1]
    local reward = team[2]
    self:_ShowCodeItem(tabParts.Content_consume, tabParts.consume, {
      {id = consume, num = rate_num}
    })
    self:_ShowCodeItem(tabParts.Content_reward, tabParts.reward, {
      {id = reward, num = 1}
    })
    local canExg = Logic.bagLogic:GetBagItemNum(consume) >= rate_num
    tabParts.grayGroup.Gray = not canExg
    UGUIEventListener.AddButtonOnClick(tabParts.btn_get, function()
      UIHelper.OpenPage("CodeExchangeConfirmPage", {
        actId = self.mActivityId,
        exgid = index,
        teamId = tmpOk[index][2],
        teamLine = team,
        pageType = codeExgType.Code
      })
    end)
  end)
end

function CodeExchangeActivityPage:_ShowCodeItem(content, obj, list)
  local itemList = list
  local rect = content
  local item = obj
  UIHelper.CreateSubPart(item, rect, #itemList, function(index, tabPart)
    local itemInfo = configManager.GetDataById("config_item_info", itemList[index].id)
    local BagNum = Logic.bagLogic:GetBagItemNum(itemList[index].id)
    UIHelper.SetImage(tabPart.img_icon, itemInfo.icon)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabPart.tx_num, itemList[index].num)
    UIHelper.SetText(tabPart.tx_currentnum, BagNum)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemList[index].id / CommonType), itemList[index].id))
    end)
  end)
end

function CodeExchangeActivityPage:ShowExgRewardPage()
  local widgets = self.tab_Widgets
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local HorizList = actData.p2
  local VertList = actData.p1
  self.mExgList = actData.p4
  self:ShowHoriz(HorizList, widgets.rect_needs_horiz, widgets.item_consume_horiz)
  self:ShowHoriz(VertList, widgets.rect_needs_vert, widgets.item_consume_vert)
  self:ShowFormat()
end

function CodeExchangeActivityPage:ShowHoriz(list, content, obj)
  local itemList = list
  local rect = content
  local item = obj
  UIHelper.CreateSubPart(item, rect, #itemList, function(index, tabParts)
    local itemId = itemList[index]
    if itemId == -1 then
      tabParts.img_icon.gameObject:SetActive(false)
    else
      local itemInfo = configManager.GetDataById("config_item_info", itemId)
      UIHelper.SetImage(tabParts.img_icon, itemInfo.icon_small)
      UIHelper.SetImage(tabParts.img_quality, QualityIcon[itemInfo.quality])
      local BagNum = Logic.bagLogic:GetBagItemNum(itemId)
      UIHelper.SetText(tabParts.tx_num, BagNum)
      UGUIEventListener.AddButtonOnClick(tabParts.btn_icon, function()
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(math.floor(itemId / CommonType), itemId))
      end)
    end
  end)
end

function CodeExchangeActivityPage:ShowFormat()
  local widgets = self.tab_Widgets
  local itemList = self.mExgList
  local rect = widgets.rect_rewards
  local item = widgets.item_reward
  UIHelper.CreateSubPart(item, rect, #itemList, function(index, tabParts)
    local itemId = itemList[index][1]
    local rewardConfig = configManager.GetDataById("config_rewards", itemId)
    local data = rewardConfig.rewards[rewardFlag]
    local itemInfo = ItemInfoPage.GenDisplayData(data[1], data[2])
    UIHelper.SetImage(tabParts.icon, itemInfo.icon)
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[itemInfo.quality])
    UIHelper.SetText(tabParts.tx_num, data[3])
    local isInfinite, remainNum = Logic.activityCodeExchangeLogic:GetRemainChangeTime(self.mActivityId, index)
    tabParts.obj_remain.gameObject:SetActive(not isInfinite)
    UIHelper.SetText(tabParts.txt_remain_num, remainNum)
    local open = self:_IsUnLock(index)
    local sellOut = not isInfinite and remainNum <= 0
    tabParts.obj_sellOut.gameObject:SetActive(sellOut)
    tabParts.obj_lock.gameObject:SetActive(not open)
    UGUIEventListener.AddButtonOnClick(tabParts.obj_sellOut, function()
      noticeManager:ShowTip(UIHelper.GetString(81005001))
    end)
    if open and not sellOut then
      UGUIEventListener.AddButtonOnClick(tabParts.btn_icon, function()
        local actData = configManager.GetDataById("config_activity", self.mActivityId)
        local x, y = Logic.activityCodeExchangeLogic:GetAxesByExgId(self.mActivityId, index)
        if actData.p1[x] == -1 and actData.p2[y] == -1 then
          local tab = {RewardId = index, Number = 1}
          Service.activityCodeExchangeService:SendExchangeReward(tab, {id = index, num = 1})
        else
          UIHelper.OpenPage("CodeExchangeConfirmPage", {
            actId = self.mActivityId,
            exgid = index,
            pageType = codeExgType.Reward
          })
        end
      end)
    end
  end)
end

function CodeExchangeActivityPage:_IsUnLock(exgid)
  local x, y = Logic.activityCodeExchangeLogic:GetAxesByExgId(self.mActivityId, exgid)
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  if actData.p1[x] == -1 and actData.p2[y] == -1 then
    return true
  end
  local HorizList = configManager.GetDataById("config_activity", self.mActivityId).p1
  local Left = Logic.activityCodeExchangeLogic:GetStateByAxes(x, y - 1, #HorizList)
  local Up = Logic.activityCodeExchangeLogic:GetStateByAxes(x - 1, y, #HorizList)
  local UnLock = Up or Left
  return UnLock
end

function CodeExchangeActivityPage:DoOnClose()
end

return CodeExchangeActivityPage
