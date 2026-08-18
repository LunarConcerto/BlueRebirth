local ResidentGameLogic = class("logic.ResidentGameLogic")
local SchoolAccumeFace = {School = 1, Accume = 2}

function ResidentGameLogic:initialize()
  self:ResetData()
end

function ResidentGameLogic:ResetData()
  self.SchoolAccume = SchoolAccumeFace.School
end

function ResidentGameLogic:SetSAFace(param)
  self.SchoolAccume = param
end

function ResidentGameLogic:GetSAFace()
  return self.SchoolAccume
end

function ResidentGameLogic:CheckAutoRyzaHelp(uid)
  local temp = PlayerPrefs.GetBool("AutoOpenRyzaHelp" .. uid, false)
  return temp
end

function ResidentGameLogic:SetAutoRyzaHelp(uid)
  PlayerPrefs.SetBool("AutoOpenRyzaHelp" .. uid, true)
end

function ResidentGameLogic:CheckOpenPlotRecorded(nowPlotId, keyStr)
  local uid = Data.userData:GetUserUid()
  local recordId = PlayerPrefs.GetInt(keyStr .. uid, 0)
  if recordId ~= 0 and nowPlotId == recordId then
    return true
  end
  return false
end

function ResidentGameLogic:RecordOpenPlot(plotId, keyStr)
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetInt(keyStr .. uid, plotId)
end

return ResidentGameLogic
