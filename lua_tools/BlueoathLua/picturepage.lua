PicturePage = class("UI.Picture.PicturePage", LuaUIPage)
local pictureHeroItem = require("ui.page.Picture.PictureHeroItem")

function PicturePage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_heroData = {}
  self.sortway = false
  self.sortwayEquip = false
  self.m_tabInParams = {}
  self.m_tabOutParams = {}
  self.m_tabEquipInParams = {}
  self.m_tabEquipOutParams = {}
  self.m_tabSortHero = {}
  self.m_rinew = false
  self.m_riEquipnew = false
  self.m_tabRemouldInParams = {}
  self.m_tabRemouldOutParams = {}
  self.sortwayRemould = false
  self.tgInfoList = {
    {
      functionId = FunctionID.Picture,
      func = self.showPicture
    },
    {
      functionId = FunctionID.Memory,
      func = self.showMemory
    },
    {
      functionId = FunctionID.EquipIllustrate,
      func = self.showEquip,
      reddotIds = {50000}
    },
    {
      functionId = FunctionID.RemouldPicture,
      func = self.showRemouldPic
    }
  }
end

function PicturePage:DoOnOpen()
  self:OpenTopPage("PicturePage", 1, "\229\155\190\233\137\180", self, true, function()
    self:_OnBack()
  end)
  local widgets = self:GetWidgets()
  self.index = Logic.illustrateLogic:GetIndex()
  widgets.tgGroup:ClearToggles()
  self.toggleParts = {}
  UIHelper.CreateSubPart(widgets.toggle, widgets.contentTgGroup, #self.tgInfoList, function(index, tabPart)
    local tgInfo = self.tgInfoList[index]
    local functionId = tgInfo.functionId
    local config = configManager.GetDataById("config_function_info", tostring(functionId))
    UIHelper.SetText(tabPart.tx_name, config.name)
    UIHelper.SetImage(tabPart.image_fun, config.page_icon)
    widgets.tgGroup:RegisterToggle(tabPart.toggle)
    self.toggleParts[index] = tabPart
    if tgInfo.reddotIds then
      self:RegisterRedDotById(tabPart.im_red, tgInfo.reddotIds)
    end
  end)
  widgets.tgGroup:SetActiveToggleIndex(self.index)
  self:_Switch(self.index)
  UIHelper.AddToggleGroupChangeValueEvent(widgets.tgGroup, self, nil, self._Switch)
end

function PicturePage:_Switch(index)
  self.index = index
  for i, part in pairs(self.toggleParts) do
    part.tween_pos:Play(i == index + 1)
  end
  local tgInfo = self.tgInfoList[index + 1]
  local functionId = tgInfo.functionId
  local func = tgInfo.func
  local config = configManager.GetDataById("config_function_info", tostring(functionId))
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = config.name
  })
  func(self)
  if functionId == FunctionID.Picture then
    self.m_rinew = true
  elseif self.index == IllustrateFun.Equip then
    self.m_riEquipnew = true
  end
end

function PicturePage:showPicture()
  local widgets = self:GetWidgets()
  widgets.hero:SetActive(true)
  widgets.memory:SetActive(false)
  widgets.img_bottom:SetActive(true)
  widgets.equip:SetActive(false)
  self:_DealSortData()
  self:_ShowPicture()
end

function PicturePage:showMemory()
  local widgets = self:GetWidgets()
  widgets.hero:SetActive(false)
  widgets.memory:SetActive(true)
  widgets.equip:SetActive(false)
  widgets.img_bottom:SetActive(false)
  self:showMemoryContent()
end

function PicturePage:showEquip()
  local widgets = self:GetWidgets()
  widgets.hero:SetActive(false)
  widgets.memory:SetActive(false)
  widgets.equip:SetActive(true)
  widgets.img_bottom:SetActive(true)
  self:_DealEquipSortData()
  self:showEquipContent()
end

function PicturePage:_btnPlot(go, chapterId)
  UIHelper.OpenPage("ActivityCopyPage", {
    enter = ActEnter.Memory,
    chapterId = chapterId
  })
end

function PicturePage:_btnHeroPlot(go, plotData)
  UIHelper.OpenPage("PlotHeroDetailPage", {plotData = plotData})
end

function PicturePage:showMemoryContent()
  local widgets = self:GetWidgets()
  local data = Logic.illustrateLogic:GetMemoryData()
  local heroMemory = Logic.illustrateLogic:GetHeroMemorys()
  local chapterMemoryCount = #data
  local heroMemoryCount = #heroMemory
  local totalCount = chapterMemoryCount + heroMemoryCount
  UIHelper.CreateSubPart(widgets.ItemMemory, widgets.ContentMemory, totalCount, function(index, tabPart)
    if index < chapterMemoryCount or index == totalCount then
      if index == totalCount then
        index = chapterMemoryCount
      end
      local subData = data[index]
      local chapterId = subData.id
      local progress = Data.illustrateData:GetMemoryIndexByChapterId(chapterId)
      local sum = #subData.level_list
      UIHelper.SetImage(tabPart.im_activity, subData.plot_copy_cover)
      UIHelper.SetText(tabPart.txt_name, subData.name)
      tabPart.txt_num.gameObject:SetActive(0 < sum)
      tabPart.im_ac:SetActive(0 < sum)
      UIHelper.SetText(tabPart.txt_num, progress .. "/" .. sum)
      if 0 < sum then
        UGUIEventListener.AddButtonOnClick(tabPart.btn_plot, self._btnPlot, self, chapterId)
      end
    else
      tabPart.im_ac:SetActive(false)
      local plotData = heroMemory[index - chapterMemoryCount + 1]
      local shipFleetId = plotData.sfId
      local plotCfgs = Logic.buildingLogic:GetHeroPlotCfgs(shipFleetId)
      UIHelper.SetText(tabPart.txt_num, #plotData.memoryList .. "/" .. #plotCfgs)
      local shipFleetCfg = configManager.GetDataById("config_ship_fleet", shipFleetId)
      UIHelper.SetImage(tabPart.im_activity, shipFleetCfg.plot_cover)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_plot, self._btnHeroPlot, self, plotData)
    end
  end)
end

function PicturePage:showEquipContent()
  local widgets = self:GetWidgets()
  local have, all = Data.illustrateData:GetEquipCount()
  self.m_tabWidgets.txt_sum.text = have
  self.m_tabWidgets.txt_num.text = "/" .. all
  local num = have / all
  self.m_tabWidgets.txt_rate.text = string.format("%.1f", num * 100) .. "%"
  local equip = Data.illustrateData:GetEquipData()
  equip = HeroSortHelper.PictureEquipFilterAndSort(equip, self.m_tabEquipOutParams[1], self.sortwayEquip)
  UIHelper.SetInfiniteItemParam(widgets.ContentEquip, widgets.ItemEquip, #equip, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for index, tabPart in pairs(tabTemp) do
      local equipData = equip[index]
      UIHelper.SetImage(tabPart.im_icon, equipData.icon)
      UIHelper.SetImage(tabPart.img_quality, EquipQualityIcon[equipData.quality])
      UIHelper.SetText(tabPart.txt_name, equipData.name)
      tabPart.obj_black:SetActive(equipData.IllustrateState == IllustrateState.LOCK)
      tabPart.obj_newBg:SetActive(equipData.newEquip)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_equip, function()
        self:_OpenEquipPicture(equipData)
      end)
    end
  end)
end

function PicturePage:_OpenEquipPicture(equipData)
  UIHelper.OpenPage("EquipPicturePage", equipData)
  local new = Logic.illustrateLogic:IsNewEquip(equipData.EquipId)
  if new then
    Service.illustrateService:SendIllustrateEquipNew({
      equipData.EquipId
    })
  end
end

function PicturePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdataHeroSort, self._UpdateHeroSort, self)
  self:RegisterEvent(LuaEvent.SaveHeroSort, self._SaveSortData, self)
  self:RegisterEvent(LuaEvent.UpdateHeroData, self._UpdateHeroLockInfo, self)
  self:RegisterEvent(LuaEvent.UpdataIllustrateList, self._UpdatePicture, self)
  self:RegisterEvent(LuaEvent.UpdataIllustrateEquipList, self.showEquipContent, self)
  UGUIEventListener.AddButtonToggleChanged(self.m_tabWidgets.tog_sort, self._SortOrder, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_screen, self._ClickScreen, self)
end

function PicturePage:_OnBack()
  UIHelper.Back()
end

function PicturePage:_UpdatePicture()
  if self.index == IllustrateFun.Girl then
    self:_ShowPicture()
  elseif self.index == IllustrateFun.RemouldGirl then
    self:_ShowRemouldPic()
  end
end

function PicturePage:_ShowPicture()
  self.m_heroData = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Normal)
  self.m_tabSortHero = HeroSortHelper.PictureFilterAndSort(self.m_heroData, self.m_tabOutParams[1], self.sortway)
  self:_HaveHeroId()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function PicturePage:_ClickScreen()
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  if #self.m_tabEquipInParams ~= 0 then
    self.m_tabEquipOutParams = self.m_tabEquipInParams
  end
  if #self.m_tabRemouldInParams ~= 0 then
    self.m_tabRemouldOutParams = self.m_tabRemouldInParams
  end
  if self.index == IllustrateFun.Girl then
    UIHelper.OpenPage("SortPage", {
      self.m_tabOutParams[1],
      nil,
      SortType = MHeroSortType.Picture
    })
  elseif self.index == IllustrateFun.Equip then
    UIHelper.OpenPage("SortPage", {
      self.m_tabEquipOutParams[1],
      nil,
      SortType = MHeroSortType.Equip
    })
  elseif self.index == IllustrateFun.RemouldGirl then
    UIHelper.OpenPage("SortPage", {
      self.m_tabRemouldOutParams[1],
      nil,
      SortType = MHeroSortType.Picture
    })
  end
end

function PicturePage:_UpdateHeroSort(tabSortParams)
  if self.index == IllustrateFun.Girl then
    self.m_tabInParams = tabSortParams
    self.m_tabOutParams = tabSortParams
  elseif self.index == IllustrateFun.Equip then
    self.m_tabEquipInParams = tabSortParams
    self.m_tabEquipOutParams = tabSortParams
  elseif self.index == IllustrateFun.RemouldGirl then
    self.m_tabRemouldInParams = tabSortParams
    self.m_tabRemouldOutParams = tabSortParams
  end
  self:_SortOrder()
end

function PicturePage:_SortOrder()
  if self.m_tabWidgets.tog_sort.isOn then
    if self.index == IllustrateFun.Girl then
      self.sortway = true
    elseif self.index == IllustrateFun.Equip then
      self.sortwayEquip = true
    elseif self.index == IllustrateFun.RemouldGirl then
      self.sortwayRemould = true
    end
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
  else
    if self.index == IllustrateFun.Girl then
      self.sortway = false
    elseif self.index == IllustrateFun.Equip then
      self.sortwayEquip = false
    elseif self.index == IllustrateFun.RemouldGirl then
      self.sortwayRemould = false
    end
    self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
  end
  if #self.m_tabInParams ~= 0 then
    self.m_tabOutParams = self.m_tabInParams
  end
  if #self.m_tabEquipInParams ~= 0 then
    self.m_tabEquipOutParams = self.m_tabEquipInParams
  end
  if #self.m_tabRemouldInParams ~= 0 then
    self.m_tabRemouldOutParams = self.m_tabRemouldInParams
  end
  if self.index == IllustrateFun.Girl then
    Logic.illustrateLogic:SetSortRule(self.sortway)
    self.m_tabSortHero = HeroSortHelper.PictureFilterAndSort(self.m_heroData, self.m_tabOutParams[1], self.sortway)
    self:_HaveHeroId()
    self:_LoadHeroItem(self.m_tabSortHero)
  elseif self.index == IllustrateFun.Equip then
    Logic.illustrateLogic:SetEquipSortRule(self.sortwayEquip)
    self:showEquipContent()
  elseif self.index == IllustrateFun.RemouldGirl then
    Logic.illustrateLogic:SetRemouldSortRule(self.sortwayRemould)
    self.m_tabSortHero = HeroSortHelper.PictureFilterAndSort(self.m_heroData, self.m_tabRemouldOutParams[1], self.sortwayRemould)
    self:_HaveHeroId()
    self:_LoadHeroItem(self.m_tabSortHero)
  end
end

function PicturePage:_DealSortData()
  if self.index == IllustrateFun.Girl then
    self.sortway = Logic.illustrateLogic:GetSortRule()
    local tabSelectData = Logic.sortLogic:GetHeroSort(CommonHeroItem.Picture)
    if self.sortway then
      self.m_tabWidgets.tog_sort.isOn = true
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
    else
      self.m_tabWidgets.tog_sort.isOn = false
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
    end
    self.m_tabOutParams = tabSelectData[2]
  end
end

function PicturePage:_DealEquipSortData()
  if self.index == IllustrateFun.Equip then
    self.sortway = Logic.illustrateLogic:GetEquipSortRule()
    local tabSelectData = Logic.sortLogic:GetHeroSort(CommonHeroItem.EquipPicture)
    if self.sortwayEquip then
      self.m_tabWidgets.tog_sort.isOn = true
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
    else
      self.m_tabWidgets.tog_sort.isOn = false
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
    end
    self.m_tabEquipOutParams = tabSelectData[2]
  end
end

function PicturePage:_SaveSortData()
  local tabSelectData = {}
  if self.index == IllustrateFun.Picture then
    tabSelectData[1] = self.sortway
    tabSelectData[2] = self.m_tabOutParams
    Logic.sortLogic:SetHeroSort(CommonHeroItem.Picture, tabSelectData)
  elseif self.index == IllustrateFun.RemouldPic then
    tabSelectData[1] = self.sortwayRemould
    tabSelectData[2] = self.m_tabRemouldOutParams
    Logic.sortLogic:SetHeroSort(CommonHeroItem.RemouldPic, tabSelectData)
  end
end

function PicturePage:_UpdateHeroLockInfo()
  self:_HaveHeroId()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function PicturePage:_LoadHeroItem(heroTab)
  if self.index == IllustrateFun.Memory or self.index == IllustrateFun.Equip then
    return
  end
  local ownNum, openNum = 0, 0
  if self.index == IllustrateFun.Girl then
    ownNum, openNum = Logic.illustrateLogic:GetNormalShipNum()
  elseif self.index == IllustrateFun.RemouldGirl then
    ownNum, openNum = Logic.illustrateLogic:GetRemouldShipNum()
  end
  self.m_tabWidgets.txt_sum.text = ownNum
  self.m_tabWidgets.txt_num.text = "/" .. openNum
  local num = ownNum / openNum
  self.m_tabWidgets.txt_rate.text = string.format("%.1f", num * 100) .. "%"
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.iil_girlsv, self.m_tabWidgets.obj_girlItem, #heroTab, function(tabParts)
    local tabTemp = {}
    for k, v in pairs(tabParts) do
      tabTemp[tonumber(k)] = v
    end
    for nIndex, tabPart in pairs(tabTemp) do
      if heroTab[nIndex].IllustrateState == IllustrateState.UNLOCK then
        tabPart.cardPart.gameObject:SetActive(true)
        tabPart.img_txt:SetActive(false)
      elseif heroTab[nIndex].IllustrateState == IllustrateState.LOCK then
        tabPart.cardPart.gameObject:SetActive(true)
        tabPart.img_txt:SetActive(false)
      elseif heroTab[nIndex].IllustrateState == IllustrateState.CLOSE then
        tabPart.cardPart.gameObject:SetActive(false)
        tabPart.img_txt:SetActive(true)
      end
      tabPart.img_new:SetActive(heroTab[nIndex].NewHero)
      local item = pictureHeroItem:new()
      item:Init(tabPart, heroTab[nIndex], nIndex, self.tabHeroId, IllustrateType.Picture)
    end
  end)
end

function PicturePage:_HaveHeroId()
  self.tabHeroId = {}
  for k, v in pairs(self.m_tabSortHero) do
    table.insert(self.tabHeroId, v.IllustrateId)
  end
end

function PicturePage:DoOnHide()
  eventManager:SendEvent(LuaEvent.SaveHeroSort)
  Logic.illustrateLogic:SetIndex(self.index)
end

function PicturePage:DoOnClose()
  eventManager:SendEvent(LuaEvent.SaveHeroSort)
  Logic.illustrateLogic:SetIndex(self.index)
  if self.m_rinew then
    self:_RemoveINew()
  end
  if self.m_riEquipnew then
    self:_RemoveEquipINew()
  end
end

function PicturePage:_RemoveINew()
  local newill = Logic.illustrateLogic:GetAllNewIllustrate()
  if 0 < #newill then
    Service.illustrateService:SendIllustrateNew(newill)
  end
end

function PicturePage:_RemoveEquipINew()
  local newill = Logic.illustrateLogic:GetAllNewEquipIllustrate()
  if 0 < #newill then
    Service.illustrateService:SendIllustrateEquipNew(newill)
  end
end

function PicturePage:showRemouldPic()
  local widgets = self:GetWidgets()
  widgets.hero:SetActive(true)
  widgets.memory:SetActive(false)
  widgets.img_bottom:SetActive(true)
  widgets.equip:SetActive(false)
  self:_DealSortRemouldPic()
  self:_ShowRemouldPic()
end

function PicturePage:_ShowRemouldPic()
  self.m_heroData = Logic.illustrateLogic:GetIllustrateByShowTag(ShipPictureType.Remould)
  self.m_tabSortHero = HeroSortHelper.PictureFilterAndSort(self.m_heroData, self.m_tabRemouldOutParams[1], self.sortwayRemould)
  self:_HaveHeroId()
  self:_LoadHeroItem(self.m_tabSortHero)
end

function PicturePage:_DealSortRemouldPic()
  if self.index == IllustrateFun.RemouldGirl then
    self.sortwayRemould = Logic.illustrateLogic:GetRemouldSortRule()
    local tabSelectData = Logic.sortLogic:GetHeroSort(CommonHeroItem.RemouldPic)
    if self.sortwayRemould then
      self.m_tabWidgets.tog_sort.isOn = true
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190002)
    else
      self.m_tabWidgets.tog_sort.isOn = false
      self.m_tabWidgets.txt_sort.text = UIHelper.GetString(190001)
    end
    self.m_tabRemouldOutParams = tabSelectData[2]
  end
end

return PicturePage
