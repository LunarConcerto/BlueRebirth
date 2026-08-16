local VideoPlot = class("UI.Plot.VideoPlot")

function VideoPlot:initialize(parent, tabWidget)
  self.m_tabWidgets = tabWidget
  self.parent = parent
  self.objVideoPlay = nil
  self.objPauseCheckTimer = nil
  self.isVideoStarted = false
  UGUIEventListener.AddButtonOnClick(tabWidget.obj_continue, function()
    self:ContinueVideo()
  end)
end

function VideoPlot:InitData()
end

function VideoPlot:PlayPlot(plotTab, index, callback)
  self.m_tabWidgets.btn_root:SetActive(false)
  self.m_tabWidgets.video_node:SetActive(true)
  self.curPlotInfo = plotTab[index]
  local mp4 = "movie/cg/" .. self.curPlotInfo.content
  self.m_tabWidgets.btn_skip_video.gameObject:SetActive(self.curPlotInfo.plot_episode_skip == 1)
  local args = {path = mp4, fit = true}
  SoundManager.Instance:PlayMusic("Story|BGM_story_silence")
  self.objVideoPlay = UIHelper.InitAndPlayVideo(mp4, self.m_tabWidgets.video_display, function()
    self.isVideoStarted = false
    if self.objPauseCheckTimer ~= nil then
      self.objPauseCheckTimer:Stop()
    end
    self.delayPlotEnd = FrameTimer.New(function()
      if callback ~= nil then
        callback()
      end
    end, 0, 0)
    self.delayPlotEnd:Start()
  end, function(mp, et, errorCode)
    if et == CS.RenderHeads.Media.AVProVideo.MediaPlayerEvent.EventType.Started then
      self.isVideoStarted = true
    end
  end)
  self:BeginCheckVideoPause(self.objVideoPlay)
end

function VideoPlot:ClickNext(callBack)
  if self.objPauseCheckTimer ~= nil then
    self.objPauseCheckTimer:Stop()
  end
  UIHelper.StopVideo(self.objVideoPlay)
  self.m_tabWidgets.video_node:SetActive(false)
  self.m_tabWidgets.btn_root:SetActive(true)
  if callBack ~= nil then
    callBack()
  end
end

function VideoPlot:ShowInfoDir(plotTab, index)
  if self.plotIndex == nil then
    self.plotIndex = 1
  end
end

function VideoPlot:BeginCheckVideoPause(objVideoPlay)
  local funcCheck = function()
    if IsNil(self.m_tabWidgets.obj_continue) then
      return
    end
    if IsNil(objVideoPlay) then
      return
    end
    local mediaPlayer = objVideoPlay:GetMediaPlayer()
    if IsNil(mediaPlayer) == nil then
      return
    end
    local objControl = mediaPlayer.Control
    if IsNil(objControl) then
      return
    end
    local bPaused = objControl:IsPaused()
    local bShow = bPaused and self.isVideoStarted
    if self.m_tabWidgets.obj_continue.activeSelf ~= bShow then
      self.m_tabWidgets.obj_continue:SetActive(bShow)
    end
  end
  if self.objPauseCheckTimer == nil then
    self.objPauseCheckTimer = Timer.New(funcCheck, 0.01, -1)
  else
    self.objPauseCheckTimer:Reset(funcCheck, 0.01, -1)
  end
  self.objPauseCheckTimer:Start()
end

function VideoPlot:ContinueVideo()
  if IsNil(self.objVideoPlay) then
    return
  end
  UIHelper.ContinueVideo(self.objVideoPlay)
end

function VideoPlot:Destroy()
  if self.objPauseCheckTimer ~= nil then
    self.objPauseCheckTimer:Stop()
  end
  UIHelper.DestroyVideoProcess(self.objVideoPlay)
end

return VideoPlot
