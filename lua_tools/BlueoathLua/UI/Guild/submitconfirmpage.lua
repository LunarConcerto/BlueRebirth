local SubmitConfirmPage = class("UI.Guild.SubmitConfirmPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function SubmitConfirmPage:DoInit()
  self.mMaxDonateNum = 1
  self.mDonateNum = 1
end

function SubmitConfirmPage:DoOnOpen()
  local tabParam = self:GetParam()
  local taskdata = tabParam.Param.TaskData
  self.mTaskData = taskdata
  if self.mDonateData == nil then
    DonateDataObj = require("ui.page.Guild.GuildTask.DonateDataObj")
    self.mDonateData = DonateDataObj.Create(taskdata)
    UIHelper.SetText(self.tab_Widgets.txtTips, self.mDonateData:GetTxtTips())
  end
  self.mMaxDonateNum = self.mDonateData:GetMaxDonateTaskNum()
  if self.mMaxDonateNum < 1 then
    self.mMaxDonateNum = 1
  end
  self:ShowPage()
end

function SubmitConfirmPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self.onBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSubmit, self.btnSubmitOnClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCancle, self.onBtnCloseClick, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnAdd, function()
    self:SetDonateNum(self.mDonateNum + 1)
    self.mDonateData:SetTaskNum(self.mDonateNum)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnReduce, function()
    self:SetDonateNum(self.mDonateNum - 1)
    self.mDonateData:SetTaskNum(self.mDonateNum)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMax, function()
    self:SetDonateNum(self.mMaxDonateNum)
    self.mDonateData:SetTaskNum(self.mDonateNum)
    self:ShowPage()
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnMin, function()
    self:SetDonateNum(1)
    self.mDonateData:SetTaskNum(self.mDonateNum)
    self:ShowPage()
  end)
end

function SubmitConfirmPage:DoOnHide()
end

function SubmitConfirmPage:DoOnClose()
end

function SubmitConfirmPage:ShowPage()
  local cfg = configManager.GetDataById("config_task_guild", self.mTaskData.TaskId)
  local havenum = Logic.guildtaskLogic:GetDonateItemNum(self.mTaskData.TaskId)
  UIHelper.SetText(self.tab_Widgets.textHave, havenum)
  local items = {}
  local tempitems = {}
  for _, item in ipairs(self.mDonateData.Items) do
    if item.ItemNum > 0 then
      local key = "" .. item.ItemType .. "#" .. item.ItemId
      local tmpitem = tempitems[key]
      if tmpitem == nil then
        tmpitem = clone(item)
        table.insert(items, tmpitem)
      else
        tmpitem.ItemNum = tmpitem.ItemNum + item.ItemNum
      end
      tempitems[key] = tmpitem
    else
      local tmpitem = clone(item)
      table.insert(items, tmpitem)
    end
  end
  UIHelper.CreateSubPart(self.tab_Widgets.objItem, self.tab_Widgets.rectItemList, #items, function(nIndex, tabPart)
    local item = items[nIndex]
    if item.ItemNum > 0 then
      tabPart.objItemInfo:SetActive(true)
      tabPart.objImgAdd:SetActive(false)
      local display = ItemInfoPage.GenDisplayData(item.ItemType, item.ItemId)
      UIHelper.SetLocText(tabPart.textNum, 710082, item.ItemNum)
      UIHelper.SetImage(tabPart.imgIcon, display.icon)
      UIHelper.SetImage(tabPart.imgQuality, QualityIcon[display.quality])
    else
      tabPart.objItemInfo:SetActive(false)
      tabPart.objImgAdd:SetActive(true)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btnItem, self.btnItemOnClick, self, {Index = nIndex})
  end)
  self:ShowDonateNum()
end

function SubmitConfirmPage:onBtnCloseClick()
  UIHelper.ClosePage("SubmitConfirmPage")
end

function SubmitConfirmPage:checkHaveNum()
  return self.mDonateData:CheckHaveNum()
end

function SubmitConfirmPage:btnSubmitOnClick()
  if not self:checkHaveNum() then
    return
  end
  local sumDonateNum = 0
  for _, item in ipairs(self.mDonateData.Items) do
    if 0 >= item.ItemNum then
      noticeManager:ShowTipById(710079)
      return
    else
      sumDonateNum = sumDonateNum + item.ItemNum
    end
  end
  local needDonateNum = self.mDonateData:GetTarDonateNum()
  if sumDonateNum < needDonateNum then
    noticeManager:ShowTipById(710079)
    return
  end
  local doSendDonate = function()
    Service.guildtaskService:SendDonate(self.mDonateData)
    UIHelper.ClosePage("SubmitConfirmPage")
  end
  if Logic.guildtaskLogic:CheckDonateNotice(self.mDonateData) then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          doSendDonate()
        end
      end
    }
    noticeManager:ShowMsgBox(710087, tabParams)
    return
  end
  doSendDonate()
end

function SubmitConfirmPage:btnItemOnClick(go, param)
  if not self:checkHaveNum() then
    return
  end
  param.TaskData = self.mTaskData
  param.DonateData = self.mDonateData
  param.Items = self.mDonateData.Items
  
  function param.CallBack(items)
    self.mDonateData.Items = items
    self.mDonateData:SetTaskNum(self.mDonateNum)
    self:ShowPage()
  end
  
  local paramTab = {
    Position = go.transform.position,
    Param = param
  }
  UIHelper.OpenPage("ChoosePage", paramTab)
end

function SubmitConfirmPage:SetDonateNum(num)
  self.mDonateNum = num
  if self.mDonateNum < 1 then
    self.mDonateNum = 1
  elseif self.mDonateNum > self.mMaxDonateNum then
    self.mDonateNum = self.mMaxDonateNum
  end
end

function SubmitConfirmPage:ShowDonateNum()
  UIHelper.SetText(self.tab_Widgets.textNum, self.mDonateNum)
end

return SubmitConfirmPage
