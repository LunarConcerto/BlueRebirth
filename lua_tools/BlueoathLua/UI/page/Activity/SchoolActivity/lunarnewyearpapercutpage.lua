local LunarNewYearPaperCutPage = class("ui.page.Activity.SchoolActivity.LunarNewYearPaperCutPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function LunarNewYearPaperCutPage:DoInit()
end

function LunarNewYearPaperCutPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  self.mActivityType = params.activityType
  self.tab_Widgets.objPapercut:SetActive(false)
  self.tab_Widgets.objEmptyPaper:SetActive(true)
  self.tab_Widgets.btnMake.gameObject:SetActive(true)
  self:ShowPage()
end

function LunarNewYearPaperCutPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGoto, function()
    moduleManager:JumpToFunc(FunctionID.SeaCopy)
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMake, function()
    Logic.activitypapercutLogic:MakePaper()
  end)
  self:RegisterEvent(LuaEvent.ActivityPaperCut_CutPageRefresh, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.ActivityPaperCut_MakePaperCut, self.onMakePaper, self)
end

function LunarNewYearPaperCutPage:DoOnHide()
end

function LunarNewYearPaperCutPage:DoOnClose()
end

function LunarNewYearPaperCutPage:ShowPage()
  local activityCfg = configManager.GetDataById("config_activity", self.mActivityId)
  local startTime, endTime = PeriodManager:GetPeriodTime(activityCfg.period, activityCfg.p1)
  local startTimeFormat = time.formatTimeToMDHM(startTime)
  local endTimeFormat = time.formatTimeToMDHM(endTime)
  UIHelper.SetText(self.tab_Widgets.textTime, startTimeFormat .. "-" .. endTimeFormat)
  self.mMaterials = Logic.activitypapercutLogic:GetShowMaterials()
  UIHelper.CreateSubPart(self.tab_Widgets.itemCut, self.tab_Widgets.contentCut, #self.mMaterials, function(index, part)
    local itemId = self.mMaterials[index]
    if 0 < itemId then
      part.objImgAdd:SetActive(false)
      part.imgCut.gameObject:SetActive(true)
      local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, itemId)
      UIHelper.SetImage(part.imgCut, display.icon)
    else
      part.objImgAdd:SetActive(true)
      part.imgCut.gameObject:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(part.btnItemCut, function()
      UIHelper.OpenPage("LunarNewYearPaperCutInfoPage", {
        ActivityId = self.mActivityId
      })
    end)
  end)
  local periodarea = activityCfg.p1
  local isIn = PeriodManager:IsInPeriodArea(activityCfg.period, periodarea)
  self.tab_Widgets.btnGoto.gameObject:SetActive(isIn)
end

function LunarNewYearPaperCutPage:onMakePaper(data)
  Logic.activitypapercutLogic:SetMaterials({})
  self:ShowPage()
  local formulaId = data.FormulaId
  local rewards = data.Reward
  self.tab_Widgets.objPapercut:SetActive(false)
  self.tab_Widgets.objEmptyPaper:SetActive(true)
  self.tab_Widgets.objEffect:SetActive(true)
  self.tab_Widgets.btnMake.gameObject:SetActive(false)
  if self.mTimer1 ~= nil then
    self.mTimer1:Stop()
    self.mTimer1 = nil
  end
  self.mTimer1 = self:CreateTimer(function()
    local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
    UIHelper.SetImage(self.tab_Widgets.im_papercutword, cfg.paper_cut_word_image)
    UIHelper.SetImage(self.tab_Widgets.im_papercutmain, cfg.paper_cut_main_image)
    UIHelper.SetImage(self.tab_Widgets.im_papercutlight, cfg.paper_cut_light_image)
    self.tab_Widgets.objEmptyPaper:SetActive(false)
    self.tab_Widgets.objPapercut:SetActive(true)
  end, 2, 1)
  self.mTimer1:Start()
  if self.mTimer2 ~= nil then
    self.mTimer2:Stop()
    self.mTimer2 = nil
  end
  self.mTimer2 = self:CreateTimer(function()
    self.tab_Widgets.btnMake.gameObject:SetActive(true)
    UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards, DontMerge = true})
  end, 2.5, 1)
  self.mTimer2:Start()
end

return LunarNewYearPaperCutPage
