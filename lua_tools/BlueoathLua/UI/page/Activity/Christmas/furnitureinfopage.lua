local FurnitureInfoPage = class("ui.page.Activity.Christmas.FurnitureInfoPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function FurnitureInfoPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function FurnitureInfoPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mTeamid = params.teamId
  self.mActivityId = params.actId
  self.mFurnitureInfo = configManager.GetDataById("config_activity", self.mActivityId).p4[self.mTeamid]
  self.m_furnitureId = self.mFurnitureInfo[FurnitureActivityTable.furnitureId]
  self:_ShowPage()
end

function FurnitureInfoPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeTip, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.button_cancel, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.button_ok, self._ClickBuyFurniture, self)
end

function FurnitureInfoPage:_ShowPage()
  local widgets = self.tab_Widgets
  local bagItemConfig = configManager.GetDataById("config_interaction_item_bag", self.m_furnitureId)
  local furnitureItemConfig = configManager.GetDataById("config_interaction_item", bagItemConfig.interactionitem)
  if furnitureItemConfig.interaction_item_type ~= InteractionItemType.Furniture then
    logWarning("\229\174\182\229\133\183\231\177\187\229\158\139\228\188\160\229\133\165\233\148\153\232\175\175\239\188\129 Id:" .. self.m_furnitureId)
    return
  end
  UIHelper.SetText(widgets.txt_itemName, furnitureItemConfig.interaction_item_name)
  UIHelper.SetText(widgets.txt_des, furnitureItemConfig.interaction_item_desc)
  UIHelper.SetImage(widgets.img_icon, furnitureItemConfig.interaction_item_pic)
  UIHelper.SetText(widgets.txt_price, self.mFurnitureInfo[FurnitureActivityTable.furnitureCost])
  self:_ShowRewardsList(self.mFurnitureInfo[FurnitureActivityTable.furnitureReward])
end

function FurnitureInfoPage:_ShowRewardsList(rewardId)
  local widgets = self.tab_Widgets
  local res = Logic.rewardLogic:FormatRewardById(rewardId)
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.rect_rewardsContent, #res, function(index, tabParts)
    local item = CommonRewardItem:new()
    item:Init(index, res[index], tabParts)
    UGUIEventListener.AddButtonOnClick(tabParts.item, self._ShowItemInfo, self, res[index])
  end)
end

function FurnitureInfoPage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function FurnitureInfoPage:_ClickBuyFurniture()
  local ownedChristmasFurniture = Data.interactionItemData:GetInteractionBagItemData()
  local actId = self.mActivityId
  local configData = configManager.GetDataById("config_activity", self.mActivityId)
  local currency = configData.p3[1]
  if actId == nil then
    logError("\230\180\187\229\138\168\230\156\170\229\188\128\229\144\175\239\188\129")
  end
  local myCurSnowCion = Data.bagData:GetItemNum(currency)
  local furniturePrice = self.mFurnitureInfo[FurnitureActivityTable.furnitureCost]
  local rewardid = self.mFurnitureInfo[FurnitureActivityTable.furnitureReward]
  local isGot = ownedChristmasFurniture[self.m_furnitureId] ~= nil
  if isGot then
    noticeManager:ShowTipById(1300050)
  elseif myCurSnowCion < furniturePrice then
    noticeManager:ShowTipById(710079)
  else
    local interactionItemTab = {
      interactionItem = self.mTeamid,
      rewardId = rewardid
    }
    Service.interactionItemService:BuyFurnitureItems(interactionItemTab)
    self:_ClickClose()
  end
end

function FurnitureInfoPage:_ClickClose()
  UIHelper.ClosePage("FurnitureInfoPage")
end

function FurnitureInfoPage:DoOnHide()
end

function FurnitureInfoPage:DoOnClose()
end

return FurnitureInfoPage
