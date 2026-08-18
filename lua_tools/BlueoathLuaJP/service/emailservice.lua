local EmailService = class("service.EmailService", Service.BaseService)

function EmailService:initialize()
  self:_InitHandlers()
end

function EmailService:_InitHandlers()
  self:BindEvent("mail.GetMailList", self._UpdataMailList, self)
  self:BindEvent("mail.OpenMail", self._OpenMail, self)
  self:BindEvent("mail.DeleteMail", self._UpdataMailList, self)
  self:BindEvent("mail.DeleteAllMail", self._UpdataMailList, self)
  self:BindEvent("mail.FetchItem", self._FetchItem, self)
  self:BindEvent("mail.FetchAllItems", self._UpdataMailList, self)
  self:BindEvent("mail.ReceiveNewMail", self._UpdataMailList, self)
  self:BindEvent("payback.newPayback", self._TagUpdataMail, self)
end

function EmailService:_TagUpdataMail()
  Data.emailData:SetUpdataTog(true)
  self:SendLuaEvent(LuaEvent.NewPayback)
end

function EmailService:SendGetNewMail()
  self:SendNetEvent("mail.ReceiveNewMail", nil)
end

function EmailService:SendGetMailList()
  self:SendNetEvent("mail.GetMailList", nil)
end

function EmailService:SendOpenMail(mid)
  local args = {Mid = mid}
  args = dataChangeManager:LuaToPb(args, mail_pb.TOPENMAILARG)
  self:SendNetEvent("mail.OpenMail", args)
end

function EmailService:SendDeleteMail(mid)
  local args = {Mid = mid}
  args = dataChangeManager:LuaToPb(args, mail_pb.TDELETEMAILARG)
  self:SendNetEvent("mail.DeleteMail", args)
end

function EmailService:SendDeleteAllMail()
  self:SendNetEvent("mail.DeleteAllMail", nil)
end

function EmailService:SendfetchItem(mid)
  local args = {Mid = mid}
  args = dataChangeManager:LuaToPb(args, mail_pb.TFETCHMAILARG)
  self:SendNetEvent("mail.FetchItem", args)
end

function EmailService:SendfetchAllItems()
  self:SendNetEvent("mail.FetchAllItems", nil)
end

function EmailService:_UpdataMailList(ret, state, err, errmsg)
  if err ~= 0 then
    logError("updata mail errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, mail_pb.TMAILLISTRET)
    Data.emailData:SetMailList(args)
    self:SendLuaEvent(LuaEvent.UpdataMailList, args)
    self:SendLuaEvent("fetchMailItem", args.Reward)
  end
end

function EmailService:_FetchItem(ret, state, err, errmsg)
  if err ~= 0 then
    logError("updata mail errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, mail_pb.TMAILLISTRET)
    Data.emailData:SetMailList(args)
    self:SendLuaEvent(LuaEvent.UpdataMailList, args)
    self:SendLuaEvent("fetchMailItem", args.Reward)
  end
end

function EmailService:_OpenMail(ret, state, err, errmsg)
  if err ~= 0 then
    logError("open mail errmsg:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, mail_pb.TMAILLISTRET)
    Data.emailData:SetMailList(args)
    self:SendLuaEvent("openMail", args)
  end
end

return EmailService
