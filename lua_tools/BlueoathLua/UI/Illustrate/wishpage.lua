local WishPage = class("UI.Illustrate.WishPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")
local WishSelectHeroItem = require("ui.page.Illustrate.WishSelectHeroItem")
local SHOWITEMNUM = 8
local wishLogic = Logic.wishLogic
local maskHideImgMap = {
  [true] = "uipic_ui_vow_fo_jiasu",
  [false] = "uipic_ui_vow_fo_xuyuan"
}

function WishPage:DoInit()
  self.m_tabWidgets = nil
  self.m_timer = nil
  self.m_pressTimer = nil
  self.m_atimer = nil
  self.m_index = 1
  self.floatCard = nil
  self.m_uiCanShowAdvance = true
  self.m_vowGetHero = nil
  self.m_audioState = false
  self.usedStones = {}
  self.banAreaTweenScale = UIHelper.GetTween(self:GetWidgets().obj_banarea, ETweenType.ETT_SCALE)
  self.banAreaScaledUp = false
  self.m_curPressItem = nil
  self.timeDownPosTween = UIHelper.GetTween(self:GetWidgets().time_down, ETweenType.ETT_POSITION)
  self.timeDownAlpTween = UIHelper.GetTween(self:GetWidgets().time_down, ETweenType.ETT_ALPHA)
  self:_OnOpenRetention()
end

function WishPage:_OnOpenRetention()
  local dotinfo = {
    info = "ui_vow",
    item_num = Logic.wishLogic:GetWishItemRetention()
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function WishPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_left, self._LeftMove, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_right, self._RightMove, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ask, self._OpenTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ask1, self._OpenTip, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_select, self._AllSelect, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ban, self._AllBan, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_start, self._StartWish, self)
  UGUIEventListener.AddButtonOnClick(widgets.tog_switch, self._TogCloseBan, self)
  UGUIEventListener.AddButtonOnClick(widgets.tog_open, self._TogOpenBan, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_info, self._ShowCdDescPop, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_hide, self._HideMask, self, true)
  UGUIEventListener.AddButtonOnClick(widgets.btn_opentips, self._HideMask, self, false)
  UGUIEventListener.AddButtonOnClick(widgets.btn_advance, self._ShowAdvance, self)
  UGUIEventListener.AddButtonOnClick(widgets.refresh, self._CloseCoolDownFinish, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_autoAdd, self._AutoAddFull, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_addOneDay, self._AutoAddOneDay, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_tip, self._ShowNoWishTip, self)
  self:RegisterEvent(LuaEvent.GetWishReward, self._OpenGetHeroPage, self)
  self:RegisterEvent(LuaEvent.UpdateWish, self._UpdataWish, self)
  self:RegisterEvent(LuaEvent.ShowGirlEnd, self._ShowChargeTip, self)
  self:RegisterEvent(LuaEvent.UseWishItem, self._OnUseWishItem, self)
  self:RegisterEvent(LuaEvent.WISH_ItemCountRefresh, self._ShowItem, self)
end

function WishPage:DoOnOpen()
  self:OpenTopPage("WishPage", 1, "\232\174\184\230\132\191\229\162\153", self, true, function()
    self:_OnBack()
  end)
  self:_InitUIData()
  self:_UpdataWish()
  self:_CheckCoolDownTime()
  self:_ActivityHandler()
end

function WishPage:_InitUIData()
  Logic.wishLogic:SetPressLock(true)
  Logic.wishLogic:ResetAllDummyItem()
end

function WishPage:_OnBack()
  local expend = Logic.wishLogic:GetExpend()
  if expend then
    self:_TogShowBan(false)
  else
    UIHelper.Back()
  end
end

function WishPage:_ShowAdvance()
  local ok, res = Logic.wishLogic:CheckAdvance()
  if ok then
    UIHelper.OpenPage("WishAdvanceDetailPage", res)
  else
    logError("\230\151\160\233\162\132\229\145\138\232\136\176\229\168\152")
  end
end

function WishPage:_ShowNoWishTip()
  UIHelper.OpenPage("WishNoTip")
end

function WishPage:_LeftMove()
  self.m_index = self.m_index - 1
  Logic.wishLogic:SetPageIndex(self.m_index)
  self:_ShowSelectHero()
end

function WishPage:_RightMove()
  self.m_index = self.m_index + 1
  Logic.wishLogic:SetPageIndex(self.m_index)
  self:_ShowSelectHero()
end

function WishPage:_UpdataWish()
  self:WishCheckRefreshHero()
  self:_ShowMask()
  self:_ShowSelectHero()
  self:_ShowBottom()
  local info = Data.wishData:GetBanHeroList()
  eventManager:SendEvent(LuaEvent.UpdateHeroItem, {heroTab = info})
end

function WishPage:WishCheckRefreshHero()
  Data.wishData:CheckRefreshHero()
end

function WishPage:_ShowCoolDownFinish()
  local widgets = self:GetWidgets()
  widgets.refresh:SetActive(true)
end

function WishPage:_CloseCoolDownFinish()
  local widgets = self:GetWidgets()
  widgets.refresh:SetActive(false)
end

function WishPage:_CheckCoolDownTime()
  local curState = self:_GetCoolDownState()
  local curCoolDownTime = Logic.wishLogic:GetCurCoolDownTime()
  if curCoolDownTime <= 0 and curState == WishCoolState.COOL then
    self:_ShowCoolDownFinish()
    self:_SetCoolDownState(WishCoolState.OPEN)
  end
end

function WishPage:_GetCoolDownState()
  return PlayerPrefs.GetInt("WishCoolDownState", WishCoolState.OPEN)
end

function WishPage:_SetCoolDownState(state)
  PlayerPrefs.SetInt("WishCoolDownState", state)
end

function WishPage:_ScrollTime(from, to, onFinish)
  local curr = from
  local step = (from - to) / 20
  local timeStr
  local widgets = self:GetWidgets()
  self:TryStopTimer(self.scrollTimer)
  self.scrollTimer = self:CreateTimer(function()
    curr = curr - step
    if curr < to then
      curr = to
    end
    timeStr = time.getTimeStringFontDynamic(curr)
    UIHelper.SetText(widgets.tx_nexttime, timeStr)
    if curr <= to then
      self:TryStopTimer(self.scrollTimer)
      onFinish()
    end
  end, 0.03, -1)
  self:StartTimer(self.scrollTimer)
end

function WishPage:_PlayTimeScrollAnim(usedId, onFinish)
  local curCoolDownTime = Logic.wishLogic:GetCurCoolDownTime()
  if 0 < curCoolDownTime then
    self:StopTimer(self.m_timer)
    local preCoolDownTime = curCoolDownTime + Logic.wishLogic:GetWishItemTime(usedId)
    self:_ScrollTime(preCoolDownTime, curCoolDownTime, onFinish)
  else
    onFinish()
  end
end

function WishPage:_OnUseWishItem(args)
  if args.UseWay == WishUseItemWay.PRESS then
    self:_UpdataWish()
  else
    local usedId = args.ItemTid
    self:_DoStoneRetention(usedId)
    self:_CheckCoolDownTime()
    self:_PlayTimeDown()
    self:_PlayTimeScrollAnim(usedId, function()
      self:_UpdataWish()
    end)
  end
end

function WishPage:_DoStoneRetention(stoneId)
  local dotinfo = {
    info = "ui_vow_stone",
    vow_stone_id = stoneId
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function WishPage:_ShowBottom()
  local widgets = self:GetWidgets()
  local sr, ssr = Logic.wishLogic:GetBanHeroNum()
  local srTime, isLimitSR = Logic.wishLogic:GetHeroChargeTimeByQuality(ShipQuality.SR)
  local ssrTime, isLimitSSR = Logic.wishLogic:GetHeroChargeTimeByQuality(ShipQuality.SSR)
  UIHelper.SetText(widgets.tx_count_sr, "SR:" .. sr)
  UIHelper.SetText(widgets.tx_count_ssr, "SSR:" .. ssr)
  local limitStr = isLimitSR and UIHelper.GetString(951032) or ""
  UIHelper.SetText(widgets.tx_time_sr, time.getTimeStringFontDynamic(srTime) .. limitStr)
  limitStr = isLimitSSR and UIHelper.GetString(951032) or ""
  UIHelper.SetText(widgets.tx_time_ssr, time.getTimeStringFontDynamic(ssrTime) .. limitStr)
  local ok, _ = Logic.wishLogic:CheckAdvance()
  widgets.btn_advance:SetActive(ok and self.m_uiCanShowAdvance)
  local hideMask = Logic.wishLogic:GetHideMask()
  local tog, cdtime = Logic.wishLogic:CheckCharge()
  tog = tog and hideMask
  local icon = maskHideImgMap[tog]
  UIHelper.SetImage(widgets.im_start, icon)
  widgets.btn_opentips.gameObject:SetActive(tog)
  if tog then
    self.m_time = Logic.wishLogic:GetCurCoolDownTime()
    UIHelper.SetText(widgets.tx_opentime, time.getTimeStringFontDynamic(cdtime, true))
    self:StopTimer(self.m_timer)
    self.m_timer = self:CreateTimer(function()
      self:_TickCharge(widgets.tx_opentime)
    end, 1, -1, false)
    self:StartTimer(self.m_timer)
    self:_SetCoolDownState(WishCoolState.COOL)
  end
end

function WishPage:_ShowMask()
  local widgets = self:GetWidgets()
  local hideMask = Logic.wishLogic:GetHideMask()
  local tog, countDownTime = Logic.wishLogic:CheckCharge()
  tog = tog and not hideMask
  widgets.obj_mask:SetActive(tog)
  if tog then
    self.m_time = Logic.wishLogic:GetCurCoolDownTime()
    UIHelper.SetText(widgets.tx_nexttime, time.getTimeStringFontDynamic(countDownTime, true))
    self:StopTimer(self.m_timer)
    self.m_timer = self:CreateTimer(function()
      self:_TickCharge(widgets.tx_nexttime)
    end, 1, -1, false)
    self:StartTimer(self.m_timer)
    self:_ShowItem()
    self:_SetCoolDownState(WishCoolState.COOL)
    self:_TryShowActiveTip()
    SoundManager.Instance:PlayMusic("System|Wish_closed")
  else
    SoundManager.Instance:PlayMusic("System|Wish_open")
    self:_ShowTimeUp(false)
  end
end

function WishPage:_ShowTimeUp(isOn)
  local widgets = self:GetWidgets()
  widgets.time_down:SetActive(isOn)
end

function WishPage:_TryShowActiveTip()
  local widgets = self:GetWidgets()
  Logic.wishLogic:DWrap_ShowActiveTip(widgets.tx_bindtip)
end

function WishPage:_TickCharge(txt)
  self.m_time = self.m_time - 1
  UIHelper.SetText(txt, time.getTimeStringFontDynamic(self.m_time, true))
  if self.m_time < 0 then
    Logic.wishLogic:SetHideMask(true)
    self:_UpdataWish()
  end
end

function WishPage:_ShowItem()
  local info = Logic.wishLogic:GetWishItemAndFormat()
  local widgets = self:GetWidgets()
  local isSuper
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #info, function(index, tabPart)
    local item = CommonRewardItem:new()
    item:Init(index, info[index], tabPart)
    local _, vip = Logic.wishLogic:GetWishItemTime(info[index].ConfigId)
    isSuper = Logic.wishLogic:IsSuperWishItem(info[index].ConfigId)
    local str = ""
    if isSuper then
      str = UIHelper.SetColor(info[index].Desc, "417AE3")
    else
      str = string.format(UIHelper.GetString(951052), UIHelper.SetColor(info[index].Desc, "417AE3"))
    end
    UIHelper.SetText(tabPart.txt_desc, str)
    UIHelper.SetText(tabPart.txt_num, "x" .. math.floor(info[index].Num))
    UGUIEventListener.AddButtonOnClick(tabPart.img_frame, self._UseWishItem, self, info[index])
    tabPart.obj_vip:SetActive(vip)
    if vip then
      local vipadd = Logic.wishLogic:GetWishItemVipAddTime(info[index].ConfigId)
      local str = string.format(UIHelper.GetString(951053), UIHelper.SetColor(time.getTimeStringFontDynamic(vipadd), "417AE3"))
      UIHelper.SetText(tabPart.txt_vip, str)
    end
    local act = Logic.wishLogic:InActivty()
    widgets.obj_activity:SetActive(act)
    local show, total = Logic.wishLogic:HaveNumLimit(info[index].ConfigId)
    tabPart.tx_limit.gameObject:SetActive(show)
    local cur = Mathf.Min(Data.illustrateData:GetWishItemNum(info[index].ConfigId), total)
    local ratiostr = string.format(UIHelper.GetString(951055), cur, total)
    UIHelper.SetText(tabPart.tx_limit, ratiostr)
    UGUIEventListener.AddButtonOnLongPress(tabPart.img_frame, self._OnItemLongPress, self, {
      Data = info[index],
      Widgets = tabPart
    })
    UGUIEventListener.AddButtonOnPointUp(tabPart.img_frame, self._OnItemPointUp, self, info[index])
  end)
end

function WishPage:_UseWishItem(go, award)
  local countOk = Logic.wishLogic:CheckWishItemNum(award.ConfigId)
  if not countOk then
    noticeManager:ShowTip(UIHelper.GetString(951054))
    return
  end
  local isSuper = award.ConfigId == Logic.wishLogic:GetSuperWishItemId()
  local itemNum = Data.bagData:GetItemNum(award.ConfigId)
  if itemNum < 1 then
    globalNoitceManager:ShowItemInfoPage(award.Type, award.ConfigId)
    local name = Logic.wishLogic:GetName(award.ConfigId)
    noticeManager:ShowTip(string.format(UIHelper.GetString(951024), name))
    return
  end
  local limitTime = Logic.wishLogic:GetLimitTime()
  local _, time = Logic.wishLogic:CheckCharge()
  local reduce = Logic.wishLogic:GetWishItemTime(award.ConfigId)
  if limitTime > time and not isSuper then
    noticeManager:ShowTip(UIHelper.GetString(951023))
    return
  end
  if isSuper then
    UIHelper.OpenPage("WishSpeedupTipPage", {
      itemId = award.ConfigId,
      itemType = award.Type,
      isSuper = isSuper,
      okCallback = function()
        self:_SendUseItemReq(award.ConfigId)
      end
    })
  elseif 0 < limitTime and limitTime > time - reduce and -1 < reduce then
    UIHelper.OpenPage("WishSpeedupTipPage", {
      itemId = award.ConfigId,
      itemType = award.Type,
      isSuper = isSuper,
      okCallback = function()
        self:_SendUseItemReq(award.ConfigId)
      end
    })
  else
    self:_SendUseItemReq(award.ConfigId)
  end
end

function WishPage:_PlayTimeDown()
  self:_ShowTimeUp(true)
  self.timeDownPosTween:ResetToInit()
  self.timeDownPosTween.from = Vector3.New(207, 533, 0)
  self.timeDownPosTween.to = Vector3.New(207, 466, 0)
  self.timeDownPosTween.duration = 0.5
  self.timeDownAlpTween:ResetToInit()
  self.timeDownAlpTween.from = 1
  self.timeDownAlpTween.to = 0
  self.timeDownAlpTween.duration = 0.5
  self.timeDownPosTween:Play(true)
  self.timeDownAlpTween:Play(true)
  if not self.m_audioState then
    SoundManager.Instance:PlayAudio("Effect_Eff_timedown")
    self.m_audioState = true
    local timer = self:CreateTimer(function()
      SoundManager.Instance:StopAudio("Effect_Eff_timedown")
      self.m_audioState = false
    end, 0.5, 1, true)
    self:StartTimer(timer)
  end
end

function WishPage:_SendUseItemReq(id)
  Service.illustrateService:SendVowDecTime({
    {ItemTid = id, ItemNum = 1}
  }, nil, WishUseItemWay.CLICK)
end

function WishPage:_ShowSelectHero()
  local info = Data.wishData:GetSelectHeroList()
  local widgets = self:GetWidgets()
  widgets.btn_left.gameObject:SetActive(#info > SHOWITEMNUM)
  widgets.obj_right.gameObject:SetActive(#info > SHOWITEMNUM)
  if #info <= SHOWITEMNUM then
    self.m_index = 1
    Logic.wishLogic:SetPageIndex(self.m_index)
    self:_InitHeroList(info, widgets)
    widgets.btn_left.gameObject:SetActive(false)
    widgets.obj_right.gameObject:SetActive(false)
  else
    local total = math.ceil(#info / SHOWITEMNUM)
    self:_checkIndex(total)
    info = self:_getIndexInfo(info)
    self:_InitHeroList(info, widgets)
    widgets.btn_left.gameObject:SetActive(self.m_index ~= 1)
    widgets.obj_right.gameObject:SetActive(self.m_index ~= total)
  end
end

function WishPage:_getIndexInfo(info)
  local res = {}
  for i = 1, SHOWITEMNUM do
    local index = (self.m_index - 1) * SHOWITEMNUM + i
    if info[index] ~= nil then
      res[i] = info[index]
    end
  end
  return res
end

function WishPage:_checkIndex(total)
  if total < self.m_index then
    self.m_index = total
    Logic.wishLogic:SetPageIndex(self.m_index)
  end
  if self.m_index < 1 then
    self.m_index = 1
    Logic.wishLogic:SetPageIndex(self.m_index)
  end
end

function WishPage:_InitHeroList(herolist, widgets)
  local posConfig = Logic.wishLogic:GetWishShipConfig()
  self.m_cardPosTwns = {}
  UIHelper.CreateSubPart(widgets.obj_hero, widgets.trans_hero, #herolist, function(index, tabPart)
    local item = WishSelectHeroItem:new()
    item:Init(self, herolist[index], tabPart, true, widgets.obj_banarea, index)
    tabPart.card.transform.localPosition = Vector3.New(posConfig[index].vow_pos_x, posConfig[index].vow_pos_y, 0)
    self.m_cardPosTwns[index] = UIHelper.AddTween(tabPart.card, ETweenType.ETT_POSITION)
  end)
end

function WishPage:_ShowBanHero()
  local info = Data.wishData:GetBanHeroList()
  local banPage = UIHelper.OpenPage("CommonHeroPage", {
    self,
    CommonHeroItem.Wish,
    info,
    nil,
    Vector3.New(0, 250, 0)
  })
  Logic.wishLogic:SetBanPage(banPage)
  self:_ShowAdvanceBtn(false)
end

function WishPage:_TogOpenBan()
  self:_TogShowBan(true)
end

function WishPage:_TogCloseBan()
  self:_TogShowBan(false)
end

function WishPage:_ShowAdvanceBtn(isOn)
  local widgets = self:GetWidgets()
  local ok, _ = Logic.wishLogic:CheckAdvance()
  ok = ok and isOn
  widgets.btn_advance:SetActive(ok)
  self.m_uiCanShowAdvance = isOn
end

function WishPage:_TogShowBan(isOn)
  local widgets = self:GetWidgets()
  widgets.obj_close:SetActive(not isOn)
  widgets.obj_open:SetActive(isOn)
  widgets.obj_banarea:SetActive(not isOn)
  if isOn then
    self:_ShowBanHero()
  else
    UIHelper.ClosePage("CommonHeroPage")
    self:_ShowAdvanceBtn(true)
  end
  Logic.wishLogic:SetExpend(isOn)
end

function WishPage:_ShowCdDescPop()
  UIHelper.OpenPage("WishCdPage", {type = "desc"})
end

function WishPage:_OpenTip()
  local str = ""
  str = UIHelper.GetString(952001) .. "\n" .. UIHelper.GetString(952002) .. "\n" .. UIHelper.GetString(952003) .. "\n" .. UIHelper.GetString(952004) .. "\n" .. UIHelper.GetString(952005) .. "\n" .. UIHelper.GetString(952006) .. "\n" .. UIHelper.GetString(952007) .. "\n" .. UIHelper.GetString(952008)
  UIHelper.OpenPage("HelpPage", {content = str})
end

function WishPage:_AllSelect()
  local sortData = Logic.sortLogic:GetHeroSort(CommonHeroItem.Wish)
  Data.wishData:AllSelect(sortData)
  self:_UpdataWish()
end

function WishPage:_AllBan()
  Data.wishData:AllBan()
  self:_UpdataWish()
end

function WishPage:_StartWish()
  local tog = Logic.wishLogic:CheckCharge()
  if tog then
    Logic.wishLogic:SetHideMask(false)
    self:_ShowMask()
  else
    local heros = Data.wishData:GetSelectHeroList()
    if heros == nil or next(heros) == nil then
      noticeManager:ShowTip(UIHelper.GetString(951026))
      return
    end
    local upCheck = Logic.dockLogic:IsReachMax()
    if upCheck then
      noticeManager:ShowTip(UIHelper.GetString(110012))
      return
    end
    UIHelper.OpenPage("WishSelectTip")
  end
end

function WishPage:_OpenGetHeroPage(args)
  local si_id = Logic.shipLogic:GetShipInfoId(args.TemplateId)
  local shipName = Logic.shipLogic:GetName(si_id)
  local dotinfo = {info = "ui_vow_get", ship_name = shipName}
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  UIHelper.OpenPage("ShowGirlPage", {
    girlId = Logic.shipLogic:GetShipInfoIdByTid(args.TemplateId),
    HeroId = args.HeroId,
    getWay = GetGirlWay.vow
  })
  local tim = Logic.wishLogic:GetFinalChargeTime()
  Data.illustrateData:SetChargeTime(tim + time.getSvrTime())
  self.m_vowGetHero = args.TemplateId
  self:_DoRetention()
end

function WishPage:_ShowChargeTip()
  UIHelper.OpenPage("WishCdPage", {type = "result"})
end

function WishPage:OnDragCard(tabPart, heroInfo, eventData)
  local delta = eventData.delta
  if self.floatCard == nil and delta.y > 5 then
    local widgets = self:GetWidgets()
    self.floatCard = UIHelper.CreateGameObject(tabPart.gameObject, widgets.float_card)
    self.floatCard.transform.pivot = Vector2.New(0.5, 0.5)
  end
  if self.floatCard then
    tabPart.fixDrag:OnEndDrag(eventData)
    tabPart.fixDrag:StopMove()
    tabPart.fixDrag.bEnable = false
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    self.floatCard.transform.position = finalPos
    tabPart.objGolden:SetActive(true)
    tabPart.objMask:SetActive(true)
  end
end

function WishPage:OnReleaseCard(tabPart)
  tabPart.fixDrag.bEnable = true
  tabPart.objGolden:SetActive(false)
  tabPart.objMask:SetActive(false)
  self:_DestroyFloatCard()
  self:_UpdataWish()
end

function WishPage:_DestroyFloatCard()
  if self.floatCard then
    GameObject.Destroy(self.floatCard)
    self.floatCard = nil
  end
end

function WishPage:_GetUseStoneStr()
  local str = ""
  local len = #self.usedStones
  for i, id in ipairs(self.usedStones) do
    if i < len then
      str = str .. id .. ","
    else
      str = str .. id
    end
  end
  str = string.format("{%s}", str)
  self.usedStones = {}
  return str
end

function WishPage:_HideMask(go, hide)
  local widgets = self:GetWidgets()
  local tog, cdtime = Logic.wishLogic:CheckCharge()
  tog = tog and hide
  local icon = maskHideImgMap[tog]
  UIHelper.SetImage(widgets.im_start, icon)
  widgets.obj_mask:SetActive(not hide)
  Logic.wishLogic:SetHideMask(hide)
  if hide then
    self:_ForceCloseAudio()
    wishLogic:SetPressLock(true)
    self:_ShowBottom()
  else
    self:_ShowMask()
  end
end

function WishPage:PlayScaleUp()
  if not self.banAreaScaledUp then
    self.banAreaTweenScale:ResetToInit()
    self.banAreaTweenScale.from = Vector3.one
    self.banAreaTweenScale.to = Vector3.New(1.5, 1.5, 1.5)
    self.banAreaTweenScale.duration = 0.3
    self.banAreaTweenScale:Play(true)
    self.banAreaScaledUp = true
  end
end

function WishPage:PlayScaleDown()
  if self.banAreaScaledUp then
    self.banAreaTweenScale:ResetToInit()
    self.banAreaTweenScale.from = Vector3.New(1.5, 1.5, 1.5)
    self.banAreaTweenScale.to = Vector3.one
    self.banAreaTweenScale.duration = 0.3
    self.banAreaTweenScale:Play(true)
    self.banAreaScaledUp = false
  end
end

function WishPage:_CardMoveXTween(direct, index, parts)
  local timebase = Logic.wishLogic:GetWishTweenTime()
  local from, to, delay
  local widgets = self:GetWidgets()
  local seq = UISequence.NewSequence(widgets.trans_hero.gameObject)
  if direct == 0 then
    for i, twn in ipairs(self.m_cardPosTwns) do
      if index < i then
        from = Logic.wishLogic:GetShipPosByIndex(i)
        to = Logic.wishLogic:GetShipPosByIndex(i - 1)
        seq:Append(self:_setPosTwn(twn, from, to, timebase))
      end
    end
    seq:AppendCallback(function()
      self:_UpdataWish()
    end)
  else
    for i = #self.m_cardPosTwns, 1, -1 do
      if index < i then
        from = Logic.wishLogic:GetShipPosByIndex(i)
        to = Logic.wishLogic:GetShipPosByIndex(i + 1)
        seq:Append(self:_setPosTwn(self.m_cardPosTwns[i], from, to, timebase))
      end
    end
    seq:AppendCallback(function()
      self:OnReleaseCard(parts)
    end)
  end
  seq:Play(true)
end

function WishPage:_rightMoveCard(param)
  self:_CardMoveXTween(1, param.index, param.parts)
end

function WishPage:_setPosTwn(postwn, from, to, time)
  postwn.from = from
  postwn.to = to
  postwn.duration = time
  return postwn
end

function WishPage:_DoRetention()
  if self.m_vowGetHero then
    local banNums = Logic.wishLogic:GetBanPickNumStr("ban")
    local pickNums = Logic.wishLogic:GetBanPickNumStr("pick")
    local banNames = Logic.wishLogic:GetBanHeroNames()
    local pickNames = Logic.wishLogic:GetPickHeroNames()
    local time = Logic.wishLogic:GetFinalChargeTime()
    local dotinfo = {}
    dotinfo.ban_name = banNames
    dotinfo.pick_name = pickNames
    dotinfo.ban_num = banNums
    dotinfo.pick_num = pickNums
    dotinfo.cd = time
    dotinfo.vow_get_id = self.m_vowGetHero
    dotinfo.vow_get_name = Logic.shipLogic:GetShipInfoById(self.m_vowGetHero).ship_name
    RetentionHelper.Retention(PlatformDotType.vow, dotinfo)
    self.m_vowGetHero = nil
  end
end

function WishPage:_OnItemPointUp(go, param)
  local tid = param.ConfigId
  local lock = Logic.wishLogic:GetPressLock()
  if not lock then
    self:_OnLongPressSend(tid)
  else
    self:TryStopTimer(self.m_pressTimer)
  end
end

function WishPage:_OnItemLongPress(go, param)
  local tid = param.Data.ConfigId
  self.m_curPressItem = param.Widgets
  Logic.wishLogic:SetPressLock(false)
  local duration = Logic.wishLogic:GetPressUseItemDurationConfig()
  self.m_pressTimer = self:CreateTimer(function()
    local ok = self:_DummyUseItem(param.Data)
    local lock = Logic.wishLogic:GetPressLock()
    if ok and not lock then
      self:_DummyOnUseItem(tid)
    else
      self:_OnLongPressSend(tid)
    end
  end, duration, -1, false)
  self:StartTimer(self.m_pressTimer)
end

function WishPage:_OnLongPressSend(tid)
  local num = Logic.wishLogic:GetDummyItem(tid)
  Logic.wishLogic:CheckAndSendUseItem(tid, num)
  Logic.wishLogic:SetPressLock(true)
  self:TryStopTimer(self.m_pressTimer)
  Logic.wishLogic:ResetAllDummyItem()
  self.m_curPressItem = nil
end

function WishPage:_DummyUseItem(param)
  local tid = param.ConfigId
  local countOk = Logic.wishLogic:DummyCheckWishItemNum(tid, num)
  if not countOk then
    noticeManager:ShowTip(UIHelper.GetString(951054))
    return false
  end
  local itemNum = Logic.wishLogic:DummyGetWishItemNum(tid)
  if itemNum < 1 then
    globalNoitceManager:ShowItemInfoPage(param.Type, tid)
    local name = Logic.wishLogic:GetName(tid)
    noticeManager:ShowTip(string.format(UIHelper.GetString(951024), name))
    return false
  end
  local isSuper = tid == Logic.wishLogic:GetSuperWishItemId()
  local limitTime = Logic.wishLogic:GetLimitTime()
  local _, time = Logic.wishLogic:DummyCheckCharge(tid)
  local reduce = Logic.wishLogic:GetWishItemTime(tid)
  if limitTime > time and not isSuper then
    noticeManager:ShowTip(UIHelper.GetString(951023))
    return false
  end
  if isSuper then
    UIHelper.OpenPage("WishSpeedupTipPage", {
      itemId = tid,
      itemType = GoodsType.ITEM,
      isSuper = isSuper,
      okCallback = function()
        Logic.wishLogic:PressBaseSend(tid)
        Logic.wishLogic:SetPressLock(true)
        return false
      end
    })
  elseif 0 < limitTime and limitTime > time - reduce and -1 < reduce then
    UIHelper.OpenPage("WishSpeedupTipPage", {
      itemId = tid,
      itemType = GoodsType.WISH,
      isSuper = isSuper,
      okCallback = function()
        Logic.wishLogic:PressBaseSend(tid)
        Logic.wishLogic:SetPressLock(true)
        return false
      end
    })
  else
    Logic.wishLogic:AddDummyItem(tid, 1)
    return true
  end
end

function WishPage:_DummyOnUseItem(tid)
  self:_DoStoneRetention(tid)
  self:_DummyCheckCoolDownTime(tid)
  self:_PlayTimeDown()
  self:_DummyPlayTimeScrollAnim(tid, function()
    self:_DummyUpdateWish(tid)
  end)
end

function WishPage:_DummyCheckCoolDownTime(tid)
  local curState = self:_GetCoolDownState()
  local curCoolDownTime = Logic.wishLogic:DummyGetCurCoolDownTime(tid)
  if curCoolDownTime <= 0 and curState == WishCoolState.COOL then
    self:_ShowCoolDownFinish()
    self:_SetCoolDownState(WishCoolState.OPEN)
  end
end

function WishPage:_DummyPlayTimeScrollAnim(tid, onFinish)
  local curCoolDownTime = Logic.wishLogic:DummyGetCurCoolDownTime(tid)
  if 0 < curCoolDownTime then
    self:StopTimer(self.m_timer)
    local preCoolDownTime = curCoolDownTime + Logic.wishLogic:GetWishItemTime(tid)
    self:_ScrollTime(preCoolDownTime, curCoolDownTime, onFinish)
    self:_DummyShowItem(tid)
  else
    onFinish()
  end
end

function WishPage:_DummyUpdateWish(tid)
  self:_DummyShowMask(tid)
end

function WishPage:_DummyShowMask(tid)
  local widgets = self:GetWidgets()
  local hideMask = Logic.wishLogic:GetHideMask()
  local tog, countDownTime = Logic.wishLogic:DummyCheckCharge(tid)
  tog = tog and not hideMask
  widgets.obj_mask:SetActive(tog)
  if tog then
    self.m_time = Logic.wishLogic:DummyGetCurCoolDownTime(tid)
    UIHelper.SetText(widgets.tx_nexttime, time.getTimeStringFontDynamic(countDownTime, true))
    self:StopTimer(self.m_timer)
    self.m_timer = self:CreateTimer(function()
      self:_TickCharge(widgets.tx_nexttime)
    end, 1, -1, false)
    self:StartTimer(self.m_timer)
    self:_DummyShowItem(tid)
    self:_SetCoolDownState(WishCoolState.COOL)
    SoundManager.Instance:PlayMusic("System|Wish_closed")
  else
    SoundManager.Instance:PlayMusic("System|Wish_open")
    self:_OnLongPressSend(tid)
  end
end

function WishPage:_DummyShowItem(tid)
  if self.m_curPressItem then
    local num = Logic.wishLogic:DummyGetWishItemNum(tid)
    UIHelper.SetText(self.m_curPressItem.txt_num, "x" .. math.floor(num))
    local _, cur = Logic.wishLogic:DummyCheckWishItemNum(tid)
    local show, total = Logic.wishLogic:HaveNumLimit(tid)
    self.m_curPressItem.tx_limit.gameObject:SetActive(show)
    local ratiostr = string.format(UIHelper.GetString(951055), cur, total)
    UIHelper.SetText(self.m_curPressItem.tx_limit, ratiostr)
  end
end

function WishPage:_AutoAddFull()
  self:_ForceCloseAudio()
  wishLogic:SetPressLock(true)
  local ok, msg = Logic.wishLogic:AutoAddCommonAssert()
  if not ok then
    noticeManager:ShowTip(msg)
    return
  end
  UIHelper.OpenPage("WishACPage")
end

function WishPage:_AutoAddOneDay()
  self:_ForceCloseAudio()
  wishLogic:SetPressLock(true)
  local ok, msg = Logic.wishLogic:AutoAddCommonAssert()
  if not ok then
    noticeManager:ShowTip(msg)
    return
  end
  local time = Logic.wishLogic:GetAutoTimeConfig()
  UIHelper.OpenPage("WishACPage", time)
end

function WishPage:_ActivityHandler()
  self:_ActivityCheck()
end

function WishPage:_ActivityCheck()
  if self.m_atimer then
    self:StopTimer(self.m_atimer)
    self.m_atimer = nil
  end
  local state, time = Logic.wishLogic:GetActivityState()
  if state ~= WISH_ActivityState.DONE and 0 < time then
    self.m_atimer = self:CreateTimer(function()
      self:_UpdataWish()
    end, time, 1, true)
    self:StartTimer(self.m_atimer)
  end
end

function WishPage:_ForceCloseAudio()
  SoundManager.Instance:StopAudio("Effect_Eff_timedown")
end

function WishPage:DoOnHide()
end

function WishPage:DoOnClose()
  Logic.wishLogic:SetExpend(false)
  self:StopTimer(self.m_timer)
  self:TryStopTimer(self.m_pressTimer)
  self:TryStopTimer(self.m_atimer)
  self:_ForceCloseAudio()
end

return WishPage
