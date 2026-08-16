local LunarNewYearPaperCutInfoPage = class("ui.page.Activity.SchoolActivity.LunarNewYearPaperCutInfoPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function LunarNewYearPaperCutInfoPage:DoInit()
  self.mPaperCutIndex = 1
end

function LunarNewYearPaperCutInfoPage:DoOnOpen()
  self.mCutList = Logic.activitypapercutLogic:GetCutList()
  self.mMaterials = Logic.activitypapercutLogic:GetMaterials()
  self:ShowPage()
end

function LunarNewYearPaperCutInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk, function()
    local materials = self.mMaterials or {}
    Logic.activitypapercutLogic:SetMaterials(materials)
    eventManager:SendEvent(LuaEvent.ActivityPaperCut_CutPageRefresh)
    UIHelper.ClosePage(self:GetName())
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroup, self, "", function(target, index)
    if index == 0 then
      self.tab_Widgets.objList:SetActive(true)
      self.tab_Widgets.objFormula:SetActive(false)
      self:ShowCutListPartial()
    else
      self.tab_Widgets.objList:SetActive(false)
      self.tab_Widgets.objFormula:SetActive(true)
      self:ShowPaperCutPartial()
    end
  end)
end

function LunarNewYearPaperCutInfoPage:DoOnHide()
end

function LunarNewYearPaperCutInfoPage:DoOnClose()
end

function LunarNewYearPaperCutInfoPage:ShowPage()
  self:ShowCutMaterialsPartial()
  self.tab_Widgets.tgGroup:SetActiveToggleIndex(0)
end

function LunarNewYearPaperCutInfoPage:ShowCutMaterialsPartial()
  self.mShowMaterials = self:GetShowMaterials()
  UIHelper.CreateSubPart(self.tab_Widgets.itemCut, self.tab_Widgets.rectCut, #self.mShowMaterials, function(index, part)
    local itemId = self.mShowMaterials[index]
    if 0 < itemId then
      part.objEmpty:SetActive(false)
      part.img_quality.gameObject:SetActive(true)
      local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, itemId)
      UIHelper.SetImage(part.img_icon, display.icon)
      UIHelper.SetImage(part.img_quality, QualityIcon[display.quality])
    else
      part.objEmpty:SetActive(true)
      part.img_quality.gameObject:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(part.btn_icon, function()
      if itemId <= 0 then
        return
      end
      if not self:RemoveMaterial(index) then
        return
      end
      if not self:DelCutListCut(itemId) then
        return
      end
      self:ShowCutListPartial()
      self:ShowCutMaterialsPartial()
    end)
  end)
end

function LunarNewYearPaperCutInfoPage:ShowCutListPartial()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentList, self.tab_Widgets.itemList, #self.mCutList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateItemListPart(index, part)
    end
  end)
end

function LunarNewYearPaperCutInfoPage:updateItemListPart(index, part)
  local data = self.mCutList[index]
  part.objSelect:SetActive(data.IsSelect)
  local itemId = data.ItemId
  local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, itemId)
  UIHelper.SetImage(part.img_icon, display.icon)
  UIHelper.SetImage(part.img_quality, QualityIcon[display.quality])
  UGUIEventListener.AddButtonOnClick(part.btn_reward, function()
    local data = self.mCutList[index]
    local succ = false
    if data.IsSelect then
      succ = self:DelMaterial(itemId)
    else
      succ = self:AddMaterial(itemId)
    end
    if succ then
      data.IsSelect = not data.IsSelect
      self:ShowCutListPartial()
      self:ShowCutMaterialsPartial()
    end
  end)
end

function LunarNewYearPaperCutInfoPage:ShowPaperCutPartial()
  self.mPaperCutList = Logic.activitypapercutLogic:GetPaperCutFormulaInfo()
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentPaper, self.tab_Widgets.itemPaper, #self.mPaperCutList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updatePaperCutTabPart(index, part)
    end
  end)
  local mPaperCutListData = self.mPaperCutList[self.mPaperCutIndex] or {}
  self.mFormulaList = mPaperCutListData.FormulaList or {}
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentFormula, self.tab_Widgets.itemFormula, #self.mFormulaList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updatePaperCutFormulaPart(index, part)
    end
  end)
end

function LunarNewYearPaperCutInfoPage:updatePaperCutTabPart(index, part)
  local mPaperCutData = self.mPaperCutList[index]
  local paperCutId = mPaperCutData.PaperId
  local isUnlock = mPaperCutData.Unlock
  if isUnlock then
    part.objEmpty:SetActive(false)
    part.objPaper:SetActive(true)
    local cfg = configManager.GetDataById("config_interaction_item", paperCutId)
    UIHelper.SetImage(part.imgIcon, cfg.interaction_item_pic)
  else
    part.objEmpty:SetActive(true)
    part.objPaper:SetActive(false)
  end
  part.objImgChoose:SetActive(self.mPaperCutIndex == index)
  UGUIEventListener.AddButtonOnClick(part.btnIcon, function()
    self.mPaperCutIndex = index
    self.tab_Widgets.contentFormula:SetTotalNum(0)
    self.tab_Widgets.itemFormula.transform.parent.localPosition = Vector3.New(0, 0, 0)
    self:ShowPaperCutPartial()
  end)
end

function LunarNewYearPaperCutInfoPage:updatePaperCutFormulaPart(index, part)
  local formulaId = self.mFormulaList[index]
  local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
  UIHelper.CreateSubPart(part.itemCut, part.rectContent, #cfg.formula, function(subindex, subpart)
    local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
    local itemId = cfg.formula[subindex]
    local display = ItemInfoPage.GenDisplayData(GoodsType.ITEM, itemId)
    UIHelper.SetImage(subpart.img_icon, display.icon)
    UIHelper.SetImage(subpart.img_quality, QualityIcon[display.quality])
    UGUIEventListener.AddButtonOnClick(subpart.btn_icon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  local isCanUse = Logic.activitypapercutLogic:CheckFormula(formulaId)
  if isCanUse then
    part.btnOk.gameObject:SetActive(true)
    part.btnNo.gameObject:SetActive(false)
  else
    part.btnOk.gameObject:SetActive(false)
    part.btnNo.gameObject:SetActive(true)
  end
  UGUIEventListener.AddButtonOnClick(part.btnNo, function()
    noticeManager:ShowTipById(1300052)
  end)
  UGUIEventListener.AddButtonOnClick(part.btnOk, function()
    for _, data in ipairs(self.mCutList) do
      data.IsSelect = false
    end
    self.mMaterials = {}
    local cfg = configManager.GetDataById("config_interaction_paper_cut_fomula", formulaId)
    for _, iid in ipairs(cfg.formula) do
      self:AddMaterial(iid)
      self:AddCutListCut(iid)
    end
    self:ShowCutListPartial()
    self:ShowCutMaterialsPartial()
  end)
end

function LunarNewYearPaperCutInfoPage:AddMaterial(itemId)
  local materials = self.mMaterials or {}
  if #materials >= ACTIVITYPAPERCUT_CUTNUM then
    noticeManager:ShowTipById(1300053)
    return false
  end
  table.insert(materials, itemId)
  self.mMaterials = materials
  return true
end

function LunarNewYearPaperCutInfoPage:DelMaterial(itemId)
  local materials = self.mMaterials or {}
  if #materials <= 0 then
    return false
  end
  local index = -1
  for i, iId in ipairs(materials) do
    if iId == itemId then
      index = i
    end
  end
  if index < 0 then
    logError("can not find item", itemId)
    return false
  end
  table.remove(materials, index)
  self.mMaterials = materials
  return true
end

function LunarNewYearPaperCutInfoPage:RemoveMaterial(index)
  local materials = self.mMaterials or {}
  if #materials <= 0 then
    return false
  end
  if index <= 0 or index > #materials then
    logError("err index", index)
    return false
  end
  table.remove(materials, index)
  self.mMaterials = materials
  return true
end

function LunarNewYearPaperCutInfoPage:DelCutListCut(itemId)
  local cutindex = -1
  for i, data in ipairs(self.mCutList) do
    if data.ItemId == itemId and data.IsSelect then
      cutindex = i
    end
  end
  if cutindex <= 0 then
    logError("err itemId", itemId)
    return false
  end
  self.mCutList[cutindex].IsSelect = false
  return true
end

function LunarNewYearPaperCutInfoPage:AddCutListCut(itemId)
  local cutindex = -1
  for i, data in ipairs(self.mCutList) do
    if data.ItemId == itemId and not data.IsSelect then
      cutindex = i
    end
  end
  if cutindex <= 0 then
    logError("err itemId", itemId)
    return false
  end
  self.mCutList[cutindex].IsSelect = true
  return true
end

function LunarNewYearPaperCutInfoPage:GetShowMaterials()
  local materials = self.mMaterials or {}
  local ret = {}
  for i = 1, ACTIVITYPAPERCUT_CUTNUM do
    local itemId = materials[i] or 0
    table.insert(ret, itemId)
  end
  return ret
end

return LunarNewYearPaperCutInfoPage
