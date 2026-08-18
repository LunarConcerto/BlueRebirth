local SportBattleResultPage = class("UI.Sport.SportBattleResultPage", LuaUIPage)
local config = {
  [720101] = {sport_type = 1},
  [720102] = {sport_type = 2},
  [720103] = {sport_type = 3},
  [720201] = {sport_type = 1},
  [720202] = {sport_type = 2},
  [720203] = {sport_type = 3}
}
local scoreType = {
  [1] = "PassTime",
  [2] = "LostHp",
  [3] = "Damage"
}

function SportBattleResultPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function SportBattleResultPage:DoOnOpen()
  self.param = self:GetParam()
  self.copyId = self.param.CopyId
  self.sport_type = config[self.copyId].sport_type
  self:LoadConfigData()
end

function SportBattleResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_skip, function()
    UIHelper.ClosePage("SportBattleResultPage")
    if self.param.Page == "SettlementLogic" then
      Logic.settlementLogic.m_flowCtrl(Logic.settlementLogic.Input.Next)
    end
  end, self)
end

local indexTxt = {
  [1] = {
    dex = "txt_damageDes",
    value = "txt_damageScore"
  },
  [2] = {
    dex = "txt_unkillDes",
    value = "txt_unkillScore"
  },
  [3] = {
    dex = "txt_hpDes",
    value = "txt_hpScore"
  }
}

function SportBattleResultPage:LoadConfigData()
  local data = configManager.GetMultiDataByKey("config_sportsmeet_score", "sport_type", self.sport_type)
  local orderData = {}
  local totalScore = 0
  for k, v in pairs(data) do
    table.insert(orderData, v)
  end
  table.sort(orderData, function(l, r)
    if l.if_rank == r.if_rank then
      return l.id < r.id
    end
    return l.if_rank > r.if_rank
  end)
  self.m_tabWidgets.obj_newPoint:SetActive(self.param.Best == true)
  local configIndex = 0
  for k, v in pairs(orderData) do
    local type = v.score_type
    local if_rank = v.if_rank
    if if_rank == 1 then
      UIHelper.SetText(self.m_tabWidgets.txt_totalScore, self.param[scoreType[type]])
      if 0 > self.param.Score then
        totalScore = 0
      else
        totalScore = self.param.Score
      end
      UIHelper.SetText(self.m_tabWidgets.txt_totalPt, totalScore)
      UIHelper.SetText(self.m_tabWidgets.txt_title, v.desc[1][1])
    else
      configIndex = configIndex + 1
      local value = self.param[scoreType[type]]
      local index = 1
      local score = 0
      for i = 1, #v.score do
        local scoreArr = v.score[i]
        if value >= scoreArr[1] and value <= scoreArr[2] then
          index = i
          score = scoreArr[3]
          break
        end
      end
      local des = v.desc[index][1]
      UIHelper.SetText(self.m_tabWidgets[indexTxt[configIndex].dex], des)
      if 0 > self.param.Score then
        score = 0
      end
      UIHelper.SetText(self.m_tabWidgets[indexTxt[configIndex].value], score)
    end
  end
end

return SportBattleResultPage
