local EquipNewTestPage = class("UI.Activity.EquipNewTestPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local txtGrades = {
  "txt_s",
  "txt_ss",
  "txt_sss"
}
local sgrades = {
  "s",
  "ss",
  "sss"
}

function EquipNewTestPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.m_curIndex = 1
end

function EquipNewTestPage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.activityId = params.activityId
  self.activityCfg = configManager.GetDataById("config_activity", self.activityId)
  self.maxNum = #self.activityCfg.p1
  self:_ShowPage()
  Logic.equipNewTestLogic:SetDot(false)
  eventManager:SendEvent(LuaEvent.EquipNewTestOpenDot)
end

function EquipNewTestPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_help, self.OnBtnHelp, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_copy, self.OnBtnCopy, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_left, self.OnBtnLeft, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_right, self.OnBtnRight, self)
  self:RegisterEvent(LuaEvent.EquipNewTestReceiveRewards, self._ShowPage, self)
  self:RegisterEvent(LuaEvent.FetchRewardBox, self._ShowPage, self)
end

function EquipNewTestPage:_ShowPage()
  self.m_curIndex = Logic.equipNewTestLogic:GetCopyIndex()
  self:__ShowSlice()
  self:__ShowCopyDetail()
end

function EquipNewTestPage:__ShowSlice()
  local widgets = self.tab_Widgets
  local damageData = self.activityCfg.p4[self.m_curIndex]
  local sssDamage = damageData[#damageData]
  local startPos = widgets.obj_start.position.x
  local endPos = widgets.obj_end.position.x
  for i, data in ipairs(damageData) do
    local arrowX = data / sssDamage * (endPos - startPos) + startPos
    local oldPos = widgets["obj_" .. sgrades[i]].position
    widgets["obj_" .. sgrades[i]].position = Vector3.New(arrowX, oldPos.y, oldPos.z)
  end
  local maxDamage = Data.equipNewTestData:GetMaxDamageByCopy(self.m_curIndex)
  for i = 1, #sgrades do
    local l_damege = self.activityCfg.p4[self.m_curIndex][i]
    local content = UIHelper.GetString(self.activityCfg.p7[self.m_curIndex][i])
    if maxDamage > l_damege then
      content = UIHelper.SetColor(content, "ffffff")
    end
    UIHelper.SetText(widgets["txt_" .. sgrades[i]], content)
  end
  UIHelper.SetText(widgets.txt_damage, maxDamage)
  local percent = maxDamage / sssDamage
  widgets.slider.value = percent
  self:UpdateBoxes()
end

function EquipNewTestPage:UpdateBoxes()
  local widgets = self:GetWidgets()
  local boxCfg = configManager.GetDataById("config_starbox", 5)
  local rewardData = self.activityCfg.p5[self.m_curIndex]
  local maxDamage = Data.equipNewTestData:GetMaxDamageByCopy(self.m_curIndex)
  local receiveInfo = Data.equipNewTestData:GetReceivedRewardsByCopy(self.m_curIndex)
  for DamageIndex, rewardId in ipairs(rewardData) do
    local tabPart = widgets["box_" .. sgrades[DamageIndex]]:GetLuaTableParts()
    local rewardState
    if maxDamage >= self.activityCfg.p4[self.m_curIndex][DamageIndex] then
      if receiveInfo[DamageIndex] then
        UIHelper.SetImage(tabPart.icon, boxCfg.recieved_icon)
        tabPart.Effect:SetActive(false)
        rewardState = RewardState.Received
      else
        UIHelper.SetImage(tabPart.icon, boxCfg.open_icon)
        tabPart.Effect:SetActive(true)
        rewardState = RewardState.Receivable
      end
    else
      UIHelper.SetImage(tabPart.icon, boxCfg.unopen_icon)
      tabPart.Effect:SetActive(false)
      rewardState = RewardState.UnReceivable
    end
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    local param = {}
    param.rewardState = rewardState
    param.rewards = rewards
    
    function param.callback()
      if not Logic.activityLogic:CheckActivityOpenById(self.activityId) or not self:IsCopyOpen(self.m_curIndex) then
        noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
      else
        local tab = {
          CopyIndex = self.m_curIndex,
          DamageIndex = DamageIndex
        }
        Service.equipNewTestService:GetEquipNewTestRewards(tab, rewards)
      end
    end
    
    UGUIEventListener.AddButtonOnClick(tabPart.btn, self._BtnRewardBox, self, param)
  end
end

function EquipNewTestPage:_BtnRewardBox(go, param)
  UIHelper.OpenPage("BoxRewardPage", param)
end

function EquipNewTestPage:__GetRewardState(DamageIndex)
  self.m_curIndex = Logic.equipNewTestLogic:GetCopyIndex()
  local maxDamage = Data.equipNewTestData:GetMaxDamageByCopy(self.m_curIndex)
  local receiveInfo = Data.equipNewTestData:GetReceivedRewardsByCopy(self.m_curIndex)
  local rewardState
  if maxDamage >= self.activityCfg.p4[self.m_curIndex][DamageIndex] then
    if receiveInfo[DamageIndex] then
      rewardState = RewardState.Received
    else
      rewardState = RewardState.Receivable
    end
  else
    rewardState = RewardState.UnReceivable
  end
  return rewardState
end

function EquipNewTestPage:__ShowCopyDetail()
  local widgets = self.tab_Widgets
  UIHelper.SetImage(widgets.img_title, self.activityCfg.p6[self.m_curIndex])
  UIHelper.SetImage(widgets.img_bg, self.activityCfg.p8[self.m_curIndex])
  UIHelper.SetLocText(widgets.txt_time, self.activityCfg.p10[self.m_curIndex])
  UIHelper.SetLocText(widgets.tx_battlerule, self.activityCfg.p3[self.m_curIndex])
  UIHelper.SetImage(widgets.img_copy, self.activityCfg.p12[self.m_curIndex])
  UIHelper.SetImage(widgets.img_instruction, self.activityCfg.p13[self.m_curIndex])
  widgets.btn_left.gameObject:SetActive(self.m_curIndex ~= 1)
  widgets.btn_right.gameObject:SetActive(self.m_curIndex ~= self.maxNum)
end

function EquipNewTestPage:OnBtnLeft()
  self.m_curIndex = Logic.equipNewTestLogic:GetCopyIndex()
  if self.m_curIndex == 1 then
    return
  else
    local tmpIndex = self.m_curIndex - 1
    local isOpen = self:IsCopyOpen(tmpIndex)
    if isOpen then
      self:SetCopyIndex(tmpIndex)
      self:_ShowPage()
    else
      local str = self.activityCfg.p9[tmpIndex]
      noticeManager:OpenTipPage(self, str)
      return
    end
  end
end

function EquipNewTestPage:OnBtnRight()
  self.m_curIndex = Logic.equipNewTestLogic:GetCopyIndex()
  if self.m_curIndex == self.maxNum then
    return
  else
    local tmpIndex = self.m_curIndex + 1
    local isOpen = self:IsCopyOpen(tmpIndex)
    if isOpen then
      self:SetCopyIndex(tmpIndex)
      self:_ShowPage()
    else
      local str = self.activityCfg.p9[tmpIndex]
      noticeManager:OpenTipPage(self, str)
      return
    end
  end
end

function EquipNewTestPage:OnBtnHelp()
  UIHelper.OpenPage("HelpPage", {
    content = self.activityCfg.p11[1]
  })
end

function EquipNewTestPage:OnBtnCopy()
  self.m_curIndex = Logic.equipNewTestLogic:GetCopyIndex()
  local isOpen = self:IsCopyOpen(self.m_curIndex)
  if not isOpen then
    noticeManager:OpenTipPage(self, self.activityCfg.p9[self.m_curIndex])
    return
  end
  local copyId = self.activityCfg.p1[self.m_curIndex]
  local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    copyId = copyId,
    tabSerData = copyData,
    chapterId = chapterId,
    IsRunningFight = false
  }
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function EquipNewTestPage:SetCopyIndex(index)
  Logic.equipNewTestLogic:SetCopyIndex(index)
end

function EquipNewTestPage:IsCopyOpen(copyIndex)
  local areaList = self.activityCfg.p14
  local area = areaList[copyIndex]
  local isOpen = PeriodManager:IsInPeriodArea(self.activityCfg.period, area)
  return isOpen
end

function EquipNewTestPage:DoOnClose()
end

return EquipNewTestPage
