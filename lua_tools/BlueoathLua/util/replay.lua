local Replay = class("util.Replay")

function Replay:initialize()
  GDReplay.Init()
end

function Replay:IsSupport()
  return GDReplay.IsSupport()
end

function Replay:StartRecording(enableMicrophone, callback)
  local code = GDReplay.StartRecording(enableMicrophone)
  if callback then
    callback(code)
  end
end

function Replay:StopRecording()
  GDReplay.StopRecording()
end

function Replay:Preview()
  GDReplay.Preview()
end

function Replay:Discard()
  GDReplay.Discard()
end

return Replay
