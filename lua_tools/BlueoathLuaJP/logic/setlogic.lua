local SetLogic = class("logic.SetLogic")

function SetLogic:initialize()
  self:ResetData()
end

function SetLogic:ResetData()
  self.sortParamTab = {}
  self.tabQuickChallenge = {}
  self.mapSettingAfter = {}
  self.ptype = nil
  self.param = nil
end

function SetLogic:_getBattleConfigById(id)
  return configManager.GetDataById("config_battle_config", id)
end

function SetLogic:GetSetControlScaleDown()
  return self:_getBattleConfigById(201).data
end

function SetLogic:SetSetControlScaleUp()
  return self:_getBattleConfigById(202).data
end

function SetLogic:GetContrilScalePrecent(value)
  return string.format("%.0f", value * 100) .. "%"
end

function SetLogic:GenSetCondition(copyId, startLevel)
  local isStart = {
    [SetConditionEnum.SkipMySkillAnim] = moduleManager:CheckFunc(FunctionID.SkipPlayerSkipSkillAnim, false),
    [SetConditionEnum.SkipEnemySkillAnim] = moduleManager:CheckFunc(FunctionID.SkipEnemySkipSkillAnim, false),
    [SetConditionEnum.SkipShipSkillFeedBack] = moduleManager:CheckFunc(FunctionID.SkipShipSkillFeedBack, false),
    [SetConditionEnum.CopyAutoAttack] = false
  }
  local isSetStart = {
    [SetConditionEnum.SkipMySkillAnim] = {
      moduleManager:CheckFunc(FunctionID.SkipPlayerSkipSkillAnim, false),
      0
    },
    [SetConditionEnum.SkipEnemySkillAnim] = {
      moduleManager:CheckFunc(FunctionID.SkipEnemySkipSkillAnim, false),
      0
    },
    [SetConditionEnum.SkipShipSkillFeedBack] = {
      moduleManager:CheckFunc(FunctionID.SkipShipSkillFeedBack, false),
      0
    },
    [SetConditionEnum.CopyAutoAttack] = {false, 0}
  }
  local m_displayConfig = Logic.copyLogic:GetCopyDesConfig(copyId)
  local m_safeStageId = m_displayConfig.stageid
  if m_safeStageId ~= 0 and m_displayConfig.auto_continuation == 0 then
    local copyData = configManager.GetDataById("config_stage", m_safeStageId)
    if copyData then
      local safeEffect = {}
      local safeNoEffect = {}
      for v, k in pairs(copyData.safe_effect) do
        for index, key in pairs(k) do
          if v <= startLevel then
            local tabSafeInfo = {
              key,
              v,
              true
            }
            table.insert(safeEffect, tabSafeInfo)
          elseif startLevel < v and v <= #copyData.safe_effect then
            local tabNoSafeInfo = {
              key,
              v,
              false
            }
            table.insert(safeEffect, tabNoSafeInfo)
          end
        end
      end
      local skill = {}
      local safeAreaInfo = configManager.GetData("config_safearea_effect")
      for v, k in pairs(safeEffect) do
        for index, key in pairs(safeAreaInfo) do
          if k[1] == key.id and key.p2 ~= 0 and key.type == 2 then
            local tabSkill = {
              key.p2,
              k[2],
              k[3]
            }
            table.insert(skill, tabSkill)
          end
        end
      end
      for v, k in pairs(skill) do
        if k[1] == SetConditionEnum.CopyAutoAttack and k[3] and k[2] ~= 0 then
          isStart[k[1]] = true
        end
      end
      for v, k in pairs(skill) do
        if k[1] == SetConditionEnum.CopyAutoAttack and isSetStart[SetConditionEnum.CopyAutoAttack][2] == 0 then
          isSetStart[k[1]] = {
            k[3],
            k[2],
            startLevel
          }
        end
      end
    end
  elseif m_displayConfig.auto_continuation == 1 then
    isStart[SetConditionEnum.CopyAutoAttack] = true
    isSetStart[SetConditionEnum.CopyAutoAttack] = {true, -1}
  end
  return isStart, isSetStart
end

function SetLogic:SetQuickChallenge(tabQuickChallenge)
  self.tabQuickChallenge = tabQuickChallenge
end

function SetLogic:GetQuickChallenge()
  return self.tabQuickChallenge
end

function SetLogic:SetBathAnimOption(value)
  local index = value and 1 or 0
  local key = Logic.bathroomLogic:GetBathAnimKey()
  PlayerPrefs.SetInt(key, index)
end

function SetLogic:GetBathAnimOption()
  local key = Logic.bathroomLogic:GetBathAnimKey()
  return PlayerPrefs.GetInt(key, 0)
end

function SetLogic:SetSettingAfter(mapSettingAfter)
  self.mapSettingAfter = mapSettingAfter
end

function SetLogic:GetSettingAfter()
  return self.mapSettingAfter
end

function SetLogic:NilSetting(ptype, param)
  self.ptype = ptype
  self.param = param
end

function SetLogic:_UnregisterBattle()
  if self.ptype == nil then
    return
  end
  if self.ptype == PlotTriggerType.fleetbattle_before_cg then
    plotManager:DisPlatSetting(PlotTriggerType.fleetbattle_before_count, self.param)
  end
end

return SetLogic
