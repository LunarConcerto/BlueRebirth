local IllustrateService = class("service.IllustrateService", Service.BaseService)

function IllustrateService:initialize()
  self:BindEvent("illustrate.IllustrateInfo", self._IllustrateInfo, self)
  self:BindEvent("illustrate.IllustrateNew", self._IllustrateNew, self)
  self:BindEvent("illustrate.OldIllustrateInfo", self._OldIllustrateInfo, self)
  self:BindEvent("illustrate.AddBehaviour", self._AddBehaviour, self)
  self:BindEvent("illustrate.Memory", self._Memory, self)
  self:BindEvent("illustrate.EquipNew", self._EquipNew, self)
  self:BindEvent("illustrate.VowHero", self._VowHero, self)
  self:BindEvent("illustrate.VowDecTime", self._VowDecTime, self)
  self:BindEvent("illustrate.ModiVowHeroList", self._OnModiVowHero, self)
end

function IllustrateService:SendVowHero(heroList)
  local args = {ChooseHeroList = heroList}
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TVOWHEROARGS)
  self:SendNetEvent("illustrate.VowHero", args, heroList)
end

function IllustrateService:SendVowDecTime(items, type, useWay)
  local args = {
    UseInfo = items,
    Type = type or 0
  }
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TVOWDECTIMEARGS)
  self:SendNetEvent("illustrate.VowDecTime", args, {
    ItemTid = items[1].ItemTid,
    ItemNum = items[1].ItemNum,
    UseWay = useWay
  })
end

function IllustrateService:SendModiVowHero(herolist)
  local args = {ChooseHeroList = herolist}
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TMODIVOWHEROLISTARG)
  self:SendNetEvent("illustrate.ModiVowHeroList", args, herolist)
end

function IllustrateService:_VowHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("vow hero err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TVOWHERORET)
    local reward = {}
    reward.HeroId = args.Id
    reward.TemplateId = args.ConfigId
    reward.Num = args.Num
    reward.Type = args.Type
    Data.illustrateData:SetPreHeroList(state)
    Data.wishData:UpdateWishHero()
    Data.illustrateData:SetVowHero(reward.TemplateId)
    self:SendLuaEvent(LuaEvent.GetWishReward, reward)
  end
end

function IllustrateService:_VowDecTime(ret, state, err, errmsg)
  if err ~= 0 then
    logError("vow dec time err:" .. errmsg)
    return
  end
  if ret ~= nil then
    self:SendLuaEvent(LuaEvent.UseWishItem, state)
  end
end

function IllustrateService:_OnModiVowHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("modi vow hero err:" .. err .. " errmsg:" .. errmsg)
    return
  end
  Data.illustrateData:SetPreHeroList(state)
end

function IllustrateService:_AddBehaviour(ret, state, err, errmsg)
  if err ~= 0 then
    logError("add behaviour ret err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TILLUSTRATELIST)
    for _, info in ipairs(args.IllustrateList) do
      Data.illustrateData:UpdataIllustrateData(info)
    end
    local res = Data.illustrateData:GetAllIllustrate()
    self:SendLuaEvent(LuaEvent.UpdataIllustrateList, res)
  end
end

function IllustrateService:_IllustrateInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TILLUSTRATEINFORET)
    Data.illustrateData:SetIllustrateData(args)
    Data.wishData:UpdateWishHero()
    self:SendLuaEvent(LuaEvent.UpdataIllustrateList, args)
    if Logic.loginLogic:GetLoginOK() == true then
      local noticeParam = Logic.illustrateLogic:GetPushNoticeParams(args.VowCoolTime)
      self:SendLuaEvent(LuaEvent.PushNotice, noticeParam)
    end
    if args.UseInfo ~= nil then
      self:SendLuaEvent(LuaEvent.WISH_ItemCountRefresh)
    end
  end
end

function IllustrateService:_OldIllustrateInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  Data.illustrateData:UpdateOldIllustrateData()
end

function IllustrateService:_IllustrateNew(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TILLUSTRATELIST)
    for _, info in ipairs(args.IllustrateList) do
      Data.illustrateData:UpdataIllustrateData(info)
    end
    local res = Data.illustrateData:GetAllIllustrate()
    self:SendLuaEvent(LuaEvent.UpdataIllustrateList, res)
  end
end

function IllustrateService:SendIllustrateNew(illustrateIds)
  local args = {IllustrateIds = illustrateIds}
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TILLUSTRATENEWARGS)
  self:SendNetEvent("illustrate.IllustrateNew", args)
end

function IllustrateService:SendIllustrateBehaviour(behaviourItems)
  local args = {BehaviourItem = behaviourItems}
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TILLUSTRATEBEHAVIOURARGS)
  self:SendNetEvent("illustrate.AddBehaviour", args, nil, false)
end

function IllustrateService:_Memory(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TMEMORYLIST)
    Data.illustrateData:SetMemoryData(args)
  end
end

function IllustrateService:SendIllustrateEquipNew(equipIds)
  local args = {EquipIds = equipIds}
  args = dataChangeManager:LuaToPb(args, illustrate_pb.TEQUIPNEWARGS)
  self:SendNetEvent("illustrate.EquipNew", args)
end

function IllustrateService:_EquipNew(ret, state, err, errmsg)
  if err ~= 0 then
    logError("get task info err:" .. errmsg)
    return
  end
  if ret ~= nil then
    local args = dataChangeManager:PbToLua(ret, illustrate_pb.TILLUSTRATEEQUIPLIST)
    for _, info in ipairs(args.EquipList) do
      Data.illustrateData:UpdataIllustrateEquipData(info)
    end
    self:SendLuaEvent(LuaEvent.UpdataIllustrateEquipList)
  end
end

return IllustrateService
