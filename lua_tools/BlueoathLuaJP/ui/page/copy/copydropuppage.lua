local CopyDropUpPage = class("UI.Copy.CopyDropUpPage", LuaUIPage)

function CopyDropUpPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.widgetsTab.btn_closeBtn, self._OnClickCloseBtn, self)
end

function CopyDropUpPage:DoInit()
  self.dropRateTab = {}
  self.heroIdTab = {}
  self.copyIdTab = {}
  self.activityId = nil
  self.widgetsTab = self:GetWidgets()
end

function CopyDropUpPage:DoOnOpen()
  local param = self:GetParam()
  self.heroIdTab = param.heroIdTab
  self.dropRateTab = param.dropRateTab
  self.copyIdTab = param.copyTab
  self.activityId = param.activityId
  self:_LoadView()
end

function CopyDropUpPage:_LoadView()
  local actConf = configManager.GetDataById("config_activity", self.activityId)
  local startTime, endTime = PeriodManager:GetStartAndEndPeriodTime(actConf.period)
  local startTimeStr = time.formatTimeToYMDHMS(startTime)
  local endTimeStr = time.formatTimeToYMDHMS(endTime)
  UIHelper.SetText(self.widgetsTab.tx_time, startTimeStr .. "--" .. endTimeStr)
  UIHelper.CreateSubPart(self.widgetsTab.obj_item, self.widgetsTab.trans_itemContent, #self.heroIdTab, function(index, uiPart)
    local heroId = self.heroIdTab[index]
    local dropRate = self.dropRateTab[index]
    local copyId = self.copyIdTab[index]
    local heroIcon = Logic.shipLogic:GetIcon(heroId)
    local quality = Logic.shipLogic:GetQuality(heroId)
    local heroName = Logic.shipLogic:GetName(heroId)
    UIHelper.SetImage(uiPart.im_icon, heroIcon)
    UIHelper.SetImage(uiPart.im_bg, QualityIcon[quality])
    UIHelper.SetText(uiPart.tx_name, heroName)
    UIHelper.SetText(uiPart.tx_dropInfo, dropRate .. "%")
    local copyDisplayConf = Logic.copyLogic:GetCopyDesConfig(copyId)
    UIHelper.SetText(uiPart.tx_copyInfo, copyDisplayConf.str_index .. "  " .. copyDisplayConf.name)
    local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
    local chapterType = Logic.copyLogic:GetChapterTypeByCopyId(copyId)
    UGUIEventListener.AddButtonOnClick(uiPart.btn_gotoButton, function()
      local isOpen = Logic.copyLogic:IsCopyOpenById(copyId)
      if isOpen then
        local copyData = Logic.copyLogic:GetCopyData(chapterType, copyId)
        local copySerInfo = Data.copyData:GetCopyDataByCopyId(copyId)
        local isRuning = copySerInfo.IsRunningFight
        local areaConfig = {
          copyType = CopyType.COMMONCOPY,
          tabSerData = copyData,
          chapterId = chapterId,
          IsRunningFight = isRuning,
          copyId = copyId
        }
        UIHelper.OpenPage("LevelDetailsPage", areaConfig)
        UIHelper.ClosePage("CopyDropUpPage")
      else
        noticeManager:ShowTipById(131026)
      end
    end)
  end)
end

function CopyDropUpPage:_OnClickCloseBtn()
  UIHelper.ClosePage("CopyDropUpPage")
end

function CopyDropUpPage:DoOnHide()
end

function CopyDropUpPage:DoOnClose()
end

return CopyDropUpPage
