local EmailData = class("data.EmailData", Data.BaseData)

function EmailData:initialize()
  self:ResetData()
end

function EmailData:ResetData()
  self.tabMailList = {}
  self.updataTog = false
  self.m_deleteNum = 0
  self.m_newMail = false
end

function EmailData:SetMailList(param)
  local newMail = function(mail)
    return mail.ReadTime == 0 and mail.IsGotReawrd == 0
  end
  local new = false
  self.m_newMail = false
  if param.list ~= nil then
    for k, v in pairs(param.list) do
      v.haveItem = #v.Items ~= 0 and 1 or 0
      new = newMail(v)
      v.haveRead = not new and 1 or 0
      if new and not self.m_newMail then
        self.m_newMail = true
      end
    end
  end
  self.tabMailList = param.list
  self.m_deleteNum = param.ExpireNum
end

function EmailData:GetMailList()
  return SetReadOnlyMeta(self.tabMailList)
end

function EmailData:GetDeleteNum()
  return self.m_deleteNum or 0
end

function EmailData:HaveNew()
  return self.m_newMail
end

function EmailData:SetUpdataTog(tog)
  self.updataTog = tog
end

function EmailData:GetUpdataTog()
  return self.updataTog
end

return EmailData
