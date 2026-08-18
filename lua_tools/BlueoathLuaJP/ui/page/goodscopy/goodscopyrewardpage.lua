local GoodsCopyRewardPage = class("UI.GoodsCopy.GoodsCopyRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function GoodsCopyRewardPage:DoInit()
end

function GoodsCopyRewardPage:DoOnOpen()
  local cfgDatas = configManager.GetData("config_challenge_reward")
  local list = {}
  for k, v in pairs(cfgDatas) do
    table.insert(list, v)
  end
  table.sort(list, function(l, r)
    return l.id < r.id
  end)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_rewardItem, self.tab_Widgets.trans_rewardItem, #list, function(index, tabPart)
    local rewardData = list[index]
    local rewardInfo = Logic.rewardLogic:FormatRewardById(rewardData.reward)
    UIHelper.SetText(tabPart.tx_des, string.format("%.2f%%-%.2f%%", rewardData.p1 / 100, rewardData.p2 / 100))
    UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.trans_reward, #rewardInfo, function(nIndex, luaPart)
      local tabReward = Logic.goodsLogic.AnalyGoods(rewardInfo[nIndex])
      UIHelper.SetImage(luaPart.im_record, tabReward.texIcon)
      UIHelper.SetImage(luaPart.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(luaPart.tx_num, rewardInfo[nIndex].Num)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_reward, self._ShowRewardInfo, self, rewardInfo[nIndex])
    end)
  end)
end

function GoodsCopyRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGroup, self._Close, self)
end

function GoodsCopyRewardPage:_ShowRewardInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function GoodsCopyRewardPage:_Close()
  UIHelper.ClosePage(self:GetName())
end

return GoodsCopyRewardPage
