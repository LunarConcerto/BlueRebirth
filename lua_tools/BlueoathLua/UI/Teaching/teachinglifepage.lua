local TeachingLifePage = class("UI.Teaching.TeachingLifePage", LuaUIPage)
local CommonItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TeachingLifePage:DoInit()
end

function TeachingLifePage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.TEACHING_GetPtReward, self._OnGetRewards, self)
end

function TeachingLifePage:DoOnOpen()
  self:_Refresh()
end

function TeachingLifePage:_Refresh()
  self:_ShowTeachCareerList()
  self:_ShowDetail()
end

function TeachingLifePage:_ShowTeachCareerList()
  local widgets = self:GetWidgets()
  local list = Logic.teachingLogic:GetShowTCareer()
  list = Logic.teachingLogic:SortTeacherCareer(list)
  local curLv = Logic.teachingLogic:GetTeachCareerLv()
  UIHelper.CreateSubPart(widgets.obj_career, widgets.trans_career, #list, function(index, luaPart)
    local info = list[index]
    UIHelper.SetText(luaPart.tx_level, "LV." .. info.level)
    UIHelper.SetText(luaPart.tx_name, info.name)
    UIHelper.SetText(luaPart.tx_detail, info.desc)
    local got = Logic.teachingLogic:HaveGetCareerReward(info.id)
    luaPart.obj_got:SetActive(got)
    local can = Logic.teachingLogic:CanGetCareerRewardById(info.id) and info.rewards > 0 and info.level <= curLv
    luaPart.btn_get.gameObject:SetActive(can)
    self:_SetRewards(luaPart, info.id)
    UGUIEventListener.AddButtonOnClick(luaPart.btn_get, self._OnClickGet, self, info.id)
    UGUIEventListener.AddButtonOnClick(luaPart.obj_career, self._OnClickCareerItem, self, {Index = index, Data = info})
  end)
end

function TeachingLifePage:_SetRewards(widgets, id)
  local rewards = Logic.teachingLogic:GetCareerReward(id)
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.trans_reward, #rewards, function(index, tabPart)
    local item = CommonItem:new()
    item:Init(index, rewards[index], tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self._ShowItemInfo, self, rewards[index])
  end)
end

function TeachingLifePage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function TeachingLifePage:_OnClickGet(go, id)
  if Logic.teachingLogic:CanGetCareerRewardById(id) then
    Service.taskService:SendGetPtReward(id)
  else
    logError("TEACHING FATAL:repeat get reward,id:", id)
  end
end

function TeachingLifePage:_OnClickCareerItem(go, param)
end

function TeachingLifePage:_OnGetRewards(rewards)
  Logic.rewardLogic:ShowCommonReward(rewards, "TeachingLifePage", nil)
  self:_Refresh()
end

function TeachingLifePage:_ShowDetail()
  self:_ShowTeachCareerDetail()
end

function TeachingLifePage:_ShowTeachCareerDetail()
  local curLv, curId = Logic.teachingLogic:GetTeachCareerLv()
  local info = Logic.teachingLogic:GetTeachingCareerConfigById(curId)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_level, "LV." .. curLv)
  UIHelper.SetText(widgets.tx_name, info.name)
  local nextId = Logic.teachingLogic:GetTeachingCareerConfigById(curId).next_id
  if nextId == -1 then
    sld_progress.value = 1
    UIHelper.SetText(widgets.tx_progress, "")
    UIHelper.SetText(widgets.tx_detail, "\229\183\178\232\190\190\229\136\176\230\156\128\229\164\167\231\173\137\231\186\167")
  else
    local delta = Logic.teachingLogic:GetSubNextLvPt(curLv + 1)
    local max = Logic.teachingLogic:GetSubLvPt(curLv, curLv + 1)
    local cur = max - delta
    UIHelper.SetText(widgets.tx_progress, cur .. "/" .. max)
    widgets.sld_progress.value = cur / max
    local name = Logic.teachingLogic:GetTeachingCareerConfigById(nextId).name
    UIHelper.SetText(widgets.tx_detail, string.format(UIHelper.GetString(2200029), delta, name))
  end
  local data = Data.teachingData:GetData()
  local show = Logic.teachingLogic:CanShowEva(data.AppraiseTimes)
  widgets.obj_score:SetActive(show)
  local score = data.Appraise or 0
  local showscore = score * 1.0E-4
  UIHelper.SetText(widgets.tx_score, showscore)
  local star, remain = Logic.teachingLogic:Score2Star(score)
  local max = Logic.teachingLogic:GetEvaStarMax()
  local fullScore = Logic.teachingLogic:GetFullStarConfig()
  UIHelper.CreateSubPart(widgets.obj_starbg, widgets.trans_starbg, max, function(index, tabParts)
  end)
  UIHelper.CreateSubPart(widgets.obj_starfg, widgets.trans_starfg, star, function(index, tabParts)
    tabParts.im_star.fillAmount = index == star and score < fullScore and remain or 1
  end)
end

function TeachingLifePage:DoOnHide()
end

function TeachingLifePage:DoOnClose()
end

return TeachingLifePage
