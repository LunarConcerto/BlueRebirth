local TeacherPrestigeTip = class("UI.Teaching.TeacherPrestigeTip", LuaUIPage)

function TeacherPrestigeTip:DoInit()
end

function TeacherPrestigeTip:DoOnOpen()
  self:_Refresh()
end

function TeacherPrestigeTip:RegisterAllEvent()
end

function TeacherPrestigeTip:_Refresh()
  self:_ShowTeachRewards()
end

function TeacherPrestigeTip:_ShowTeachRewards()
end

function TeacherPrestigeTip:DoOnHide()
end

function TeacherPrestigeTip:DoOnClose()
end

return TeacherPrestigeTip
