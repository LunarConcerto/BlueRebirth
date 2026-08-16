local utf8stringHelper = {}

function utf8stringHelper.SubStringUTF8(str, startIndex, endIndex)
  if startIndex < 0 then
    startIndex = utf8stringHelper.SubStringGetTotalIndex(str) + startIndex + 1
  end
  if endIndex ~= nil and endIndex < 0 then
    endIndex = utf8stringHelper.SubStringGetTotalIndex(str) + endIndex + 1
  end
  if endIndex == nil then
    return string.sub(str, utf8stringHelper.SubStringGetTrueIndex(str, startIndex))
  else
    return string.sub(str, utf8stringHelper.SubStringGetTrueIndex(str, startIndex), utf8stringHelper.SubStringGetTrueIndex(str, endIndex + 1) - 1)
  end
end

function utf8stringHelper.SubStringGetTotalIndex(str)
  local curIndex = 0
  local i = 1
  local lastCount = 1
  repeat
    lastCount = utf8stringHelper.SubStringGetByteCount(str, i)
    i = i + lastCount
    curIndex = curIndex + 1
  until lastCount == 0
  return curIndex - 1
end

function utf8stringHelper.SubStringGetTrueIndex(str, index)
  local curIndex = 0
  local i = 1
  local lastCount = 1
  repeat
    lastCount = utf8stringHelper.SubStringGetByteCount(str, i)
    i = i + lastCount
    curIndex = curIndex + 1
  until index <= curIndex
  return i - lastCount
end

function utf8stringHelper.SubStringGetTrueEndIndex(str, index)
  local curIndex = 0
  local i = 1
  local lastCount = 1
  repeat
    lastCount = utf8stringHelper.SubStringGetByteCount(str, i)
    i = i + lastCount
    curIndex = curIndex + 1
  until index <= curIndex
  return i - 1
end

function utf8stringHelper.SubStringGetByteCount(str, index)
  local curByte = string.byte(str, index)
  local byteCount = 1
  if curByte == nil then
    byteCount = 0
  elseif 0 < curByte and curByte <= 127 then
    byteCount = 1
  elseif 192 <= curByte and curByte <= 223 then
    byteCount = 2
  elseif 224 <= curByte and curByte <= 239 then
    byteCount = 3
  elseif 240 <= curByte and curByte <= 247 then
    byteCount = 4
  end
  return byteCount
end

return utf8stringHelper
