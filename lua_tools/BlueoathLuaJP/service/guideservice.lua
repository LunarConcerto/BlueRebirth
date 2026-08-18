local GuideService = class("service.GuideService", Service.BaseService)

function GuideService:initialize()
  self:_InitHandlers()
end

function GuideService:_InitHandlers()
  self:BindEvent("guide.GuideInfo", self._GuideInfo, self)
  self:BindEvent("guide.PlotReward", self._PlotReward, self)
  self:BindEvent("guide.Setting", self._ReceiveUserSetting, self)
end

function GuideService:_GuideInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("guide info errmsg:" .. errmsg)
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, guide_pb.TGUIDEINFO)
    Data.guideData:SetGuideData(info)
    plotManager:InitPlotPassFlags(info)
    eventManager:SendEvent(LuaEvent.GuideInfoReceive)
  end
end

function GuideService:SendPlotReward(id)
  local args = {PlotId = id}
  args = dataChangeManager:LuaToPb(args, guide_pb.TGUIDEPLOTREWARDARG)
  self:SendNetEvent("guide.PlotReward", args)
end

function GuideService:_PlotReward(ret, state, err, errmsg)
  if err ~= 0 then
    logError("save plot data errmsg:" .. errmsg)
    if 0 < err then
      local str = UIHelper.GetString(err)
      if str == nil or str == "" then
        noticeManager:ShowTip(err .. " error" .. tostring(errmsg))
      else
        noticeManager:ShowTip(str)
      end
    else
      noticeManager:ShowTip(err .. " error" .. tostring(errmsg))
    end
  end
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, guide_pb.TGUIDEREWARDRET)
  end
end

function GuideService:SendUserSetting(tblParam)
  local arg = {param = tblParam}
  arg = dataChangeManager:LuaToPb(arg, guide_pb.TGUIDESETTINGARG)
  self:SendNetEvent("guide.Setting", arg, nil, false)
end

function GuideService:_ReceiveUserSetting(msg, state, err, errmsg)
  if err ~= 0 then
    logError("Get Guide Setting Error" .. err .. "  " .. errmsg)
  end
  if msg ~= nil then
    local info = dataChangeManager:PbToLua(msg, guide_pb.TGUIDEINFO)
    Data.guideData:SetSetting(info.Setting)
    eventManager:SendEvent(LuaEvent.GuideSettingReceive, info.Setting)
  end
end

return GuideService
