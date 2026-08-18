local FoodComposePage = class("ui.page.Activity.FoodCompose.FoodComposePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function FoodComposePage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.canClick = true
  self.actConfig = {}
  self.composeNum = 0
end

function FoodComposePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_recipe, function()
    UIHelper.OpenPage("RecipePage", {
      activityId = self:GetParam().activityId
    })
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_task, function()
    UIHelper.OpenPage("RecipeTaskPage", {
      activityId = self:GetParam().activityId
    })
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, function()
    UIHelper.OpenPage("HelpPage", {content = 940000104})
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_apply, self._Apply, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_getMoreMaterial, self._GetMoreMaterial, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_compose, self._Compose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseRewardsPanel, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self.__DelayInComposeShow, self)
  self:RegisterEvent(LuaEvent.GetFoodComposeMsg, self.__DelayInComposeShow, self)
  self:RegisterEvent(LuaEvent.FoodComposeRewardRet, self._ShowRewardsPanel, self)
end

function FoodComposePage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.mActivityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.mActivityId)
  self.composeNum = self.actConfig.p3[1]
  local Idata = Data.foodComposeData:GetFoodComposeDataFreshData()
  if not Idata then
    if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
      noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
    else
      Service.foodComposeService:SendGetFoodComposeData()
    end
  else
    Logic.foodComposeLogic:SetActivityId(self.mActivityId)
    self:_ShowPage()
    if params.subPage ~= nil then
      UIHelper.OpenPage(params.SubPage, {
        activityId = self:GetParam().activityId
      })
    end
  end
end

function FoodComposePage:_ShowPage()
  self:_ShowChoose()
  self:_ShowPreview()
  self:_ShowMyMaterial()
end

function FoodComposePage:__DelayInComposeShow()
  if self.canClick then
    self:_ShowPage()
  end
end

function FoodComposePage:_ShowChoose()
  local mmList = Logic.foodComposeLogic:GetMaterialChoose()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item_result, self.tab_Widgets.Content_result, self.composeNum, function(index, tabPart)
    local mid = mmList[index]
    local isEmpty = mid == nil or mid == 0
    if isEmpty then
      tabPart.im_icon.gameObject:SetActive(false)
    else
      local mInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.ITEM, mid)
      tabPart.im_icon.gameObject:SetActive(true)
      UIHelper.SetImage(tabPart.im_bg, QualityIcon[mInfo.quality])
      UIHelper.SetImage(tabPart.im_icon, tostring(mInfo.icon))
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_bg_result, function()
      if not isEmpty then
        Logic.foodComposeLogic:RemoveMaterial(index)
      end
    end)
  end)
end

function FoodComposePage:_ShowPreview()
  local mmList = Logic.foodComposeLogic:GetMaterialChoose()
  local len = 0
  for i, v in pairs(mmList) do
    if v and v ~= 0 then
      len = len + 1
    end
  end
  local isfull = len == self.actConfig.p3[1]
  if isfull then
    local find, rid = Logic.foodComposeLogic:GetRecipeByMaterial()
    if not find then
      logError(" \230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\231\154\132\233\133\141\230\150\185id\239\188\129", mmList)
    end
    local recipeConf = configManager.GetDataById("config_food_compose", rid)
    local c_times = Data.foodComposeData:GetRecipeComposeTById(rid)
    local r_times = Data.foodComposeData:GetRecipeRewardTById(rid)
    local rewardTime = recipeConf.reward[2] or 0
    local rr_times = r_times < rewardTime and rewardTime - r_times or 0
    local rp_str = rr_times .. "/" .. rewardTime
    local haveRTime = r_times < rewardTime
    local zero = rewardTime == 0
    if 0 < c_times then
      local mInfo = Logic.bagLogic:GetItemByTempateId(recipeConf.item[1], recipeConf.item[2])
      UIHelper.SetImage(self.tab_Widgets.obj_item_show, QualityIcon[mInfo.quality])
      UIHelper.SetImage(self.tab_Widgets.im_icon_show, tostring(mInfo.icon))
      UIHelper.SetText(self.tab_Widgets.tx_rewardNum, rp_str)
      self.tab_Widgets.tx_rewardTips:SetActive(not zero)
      self.tab_Widgets.tx_norewardTips:SetActive(zero)
    else
      self.tab_Widgets.tx_rewardTips:SetActive(false)
      self.tab_Widgets.tx_norewardTips:SetActive(false)
    end
    self.tab_Widgets.im_icon_unknown:SetActive(c_times <= 0)
    self.tab_Widgets.im_icon_show.gameObject:SetActive(0 < c_times)
  else
    self.tab_Widgets.tx_rewardTips:SetActive(false)
    self.tab_Widgets.tx_norewardTips:SetActive(false)
  end
  self.tab_Widgets.obj_item_show.gameObject:SetActive(isfull)
end

function FoodComposePage:_ShowMyMaterial()
  local materialPile = self.actConfig.p1
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item_material, self.tab_Widgets.Content_material, #materialPile, function(index, tabPart)
    local mid = materialPile[index]
    local mInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.ITEM, mid)
    local allNum = Logic.bagLogic:GetBagItemNum(mid)
    local chooseNum = Logic.foodComposeLogic:GetMaterialChooseNum(mid)
    local finalNum = allNum - chooseNum
    UIHelper.SetText(tabPart.tx_num, "x" .. finalNum)
    UIHelper.SetImage(tabPart.im_bg, QualityIcon[mInfo.quality])
    UIHelper.SetImage(tabPart.im_icon, tostring(mInfo.icon))
    UIHelper.SetImage(tabPart.im_noicon, tostring(mInfo.icon))
    tabPart.im_icon.gameObject:SetActive(0 < finalNum)
    tabPart.im_noicon.gameObject:SetActive(finalNum == 0)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_bg_material, function()
      if 0 < finalNum then
        Logic.foodComposeLogic:AddMaterial(mid)
      else
        noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(940000105), mInfo.name))
      end
    end)
  end)
end

function FoodComposePage:_CloseRewardsPanel()
  self.tab_Widgets.obj_effect_getFood:SetActive(false)
  self:_ShowPage()
  self.canClick = true
end

function FoodComposePage:_ShowRewardsPanel(info)
  local rid = info.RecipeID
  local recipeConf = configManager.GetDataById("config_food_compose", rid)
  local mInfo = Logic.bagLogic:GetItemByTempateId(recipeConf.item[1], recipeConf.item[2])
  local c_times = Data.foodComposeData:GetRecipeComposeTById(rid)
  local r_times = Data.foodComposeData:GetRecipeRewardTById(rid)
  local rewardTime = recipeConf.reward[2] or 0
  local rr_times = r_times < rewardTime and rewardTime - r_times or 0
  local rp_str = rr_times .. "/" .. rewardTime
  local haveRTime = r_times < rewardTime
  local zero = rewardTime == 0
  local isCommonRrward = r_times > rewardTime
  UIHelper.SetImage(self.tab_Widgets.im_food_get, tostring(mInfo.icon))
  local isnew = c_times == 1
  self.tab_Widgets.obj_new:SetActive(isnew)
  UIHelper.SetText(self.tab_Widgets.tx_rewardNum_get, rp_str)
  self.tab_Widgets.obj_rewardTips_get:SetActive(not isCommonRrward)
  self.tab_Widgets.tx_noRewardTips:SetActive(isCommonRrward)
  self:_ShowRewards(self.tab_Widgets.repeatReward, self.tab_Widgets.obj_re_reward, info.Reward)
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  self.mEffectTimer = self:CreateTimer(function()
    self.tab_Widgets.obj_effect_getFood:SetActive(true)
    self.tab_Widgets.obj_composeEffect:SetActive(false)
    self.mEffectTimer = nil
  end, 2, 1, false)
  self.tab_Widgets.obj_composeEffect:SetActive(true)
  self.mEffectTimer:Start()
  for i = 1, self.actConfig.p3[1] do
    Logic.foodComposeLogic:RemoveMaterial(i)
  end
end

function FoodComposePage:_ShowRewards(trans, obj, rewards)
  Logic.foodComposeLogic:ShowFoodMergeRewardPartCommon(trans, obj, rewards)
end

function FoodComposePage:DoOnHide()
end

function FoodComposePage:DoOnClose()
end

function FoodComposePage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

function FoodComposePage:_Apply()
  if not self:__CheckCanClick() then
    return
  end
  local lastRid = Data.foodComposeData:GetLastRecipeId()
  if lastRid <= 0 then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000102))
    return
  end
  if not Logic.foodComposeLogic:_CheckMaterial(lastRid) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000103))
    return
  end
  Logic.foodComposeLogic:AddMaterialByRid(lastRid)
end

function FoodComposePage:_GetMoreMaterial()
  if not self:__CheckCanClick() then
    return
  end
  globalNoitceManager:ShowItemInfoPage(GoodsType.ITEM, self.actConfig.p6[1])
end

function FoodComposePage:_Compose()
  if not self:__CheckCanClick() then
    return
  end
  local mmList = Logic.foodComposeLogic:GetMaterialChoose()
  local tmp = {}
  for _, mid in pairs(mmList) do
    if mid and mid ~= 0 then
      table.insert(tmp, mid)
    end
  end
  if #tmp ~= self.actConfig.p3[1] then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000101))
    return
  end
  self.canClick = false
  local arg = {MaterialID = tmp}
  Service.foodComposeService:SendFoodCompose(arg)
end

function FoodComposePage:__CheckCanClick()
  if not self.canClick then
    return false
  end
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:OpenTipPage(self, UIHelper.GetString(4200001))
    return false
  end
  return true
end

return FoodComposePage
