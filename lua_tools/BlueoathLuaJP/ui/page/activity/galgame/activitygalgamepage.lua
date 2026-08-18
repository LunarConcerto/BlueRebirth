local ActivityGalgamePage = class("UI.Activity.Galgame.ActivityGalgamePage", LuaUIPage)
local specialIdx = {
  shop = 4,
  plot = 6,
  seaCopy = 7,
  buildShip = 8
}
local OpenPlotEndTriggerId = 10042901

function ActivityGalgamePage:DoInit()
  self.actId = 0
end

function ActivityGalgamePage:DoOnOpen()
  self.actId = self.param and self.param.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.actId)
  self:_PlayEnterPlot()
  self:_CreateBtnList()
end

function ActivityGalgamePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_exit, self._ClickClose, self)
  self:RegisterEvent(LuaEvent.SeaCopyPageClose, self._PlayMusic, self)
end

function ActivityGalgamePage:_PlayMusic()
  local pageName = self:GetName()
  local config = configManager.GetDataById("config_ui_config", pageName)
  if config.bgm ~= "" then
    SoundManager.Instance:PlayMusic(config.bgm)
  end
end

function ActivityGalgamePage:_PlayEnterPlot()
  if #self.actConfig.p5 == 0 then
    return
  end
  local plotId = self.actConfig.p5[1]
  local keyStr = "ActGalgamePlotId" .. plotId
  local recorded = Logic.residentGameLogic:CheckOpenPlotRecorded(plotId, keyStr)
  local copyData = Data.copyData:GetCopyInfoById(plotId)
  if recorded then
    if copyData.FirstPassTime == 0 then
      Service.guideService:SendPlotReward(OpenPlotEndTriggerId)
    end
    return
  end
  plotManager:OpenPlotByType(PlotTriggerType.plot_copy_display_trigger, plotId)
  Logic.residentGameLogic:RecordOpenPlot(plotId, keyStr)
end

function ActivityGalgamePage:_CreateBtnList()
  local btnTab = {}
  local btnList = {
    self.actConfig.p1,
    self.actConfig.p2,
    self.actConfig.p3,
    self.actConfig.p4,
    self.actConfig.p6,
    self.actConfig.p7,
    self.actConfig.p8,
    {
      self.actConfig.extra_ship_id
    }
  }
  for i, v in ipairs(btnList) do
    if 0 < #v then
      local tabPageInfo = self:_GettabPageInfo()
      local btnInfo = {
        pageName = tabPageInfo[i].name,
        functionId = tabPageInfo[i].functionId,
        activityParam = tabPageInfo[i].Param,
        openType = tabPageInfo[i].openType
      }
      local btnObj = self.tab_Widgets["btn_next" .. i]
      if btnInfo == nil then
        btnObj.gameObject:SetActive(false)
      else
        btnObj.gameObject:SetActive(true)
        UGUIEventListener.AddButtonOnClick(btnObj, function()
          if i == specialIdx.shop then
            moduleManager:JumpToFunc(FunctionID.Shop, btnInfo.activityParam)
          elseif i == specialIdx.plot then
            UIHelper.OpenPage(btnInfo.pageName, {
              activityId = btnInfo.activityParam
            })
          elseif i == specialIdx.seaCopy then
            moduleManager:JumpToFunc(FunctionID.SeaCopy, btnInfo.activityParam)
          elseif i == specialIdx.buildShip then
            moduleManager:JumpToFunc(FunctionID.BuildShip, btnInfo.activityParam)
          else
            if not Logic.activityLogic:CheckActivityOpenById(v[1]) then
              noticeManager:ShowTipById(270022)
              return
            end
            if btnInfo.openType == 1 then
              if btnInfo.pageName ~= "" then
                UIHelper.OpenPage(btnInfo.pageName, btnInfo.activityParam)
              else
                local pagename = configManager.GetDataById("config_activity", btnInfo.activityParam).banner_gotopage_activity
                UIHelper.OpenPage(pagename, {
                  activityId = btnInfo.activityParam
                })
              end
            else
              moduleManager:JumpToFunc(FunctionID.Activity, btnInfo.activityParam)
            end
          end
        end, self)
        if i ~= specialIdx.shop then
          do
            local redObj = self.tab_Widgets["obj_red" .. i]
            if redObj then
              local redId = Logic.activityLogic:GetActReddotId(v[1])
              self:RegisterRedDotById(redObj, redId, v[1])
            end
          end
        end
      end
    end
  end
end

function ActivityGalgamePage:_ClickClose()
  UIHelper.ClosePage("ActivityGalgamePage")
end

function ActivityGalgamePage:_GettabPageInfo()
  local tabPageInfo = {
    {
      name = "SeaCopyPage",
      Param = {
        nil,
        self.actConfig.p1[1]
      },
      openType = self.actConfig.p1[2]
    },
    {
      name = "",
      Param = self.actConfig.p2[1],
      openType = self.actConfig.p2[2]
    },
    {
      name = "",
      Param = self.actConfig.p3[1],
      openType = self.actConfig.p3[2]
    },
    {
      name = "ShopPage",
      functionId = FunctionID.Shop
    },
    {
      name = "",
      Param = self.actConfig.p6[1],
      openType = self.actConfig.p6[2]
    },
    {
      name = "ActivityGalgameCopyPage",
      Param = self.actConfig.p7[1],
      openType = self.actConfig.p7[2]
    },
    {
      name = "",
      Param = self.actConfig.p8[1],
      openType = self.actConfig.p8[2]
    },
    {
      name = "",
      Param = self.actConfig.extra_ship_id,
      openType = 0
    }
  }
  return tabPageInfo
end

function ActivityGalgamePage:DoOnHide()
end

function ActivityGalgamePage:DoOnClose()
end

return ActivityGalgamePage
