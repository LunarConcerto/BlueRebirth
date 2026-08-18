local BuildShipBoxPage = class("UI.BuildShip.BuildShipBoxPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function BuildShipBoxPage:DoInit()
  self.rewards = 0
  self.allTabPart = {}
end

function BuildShipBoxPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self._GetBoxReward, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_disconfirm, self._ShowTips, self)
  self:RegisterEvent(LuaEvent.BuildShipBox, self._Play, self)
end

function BuildShipBoxPage:DoOnOpen()
  self.buildId = self.param.buildId
  self.rewards = self.param.rewards
  self.limitCount = self.param.limitCount
  self.normalCount = self.param.normalCount
  self:_Display()
end

function BuildShipBoxPage:_Display()
  UIHelper.CreateSubPart(self.tab_Widgets.obj, self.tab_Widgets.content, #self.rewards, function(nIndex, tabPart)
    local reward = self.rewards[nIndex]
    local conf = Logic.bagLogic:GetItemByTempateId(reward.Type, reward.ConfigId)
    tabPart.txt_name.text = conf.name
    UIHelper.SetImage(tabPart.img_icon, conf.icon)
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[conf.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_goods, self._ShowItemInfo, self, reward)
    table.insert(self.allTabPart, tabPart)
  end)
  if self.limitCount - self.normalCount <= 0 then
    self.tab_Widgets.btn_confirm.gameObject:SetActive(true)
    self.tab_Widgets.btn_disconfirm.gameObject:SetActive(false)
  else
    self.tab_Widgets.btn_confirm.gameObject:SetActive(false)
    self.tab_Widgets.btn_disconfirm.gameObject:SetActive(true)
    self.tab_Widgets.txt_note.text = string.format(UIHelper.GetString(1110061), self.limitCount - self.normalCount)
  end
end

function BuildShipBoxPage:_ShowItemInfo(obj, reward)
  if reward.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = reward.ConfigId,
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
  end
end

function BuildShipBoxPage:_GetBoxReward()
  if not self:CheckStatus() then
    return
  end
  if not Logic.rewardLogic:CanGotReward(self.rewards, true, 1, 1) then
    return
  end
  UIHelper.DisableButton(self.tab_Widgets.btn_confirm, true)
  Service.buildShipService:SendBuildShipBoxReward({
    Id = self.buildId,
    Num = self.limitCount
  })
end

function BuildShipBoxPage:_ShowTips()
  noticeManager:OpenTipPage(self, string.format(UIHelper.GetString(1110061), self.limitCount - self.normalCount))
end

function BuildShipBoxPage:_Play(param)
  local rewards = param.BuildShipResult
  local transReward = param.TransReward
  local rewardType
  if param.IsChangeReward == true then
    rewardType = RewardType.REDAUCKLAND_CHANGE_REWARD
  end
  Logic.rewardLogic:ShowCommonReward(rewards, "BuildShipBoxPage", nil, rewardType, transReward)
  Logic.buildShipLogic:BoxRewardChooseFlg(true)
  self._ClickClose()
end

function BuildShipBoxPage:CheckStatus()
  local isOpen = Logic.buildShipLogic:CheckServerOpenDay(self.buildId)
  if not isOpen then
    noticeManager:OpenTipPage(self, UIHelper.GetString(1110047))
  else
    isOpen = Logic.buildShipLogic:CheckActIsOpen(self.buildId)
    if not isOpen then
      noticeManager:OpenTipPage(self, UIHelper.GetString(1001007))
    end
  end
  if not isOpen then
    eventManager:SendEvent(LuaEvent.BuildShipBoxPageOpen)
    self:_ClickClose()
    return false
  end
  return true
end

function BuildShipBoxPage:_ClickClose()
  UIHelper.ClosePage("BuildShipBoxPage")
end

function BuildShipBoxPage:DoOnHide()
end

function BuildShipBoxPage:DoOnClose()
end

return BuildShipBoxPage
