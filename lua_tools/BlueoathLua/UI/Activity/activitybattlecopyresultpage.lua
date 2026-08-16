local ActivityBattleCopyResultPage = class("UI.Activity.ActivityBattleCopyResultPage", LuaUIPage)

function ActivityBattleCopyResultPage:DoInit()
end

function ActivityBattleCopyResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSkip, function()
    UIHelper.ClosePage(self:GetName())
    local callback = self.param.callback
    callback()
  end)
end

function ActivityBattleCopyResultPage:DoOnOpen()
  local param = self.param
  local result = {}
  for k, v in pairs(param.result) do
    result[v.Key] = v.Value
  end
  self.isActivityBoss = param.isActivityBoss or false
  if self.isActivityBoss then
    local curDamage = result.CurDamage
    local totalDamage = result.TotalDamage
    curDamage = curDamage or 0
    totalDamage = totalDamage or 0
    UIHelper.SetLocText(self.tab_Widgets.txt_curtitle, 4300017)
    UIHelper.SetLocText(self.tab_Widgets.txt_totaltitle, 4300018)
    self.tab_Widgets.txt_totalunit.gameObject:SetActive(false)
    self.tab_Widgets.txt_curunit.gameObject:SetActive(false)
    self.tab_Widgets.time1.gameObject:SetActive(false)
    UIHelper.SetText(self.tab_Widgets.textPassTimeReal, curDamage)
    UIHelper.SetText(self.tab_Widgets.textBestTime, totalDamage)
  else
    local passTimeReal = result.passTimeReal
    local passTime = result.passTime
    local punishTime = result.punishTime
    local passTimePerfect = result.passTimePerfect
    UIHelper.SetLocText(self.tab_Widgets.txt_curtitle, 910001722)
    UIHelper.SetLocText(self.tab_Widgets.txt_totaltitle, 910001726)
    self.tab_Widgets.txt_totalunit.gameObject:SetActive(true)
    self.tab_Widgets.txt_curunit.gameObject:SetActive(true)
    self.tab_Widgets.time1.gameObject:SetActive(true)
    UIHelper.SetText(self.tab_Widgets.textPassTimeReal, passTimeReal)
    UIHelper.SetText(self.tab_Widgets.textPassTime, passTime)
    UIHelper.SetText(self.tab_Widgets.textPunishTime, punishTime)
    UIHelper.SetText(self.tab_Widgets.textBestTime, passTimePerfect)
  end
end

return ActivityBattleCopyResultPage
