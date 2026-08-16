local DisableSkill = class("game.Guide.guidebehaviours.DisableSkill", GR.requires.BehaviourBase)

function DisableSkill:doBehaviour()
  local nType = self.objParam
  local strPath = SkillTypeToUIPath[nType]
  local tblParam = {}
  tblParam.targetPath = strPath
  tblParam.bShow = false
  local bShowMainGun = nType == 1
  tblParam.bShowMainGun = bShowMainGun
  if bShowMainGun then
    tblParam.mainGunUIStatePath = "BattleOpeGroup/MainGunUIState"
  end
  GR.guideHub:doCSharpInstrument(BEHAVIOUR_INSTRUMENT_TYPE.ShowSkillBtn, tblParam)
  self:onDone()
end

return DisableSkill
