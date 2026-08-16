local HeroService = class("servic.HeroService", Service.BaseService)

function HeroService:initialize()
  self:_InitHandlers()
end

function HeroService:_InitHandlers()
  self:BindEvent("hero.GetHeroInfo", self._GetHeroInfo, self)
  self:BindEvent("hero.UpdateHeroBagData", self._UpdateHeroBagData, self)
  self:BindEvent("hero.HeroIntensify", self._HeroIntensify, self)
  self:BindEvent("hero.ChangeEquip", self._ChangeEquip, self)
  self:BindEvent("hero.HeroAdvance", self._HeroBreak, self)
  self:BindEvent("hero.LockHero", self._HeroSetLock, self)
  self:BindEvent("hero.RetireHero", self._RetireHero, self)
  self:BindEvent("hero.Marry", self._MarryHero, self)
  self:BindEvent("hero.ChangeName", self._ChangeNameHero, self)
  self:BindEvent("hero.AddExp", self._SendAddExp, self)
  self:BindEvent("hero.StudySkill", self._SendStudySkill, self)
  self:BindEvent("hero.GetHeroInfoByHeroIdArray", self._UpdateHeroData, self)
  self:BindEvent("hero.AutoEquip", self._OnAutoEquip, self)
  self:BindEvent("hero.AutoUnEquip", self._OnAutoUnEquip, self)
  self:BindEvent("hero.HeroAdvMaxLv", self._OnLFurther, self)
  self:BindEvent("hero.HeroEquipEffect", self._GetEquipEffect, self)
  self:BindEvent("hero.HeroRemould", self._GetHeroRemould, self)
  self:BindEvent("hero.EquipBinding", self._GetEquipBinding, self)
  self:BindEvent("hero.EquipUnBinding", self._GetEquipUnBinding, self)
  self:BindEvent("hero.EquipLockTransplant", self._GetEquipLockTransplant, self)
end

function HeroService:SendGetHeroInfo()
  self:SendNetEvent("hero.GetHeroInfo", nil)
end

function HeroService:SendChangeEquip(heroId, index, equipId, fleetType)
  local args = {
    HeroId = heroId,
    Index = index,
    EquipId = equipId,
    Type = fleetType or FleetType.Normal
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROCHANGEEQUIPARGS)
  self:SendNetEvent("hero.ChangeEquip", args)
end

function HeroService:SendAutoEquip(autoUnixs, fleetType)
  local args = {
    AutoUnit = autoUnixs,
    Type = fleetType or FleetType.Normal
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROAUTOEQUIPARG)
  self:SendNetEvent("hero.AutoEquip", args)
end

function HeroService:SendAutoUnEquip(heroIds, fleetType)
  local args = {
    HeroId = heroIds,
    Type = fleetType or FleetType.Normal
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROAUTOUNEQUIPARG)
  self:SendNetEvent("hero.AutoUnEquip", args)
end

function HeroService:_ChangeEquip(ret, state, err, errmsg)
  if err ~= 0 then
    logError("ChangeEquip: " .. err .. errmsg)
  else
    self:SendLuaEvent("changeHeroEquip")
  end
end

function HeroService:_OnAutoEquip(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero.AutoEquip: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.EQUIP_AutoAddOk)
  end
end

function HeroService:_OnAutoUnEquip(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero.AutoUnEquip: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.EQUIP_AutoUnAddOk)
  end
end

function HeroService:SendHeroIntensify(heroid, consumeIds, isSuper)
  local args = {
    HeroId = heroid,
    ConsumedHeros = consumeIds,
    SuperIntensify = isSuper
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.TINTENSIFYHEROARGS)
  self:SendNetEvent("hero.HeroIntensify", args, args)
end

function HeroService:_GetHeroInfo(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetHeroInfo: " .. errmsg)
  else
    self:SendLuaEvent("getHeroInfoMsg")
  end
end

function HeroService:_HeroIntensify(ret, state, err, errmsg)
  if err ~= 0 then
    logError("HeroIntensify: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.HeroIntensifySuccess, state)
  end
end

function HeroService:_UpdateHeroBagData(ret, state, err, errmsg)
  if ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, hero_pb.THEROINFO)
    Data.heroData:SetData(info)
    Data.wishData:UpdateWishHero()
    Data.equipData:RefreshHeroEquipData()
    self:SendLuaEvent(LuaEvent.UpdateHeroData)
  end
end

function HeroService:SendHeroBreak(heroid, consumeIds)
  local args = {HeroId = heroid, ConsumedHeros = consumeIds}
  args = dataChangeManager:LuaToPb(args, hero_pb.TADVANCEARG)
  self:SendNetEvent("hero.HeroAdvance", args, args)
end

function HeroService:_HeroBreak(ret, state, err, errmsg)
  if err ~= 0 then
    logError("errId: " .. tostring(err))
  else
    self:SendLuaEvent(LuaEvent.HeroBreakSuccess, state)
  end
end

function HeroService:SendHeroLock(heroId, bLock)
  local args = {HeroId = heroId, lock = bLock}
  args = dataChangeManager:LuaToPb(args, hero_pb.TLOCKHEROARG)
  self:SendNetEvent("hero.LockHero", args, args)
end

function HeroService:_HeroSetLock(ret, state, err, errmsg)
  if err ~= 0 then
    noticeManager:OpenTipPage(self, 950000001)
    logError("LockHero Failed: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.SendHeroLock, state)
  end
end

function HeroService:SendRetireHero(heroIds, isDisEquip)
  local args = {HeroIds = heroIds, IsDisEquip = isDisEquip}
  args = dataChangeManager:LuaToPb(args, hero_pb.TRETIREHEROARG)
  self:SendNetEvent("hero.RetireHero", args)
end

function HeroService:_RetireHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("GetRetireHero Failed:" .. errmsg)
  elseif ret ~= nil then
    local info = dataChangeManager:PbToLua(ret, hero_pb.TRETIREHERORET)
    self:SendLuaEvent(LuaEvent.RetireHeros, info)
  end
end

function HeroService:SendMarry(args)
  local args = {
    HeroId = args.HeroId,
    MarryType = args.MarryType
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.TMARRYARG)
  self:SendNetEvent("hero.Marry", args)
end

function HeroService:_MarryHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_MarryHero: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.MarrySuccess)
  end
end

function HeroService:SendChangeName(args)
  local args = {
    HeroId = args.HeroId,
    Name = args.Name
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.TCHANGEHERONAMEARG)
  self:SendNetEvent("hero.ChangeName", args)
end

function HeroService:_ChangeNameHero(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_ChangeNameHero: " .. errmsg)
    self:SendLuaEvent(LuaEvent.ChangeNameError, err)
  else
    self:SendLuaEvent(LuaEvent.ChangeNameSuccess)
  end
end

function HeroService:SendAddExp(args)
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROADDEXP)
  self:SendNetEvent("hero.AddExp", args)
end

function HeroService:_SendAddExp(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SendAddExp: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.HeroAddExp, ret)
  end
end

function HeroService:SendStudySkill(args)
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROSKILL)
  self:SendNetEvent("hero.StudySkill", args)
end

function HeroService:_SendStudySkill(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_SendStudySkill: " .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.HeroStudySkill, ret)
  end
end

function HeroService:_SendBathHero(args)
  local args = {
    HeroId = args.HeroId
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROARRAYARG)
  self:SendNetEvent("hero.GetHeroInfoByHeroIdArray", args)
end

function HeroService:_UpdateHeroData(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_UpdateHeroData: ", err, errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateMoodHero, err)
  end
end

function HeroService:_SendHeroLFurther(heroId)
  local args = {HeroId = heroId}
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROADVMAXLVARG)
  self:SendNetEvent("hero.HeroAdvMaxLv", args)
end

function HeroService:_OnLFurther(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero lv further err:" .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.HERO_LvFurtherOk)
  end
end

function HeroService:_SendEquipEffect(args)
  local args = {
    HeroId = args.HeroId,
    Effects = args.Effects
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROEQUIPEFFECTARG)
  self:SendNetEvent("hero.HeroEquipEffect", args)
end

function HeroService:_GetEquipEffect(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero HeroEquipEffect err:" .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateEquipEffect)
  end
end

function HeroService:_SendHeroRemould(args)
  local args = {
    HeroId = args.HeroId,
    EffectId = args.EffectId
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.TREMOULDARG)
  local state = args.EffectId
  self:SendNetEvent("hero.HeroRemould", args, state)
end

function HeroService:_GetHeroRemould(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero.HeroRemould err: ", err)
    logError("hero.HeroRemould errMsg: ", errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateHeroRemould, state)
  end
end

function HeroService:_SendEquipBinding(args)
  local args = {
    HeroId = args.HeroId,
    EquipId = args.EquipId,
    EquipType = args.EquipType
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROEQUIPBINDINGARG)
  self:SendNetEvent("hero.EquipBinding", args)
end

function HeroService:_GetEquipBinding(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero EquipBinding err:" .. errmsg)
  else
    self:SendLuaEvent(LuaEvent.UpdateEquipBind)
  end
end

function HeroService:_SendEquipUnBinding(args)
  local args = {
    HeroId = args.HeroId,
    EquipId = args.EquipId,
    EquipType = args.EquipType
  }
  args = dataChangeManager:LuaToPb(args, hero_pb.THEROEQUIPBINDINGARG)
  self:SendNetEvent("hero.EquipUnBinding", args)
end

function HeroService:_GetEquipUnBinding(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero EquipUnBinding err:" .. errmsg)
  else
    if ret ~= nil then
      local luaRet = dataChangeManager:PbToLua(ret, hero_pb.TRETIREHERORET)
      Data.heroData:SetEquipRetireReward(luaRet.Reward)
      self:SendLuaEvent(LuaEvent.GetUnBindReward)
    end
    self:SendLuaEvent(LuaEvent.UpdateEquipBind)
  end
end

function HeroService:_SendEquipLockTransplant(args)
  local pbArgs = dataChangeManager:LuaToPb(args, hero_pb.THEROEQUIPTRANSPLANTARG)
  self:SendNetEvent("hero.EquipLockTransplant", pbArgs)
end

function HeroService:_GetEquipLockTransplant(ret, state, err, errmsg)
  if err ~= 0 then
    logError("hero _GetEquipLockTransplant err:" .. errmsg)
  end
end

return HeroService
