local PlotHeroDetailPage = class("UI.Copy.PlotHeroDetailPage", LuaUIPage)

function PlotHeroDetailPage:DoOnOpen()
  self:OpenTopPage("PlotHeroDetailPage", 1, UIHelper.GetString(2500001), self, true)
  self.plotData = self:GetParam().plotData
  local datas = Logic.illustrateLogic:GetHeroMemorys()
  self.plots = self.plotData.memoryList
  table.sort(self.plots, function(l, r)
    return l < r
  end)
  self.total = #self.plots
  self.pageCount = math.ceil(self.total / 6)
  self.pageNum = self.pageNum or 1
  self:_UpdateItem()
end

function PlotHeroDetailPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self._ClickRight, self)
end

function PlotHeroDetailPage:_UpdateItem()
  local total = self.total
  local start = 1 + (self.pageNum - 1) * 6
  local last = total < start + 5 and total or start + 5
  local count = last - start + 1
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyPlotItem, self.tab_Widgets.trans_copyPlotContent, count, function(nIndex, tabPart)
    local idx = (self.pageNum - 1) * 6 + nIndex
    local plotId = self.plots[idx]
    local plotCfg = configManager.GetDataById("config_building_character_story", plotId)
    tabPart.obj_story:SetActive(true)
    tabPart.obj_battle:SetActive(false)
    tabPart.obj_clear:SetActive(false)
    tabPart.obj_lock:SetActive(false)
    UIHelper.SetImage(tabPart.im_icon, plotCfg.plot_cover)
    tabPart.txt_name.text = plotCfg.plot_title
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot.gameObject, function()
      self:_OpenPlotPage(plotCfg.plot_trigger_id)
    end)
  end)
  self.tab_Widgets.btn_left.interactable = self.pageNum > 1
  self.tab_Widgets.btn_right.interactable = self.pageNum < self.pageCount
end

function PlotHeroDetailPage:_OpenPlotPage(plotTriggerId)
  plotManager:OpenPlotPage(plotTriggerId, false)
end

function PlotHeroDetailPage:_ClickLeft()
  if self.pageNum == 1 then
    return
  end
  self.pageNum = self.pageNum - 1
  self:_UpdateItem()
end

function PlotHeroDetailPage:_ClickRight()
  if self.pageNum == self.pageCount then
    return
  end
  self.pageNum = self.pageNum + 1
  self:_UpdateItem()
end

return PlotHeroDetailPage
