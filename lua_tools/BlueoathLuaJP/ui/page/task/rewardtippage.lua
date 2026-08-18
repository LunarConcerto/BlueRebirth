local RewardTipPage = class("UI.Task.RewardTipPage", LuaUIPage)
local AwardShowNum = 5

function RewardTipPage:DoInit()
  self.topPositions = Logic.taskLogic:GetTopIconPos()
  self.currencyPos = {
    ["5"] = self.topPositions[1],
    ["1"] = self.topPositions[2],
    ["2"] = self.topPositions[3]
  }
  self.objList = {}
end

local width = 156
local center = 425
local localPos = {
  {
    Vector3.New(center, -28, 0)
  },
  {
    Vector3.New(center - width / 2, -28, 0),
    Vector3.New(center + width / 2, -28, 0)
  },
  {
    Vector3.New(center - width, -28, 0),
    Vector3.New(center, -28, 0),
    Vector3.New(center + width, -28, 0)
  },
  {
    Vector3.New(center - width / 2 * 3, -28, 0),
    Vector3.New(center - width / 2, -28, 0),
    Vector3.New(center + width / 2, -28, 0),
    Vector3.New(center + width / 2 * 3, -28, 0)
  },
  {
    Vector3.New(center - width * 2, -28, 0),
    Vector3.New(center - width, -28, 0),
    Vector3.New(center, -28, 0),
    Vector3.New(center + width, -28, 0),
    Vector3.New(center + width * 2, -28, 0)
  }
}

function RewardTipPage:DoOnOpen()
  self:RegisterEvent(LuaEvent.ShowRewardTaskEffect, self._ShowAnim)
end

function RewardTipPage:_ShowAnim(params)
  local rewards = params.rewards
  local config = params.config
  if table.empty(rewards) then
    if config then
      local cfgRewards = Logic.rewardLogic:FormatRewardById(config.rewards)
      local hasShip = Logic.rewardLogic:_CheckHeroInReward(cfgRewards)
      if hasShip then
        noticeManager:ShowTip(UIHelper.GetString(340017))
      else
        noticeManager:ShowTip(UIHelper.GetString(340016))
      end
    end
    return
  end
  local partObj, tabPart = self:_GetWidgets()
  local hasShip, siIdTab, heroIdTab = Logic.rewardLogic:_CheckHeroInReward(rewards)
  local hasItem = #siIdTab < #rewards
  local isFashion, ssIdTab, fashionIdTab = Logic.rewardLogic:_CheckFashionInReward(rewards)
  if hasShip then
    if hasItem then
      self:_ShowShipAnim(siIdTab, heroIdTab, function()
        local partObj, tabPart = self:_GetWidgets()
        self:_ShowTips(partObj, tabPart, rewards)
      end)
    else
      self:_ShowShipAnim(siIdTab, heroIdTab)
    end
  elseif isFashion then
    local param = {
      girlId = ssIdTab,
      showType = ShowGirlType.Fashion,
      fashionTab = fashionIdTab
    }
    UIHelper.OpenPage("ShowGirlPage", param)
  else
    self:_ShowTips(partObj, tabPart, rewards)
  end
end

function RewardTipPage:_ShowShipAnim(siIdTab, heroIdTab, callback)
  local param = {
    girlId = siIdTab,
    HeroId = heroIdTab,
    getWay = GetGirlWay.reward,
    callback = callback
  }
  UIHelper.OpenPage("ShowGirlPage", param)
end

function RewardTipPage:_GetWidgets()
  local widgets = self:GetWidgets()
  local trans = widgets.reward_tips:GetComponent(Transform.GetClassType())
  local partObj = UIHelper.CreateGameObject(widgets.reward_tips, trans.parent, false)
  local partComp = CSUIHelper.GetObjComponent(partObj, BabelTime.Lobby.UI.LuaPart.GetClassType())
  local tabPart = partComp:GetLuaTableParts()
  table.insert(self.objList, partObj)
  return partObj, tabPart
end

function RewardTipPage:_ShowTips(partObj, tabPart, taskInfo, onComplete)
  self.firstCreate = true
  local taskAward = taskInfo
  local showReplace, showReward = Logic.rewardLogic:MedalReplaceReward(taskAward)
  if showReplace and next(showReward) ~= nil then
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = showReward,
      Desc = UIHelper.GetString(7200074)
    })
  end
  local count = #taskAward > AwardShowNum and AwardShowNum or #taskAward
  local widgets = tabPart
  partObj.gameObject:SetActive(true)
  local bgTweenScale = UIHelper.GetTween(widgets.bg_tips, ETweenType.ETT_SCALE)
  widgets.bg_effect1:SetActive(true)
  local bgEffectTweenScale = UIHelper.GetTween(widgets.bg_effect1, ETweenType.ETT_SCALE)
  bgEffectTweenScale:ResetToInit()
  widgets.bg_animator:Update(0.4)
  local bgScaleDuration = 0.2
  bgTweenScale:ResetToInit()
  bgTweenScale.from = Vector3.New(0.5, 0.5, 0.5)
  bgTweenScale.to = Vector3.New(1, 1, 1)
  bgTweenScale.duration = bgScaleDuration
  bgTweenScale:Play(true)
  local rotateWaits = {
    0,
    0,
    0
  }
  local templateLuaPart = widgets.item_template:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
  self:PerformDelay(bgScaleDuration, function()
    SoundManager.Instance:PlayAudio("Effect_Eff_huodeziyuan_ban")
    UIHelper.CreateSubPart(widgets.item_template, widgets.item_list, count, function(nIndex, tabPart)
      local data = taskAward[nIndex]
      local num = data.Num
      local icon = Logic.goodsLogic:GetIcon(data.ConfigId, data.Type)
      UIHelper.SetImage(tabPart.icon_img, icon)
      UIHelper.SetText(tabPart.num_txt, "x" .. math.floor(num))
      local topPos = self.currencyPos[math.floor(data.ConfigId) .. ""]
      topPos = topPos or widgets.store_pos.position
      if nIndex == 1 then
        widgets.bg_effect1:SetActive(false)
        widgets.bg_effect2:SetActive(false)
      end
      tabPart.icon_img.enabled = true
      tabPart.num_obj:SetActive(false)
      tabPart.icon_obj:SetActive(false)
      tabPart.icon_explode:SetActive(false)
      tabPart.icon_light:SetActive(false)
      tabPart.icon_trans.localScale = Vector3.New(1, 1, 1)
      local scaleInterval = 0
      local scaleDuration = 0.3
      local iconScaleDelay = scaleInterval * (nIndex - 1)
      self:PerformDelay(iconScaleDelay, function()
        tabPart.icon_obj:SetActive(true)
        local iconScaleTween = tabPart.icon_scale
        iconScaleTween:ResetToInit()
        iconScaleTween.from = Vector3.New(5.3, 5.3, 5.3)
        iconScaleTween.to = Vector3.New(1, 1, 1)
        iconScaleTween.duration = scaleDuration
        iconScaleTween:Play(true)
        local iconAlphaTween = tabPart.icon_alpha
        iconAlphaTween:ResetToInit()
        iconAlphaTween.from = 0.5
        iconAlphaTween.to = 1
        iconAlphaTween.duration = scaleDuration
        iconAlphaTween:Play(true)
      end)
      self:PerformDelay(iconScaleDelay + scaleDuration, function()
        tabPart.icon_light:SetActive(true)
        SoundManager.Instance:PlayAudio("Effect_Eff_huodeziyuan_one")
      end)
      self:PerformDelay(iconScaleDelay + 0.2, function()
        tabPart.num_obj:SetActive(true)
      end)
      local rotateWait = 0.3
      local posInterval = 0.2
      local posDuration = 0.4
      local posDelay = scaleDuration + (count - 1) * scaleInterval + posInterval * (nIndex - 1) + rotateWait
      local toPos
      if self.firstCreate then
        local oldPos = templateLuaPart.item_trans.parent.anchoredPosition3D
        templateLuaPart.item_trans.parent.anchoredPosition3D = localPos[count][nIndex]
        templateLuaPart.item_trans.anchoredPosition3D = Vector3.zero
        toPos = templateLuaPart.item_trans:InverseTransformPoint(topPos)
        templateLuaPart.item_trans.parent.anchoredPosition3D = oldPos
      else
        toPos = tabPart.item_trans:InverseTransformPoint(topPos)
      end
      local initPos = tabPart.icon_trans.anchoredPosition3D
      self:PerformDelay(posDelay, function()
        tabPart.icon_tail:SetActive(true)
        local iconPosTween = tabPart.icon_pos
        iconPosTween:ResetToInit()
        iconPosTween.from = initPos
        iconPosTween.to = toPos
        iconPosTween.duration = posDuration
        iconPosTween:Play(true)
      end)
      self:PerformDelay(posDelay + 0.1, function()
        tabPart.num_obj:SetActive(false)
      end)
      local posTime = posDelay + posDuration
      self:PerformDelay(posTime * 0.9, function()
        tabPart.icon_img.enabled = false
      end)
      local explodeDelay = posTime
      self:PerformDelay(explodeDelay, function()
        SoundManager.Instance:PlayAudio("Effect_Eff_huodeziyuan_flash")
        tabPart.icon_explode:SetActive(true)
      end)
      local animFinishDelay = scaleDuration + scaleInterval * (count - 1) + posDuration + (count - 1) * posInterval + rotateWait + 0.5
      self:PerformDelay(animFinishDelay, function()
        tabPart.icon_trans.anchoredPosition3D = initPos
      end)
      local bgOffDelay = scaleDuration + scaleInterval * (count - 1) + (count - 1) * posInterval + rotateWait
      if nIndex == 1 then
        widgets.bg_effect1:SetActive(true)
        local starDelay = scaleDuration + scaleInterval * (count - 1)
        self:PerformDelay(starDelay, function()
          widgets.bg_effect2:SetActive(true)
        end)
        self:PerformDelay(bgOffDelay, function()
          local bgTweenAlpha = UIHelper.GetTween(widgets.bg_tips, ETweenType.ETT_ALPHA)
          bgTweenAlpha:ResetToInit()
          bgTweenAlpha.from = 1
          bgTweenAlpha.to = 0
          bgTweenAlpha.duration = bgScaleDuration
          bgTweenAlpha:Play(true)
          local bgTweenPos = UIHelper.GetTween(widgets.bg_tips, ETweenType.ETT_POSITION)
          bgTweenPos:ResetToInit()
          bgTweenPos.from = Vector3.zero
          bgTweenPos.to = Vector3.New(0, 100, 0)
          bgTweenPos.duration = bgScaleDuration
          bgTweenPos:Play(true)
          bgTweenScale:ResetToInit()
          bgTweenScale.from = Vector3.New(1, 1, 1)
          bgTweenScale.to = Vector3.New(0.5, 0.5, 0.5)
          bgTweenScale.duration = bgScaleDuration
          bgTweenScale:Play(true)
          self.firstCreate = false
          bgEffectTweenScale:ResetToInit()
          bgEffectTweenScale.from = Vector3.one
          bgEffectTweenScale.to = Vector3.zero
          bgEffectTweenScale.duration = bgScaleDuration
          bgEffectTweenScale:Play(true)
        end)
      end
      if nIndex == count then
        self:PerformDelay(animFinishDelay, function()
          for i, obj in ipairs(self.objList) do
            if obj == partObj then
              table.remove(self.objList, i)
              break
            end
          end
          GameObject.Destroy(partObj)
          if onComplete then
            onComplete()
          end
        end)
      end
    end)
  end)
end

function RewardTipPage:_ClearObjects()
  for i, obj in ipairs(self.objList) do
    GameObject.Destroy(obj)
  end
  self.objList = {}
end

function RewardTipPage:DoOnHide()
  self:_ClearObjects()
end

function RewardTipPage:DoOnClose()
  self:_ClearObjects()
end

return RewardTipPage
