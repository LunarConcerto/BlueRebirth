local ProductionSpeedUpPage = class("UI.Building.Building2D.ProductionSpeedUpPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ProductionSpeedUpPage:DoOnOpen()
  self.recipeId = self:GetParam().recipeId
  self.buildingData = self:GetParam().buildingData
  self.recipeCfg = configManager.GetDataById("config_recipe", self.recipeId)
  local widgets = self:GetWidgets()
  local tableIndex = configManager.GetDataById("config_table_index", GoodsType.CURRENCY)
  local strengthItem = configManager.GetDataById(tableIndex.file_name, CurrencyType.STRENGTH)
  UIHelper.SetText(widgets.txt_name, strengthItem.name)
  UIHelper.SetImage(widgets.img_item, QualityIcon[strengthItem.quality])
  UIHelper.SetImage(widgets.img_icon, strengthItem.icon)
  self.curStrength = Data.userData:GetCurrency(CurrencyType.STRENGTH)
  UIHelper.SetText(widgets.txt_ownNum, self.curStrength)
  self:Reset()
end

function ProductionSpeedUpPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.OnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_mask, self.OnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self.OnBtnAdd, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_sub, self.OnBtnSub, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_max, self.OnBtnMax, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_reset, self.OnBtnReset, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_confirm, self.OnBtnConfirm, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancle, self.OnBtnCancle, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_icon, self._ShowRewardInfo, self, {
    Type = GoodsType.CURRENCY,
    ConfigId = CurrencyType.STRENGTH
  })
end

function ProductionSpeedUpPage:StartCountDownTimer()
  self:StopCountDownTimer()
  self.timer = self:CreateTimer(function()
    self:DoCountDown()
  end, 1, -1, false)
  self:StartTimer(self.timer)
  self:DoCountDown()
end

function ProductionSpeedUpPage:DoCountDown()
  local timePerStrength = self.recipeCfg.time / self:GetEnergyCost()
  local subTime = timePerStrength * self.costStrength
  local remainTime = Logic.buildingLogic:ProduceItem(self.buildingData)
  if remainTime <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(3200005))
    self:StopCountDownTimer()
    self:OnClose()
    return
  end
  remainTime = remainTime - subTime
  local remainTimeStr = time.getHoursString(math.ceil(remainTime))
  UIHelper.SetText(self.tab_Widgets.txt_remainTime, remainTimeStr)
end

function ProductionSpeedUpPage:StopCountDownTimer()
  if self.timer then
    self:StopTimer(self.timer)
    self.timer = nil
  end
end

function ProductionSpeedUpPage:UpdateCost()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.txt_cost, self.costStrength)
  local timePerStrength = self.recipeCfg.time / self:GetEnergyCost()
  local subTime = timePerStrength * self.costStrength
  local subTimeStr = time.getHoursString(math.floor(subTime))
  UIHelper.SetText(widgets.txx_subTime, subTimeStr)
  local _, _, _, realRemainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  local realProduceCount = self.buildingData.ItemCount - realRemainCount
  local extraCount = Logic.buildingLogic:ProduceNow(self.buildingData, subTime)
  local finishCount = realProduceCount + extraCount - math.floor(realProduceCount)
  UIHelper.SetText(widgets.txt_count, math.floor(finishCount))
  self:StartCountDownTimer()
end

function ProductionSpeedUpPage:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function ProductionSpeedUpPage:Reset()
  self.costStrength = 1
  self:UpdateCost()
end

function ProductionSpeedUpPage:GetMax()
  local remainTime, _, remainCount, realRemainCount = Logic.buildingLogic:ProduceItem(self.buildingData)
  local needStrength = math.ceil(remainTime / self.recipeCfg.time * self:GetEnergyCost())
  local maxStrength = 0
  if needStrength < self.curStrength then
    maxStrength = needStrength
  else
    maxStrength = self.curStrength
  end
  return maxStrength
end

function ProductionSpeedUpPage:OnBtnAdd()
  local max = self:GetMax()
  if max <= self.costStrength then
    noticeManager:ShowTip(UIHelper.GetString(3200002))
    return
  end
  self.costStrength = self.costStrength + 1
  self:UpdateCost()
end

function ProductionSpeedUpPage:OnBtnSub()
  if self.costStrength <= 1 then
    noticeManager:ShowTip(UIHelper.GetString(3200003))
    return
  end
  self.costStrength = self.costStrength - 1
  self:UpdateCost()
end

function ProductionSpeedUpPage:OnBtnMax()
  self.costStrength = self:GetMax()
  self:UpdateCost()
end

function ProductionSpeedUpPage:GetEnergyCost()
  return self.recipeCfg.cost_energy * BuildingBase.Float
end

function ProductionSpeedUpPage:OnBtnReset()
  self:Reset()
end

function ProductionSpeedUpPage:OnBtnConfirm()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(ok)
      if ok then
        self:DoSpeedup()
      end
    end
  }
  local remainTime = Logic.buildingLogic:ProduceItem(self.buildingData)
  local timePerStrength = self.recipeCfg.time / self:GetEnergyCost()
  local reduceTime = self.costStrength * timePerStrength
  if remainTime < reduceTime then
    local timeStr = ""
    local deltaTime = math.floor(reduceTime - remainTime)
    if 3600 <= deltaTime then
      timeStr = time.getHoursString(deltaTime)
    else
      timeStr = time.getMinutesString(deltaTime)
    end
    local content = UIHelper.GetLocString(3200004, timeStr)
    noticeManager:ShowMsgBox(content, tabParams)
  else
    self:DoSpeedup()
  end
end

function ProductionSpeedUpPage:DoSpeedup()
  Service.buildingService:UseStrengthSpeedup(self.buildingData.Id, self.costStrength)
  self:OnClose()
end

function ProductionSpeedUpPage:OnBtnCancle()
  self:OnClose()
end

function ProductionSpeedUpPage:OnClose()
  UIHelper.ClosePage("ProductionSpeedUpPage")
end

return ProductionSpeedUpPage
