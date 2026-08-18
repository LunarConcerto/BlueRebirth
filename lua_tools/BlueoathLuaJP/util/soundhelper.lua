SoundHelper = {}
local soundSetData
local TAB_SFX = {"sfx01_bank", "sfx02_bank"}

function SoundHelper.SetSoundData(data)
  soundSetData = data
  PlayerPrefs.SetFloat("bgm_volume", data.bgm)
  PlayerPrefs.SetFloat("audio_volume", data.audio)
  PlayerPrefs.SetFloat("cv_volume", data.cv)
end

function SoundHelper.SetSoundByKey(key, value)
  if soundSetData[key] then
    soundSetData[key] = value
  end
end

function SoundHelper.GetSoundData()
  if soundSetData == nil then
    local data = {}
    data.bgm = PlayerPrefs.GetFloat("bgm_volume", 100)
    data.audio = PlayerPrefs.GetFloat("audio_volume", 100)
    data.cv = PlayerPrefs.GetFloat("cv_volume", 100)
    soundSetData = data
  end
  return soundSetData
end

function SoundHelper.SetSound()
  local data = SoundHelper.GetSoundData()
  SoundManager.Instance:SetBGMVolume(data.bgm)
  SoundManager.Instance:SetAudioVolume(data.audio)
  SoundManager.Instance:SetCVVolume(data.cv)
  if data.audio == 0 then
    SoundManager.Instance:PlayAudio("SFX_Mute")
  else
    SoundManager.Instance:PlayAudio("SFX_Unmute")
  end
  if data.cv == 0 then
    SoundManager.Instance:PlayAudio("CV_Mute")
  else
    SoundManager.Instance:PlayAudio("CV_Unmute")
  end
end

function SoundHelper.LoadSFX()
  for i = 1, #TAB_SFX do
    SoundManager.Instance:PreLoad(TAB_SFX[i])
  end
end

function SoundHelper.UnloadSFX()
  for i = 1, #TAB_SFX do
    SoundManager.Instance:UnLoad(TAB_SFX[i])
  end
end
