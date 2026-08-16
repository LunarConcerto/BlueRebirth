local ActivityGiftPage = class("ui.page.Activity.HalloweenActivity.ActivityGiftPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ActivityGiftPage:DoInit()
end

function ActivityGiftPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mEquipData = params.EquipData
  self:ShowPage()
end

function ActivityGiftPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.AEQUIP_RefreshData, self.ShowPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.CloseMySelf, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk, self.CloseMySelf, self)
end

function ActivityGiftPage:DoOnHide()
end

function ActivityGiftPage:DoOnClose()
end

function ActivityGiftPage:ShowPage()
  local equipTid = self.mEquipData.EquipTid
  local equipCfg = configManager.GetDataById("config_equip", equipTid)
  local rewardConf = configManager.GetDataById("config_rewards", equipCfg.reward)
  local rewards = rewardConf.rewards
  UIHelper.CreateSubPart(self.tab_Widgets.itemReward, self.tab_Widgets.rectReward, #rewards, function(index, tabPart)
    local reward = rewards[index]
    UIHelper.SetText(tabPart.text_num, reward[3])
    local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[rewardInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, tostring(rewardInfo.icon))
    UIHelper.SetText(tabPart.text_name, rewardInfo.name)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
      if reward[1] == GoodsType.EQUIP then
        UIHelper.OpenPage("ShowEquipPage", {
          templateId = reward[2],
          showEquipType = ShowEquipType.Simple
        })
      else
        UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
      end
    end, self)
  end)
  self.tab_Widgets.btnOk.gameObject:SetActive(true)
  self.tab_Widgets.btnGet.gameObject:SetActive(false)
  self.tab_Widgets.btnComplete.gameObject:SetActive(false)
  local equipId = self.mEquipData.EquipId
  if 0 < equipId then
    local power = Data.equipactivityData:GetPowerPointByEquipId(equipId)
    local isReward = Data.equipactivityData:GetIsRewardByEquipId(equipId)
    if isReward <= 0 then
      if power >= equipCfg.max_energy then
        self.tab_Widgets.btnOk.gameObject:SetActive(false)
        self.tab_Widgets.btnGet.gameObject:SetActive(true)
        UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnGet, function()
          Service.equipactivityService:SendGetReward({EquipId = equipId})
        end)
      end
    else
      self.tab_Widgets.btnOk.gameObject:SetActive(false)
      self.tab_Widgets.btnGet.gameObject:SetActive(false)
      self.tab_Widgets.btnComplete.gameObject:SetActive(true)
    end
  end
end

function ActivityGiftPage:CloseMySelf()
  UIHelper.ClosePage("ActivityGiftPage")
end

return ActivityGiftPage
