local m = {}

function m:OpenVideoFromFile(location, path, autoPlay)
end

function m:OpenVideoFromBuffer(buffer, autoPlay)
end

function m:StartOpenChunkedVideoFromBuffer(length, autoPlay)
end

function m:AddChunkToVideoBuffer(chunk, offset, chunkSize)
end

function m:EndOpenChunkedVideoFromBuffer()
end

function m:EnableSubtitles(fileLocation, filePath)
end

function m:DisableSubtitles()
end

function m:CloseVideo()
end

function m:Play()
end

function m:Pause()
end

function m:Stop()
end

function m:Rewind(pause)
end

function m.GetPlatform()
end

function m:GetCurrentPlatformOptions()
end

function m:GetPlatformOptions(platform)
end

function m.GetPlatformOptionsVariable(platform)
end

function m.GetPath(location)
end

function m.GetFilePath(path, location)
end

function m:CreatePlatformMediaPlayer()
end

function m:SaveFrameToPng()
end

function m:ExtractFrameAsync(target, callback, timeSeconds, accurateSeek, timeoutMs)
end

function m:ExtractFrame(target, timeSeconds, accurateSeek, timeoutMs)
end

return m
