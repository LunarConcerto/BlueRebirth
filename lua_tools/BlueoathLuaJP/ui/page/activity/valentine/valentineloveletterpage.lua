local ValentineLoveLetterPage = class("ui.page.Activity.VocationActivity.ValentineLoveLetterPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function ValentineLoveLetterPage:DoInit()
  SoundManager.Instance:PreLoad("CV_role_gaobai_bank")
end

function ValentineLoveLetterPage:DoOnOpen()
  local params = self:GetParam() or {}
  self.mItemId = params.ItemId
  self:ShowPage()
end

function ValentineLoveLetterPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, function()
    UIHelper.ClosePage(self:GetName())
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tip, function()
    UIHelper.OpenPage("HelpPage", {content = 1500013})
  end)
end

function ValentineLoveLetterPage:DoOnHide()
end

function ValentineLoveLetterPage:DoOnClose()
  SoundManager.Instance:UnLoad("CV_role_gaobai_bank")
  if self.m_showGirl ~= nil then
    UIHelper.Close3DModel(self.m_showGirl)
    self.m_showGirl = nil
  end
end

function ValentineLoveLetterPage:ShowPage()
  local itemCfg = configManager.GetDataById("config_item_valentine_gift", self.mItemId)
  UIHelper.SetText(self.tab_Widgets.tx_lettertext, itemCfg.love_letter_description)
  UIHelper.SetText(self.tab_Widgets.tx_letterfrom, itemCfg.love_letter_sign)
  local rewards = Logic.rewardLogic:FormatRewardById(itemCfg.attach_reward)
  UIHelper.CreateSubPart(self.tab_Widgets.objItem, self.tab_Widgets.rectItem, #rewards, function(index, tabPart)
    local rewarditem = rewards[index]
    local display = ItemInfoPage.GenDisplayData(rewarditem.Type, rewarditem.ConfigId)
    UIHelper.SetLocText(tabPart.txtNum, 710082, rewarditem.Num)
    UIHelper.SetImage(tabPart.imgIcon, display.icon)
    UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    UIHelper.SetText(tabPart.txtName, display.name)
    UGUIEventListener.AddButtonOnClick(tabPart.btnIcon, function()
      UIHelper.OpenPage("ItemInfoPage", display)
    end)
  end)
  local shipTid = itemCfg.ship_fleet_id
  local heroTid = Data.activityvalentineloveletterData:GetHeroTidByShipTid(shipTid)
  local heroId = Data.activityvalentineloveletterData:GetHeroIdByShipTid(shipTid)
  local shipshow = Logic.shipLogic:GetPictureData(shipTid)
  if shipshow == nil then
    logError("err ship show", heroTid)
    return
  end
  if heroTid <= 0 then
    logWarning("err tid <= 0")
  end
  if 0 < heroTid then
    local tmpshipshow = Logic.shipLogic:GetShipShowById(heroTid)
    if tmpshipshow then
      shipshow = tmpshipshow
    end
  end
  local showId = shipshow.ss_id
  self.tab_Widgets.tween_content:Play(true)
  UIHelper.SetImage(self.tab_Widgets.im_girl, shipshow.ship_draw)
  local position = configManager.GetDataById("config_ship_position", shipshow.ss_id).affection_position
  local scale = configManager.GetDataById("config_ship_position", shipshow.ss_id).affection_scale
  self.tab_Widgets.im_girl.transform.anchoredPosition3D = Vector3.New(position[1], position[2], 0)
  self.tab_Widgets.im_girl.transform.localScale = Vector3.New(scale / 10000, scale / 10000, scale / 10000)
  if 0 < heroId then
    self.tab_Widgets.obj_rigth:SetActive(true)
    local loveInfo, num = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
    UIHelper.SetImage(self.tab_Widgets.imgRelation, loveInfo.affection_icon, true)
    local singleGirl = Data.heroData:GetHeroById(heroId)
    local noMarry = configManager.GetDataById("config_parameter", 155).arrValue
    local marryed = configManager.GetDataById("config_parameter", 156).arrValue
    local max = 0
    if singleGirl.MarryTime == 0 then
      max = math.modf(noMarry[2] / 10000)
    else
      max = math.modf(marryed[2] / 10000)
    end
    self.tab_Widgets.sliderAffection.value = math.modf(num / 10000) / max
    UIHelper.SetText(self.tab_Widgets.tx_value, math.modf(num / 10000) .. "/" .. max)
  else
    self.tab_Widgets.obj_rigth:SetActive(false)
  end
  if self.m_showGirl ~= nil then
    UIHelper.Close3DModel(self.m_showGirl)
    self.m_showGirl = nil
  end
  local param = {showID = showId}
  self.m_showGirl = UIHelper.Create3DModelNoRT(param, nil, false)
  self.m_showGirl:Get3dObj():playBehaviour("show_click_fs16", false)
end

function ValentineLoveLetterPage:PlayShipBehaviour()
end

return ValentineLoveLetterPage
