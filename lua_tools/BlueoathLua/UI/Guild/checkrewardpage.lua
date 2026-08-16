local CheckRewardPage = class("UI.Guild.CheckRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function CheckRewardPage:DoInit()
end

function CheckRewardPage:DoOnOpen()
  self:ShowPage()
end

function CheckRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.onBtnCloseClick, self)
end

function CheckRewardPage:DoOnHide()
end

function CheckRewardPage:DoOnClose()
end

function CheckRewardPage:ShowPage()
  self.mRandomRewardResultList = Logic.guildtaskLogic:GetRandomRewardResultList()
  if #self.mRandomRewardResultList > 0 then
    self.tab_Widgets.objEmpty:SetActive(false)
  else
    self.tab_Widgets.objEmpty:SetActive(true)
  end
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentRewardList, self.tab_Widgets.itemReward, #self.mRandomRewardResultList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateRandomRewardPart(index, part)
    end
  end)
end

function CheckRewardPage:onBtnCloseClick()
  UIHelper.ClosePage("CheckRewardPage")
end

function CheckRewardPage:updateRandomRewardPart(index, part)
  local randomRewardData = self.mRandomRewardResultList[index]
  local display = ItemInfoPage.GenDisplayData(randomRewardData.ItemType, randomRewardData.ItemId)
  UIHelper.SetLocText(part.txtNum, 710082, randomRewardData.ItemNum)
  UIHelper.SetImage(part.imgIcon, display.icon)
  UIHelper.SetImage(part.imgQuality, QualityIcon[display.quality])
  UIHelper.SetText(part.textName, randomRewardData.GiveUname)
  UGUIEventListener.AddButtonOnClick(part.btnIcon, function()
    UIHelper.OpenPage("ItemInfoPage", display)
  end)
end

return CheckRewardPage
