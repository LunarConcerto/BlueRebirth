local WishACPage = class("UI.Illustrate.WishACPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")

function WishACPage:DoInit()
  self.subTime = 0
  self.rmdItems = {}
  self.m_time = 0
  self.m_timer = nil
  self.m_itemTimer = nil
  self.m_upType = 0
end

function WishACPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bacground, self.CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_cancel, self.CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancle, self.CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_OK, self._SendWishUp, self)
end

function WishACPage:DoOnOpen()
  self.subTime = self:GetParam()
  if self.subTime then
    self.m_upType = 1
  end
  self.rmdItems = Logic.wishLogic:GetAutoAddRmd(self.subTime)
  self:_ShowCDTime()
  self:_ShowSelectInfo(self.rmdItems)
end

function WishACPage:_ShowCDTime()
  local widgets = self:GetWidgets()
  self.m_time = Logic.wishLogic:GetCurCoolDownTime()
  UIHelper.SetText(widgets.tx_reopen_virtual, time.getTimeStringFontDynamic(self.m_time, true))
  self.m_timer = self:CreateTimer(function()
    self:_TickCharge(widgets.tx_reopen_virtual)
  end, 1, -1, false)
  self:StartTimer(self.m_timer)
end

function WishACPage:_TickCharge(txt)
  self.m_time = self.m_time - 1
  UIHelper.SetText(txt, time.getTimeStringFontDynamic(self.m_time, true))
  if self.m_time < 0 then
    Logic.wishLogic:SetHideMask(true)
    self:StopTimer(self.m_timer)
    self:CloseSelf()
  end
end

function WishACPage:_ShowSelectInfo(param)
  local infos = self:_formatItem(param)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.item, widgets.trans_item, #infos, function(index, tabPart)
    local item = CommonRewardItem:new()
    item:Init(index, infos[index], tabPart)
    UIHelper.SetText(tabPart.tx_icon_num, infos[index].Num)
    local total = Logic.wishLogic:GetWishItemNumById(infos[index].ConfigId)
    local str = string.format(UIHelper.GetString(951052), UIHelper.SetColor(infos[index].Desc, "417AE3"))
    UIHelper.SetText(tabPart.txt_desc, str)
    UIHelper.SetText(tabPart.txt_num, "x" .. math.floor(total))
    local _, vip = Logic.wishLogic:GetWishItemTime(infos[index].ConfigId)
    tabPart.obj_vip:SetActive(vip)
    if vip then
      local vipadd = Logic.wishLogic:GetWishItemVipAddTime(infos[index].ConfigId)
      local str = string.format(UIHelper.GetString(951053), UIHelper.SetColor(time.getTimeStringFontDynamic(vipadd), "417AE3"))
      UIHelper.SetText(tabPart.txt_vip, str)
    end
    local show, total = Logic.wishLogic:HaveNumLimit(infos[index].ConfigId)
    tabPart.tx_limit.gameObject:SetActive(show)
    local cur = Data.illustrateData:GetWishItemNum(infos[index].ConfigId)
    local ratiostr = string.format(UIHelper.GetString(951055), cur, total)
    UIHelper.SetText(tabPart.tx_limit, ratiostr)
  end)
  local numStr, timeStr = "", ""
  if 0 < #infos then
    local timeCount = 0
    numStr = "\229\189\147\229\137\141\233\128\137\228\184\173:"
    timeStr = "\229\176\134\229\135\143\229\176\145\232\174\184\230\132\191\229\162\153\229\134\183\229\141\180\230\151\182\233\151\180:"
    local length = #infos
    local up, have
    for index, info in ipairs(infos) do
      local name = Logic.wishLogic:GetName(info.ConfigId)
      numStr = numStr .. name .. UIHelper.SetColor(info.Num, "417AE3") .. "\228\184\170"
      have = Logic.wishLogic:HaveNumLimit(info.ConfigId)
      _, up = Logic.wishLogic:CheckWishItemNum(info.ConfigId)
      if have and up <= info.Num then
        numStr = numStr .. "(\228\184\138\233\153\144)"
      end
      if index == length then
        numStr = numStr .. "\227\128\130"
      else
        numStr = numStr .. "\239\188\140"
      end
      timeCount = timeCount + Logic.wishLogic:GetWishItemTime(info.ConfigId) * info.Num
    end
    timeStr = timeStr .. UIHelper.SetColor(time.getTimeStringFontDynamic(timeCount, false), "417ae3")
    if timeCount >= self.m_time then
      timeStr = timeStr .. "(\231\171\139\229\141\179\229\188\128\229\144\175)"
    end
  end
  UIHelper.SetText(widgets.tx_choose_num, numStr)
  UIHelper.SetText(widgets.tx_cooling_time, timeStr)
  self:_SetItemTimer(param)
end

function WishACPage:_SetItemTimer(items)
  if self.m_itemTimer then
    self:StopTimer(self.m_itemTimer)
    self.m_itemTimer = nil
  end
  if next(items) == nil then
    return
  end
  local ids = {}
  for id, num in pairs(items) do
    table.insert(ids, id)
  end
  local id = Logic.wishLogic:GetCdMinItem(ids)
  local duration = Logic.wishLogic:GetWishItemTime(id)
  self.m_itemTimer = self:CreateTimer(function()
    self:_TickItemRefresh(items, id)
  end, duration, 1, false)
  self:StartTimer(self.m_itemTimer)
end

function WishACPage:_TickItemRefresh(items, id)
  if items[id] then
    items[id] = items[id] - 1
    if items[id] <= 0 then
      items[id] = nil
    end
  else
    logError("can not find id:" .. id .. " in items:" .. printTable(items))
  end
  self:_ShowSelectInfo(items)
end

function WishACPage:_formatItem(items)
  local temp = {}
  for id, num in pairs(items) do
    local des = time.getTimeStringFontDynamic(Mathf.ToInt(Logic.wishLogic:GetWishItemTime(id)), false)
    table.insert(temp, {
      ConfigId = id,
      Num = num,
      Type = GoodsType.WISH,
      Desc = des
    })
  end
  table.sort(temp, function(data1, data2)
    local quality1, quality2
    quality1 = Logic.wishLogic:GetQuality(data1.ConfigId)
    quality2 = Logic.wishLogic:GetQuality(data2.ConfigId)
    return quality1 > quality2
  end)
  return temp
end

function WishACPage:_SendWishUp()
  local res = Logic.wishLogic:CheckUseItem(self.rmdItems)
  local waste, num = Logic.wishLogic:CheckWishWaste(res)
  if waste then
    local str = "\228\186\178\231\136\177\231\154\132\230\140\135\230\140\165\229\174\152,\229\189\147\229\137\141\233\128\137\230\139\169\228\188\154\230\181\170\232\180\185" .. time.getTimeStringFontDynamic(num, true) .. "\229\138\160\233\128\159\230\151\182\233\149\191,\230\152\175\229\144\166\231\187\167\231\187\173\229\189\147\229\137\141\230\147\141\228\189\156?"
    local tabParam = {
      msgType = 2,
      callback = function(bool)
        if bool then
          self:_SendWishImp()
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParam)
    return
  else
    self:_SendWishImp()
  end
end

function WishACPage:_SendWishImp()
  local res = Logic.wishLogic:CheckUseItem(self.rmdItems)
  local temp = {}
  for id, num in pairs(res) do
    if 0 < num then
      table.insert(temp, {ItemTid = id, ItemNum = num})
    end
  end
  if 0 < #temp then
    Service.illustrateService:SendVowDecTime(temp, self.m_upType, WishUseItemWay.AUTO)
  else
    logError("use wish item rpc param nil exception")
  end
  self:CloseSelf()
end

function WishACPage:CloseSelf()
  UIHelper.ClosePage("WishACPage")
end

function WishACPage:DoOnHide()
end

function WishACPage:DoOnClose()
end

return WishACPage
