local RecipePage = class("ui.page.Activity.FoodCompose.RecipePage", LuaUIPage)

function RecipePage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.actConfig = {}
end

function RecipePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
end

function RecipePage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam()
  self.mActivityId = params.activityId
  self.actConfig = configManager.GetDataById("config_activity", self.mActivityId)
  self:ShowPage()
end

function RecipePage:ShowPage()
  self:ShowRecipe()
  self:ShowRepeatedReward()
  self:ShowMaterial()
end

function RecipePage:ShowRecipe()
  local recipeList = self.actConfig.p2
  local recipeList_sort = Logic.foodComposeLogic:SortRecipeTable(recipeList)
  UIHelper.CreateSubPart(self.tab_Widgets.item_recipe, self.tab_Widgets.Content, #recipeList_sort, function(index, tabPart)
    local rid = recipeList_sort[index]
    local recipeConf = configManager.GetDataById("config_food_compose", rid)
    local c_times = Data.foodComposeData:GetRecipeComposeTById(rid)
    local r_times = Data.foodComposeData:GetRecipeRewardTById(rid)
    local rewardTime = recipeConf.reward[2] or 0
    local rr_times = r_times < rewardTime and rewardTime - r_times or 0
    local rp_str = rr_times .. "/" .. rewardTime
    local haveRTime = r_times < rewardTime
    local zero = rewardTime == 0
    local materialList = recipeConf.material
    local foodShow = {
      recipeConf.item
    }
    UIHelper.CreateSubPart(tabPart.obj_item_detail, tabPart.rect_recipeDetial, #materialList + #foodShow, function(i, part)
      local item = {}
      if i <= #materialList then
        item = materialList[i]
      else
        item = foodShow[i - #materialList]
      end
      part.im_plus:SetActive(i < #materialList)
      part.im_dengyu:SetActive(i == #materialList)
      local mInfo = Logic.bagLogic:GetItemByTempateId(item[1], item[2])
      UIHelper.SetImage(part.im_bg, QualityIcon[mInfo.quality])
      UIHelper.SetImage(part.im_icon, tostring(mInfo.icon))
      UIHelper.SetText(part.tx_num, item[3])
      local canShow = item[4] == 1
      if canShow == nil then
        part.im_icon.gameObject:SetActive(true)
        part.im_noicon.gameObject:SetActive(false)
      elseif 0 < c_times then
        part.im_icon.gameObject:SetActive(true)
        part.im_noicon.gameObject:SetActive(false)
      else
        part.im_icon.gameObject:SetActive(canShow)
        part.im_noicon.gameObject:SetActive(not canShow)
      end
      UGUIEventListener.AddButtonOnClick(part.btn_bg, function()
        local award = {
          Type = item[1],
          ConfigId = item[2]
        }
        Logic.foodComposeLogic:ShowItemInfo(award)
      end)
    end)
    local r_rewardid = recipeConf.reward[1] and recipeConf.reward[1] or self.actConfig.p7[1]
    local rewardList = configManager.GetDataById("config_rewards", r_rewardid).rewards
    self:__ShowRewardPartCommon(tabPart.rect_recipeReward, tabPart.obj_item_reward, rewardList)
    tabPart.rect_recipeReward.gameObject:SetActive(recipeConf.reward[1] ~= nil)
    UIHelper.SetText(tabPart.tx_rewardNum, rp_str)
    tabPart.obj_rewardTips:SetActive(0 < c_times and not zero)
    tabPart.btn_apply.gameObject:SetActive(0 < c_times)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_apply, function()
      if not Logic.foodComposeLogic:_CheckMaterial(rid) then
        noticeManager:OpenTipPage(self, UIHelper.GetString(940000103))
      else
        Logic.foodComposeLogic:AddMaterialByRid(rid)
        self:_ClickClose()
      end
    end)
  end)
end

function RecipePage:ShowRepeatedReward()
  local rewardList = configManager.GetDataById("config_rewards", self.actConfig.p7[1]).rewards
  self:__ShowRewardPartCommon(self.tab_Widgets.repeatReward, self.tab_Widgets.obj_item_repeat, rewardList)
end

function RecipePage:__ShowRewardPartCommon(trans, obj, rewardList)
  Logic.foodComposeLogic:ShowFoodRewardPartCommon(trans, obj, rewardList)
end

function RecipePage:ShowMaterial()
  local materialPile = self.actConfig.p1
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item_material, self.tab_Widgets.material, #materialPile, function(index, tabPart)
    local mid = materialPile[index]
    local mInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.ITEM, mid)
    local allNum = Logic.bagLogic:GetBagItemNum(mid)
    local chooseNum = 0
    local finalNum = allNum - chooseNum
    UIHelper.SetText(tabPart.tx_num, "x" .. finalNum)
    UIHelper.SetImage(tabPart.im_bg, QualityIcon[mInfo.quality])
    UIHelper.SetImage(tabPart.im_icon, tostring(mInfo.icon))
    UIHelper.SetImage(tabPart.im_noicon, tostring(mInfo.icon))
    tabPart.im_icon.gameObject:SetActive(0 < finalNum)
    tabPart.im_noicon.gameObject:SetActive(finalNum <= 0)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_bg, function()
      local award = {
        Type = GoodsType.ITEM,
        ConfigId = mid
      }
      Logic.foodComposeLogic:ShowItemInfo(award)
    end)
  end)
end

function RecipePage:_ShowItemInfo(go, award)
  Logic.foodComposeLogic:ShowItemInfo(award)
end

function RecipePage:DoOnHide()
end

function RecipePage:DoOnClose()
end

function RecipePage:_ClickClose()
  UIHelper.ClosePage(self:GetName())
end

return RecipePage
