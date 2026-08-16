TimelineHelp = {}

function TimelineHelp.PlayTimeline(scene)
  local playTimeline = scene:GetComponent(PlayableDirector.GetClassType())
  playTimeline:Play()
end

function TimelineHelp.PauseTimeline(scene)
  local playTimeline = scene:GetComponent(PlayableDirector.GetClassType())
  playTimeline:Pause()
end

function TimelineHelp.Clear()
  TimelineHub:Clear()
end

function TimelineHelp.SetObj(obj)
  TimelineHub:SetObject(obj)
end

function TimelineHelp.SetShotIndex(index)
  TimelineHub:SetShotIndex(index)
end

function TimelineHelp.SetPathAndPlay(scene, path)
  logWarning(scene)
  logWarning(path)
  local playTimeline = scene:GetComponent(PlayableDirector.GetClassType())
  local asset = TimelineHub:SetPlayableAsset(playTimeline, path)
end
