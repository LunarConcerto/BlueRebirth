local FoodComposeLogic = class("logic.FoodComposeLogic")

function FoodComposeLogic:initialize()
  self.mMaterials = {}
  self.mActivityId = 0
end

function FoodComposeLogic:SetActivityId(actid)
  self.mActivityId = actid
end

function FoodComposeLogic:AddMaterial(id)
  local len = configManager.GetDataById("config_activity", self.mActivityId).p3[1]
  for i = 1, len do
    if self.mMaterials[i] == nil or self.mMaterials[i] == 0 then
      self.mMaterials[i] = id
      eventManager:SendEvent(LuaEvent.GetFoodComposeMsg)
      return
    end
  end
  noticeManager:OpenTipPage(self, UIHelper.GetString(940000106))
end

function FoodComposeLogic:AddMaterialByIndex(index, id)
  self.mMaterials[index] = id
  eventManager:SendEvent(LuaEvent.GetFoodComposeMsg)
end

function FoodComposeLogic:AddMaterialByRid(rid)
  local recipeConf = configManager.GetDataById("config_food_compose", rid)
  for i, info in pairs(recipeConf.material) do
    self.mMaterials[i] = info[2]
  end
  eventManager:SendEvent(LuaEvent.GetFoodComposeMsg)
end

function FoodComposeLogic:RemoveMaterial(index)
  self.mMaterials[index] = 0
  eventManager:SendEvent(LuaEvent.GetFoodComposeMsg)
end

function FoodComposeLogic:GetMaterialChoose()
  return self.mMaterials
end

function FoodComposeLogic:GetListByMap(Map)
  local tmp = {}
  for i, mid in pairs(Map) do
    if tmp[mid] == nil then
      tmp[mid] = 1
    else
      tmp[mid] = tmp[mid] + 1
    end
  end
  return tmp
end

function FoodComposeLogic:GetMaterialChooseNum(mid)
  local tmp = self:GetListByMap(self.mMaterials)
  return tmp[mid] or 0
end

function FoodComposeLogic:GetRecipeByMaterial()
  local m_tmp = self:GetListByMap(self.mMaterials)
  local recipeList = configManager.GetDataById("config_activity", self.mActivityId).p2
  for _, rid in pairs(recipeList) do
    local materials = configManager.GetDataById("config_food_compose", rid).material
    local tbl_map = {}
    for _, info in pairs(materials) do
      local mid = info[2]
      if tbl_map[mid] == nil then
        tbl_map[mid] = 1
      else
        tbl_map[mid] = tbl_map[mid] + 1
      end
      if self:__CheckMap(m_tmp, tbl_map) then
        return true, rid
      end
    end
  end
  return false, 0
end

function FoodComposeLogic:__CheckMap(m1, m2)
  for k, v in pairs(m1) do
    if m2[k] ~= v then
      return false
    end
  end
  for k, v in pairs(m2) do
    if m1[k] ~= v then
      return false
    end
  end
  return true
end

function FoodComposeLogic:ShowFoodRewardPartCommon(trans, obj, rewardList)
  UIHelper.CreateSubPart(obj, trans, #rewardList, function(i, part)
    local item = rewardList[i]
    local mInfo = Logic.bagLogic:GetItemByTempateId(item[1], item[2])
    UIHelper.SetImage(part.im_bg, QualityIcon[mInfo.quality])
    UIHelper.SetImage(part.im_icon, tostring(mInfo.icon))
    UIHelper.SetText(part.tx_num, "x" .. item[3])
    UGUIEventListener.AddButtonOnClick(part.btn_bg, function()
      local award = {
        Type = item[1],
        ConfigId = item[2]
      }
      self:ShowItemInfo(award)
    end)
  end)
end

function FoodComposeLogic:ShowFoodMergeRewardPartCommon(trans, obj, rewardList)
  local rewardMergeList = self:_SameItemMerge(rewardList)
  UIHelper.CreateSubPart(obj, trans, #rewardMergeList, function(i, part)
    local item = rewardMergeList[i]
    local mInfo = Logic.bagLogic:GetItemByTempateId(item.Type, item.ConfigId)
    UIHelper.SetImage(part.im_bg, QualityIcon[mInfo.quality])
    UIHelper.SetImage(part.im_icon, tostring(mInfo.icon))
    UIHelper.SetText(part.tx_num, "x" .. item.Num)
    UGUIEventListener.AddButtonOnClick(part.btn_icon, function()
      local award = {
        Type = item.Type,
        ConfigId = item.ConfigId
      }
      self:ShowItemInfo(award)
    end)
  end)
end

function FoodComposeLogic:ShowItemInfo(award)
  local itemType = award.Type
  if itemType == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemType, award.ConfigId))
  end
end

function FoodComposeLogic:_SameItemMerge(rewards)
  local mergeItemInfo = {}
  for k, v in pairs(rewards) do
    local isHave = self:_IsHaveItem(mergeItemInfo, v.Type, v.ConfigId, v.Num)
    if isHave == false then
      table.insert(mergeItemInfo, v)
    end
  end
  return mergeItemInfo
end

function FoodComposeLogic:_IsHaveItem(mergeItemInfo, type, tid, num)
  for k, v in pairs(mergeItemInfo) do
    if v.ConfigId == tid and v.Type == type and not self.dontMerge then
      v.Num = v.Num + num
      return true
    end
  end
  return false
end

function FoodComposeLogic:_CheckMaterial(rid)
  local recipeConf = configManager.GetDataById("config_food_compose", rid)
  local map = {}
  for i, info in pairs(recipeConf.material) do
    if map[info[2]] == nil then
      map[info[2]] = info[3]
    else
      map[info[2]] = map[info[2]] + info[3]
    end
  end
  for id, num in pairs(map) do
    if num > Logic.bagLogic:GetBagItemNum(id) then
      return false
    end
  end
  return true
end

function FoodComposeLogic:SortRecipeTable(recipeList)
  local tmp = {}
  local unlock_reward = {}
  local tbl_lock = {}
  local unlock_noreward = {}
  local zeroreward = {}
  for _, rid in pairs(recipeList) do
    local unlock_reward_i, tbl_lock_i, unlock_noreward_i, zeroreward_i = self:__CaninTable(rid)
    if unlock_reward_i ~= 0 then
      table.insert(unlock_reward, rid)
    end
    if tbl_lock_i ~= 0 then
      table.insert(tbl_lock, rid)
    end
    if unlock_noreward_i ~= 0 then
      table.insert(unlock_noreward, rid)
    end
    if zeroreward_i ~= 0 then
      table.insert(zeroreward, rid)
    end
  end
  local tableList = {
    unlock_reward,
    tbl_lock,
    unlock_noreward,
    zeroreward
  }
  for _, tbl in pairs(tableList) do
    for _, rid in pairs(tbl) do
      table.insert(tmp, rid)
    end
  end
  return tmp
end

function FoodComposeLogic:__CaninTable(rid)
  local recipeConf = configManager.GetDataById("config_food_compose", rid)
  local c_times = Data.foodComposeData:GetRecipeComposeTById(rid)
  local r_times = Data.foodComposeData:GetRecipeRewardTById(rid)
  local rewardTime = recipeConf.reward[2] or 0
  local lock = c_times <= 0
  local zero = rewardTime == 0
  local haveRTime = r_times < rewardTime
  if lock then
    if recipeConf.hide == 0 then
      return 0, rid, 0, 0
    end
  elseif zero then
    return 0, 0, 0, rid
  elseif haveRTime then
    return rid, 0, 0, 0
  else
    return 0, 0, rid, 0
  end
  return 0, 0, 0, 0
end

return FoodComposeLogic
