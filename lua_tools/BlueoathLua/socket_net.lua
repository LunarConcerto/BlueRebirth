require("net.ProtobufSerializer")
protobufTypeManager = require("net.ProtobufTypeManager")
SocketConnState = {
  Disconnected = 0,
  Connecting = 1,
  Connected = 2,
  Disconnecting = 3
}
Socket = {}
Socket.States = {}
Socket.Listeners = {}
Socket.SlientSendMethod = {}
local types = ProtobufTypeManager
local serializer = ProtobufSerializer
local connected = 2
local _GetStateID = function(state)
  if state == nil then
    return 0
  end
  for i = 1, 100000 do
    if Socket.States[i] == nil then
      Socket.States[i] = state
      return i
    end
  end
end
local _GetStateByID = function(id)
  if Socket.States[id] ~= nil then
    local state = Socket.States[id]
    Socket.States[id] = nil
    return state
  end
end
local _FixTime = function(serverTime)
  time.syncTime(serverTime)
end
local receivedSign = true
local m_timer, m_waitCo
local seqMap = {}
local tokenErrTime = 0
local tokenRequestHeap = {}
local tokenNum = 0

function Socket.OnReceived(handle, method, time, errcode, errmsg, seq, isResponse, payload, printout)
  local requestState = _GetStateByID(handle)
  if requestState and requestState.__needToken then
    state = requestState.params
    if requestState.__needToken then
      tokenNum = tokenNum - 1
      local requestArgs = tokenRequestHeap[1]
      if requestArgs ~= nil then
        table.remove(tokenRequestHeap, 1)
        Socket._RealSend(table.unpack(requestArgs))
      end
    end
  end
  if printout then
    log("[RECEIVED RESEND] message: " .. method .. ", errcode: " .. tostring(errcode) .. ", errmsg: " .. errmsg)
  end
  if time ~= nil and time ~= 0 then
    _FixTime(time)
  end
  if errcode < 0 then
    if errcode == -2 then
      logError("this request has fake token")
      tokenErrTime = tokenErrTime + 1
      if 2 <= tokenErrTime then
        logError("tokenErrTime reaches max ", tokenErrTime)
        tokenErrTime = 0
        Socket.Disconnect()
        return
      end
    else
      tokenErrTime = 0
      if errcode == -5 then
        noticeManager:ShowMsgBox(420016)
        return
      end
    end
  end
  local methodList = string.split(method, "_")
  if 1 < #methodList then
    local method_old = method
    local methodListDot = string.split(method, ".")
    method = methodList[1] .. "." .. methodListDot[2]
    log("method_old:%s, method:%s", method_old, method)
  end
  if errcode == 0 then
    eventManager:SendEvent(LuaEvent.SocketOnReceived, method)
  end
  tokenErrTime = 0
  local listener = Socket.Listeners[method]
  if listener == nil then
    logWarning("no method:" .. method)
    return
  end
  local pbType = types[method]
  if pbType == nil then
    listener.handler(listener.target, nil, state, errcode, errmsg)
  elseif payload == nil then
    log("OnReceived: payload is nil")
    listener.handler(listener.target, nil, state, errcode, errmsg)
  else
    local obj = pbType()
    obj:ParseFromString(payload)
    listener.handler(listener.target, obj, state, errcode, errmsg)
  end
  if isResponse == 1 then
  end
end

local onConnected = function(...)
end
local onDisconnected = function(...)
end

function Socket.OnConnState(prev, curr)
  if Socket.curState == curr then
    return
  end
  if curr == connected then
    eventManager:SendEvent(LuaEvent.ConnectServer)
  elseif curr == SocketConnState.Disconnected then
    eventManager:SendEvent(LuaEvent.DisconnectServer)
  end
  Socket.curState = curr
end

function Socket.Init(...)
  BabelTime.Net.NetLogic.Init()
  BabelTime.Net.NetLogic.InitLuaCallbacks(Socket.OnConnState, Socket.OnReceived)
end

function Socket.Cleanup(...)
  BTNet.CleanLuaCallbacks()
  BTNet.Cleanup()
end

function Socket.Connect(host, port)
  tokenRequestHeap = {}
  tokenNum = 0
  BabelTime.Net.NetLogic.Connect(host, port)
end

function Socket.Disconnect()
  if Socket.curState == SocketConnState.Disconnected then
    onDisconnected()
    return
  end
  BabelTime.Net.NetLogic.Disconnect()
end

function Socket.RegisterHandler(eventName, handler, target, pbType)
  Socket.Listeners[eventName] = {handler = handler, target = target}
  if pbType ~= nil then
    types[eventName] = pbType
  end
end

function Socket.UnregisterHandler(eventName)
  Socket.Listeners[eventName] = nil
end

function Socket.Send(method, args, state, waitRecv)
  local requestState = {params = state}
  requestState.__needToken = true
  tokenNum = tokenNum + 1
  if tokenNum == 1 then
    Socket._RealSend(method, args, requestState, waitRecv)
    return
  end
  table.insert(tokenRequestHeap, {
    method,
    args,
    requestState,
    waitRecv
  })
end

function Socket._RealSend(method, args, state, waitRecv)
  local argsStr
  if args == nil then
    argsStr = nil
  else
    argsStr = serializer.serializ(args)
  end
  local handle = _GetStateID(state)
  local sendSuccess = BabelTime.Net.NetLogic.LuaSend(handle, method, argsStr, waitRecv)
  if sendSuccess == false then
    logWarning("send method:%s fail", method)
    Socket.OnReceived(nil, method, nil, -1, "", 0, 1)
  end
  return sendSuccess
end

Socket.send1 = Socket.Send
Socket.registerHandler = Socket.RegisterHandler
Socket.removeHandler = Socket.UnregisterHandler

function Socket.ConnectImp(host, port)
  if Socket.curState == SocketConnState.Connecting or Socket.curState == SocketConnState.Connected then
    return
  end
  Socket.Connect(host, port)
end

Socket.close = Socket.Disconnect
return Socket
