SettlementItem = class("UI.Settlement.SettlementItem")
local SettlementSkillItem = require("ui.page.Settlement.SettlementSkillItem")
local heroDev = Logic.developLogic

function SettlementItem:initialize(...)
end

function SettlementItem:Init(nIndex, data, tabPart, type)
  self.m_index = nIndex
  self:SetData(data)
  self:SetPart(tabPart)
  if type == SettlementItemType.HERO then
    if data.bSelf then
      self:SetWidgets()
    else
      self:SetEnemyWidgets()
    end
  end
  if type == SettlementItemType.DETIAL then
    self:SetDetailWidgets()
  end
end

function SettlementItem:SetWidgets()
  local widgets = self.m_part
  local txt_lv = widgets.txt_lv
  local txt_name = widgets.txt_name
  local img_status = widgets.img_status
  local sld_hp = widgets.sld_hp
  local data = self.m_data
  local heroLv = Mathf.ToInt(SettlementItem.VerifyHeroLv(data.oldLevel))
  txt_name.text = data.name
  txt_lv.text = heroLv
  ShipCardItem:LoadFightLeftCard(data.heroId, data.si_id, widgets.childpart)
  if data.status == HeroHpState.NONE then
    img_status.gameObject:SetActive(false)
  else
    img_status.gameObject:SetActive(true)
    UIHelper.SetImage(img_status, ShipBattleHpState[data.status])
  end
  sld_hp.value = data.hp / data.maxHp
  widgets.sld_add.value = data.hp / data.maxHp
  widgets.grayGroup.Gray = data.status == HeroHpState.JiChen
  local pskillInfo, nextPSkillItem
  local isHpBuf = false
  if data.PSkillList and #data.PSkillList > 0 then
    for i = #data.PSkillList, 1, -1 do
      pskillInfo = data.PSkillList[i]
      local id = Logic.shipLogic:GetPSkillDisplayIdByGroupId(pskillInfo.skillGroupDictId)
      local pskillData = {
        pskillId = id,
        ss_id = data.si_id,
        comp = SettlementComp.MY,
        showState = data.status ~= HeroHpState.NONE
      }
      isHpBuf = Logic.settlementLogic:GetSkillDisplayType(id) == 3
      if isHpBuf then
        local ok, from, to = self:hpBuffCheck(data.cacheHp, data.hp, data.maxHp)
        sld_hp.value = from
        if ok then
          pskillData.hpStart = from
          pskillData.hpEnd = to
        end
      end
      local pskillItem = SettlementSkillItem:new()
      pskillItem:Init(self.m_index, widgets, pskillData, nextPSkillItem)
      nextPSkillItem = pskillItem
      settlementSkillItemManager:AddItem(SettlementComp.MY, self.m_index, pskillItem)
    end
  end
end

function SettlementItem:hpBuffCheck(cacheHp, hp, maxHp)
  if maxHp <= 0 then
    return false
  end
  local before = cacheHp / maxHp
  local after = hp / maxHp
  before = Mathf.Clamp01(before)
  after = Mathf.Clamp01(after)
  return before < after, before, after
end

function SettlementItem:SetDetailWidgets()
  local widgets = self.m_part
  local obj_mvp = widgets.obj_mvp
  if obj_mvp == nil then
    return
  end
  local txt_lv = widgets.txt_lv
  local txt_name = widgets.txt_name
  local sld_hp = widgets.sld_hp
  local sld_damage = widgets.sld_damage
  local txt_addExp = widgets.txt_addExp
  local txt_nowExp = widgets.txt_nowExp
  local img_status = widgets.img_status
  local tx_addRatio = widgets.tx_addRatio
  local data = self.m_data
  local heroLv = Mathf.ToInt(SettlementItem.VerifyHeroLv(data.oldLevel))
  obj_mvp:SetActive(data.mvp)
  txt_lv.text = heroLv
  txt_name.text = data.name
  sld_hp.value = data.hp / data.maxHp
  local damRatio = 0
  if data.totalDamage and data.mvpDamage then
    damRatio = data.mvpDamage == 0 and 0 or data.totalDamage / data.mvpDamage
  end
  sld_damage.value = damRatio
  txt_addExp.text = math.ceil(data.addExp)
  local expRatio = data.oldExp / Logic.shipLogic:GetLvExp(data.oldLevel)
  expRatio = string.format("%.2f", expRatio * 100)
  UIHelper.SetText(txt_nowExp, expRatio .. "%")
  local addExpRatio = data.addExp / Logic.shipLogic:GetLvExp(data.oldLevel)
  addExpRatio = string.format("%.2f", addExpRatio * 100)
  UIHelper.SetText(tx_addRatio, addExpRatio)
  ShipCardItem:LoadFightLeftCard(data.heroId, data.si_id, widgets.childpart)
  if data.status == HeroHpState.NONE then
    img_status.gameObject:SetActive(false)
  else
    img_status.gameObject:SetActive(true)
    UIHelper.SetImage(img_status, ShipBattleHpState[data.status])
  end
  widgets.grayGroup.Gray = data.status == HeroHpState.JiChen
end

function SettlementItem:SetEnemyWidgets()
  local widgets = self.m_part
  local txt_name = widgets.txt_name
  local img_status = widgets.img_status
  local sld_hp = widgets.sld_hp
  local obj_notJoin = widgets.obj_notJoin
  local data = self.m_data
  txt_name.text = data.name
  ShipCardItem:LoadFightRightCard(data, widgets.childpart)
  if data.status == HeroHpState.NONE then
    img_status.gameObject:SetActive(false)
  else
    img_status.gameObject:SetActive(true)
    UIHelper.SetImage(img_status, ShipBattleHpState[data.status])
  end
  sld_hp.value = data.hp / data.maxHp
  widgets.sld_add.value = data.hp / data.maxHp
  if not IsNil(obj_notJoin) then
    obj_notJoin.gameObject:SetActive(not data.joinBattle)
  end
  widgets.grayGroup.Gray = data.status == HeroHpState.JiChen
  local pskillInfo, nextPSkillItem
  local isHpBuf = false
  if data.PSkillList and #data.PSkillList > 0 then
    for i = #data.PSkillList, 1, -1 do
      pskillInfo = data.PSkillList[i]
      local id = Logic.shipLogic:GetPSkillDisplayIdByGroupId(pskillInfo.skillGroupDictId)
      local pskillData = {
        pskillId = id,
        comp = SettlementComp.ENEMY
      }
      isHpBuf = Logic.settlementLogic:GetSkillDisplayType(id) == 3
      if isHpBuf then
        local ok, from, to = self:hpBuffCheck(data.cacheHp, data.hp, data.maxHp)
        if ok then
          pskillData.hpStart = from
          pskillData.hpEnd = to
        end
        sld_hp.value = from
      end
      local pskillItem = SettlementSkillItem:new()
      pskillItem:Init(self.m_index, widgets, pskillData, nextPSkillItem)
      nextPSkillItem = pskillItem
      settlementSkillItemManager:AddItem(SettlementComp.ENEMY, self.m_index, pskillItem)
    end
  end
end

function SettlementItem:SetData(data)
  self.m_data = data
end

function SettlementItem:SetPart(tabPart)
  self.m_part = tabPart
end

function SettlementItem:AnimBegin()
  local part = self.m_part
  if self.m_part then
  end
end

function SettlementItem:BeginExpAddTween()
  local widgets = self.m_part
  local data = self.m_data
  if data.addExp <= 0 then
    return
  end
  if widgets.obj_addRatio == nil then
    return
  end
  widgets.obj_addRatio:SetActive(true)
  local rect_lvUp = widgets.obj_addRatio:GetComponent(RectTransform.GetClassType())
  local tweenSequence = UISequence.NewSequence(widgets.obj_addRatio, true)
  tweenSequence:Append(rect_lvUp:TweenAnchorPosY(0, 45, 0.3))
  tweenSequence:AppendInterval(0.3)
  tweenSequence:AppendCallback(function()
    widgets.obj_addRatio:SetActive(false)
  end)
  tweenSequence:Play(true)
end

function SettlementItem:BeginExpSlider()
  local widgets = self.m_part
  local rect_lvUp = widgets.obj_levelUp:GetComponent(RectTransform.GetClassType())
  local txt_needExp = widgets.txt_needExp
  local txt_lv = widgets.txt_lv
  local obj_levelUp = widgets.obj_levelUp
  local data = self.m_data
  local curLv = data.oldLevel
  local originExp = data.oldExp
  local addExp = data.addExp
  local tInc = 1
  self.m_sequence = UISequence.NewSequence(widgets.gameObject, true)
  while 0 < addExp do
    local levelExp = Logic.shipLogic:GetLvExp(curLv)
    if levelExp == 0 then
      break
    end
    local needExp = levelExp - originExp
    local curLvExp = originExp
    local curAdd = addExp > needExp and needExp or addExp
    local curNeed = math.ceil(addExp > needExp and 0 or needExp - addExp)
    local value = (curLvExp + curAdd) / levelExp
    local t = curAdd / levelExp * tInc
    local txt_nowExp = widgets.txt_nowExp
    value = string.format("%.2f", value * 100)
    UIHelper.SetText(txt_nowExp, value .. "%")
    addExp = addExp - curAdd
    originExp = originExp + curAdd
    if curNeed == 0 then
      curLv = curLv + 1
      originExp = 0
    end
    if curNeed == 0 then
      local CreateCallback = function(level)
        local lv = level
        return function()
          txt_lv.text = Mathf.ToInt(lv)
          obj_levelUp:SetActive(true)
          rect_lvUp.anchoredPosition = Vector2.New(144, -15)
          if not IsNil(self.m_seqLevelUp) then
            self.m_seqLevelUp:Destroy()
          end
          self.m_seqLevelUp = UISequence.NewSequence(obj_levelUp, true)
          self.m_seqLevelUp:AppendCallback(function()
            SoundManager.Instance:PlayAudio("UI_Levelup")
          end)
          self.m_seqLevelUp:Append(rect_lvUp:TweenAnchorPosY(0, 0, 0.1))
          self.m_seqLevelUp:AppendInterval(0.5)
          self.m_seqLevelUp:AppendCallback(function()
            obj_levelUp:SetActive(false)
          end)
          self.m_seqLevelUp:Play(true)
        end
      end
      self.m_sequence:AppendCallback(CreateCallback(curLv))
      self.m_sequence:AppendInterval(0.1)
    end
  end
  self.m_sequence:Play(true)
end

function SettlementItem:BeginHpSlider(t)
  local widgets = self.m_part
  local sld = widgets.sld_hp
  local hp = self.m_data.hp
  local maxHp = self.m_data.maxHp
  sld:TweenValue(0, hp / maxHp, t or 1)
end

function SettlementItem:BeginDamageSlider()
  local widgets = self.m_part
  local sld = widgets.sld_damage
end

function SettlementItem.VerifyHeroLv(lv)
  local max = heroDev:GetHeroMaxLv()
  return Mathf.Min(lv, max)
end

function SettlementItem:DoOnClose()
end

return SettlementItem
