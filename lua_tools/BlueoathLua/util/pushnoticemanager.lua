local PushNoticeManager = class("util.PushNoticeManager")
local noticeSetting = {}
local noticeParamMap = {}

function PushNoticeManager:initialize()
  eventManager:RegisterEvent(LuaEvent.PushNotice, self._PushNotice, self)
  eventManager:RegisterEvent(LuaEvent.PushAllNotice, self._PushAllNotice, self)
  eventManager:RegisterEvent(LuaEvent.NoticeSetingHasChanged, self._ChangeNoticeSetting, self)
  eventManager:RegisterEvent(LuaEvent.BuildFinish, self._FreeBuildRefresh, self)
end

function PushNoticeManager:_FreeBuildRefresh()
  local key = "freeBuildShip"
  self:_PushNotice(noticeParamMap[key]())
end

function PushNoticeManager:_ChangeNoticeSetting(setting)
  noticeSetting = setting
end

function PushNoticeManager:_PushNotice(paramList)
  for key, param in pairs(paramList) do
    if noticeSetting[param.key] then
      platformManager:AddLocalNotification(param.key, param.text, param.time, param.repeatTime)
    else
      platformManager:CancelLocalNotification(param.key)
    end
  end
end

function PushNoticeManager:_PushAllNotice()
  if #noticeSetting == 0 then
    self:_ChangeNoticeSetting(SettingHelper.GetAllSetting().noticeData)
  end
  self:_CancelAllNotice()
  for key, paramHandler in pairs(noticeParamMap) do
    self:_PushNotice(paramHandler())
  end
end

function PushNoticeManager:_CancelAllNotice()
  for key, v in pairs(noticeSetting) do
    platformManager:CancelLocalNotification(key)
  end
end

function PushNoticeManager:_BindNotice(eventName, handler)
  noticeParamMap[eventName] = handler
end

return PushNoticeManager
