local CrusadeSuccessPage = class("UI.Crusade.CrusadeSuccessPage", LuaUIPage)
local heroDev = Logic.developLogic

function CrusadeSuccessPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_tweencount = 0
end

function CrusadeSuccessPage:DoOnOpen()
  self.param = self:GetParam()
  self:_SetResult(self.param)
  self:_RegisterExe()
  if self.param.result ~= SupportResult.Failure then
    local expMap = {}
    if self.param.heroAddExp then
      expMap = self.param.heroAddExp
    else
      expMap = self:_formatRewards()
    end
    self:_LoadFleet(self.param.fleets, expMap)
    self:_TryAutoExe()
  end
  if self.param.userAddExp then
    self:_SetUser()
  end
end

function CrusadeSuccessPage:_TryAutoExe()
  local timer = self:CreateTimer(function(...)
    if self.param.isAuto then
      settlementExeManager:AutoExecute()
    end
  end, self.m_tweencount, 1, false)
  self:StartTimer(timer)
end

function CrusadeSuccessPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.im_bg, self._Next, self)
end

function CrusadeSuccessPage:_RegisterExe()
  if self.param.supportId then
    return
  end
  Logic.settlementLogic:InitFastFlowCtrl(self.param)
  if self.param.isAuto then
    settlementExeManager:AutoExecute()
  end
end

function CrusadeSuccessPage:_SetResult(param)
  local widgets = self:GetWidgets()
  if param.supportId then
    widgets.obj_success:SetActive(param.result == SupportResult.Success)
    widgets.obj_bigsuccess:SetActive(param.result == SupportResult.SuperSuccess)
    widgets.obj_loss:SetActive(param.result == SupportResult.Failure)
    widgets.obj_lossTxt:SetActive(param.result == SupportResult.Failure)
  else
    widgets.obj_fastsuccess:SetActive(true)
  end
end

function CrusadeSuccessPage:_SetUser()
  local widgets = self:GetWidgets()
  widgets.obj_user:SetActive(self.param.userAddExp)
  local usrName = Data.userData:GetUserName()
  local usrLv = Data.userData:GetUserLevel()
  local usrExp = Data.userData:GetUserExp()
  local preLvExp = Logic.userLogic:GetMaxExp(usrLv - 1)
  local needExp = Logic.userLogic:GetLvExp(usrLv)
  UIHelper.SetText(widgets.tx_name, usrName)
  UIHelper.SetText(widgets.tx_lv, math.tointeger(usrLv))
  UIHelper.SetText(widgets.tx_addExp, "EXP+" .. self.param.userAddExp)
  widgets.sld_add.value = (usrExp - preLvExp) / needExp
end

function CrusadeSuccessPage:_formatRewards()
  local addExp = 0
  local otherRewards = {}
  for index, item in pairs(self.param.rewards) do
    if item.ConfigId == CurrencyType.ShipExp and item.Type == GoodsType.CURRENCY then
      addExp = addExp + math.tointeger(item.Num)
    else
      table.insert(otherRewards, item)
    end
  end
  self.param.rewards = otherRewards
  local expMap = {}
  if addExp == 0 then
    return {}
  else
    for _, v in ipairs(self.param.fleets) do
      expMap[v] = addExp
    end
  end
  return expMap
end

function CrusadeSuccessPage:_LoadFleet(heroIds, expMap)
  local widgets = self.m_tabWidgets
  local uiTweenDuration = Logic.assistNewLogic:GetFinishTweenTime()
  local seq = UISequence.NewSequence(widgets.trans_shipPrt.gameObject)
  local alphaSeq = UISequence.NewSequence(widgets.trans_shipPrt.gameObject)
  local e_state = Logic.developLogic.E_HeroLvState
  UIHelper.CreateSubPart(widgets.obj_ship, widgets.trans_shipPrt, #heroIds, function(index, tabPart)
    local tabHero = Data.heroData:GetHeroById(heroIds[index])
    local addExp = expMap[heroIds[index]] or 0
    local state = Logic.developLogic:GetLHeroState(heroIds[index])
    if state ~= e_state.LEVELUP then
      addExp = 0
    end
    local preLv = Logic.shipLogic:GetPreLv(tabHero.Exp, addExp, tabHero.Lvl)
    local maxLv = heroDev:GetHeroMaxLv()
    if maxLv > tabHero.Lvl then
      UIHelper.SetText(tabPart.tx_addExp, "EXP+" .. addExp)
      UIHelper.SetText(tabPart.tx_lv, preLv)
      tabPart.sld_exp.value = self:_GetFrom(tabHero.Lvl, tabHero.Exp, addExp)
    else
      self:_MaxLvShow(tabPart)
    end
    ShipCardItem:LoadVerticalCard(heroIds[index], tabPart.card)
    for i = 1, tabHero.Advance do
      local stri = tostring(i)
      tabPart[stri]:SetActive(true)
    end
    local twn = tabPart.trans_ship:TweenAnchorPosY(-160, -420, uiTweenDuration)
    twn.playForwardAudio = true
    seq:Append(twn)
    self:_TimerCount(uiTweenDuration)
    seq:AppendCallback(function()
      if tabHero.Lvl < maxLv then
        self:_PlayExpTween(tabPart, tabHero.Lvl, tabHero.Exp, addExp)
      end
    end)
    alphaSeq:Append(tabPart.trans_ship:TweenCanvasAlpha(0, 1, uiTweenDuration))
  end)
  self.m_frame = FrameTimer.New(function()
    widgets.hlg_shipbase.enabled = false
    if not IsNil(seq) and not IsNil(alphaSeq) then
      seq:Play(true)
      alphaSeq:Play(true)
    else
      logError("try play null uisequence in fast settlement !!!")
    end
  end, 1, 1)
  self.m_frame:Start()
end

function CrusadeSuccessPage:_GetFrom(curLv, curExp, addExp)
  local preLv = Logic.shipLogic:GetPreLv(curExp, addExp, curLv)
  local preExp = curExp - addExp
  local needExp
  if curLv == preLv then
    needExp = Logic.shipLogic:GetLvExp(curLv)
    return preExp / needExp
  end
  needExp = Logic.shipLogic:GetLvExp(preLv)
  local temp = self:_GetNeedExp(preLv, curLv - 1)
  return (temp + preExp) / needExp
end

function CrusadeSuccessPage:_TimerCount(number)
  self.m_tweencount = self.m_tweencount + number
end

function CrusadeSuccessPage:_MaxLvShow(widgets)
  UIHelper.SetText(widgets.tx_addExp, "\229\183\178\230\187\161\231\186\167")
  widgets.sld_exp.value = 1
  local maxLv = heroDev:GetHeroMaxLv()
  UIHelper.SetText(widgets.tx_lv, maxLv)
end

function CrusadeSuccessPage:_PlayExpTween(widgets, currentLv, currentExp, addExp)
  local preLv = Logic.shipLogic:GetPreLv(currentExp, addExp, currentLv)
  local preExp = currentExp - addExp
  if currentLv < preLv then
    logError("Crusade Module:preLv greater then currentLv fatel,Please check CrusadeSuccessPage's _GetPreLv method")
  end
  if currentLv == preLv then
    local needExp = Logic.shipLogic:GetLvExp(currentLv)
    local from = preExp / needExp
    local to = currentExp / needExp
    local sliderTween = self:_CreateSliderTween(widgets.slider, 1, from, to)
    sliderTween:Play(true)
    return
  end
  local addLv = currentLv - preLv
  for i = 0, addLv do
    if i == 0 then
      local needExp = Logic.shipLogic:GetLvExp(preLv)
      local temp = self:_GetNeedExp(preLv, currentLv - 1)
      local from = (temp + preExp) / needExp
      local sliderTween = self:_CreateFromTween(widgets.slider, from)
      widgets.ui_equence:Append(sliderTween)
      widgets.ui_equence:AppendCallback(function()
        self:_PlayLvUpTween(widgets.obj_lvup, widgets.trans_lvprt, widgets.tx_lv, preLv + 1)
      end)
    elseif i == addLv then
      local needExp = Logic.shipLogic:GetLvExp(currentLv)
      local to = currentExp / needExp
      local sliderTween = self:_CreateToTween(widgets.slider, to)
      widgets.ui_equence:Append(sliderTween)
    else
      local sliderTween = self:_CreateNormalTween(widgets.slider)
      widgets.ui_equence:Append(sliderTween)
      widgets.ui_equence:AppendCallback(function()
        self:_PlayLvUpTween(widgets.obj_lvup, widgets.trans_lvprt, widgets.tx_lv, preLv + i + 1)
      end)
    end
  end
  widgets.ui_equence:Play(true)
end

function CrusadeSuccessPage:_GetNeedExp(lv1, lv2)
  local res = 0
  for i = lv1, lv2 do
    res = res + Logic.shipLogic:GetLvExp(i)
  end
  return res
end

function CrusadeSuccessPage:_PlayLvUpTween(go, trans, txt, lv)
  local objAddLv = GameObject.Instantiate(go, trans)
  objAddLv:SetActive(true)
  local m_tweenPosition = UIHelper.GetTween(objAddLv, ETweenType.ETT_POSITION)
  m_tweenPosition:Play(true)
  GameObject.Destroy(objAddLv, 1)
  self:_UpdataLv(txt, lv)
end

function CrusadeSuccessPage:_UpdataLv(txt, lv)
  UIHelper.SetText(txt, lv)
end

function CrusadeSuccessPage:_CreateFromTween(go, from)
  return self:_CreateSliderTween(go, 1, from, 1)
end

function CrusadeSuccessPage:_CreateToTween(go, to)
  return self:_CreateSliderTween(go, 1, 0, to)
end

function CrusadeSuccessPage:_CreateNormalTween(go)
  return self:_CreateSliderTween(go, 1, 0, 1)
end

function CrusadeSuccessPage:_CreateSliderTween(go, duration, from, to)
  local tweenSlider = TweenSlider.Add(go, duration, from, to)
  self:_TimerCount(duration)
  return tweenSlider
end

function CrusadeSuccessPage:_Next()
  if self.param.supportId then
    UIHelper.ClosePage("CrusadeSuccessPage")
    self:_LoadRewards()
  else
    Logic.settlementLogic:Execute(Logic.settlementLogic.State.Reward)
  end
end

function CrusadeSuccessPage:_LoadRewards()
  if self.param.result ~= SupportResult.Failure and #self.param.rewards > 0 then
    local param = {
      Rewards = self.param.rewards,
      callBack = function()
        local sm_id, heroId = Logic.settlementLogic.GetNeedShowGirl(self.param.rewards)
        local show = Logic.settlementLogic:CheckShowShip(sm_id)
        if sm_id and show then
          local si_id = Logic.shipLogic:GetShipInfoId(sm_id)
          eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, false)
          UIHelper.OpenPage("ShowGirlPage", {
            girlId = si_id,
            HeroId = heroId,
            getWay = GetGirlWay.battle,
            callback = function()
              eventManager:FireEventToCSharp(LuaCSharpEvent.SettlementTurnOnOffCamera, true)
              self:SupportAgain()
            end
          })
        else
          self:SupportAgain()
        end
      end
    }
    UIHelper.OpenPage("GetRewardsPage", param)
  end
end

function CrusadeSuccessPage:SupportAgain()
  if self.param.supportId == nil then
    return
  end
  local id = Logic.assistNewLogic:GetBestSameGroupSupporter(self.param.supportId)
  if 0 < id then
    local name = Logic.assistNewLogic:GetName(id)
    local str = string.format(UIHelper.GetString(971038), name)
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:SupportAgainImpl(id)
        else
          eventManager:SendEvent(LuaEvent.UpdateAssistList, nil)
        end
      end
    }
    noticeManager:ShowMsgBox(str, tabParams)
  end
end

function CrusadeSuccessPage:SupportAgainImpl(supportId)
  local assist = Logic.assistNewLogic.GenAssistTemplate()
  assist.SupportId = supportId
  assist.HeroList = self.param.fleets
  local index = Logic.assistNewLogic:GetFirstEmptySlot()
  if index <= 0 then
    logError("\230\151\160\231\169\186\228\189\153\230\167\189\228\189\141,\233\128\187\232\190\145\228\184\138\232\175\180\228\184\141\233\128\154,\229\177\158\228\186\142\232\135\180\229\145\189bug")
    eventManager:SendEvent(LuaEvent.UpdateAssistList, nil)
    return
  end
  Logic.assistNewLogic:SetCurIndex(index)
  local data = Logic.assistNewLogic:SetAssistByIndex(index, assist)
  eventManager:SendEvent(LuaEvent.SupportAgain, data)
end

function CrusadeSuccessPage:DoOnHide()
end

function CrusadeSuccessPage:DoOnClose()
  if not self.param.supportId or not (Logic.assistNewLogic:GetBestSameGroupSupporter(self.param.supportId) > 0) then
    eventManager:SendEvent(LuaEvent.UpdateAssistList, nil)
  end
  if self.m_frame then
    self.m_frame:Stop()
    self.m_frame = nil
  end
end

return CrusadeSuccessPage
