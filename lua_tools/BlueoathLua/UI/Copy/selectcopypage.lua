local SelectCopyPage = class("UI.Copy.SelectCopyPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function SelectCopyPage:DoInit()
  self.actId = 0
  self.showExploit = false
  self.openIndex = 0
  self.fleetAttrPower = 0
end

function SelectCopyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.UpdateMeritInfo, self._SetMeritInfo, self)
end

function SelectCopyPage:DoOnOpen()
  local param = self:GetParam()
  self.openIndex = self.openIndex + 1
  local levelList = param[1]
  self.tab_Widgets.txt_maxExploit.text = string.format(UIHelper.GetString(1001003), param[2])
  self.nSelectedChapIndex = param[3]
  self.actId = param[4]
  self.curIndex = param[5]
  local topItem = Logic.activityLogic:GetTopItem(self.actId)
  self:OpenTopPage("SelectCopyPage", 1, UIHelper.GetString(1001004), self, true, nil, topItem)
  local meritData = Data.meritData:GetData()
  local meritNum = 0
  for _, v in ipairs(meritData.List) do
    if v.Index == self.curIndex - 1 then
      meritNum = v.Merits
    end
  end
  self.fleetAttrPower = Logic.fleetLogic:GetCurFleetAttr()
  self:_SetMeritInfo()
  self.m_tabServiceData = Data.copyData:GetActSeaData()
  self:_CreateItem(levelList)
end

function SelectCopyPage:_SetMeritInfo()
  local meritData = Data.meritData:GetData()
  local meritNum = 0
  for _, v in ipairs(meritData.List) do
    if v.Index == self.curIndex - 1 then
      meritNum = v.Merits
    end
  end
  self.tab_Widgets.txt_exploit.text = math.tointeger(meritNum)
  local limit = Logic.meritLogic:GetExtraRewardTimes(self.actId)
  local extraNum = Logic.meritLogic:GetExtraReward(self.curIndex)
  extraNum = extraNum ~= nil and extraNum or 0
  self.showExploit = 0 < limit - extraNum
  if self.showExploit then
    self.tab_Widgets.txt_extraNum.text = math.tointeger(limit - extraNum) .. "/" .. limit
  else
    self.tab_Widgets.txt_extraNum.text = "0/" .. limit
  end
end

function SelectCopyPage:_CreateItem(levelList)
  local tabDropInfo = Logic.copyLogic:GetDropInfo()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_copyItem, self.tab_Widgets.trans_layout, #levelList, function(nIndex, tabPart)
    local displayInfo = Logic.copyLogic:GetActLevelConf(levelList[nIndex])
    local baseId = displayInfo.id
    tabPart.txt_name.text = displayInfo.name
    local color = self.fleetAttrPower >= displayInfo.recommend_power and "5e718a" or "ff0000"
    UIHelper.SetTextColor(tabPart.txt_power, displayInfo.recommend_power, color)
    UIHelper.SetImage(tabPart.img_mask, displayInfo.diff_choosing_bg)
    if self.openIndex <= 1 then
      local pos = tabPart.rect_bg.transform.localPosition
      tabPart.rect_bg.transform.localPosition = Vector3.New(pos.x + displayInfo.copy_button_deviation, pos.y, 0)
    end
    tabPart.txt_mask.text = displayInfo.title
    local config = Logic.bagLogic:GetItemByConfig(displayInfo.reward_coin[2])
    UIHelper.SetImage(tabPart.img_reward, config.icon)
    tabPart.txt_reward.text = displayInfo.reward_coin[3]
    tabPart.txt_exploit.text = displayInfo.reward_gongxun[1] .. "~" .. displayInfo.reward_gongxun[2]
    local rewardOne = {
      Type = displayInfo.reward_coin[1],
      ConfigId = displayInfo.reward_coin[2],
      Num = displayInfo.reward_coin[3]
    }
    local rewardTwo = {
      Type = 5,
      ConfigId = 17,
      Num = 0
    }
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self._ShowItemInfo, self, rewardOne)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_exploit, self._ShowItemInfo, self, rewardTwo)
    tabPart.btn_extra.gameObject:SetActive(self.showExploit)
    local extra = displayInfo.extra_drop_info[1]
    local itemInfo = tabDropInfo[extra]
    if itemInfo ~= nil then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_extra, function()
        Logic.rewardLogic:OnClickDropItem(itemInfo, displayInfo)
      end)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_battle, function()
      if not Logic.copyLogic:CheckOpenByCopyId(baseId, true) then
        return
      end
      local param = {
        copyType = CopyType.COMMONCOPY,
        tabSerData = self.m_tabServiceData[baseId],
        chapterId = self.nSelectedChapIndex,
        IsRunningFight = false,
        copyId = baseId,
        actId = self.actId
      }
      UIHelper.OpenPage("LevelDetailsPage", param)
    end)
  end)
end

function SelectCopyPage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function SelectCopyPage:DoOnHide()
end

function SelectCopyPage:DoOnClose()
end

return SelectCopyPage
