local YesterdayRewardPage = class("UI.Guild.YesterdayRewardPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function YesterdayRewardPage:DoInit()
end

function YesterdayRewardPage:DoOnOpen()
  self.mRewardMemList = Logic.guildtaskLogic:GetConstantRewardMemGetList()
  self.tab_Widgets.objEmpty:SetActive(#self.mRewardMemList == 0)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.contentPlayerList, self.tab_Widgets.itemTemplate, #self.mRewardMemList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      self:updateRewardMemPart(index, part)
    end
  end)
end

function YesterdayRewardPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCloseTip, function()
    UIHelper.ClosePage("YesterdayRewardPage")
  end)
end

function YesterdayRewardPage:DoOnHide()
end

function YesterdayRewardPage:DoOnClose()
end

function YesterdayRewardPage:updateRewardMemPart(index, part)
  local mem = self.mRewardMemList[index]
  UIHelper.SetText(part.textName, mem.User.Uname)
  UIHelper.SetLocText(part.textLevel, 710080, mem.User.Level)
  local myUid = Data.userData:GetUserUid()
  part.objImgSelf:SetActive(myUid == mem.Uid)
  local icon, quality = Logic.meritLogic:GetUserHead(mem.User)
  UIHelper.SetImage(part.imgQuality, quality)
  UIHelper.SetImage(part.imgHead, icon)
  local post = Data.guildData:GetPostByUid(mem.Uid)
  local cfg = configManager.GetDataById("config_guildpost", GuildPostCfgID[post])
  UIHelper.SetLocText(part.textPost, 710081, cfg.post)
  local memContri = Data.guildtaskData:GetMemberContribute()
  local contri = memContri[mem.Uid] or 0
  UIHelper.SetText(part.textContri, contri)
  local constItemReward = Data.guildtaskData:GetGetConstantRewardByUid(mem.Uid)
  if constItemReward ~= nil then
    UIHelper.CreateSubPart(part.objReward, part.rectRewardList, #constItemReward, function(nIndex, tabPart)
      local rewarditem = constItemReward[nIndex]
      local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
      UIHelper.SetLocText(tabPart.textNum, 710082, rewarditem.Num)
      UIHelper.SetImage(tabPart.imgIcon, display.icon)
      UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
      UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
        UIHelper.OpenPage("ItemInfoPage", display)
      end)
    end)
  end
end

return YesterdayRewardPage
