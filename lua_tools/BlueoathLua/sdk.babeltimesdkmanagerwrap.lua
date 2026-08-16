local m = {}

function m.Init(cb)
end

function m.TickLoop()
end

function m.GetGameVersion(packageVersion, scriptVersion, OnError, OnWholePackageUpdate, OnPatchUpdate)
end

function m.Retention(eventID, uId, defineKV)
end

function m.RetentionForLua(eventID, uId, kvstring)
end

function m.IsSimulator()
end

function m.GetPatchVersion()
end

function m.GetSensorInfo()
end

function m.GetStrDeviceInfo()
end

function m.GetDangerWidth()
end

function m.GetDeviceFeatureInfo()
end

function m.SendLog(luaType, log, nameLines)
end

function m.OpenUrl(url)
end

function m.OnCallBack(backType, values)
end

function m.Login()
end

function m.SetDebug()
end

function m.SetInitRetention(quality)
end

function m.GetOtherInfo()
end

function m.GetResolution()
end

function m.Logout()
end

function m.GetServiceList()
end

function m.SelectService(jsonString)
end

function m.GetLastServiceList(jsonString)
end

function m.GetDeviceInfo()
end

function m.GetSystemVersion()
end

function m.GetScreenWidth()
end

function m.GetScreenHeight()
end

function m.GetOS()
end

function m.GetGN()
end

function m.GetPL()
end

function m.CheckReview()
end

function m.ShowToolBar()
end

function m.HideToolBar()
end

function m.Question(jsonString)
end

function m.PlayVideo(jsonString)
end

function m.ChangeUserInfo(jsonString)
end

function m.IsShowUserCenter()
end

function m.EnterUserCenter()
end

function m.Pause()
end

function m.PressBack()
end

function m.OpenCustomWebView(jsonString)
end

function m.CloseCustomWebView()
end

function m.Quit()
end

function m.GetBrowseActive(jsonString)
end

function m.GetSuperNotice(jsonString)
end

function m.CallWebFunction(kType, functionName, jsonString)
end

function m.CallUniversalFunction(functionName, jsonString)
end

function m.CallUniversalFunctionWithBack(functionName, jsonString)
end

function m.Pay(jsonString)
end

function m.AddLocalNotification(key, body, time, repeatInterval)
end

function m.CancelLocalNotification(key)
end

function m.CancelAllLocalNotification()
end

function m.TotalRelease()
end

function m.ReleaseLuaAndVoice()
end

function m.OnApplicationPause(pause)
end

function m.Start()
end

function m.CheckNetState()
end

function m.GetNetState()
end

function m.OnVoiceCallBack(backType, json)
end

function m.StartRecord()
end

function m.StopRecord()
end

function m.CancelRecord()
end

function m.DownloadVoice(url)
end

function m.PlayVoice(filePath)
end

function m.StopPlay()
end

function m.QuitVoice()
end

function m.OnVoicePause()
end

function m.OnVoiceResume()
end

function m.CheckVoiceInit()
end

return m
