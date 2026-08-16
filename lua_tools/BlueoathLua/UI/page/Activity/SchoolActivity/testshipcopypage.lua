local TestShipCopyPage = class("ui.page.Activity.SchoolActivity.TestShipCopyPage", LuaUIPage)
local plotCopyDetailPage = require("ui.page.Copy.PlotCopyDetailPage")

function TestShipCopyPage:DoInit()
  self.mItemList = {
    self.tab_Widgets.item1,
    self.tab_Widgets.item2,
    self.tab_Widgets.item3,
    self.tab_Widgets.item4,
    self.tab_Widgets.item5
  }
end

function TestShipCopyPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  local jumpParam = params.jumpParam or {}
  if jumpParam[2] ~= nil then
    self.mJumpChapter = jumpParam[2]
  end
  self:ShowPage()
end

function TestShipCopyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.ShipTask_RefreshData, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnHelp, function()
    UIHelper.OpenPage("HelpPage", {content = 7400002})
  end)
end

function TestShipCopyPage:DoOnHide()
end

function TestShipCopyPage:DoOnClose()
end

function TestShipCopyPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.period_area)
  local heroTid = Data.shiptaskData:GetCurrentHeroTemplateId()
  if 0 < heroTid then
    self.tab_Widgets.objShip:SetActive(true)
    self.tab_Widgets.objDefault:SetActive(false)
    local shipInfo = Logic.shipLogic:GetShipInfoIdByTid(heroTid)
    shipInfo = Logic.shipLogic:GetShipInfoBySiId(shipInfo)
    local shipshow = Logic.shipLogic:GetShipShowById(heroTid)
    UIHelper.SetText(self.tab_Widgets.textShipName, shipInfo.ship_name)
    UIHelper.SetImage(self.tab_Widgets.imgGirl, shipshow.ship_draw)
    UIHelper.SetImage(self.tab_Widgets.imgBlack, shipshow.ship_draw_black)
    Logic.activityLogic:SetGirlImgPosition(self.tab_Widgets.imgShip, shipshow)
  else
    self.tab_Widgets.objShip:SetActive(false)
    self.tab_Widgets.objDefault:SetActive(true)
  end
  if self.mTimer ~= nil then
    self.mTimer:Stop()
    self.mTimer = nil
  end
  local setShipTime = Data.shiptaskData:GetSetShipTime()
  local isInCd = false
  if 0 < setShipTime then
    local parameterCfg = configManager.GetDataById("config_parameter", 331)
    local now = time.getSvrTime()
    local endTime = setShipTime + parameterCfg.value
    if now < endTime then
      isInCd = true
      do
        local callFunc = function()
          local svrTime = time.getSvrTime()
          local surplusTime = endTime - svrTime
          if surplusTime <= 0 then
            self.mTimer:Stop()
            self.mTimer = nil
            self:ShowPage()
          else
            UIHelper.SetText(self.tab_Widgets.textCdTime, UIHelper.GetCountDownStr(surplusTime))
          end
        end
        self.mTimer = self:CreateTimer(callFunc, 1, -1)
        self.mTimer:Start()
        callFunc()
      end
    end
  end
  if isInCd then
    self.tab_Widgets.objCdInfo:SetActive(true)
    self.tab_Widgets.objChangeInfo:SetActive(false)
  else
    self.tab_Widgets.objCdInfo:SetActive(false)
    self.tab_Widgets.objChangeInfo:SetActive(true)
  end
  local funcSetShip = function()
    if isInCd then
      noticeManager:ShowTipById(7400004)
      return
    end
    local displayInfo = Logic.shipLogic:GetRidHeroTid(heroTid)
    UIHelper.OpenPage("CommonSelectPage", {
      CommonHeroItem.ShipTask,
      displayInfo,
      {m_selectMax = 1}
    })
  end
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAddShip, funcSetShip)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnChange, funcSetShip)
  local chapterIds = activityCfg.p1
  if self.mJumpChapter ~= nil then
    for index, chapterId in ipairs(chapterIds) do
      if self.mJumpChapter == chapterId then
        Logic.shiptaskLogic.TabIndex_Copy = index
        break
      end
    end
    self.mJumpChapter = nil
  end
  local mTabIndex = Logic.shiptaskLogic.TabIndex_Copy or 1
  local chapterId = chapterIds[mTabIndex]
  local chapterCfg = configManager.GetDataById("config_chapter", chapterId)
  local copyIdList = chapterCfg.level_list
  local mvpCountMax = #copyIdList
  local mvpCount = 0
  for _, copyId in ipairs(copyIdList) do
    local count = Data.shiptaskData:GetExtraMvpCount(copyId)
    if 0 < count then
      mvpCount = mvpCount + 1
    end
  end
  UIHelper.SetText(self.tab_Widgets.textMvp, mvpCount .. "/" .. mvpCountMax)
  local chapterIdsLen = #chapterIds
  local isFirst = mTabIndex == 1
  local isEnd = mTabIndex >= chapterIdsLen
  self.tab_Widgets.btnLast.gameObject:SetActive(not isFirst)
  self.tab_Widgets.btnNext.gameObject:SetActive(not isEnd)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnNext, function()
    Logic.shiptaskLogic.TabIndex_Copy = mTabIndex + 1
    if Logic.shiptaskLogic.TabIndex_Copy >= chapterIdsLen then
      Logic.shiptaskLogic.TabIndex_Copy = chapterIdsLen
    end
    self.tab_Widgets.tweenPos:ResetToBeginning()
    self.tab_Widgets.tweenPos:Play(true)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnLast, function()
    Logic.shiptaskLogic.TabIndex_Copy = mTabIndex - 1
    if Logic.shiptaskLogic.TabIndex_Copy <= 1 then
      Logic.shiptaskLogic.TabIndex_Copy = 1
    end
    self.tab_Widgets.tweenPos:ResetToBeginning()
    self.tab_Widgets.tweenPos:Play(true)
    self:ShowPage()
  end)
  for index, _ in ipairs(copyIdList) do
    local part = self.mItemList[index]:GetLuaTableParts()
    local copyId = copyIdList[index]
    local copyData = Data.copyData:GetCopyInfoById(copyId)
    local copyDisplayCfg = configManager.GetDataById("config_copy_display", copyId)
    UIHelper.SetText(part.textCopyName, copyDisplayCfg.name)
    UIHelper.SetImage(part.imgIcon, copyDisplayCfg.copy_thumbnail_before)
    local count = Data.shiptaskData:GetExtraMvpCount(copyId)
    part.objMvp:SetActive(0 < count)
    local funcGotoCopy = function()
      local chapterTypeCfg = configManager.GetDataById("config_chapter_type", chapterCfg.class_type)
      if chapterTypeCfg.function_id > 0 and not moduleManager:CheckFunc(chapterTypeCfg.function_id, true) then
        return
      end
      if copyData == nil then
        noticeManager:OpenTipPage(self, UIHelper.GetString(7600006))
      else
        if Logic.copyLogic:CheckEquipBagFull() then
          local tabParams = {
            msgType = NoticeType.TwoButton,
            callback = function(toEquip)
              if toEquip then
                UIHelper.ClosePage("NoticePage")
                UIHelper.OpenPage("DismantlePage")
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(1000014), tabParams)
          return
        end
        if copyDisplayCfg.copy_display_type == 1 then
          local isHasFleet = Logic.fleetLogic:IsHasFleet()
          if not isHasFleet then
            noticeManager:OpenTipPage(self, 110007)
            return
          end
          plotCopyDetailPage:_OpenLevelPage(copyData, copyId)
        else
          plotCopyDetailPage:_OpenPlotPage(copyData.BaseId)
        end
      end
    end
    UGUIEventListener.AddButtonOnClick(part.btnGoto, funcGotoCopy)
    UGUIEventListener.AddButtonOnClick(part.btnCopy, funcGotoCopy)
  end
end

return TestShipCopyPage
