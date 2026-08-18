local GoodsCopyResultPage = class("UI.GoodsCopy.GoodsCopyResultPage", LuaUIPage)

function GoodsCopyResultPage:DoInit()
end

function GoodsCopyResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_skip, self._OnBtnSkip, self)
end

function GoodsCopyResultPage:DoOnOpen()
  local param = self.param
  local result = {}
  for k, v in pairs(param.result) do
    result[v.Key] = v.Value
  end
  local rankPercent = result.RankPercent
  if rankPercent == -1 then
    self.tab_Widgets.pointer.gameObject:SetActive(false)
  else
    UIHelper.SetText(self.tab_Widgets.txt_percent, string.format("%.2f%%", result.RankPercent / 100))
    self:SetArrowPos(result.RankPercent)
  end
  local copyId = result.CopyId
  local copyBattleCfg = configManager.GetDataById("config_goods_battle", copyId)
  UIHelper.SetText(self.tab_Widgets.txt_damage, result.CurDamage)
  UIHelper.SetLocText(self.tab_Widgets.txt_max_damage, 7200016, copyBattleCfg.name)
  UIHelper.SetText(self.tab_Widgets.txt_curdamage, result.CurCopyMaxDamage)
  UIHelper.SetLocText(self.tab_Widgets.txt_allcopy, 7200017)
  UIHelper.SetText(self.tab_Widgets.txt_totaldamage, result.MaxDamage)
  local monthCardBonus = result.MonthCardBonus
  UIHelper.SetText(self.tab_Widgets.txt_reward, math.floor(result.CurReward))
  self.tab_Widgets.txt_month.gameObject:SetActive(monthCardBonus ~= nil)
  if monthCardBonus then
    UIHelper.SetLocText(self.tab_Widgets.txt_month, 520001, math.floor(monthCardBonus))
  end
  UIHelper.SetText(self.tab_Widgets.txt_total_reward, math.floor(result.TotalReward))
end

function GoodsCopyResultPage:SetArrowPos(percent)
  local leftX = self.tab_Widgets.trans_left.position.x
  local rightX = self.tab_Widgets.trans_right.position.x
  local arrowX = (10000 - percent) / 10000.0 * (rightX - leftX) + leftX
  local oldPos = self.tab_Widgets.pointer.position
  self.tab_Widgets.pointer.position = Vector3.New(arrowX, oldPos.y, oldPos.z)
end

function GoodsCopyResultPage:_OnBtnSkip()
  UIHelper.ClosePage(self:GetName())
  local callback = self.param.callback
  callback()
end

return GoodsCopyResultPage
