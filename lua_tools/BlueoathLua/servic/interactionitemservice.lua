local InteractionItemService = class("servic.InteractionItemService", Service.BaseService)

function InteractionItemService:initialize()
  self:_InitHandlers()
end

function InteractionItemService:_InitHandlers()
  self:BindEvent("interactionitem.RefreshInteractionItems", self._RefreshInteractionItems, self)
  self:BindEvent("interactionitem.GetItemReward", self._GetInteractionItemRet, self)
  self:BindEvent("interactionitem.BuyChristmasFurniture", self._BuyChristmasFurnitureRet, self)
  self:BindEvent("interactionitem.GetSpringPaperFlowerReward", self._GetClickSpringPaperFlowerRet, self)
  self:BindEvent("interactionitem.SetCrystalBallToy", self._SetCrystalBallToyStateRet, self)
  self:BindEvent("interactionitem.SetBagItemVisible", self._GetBagItemVisibleRet, self)
  self:BindEvent("interactionitem.SetMutexBagGroupState", self._GetSetMutexBagGroupState, self)
  self:BindEvent("interactionitem.SetPosterState", self._GetSetDecoratePoster, self)
end

function InteractionItemService:SetInteractionItems(arg, state)
  arg = dataChangeManager:LuaToPb(arg, interactionitem_pb.TINTERACTIONITEMARG)
  self:SendNetEvent("interactionitem.GetItemReward", arg, state)
end

function InteractionItemService:_GetInteractionItemRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get InteractionItem Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
  Logic.interactionItemLogic:GetItemReward(state)
end

function InteractionItemService:BuyFurnitureItems(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TINTERACTIONITEMARG)
  self:SendNetEvent("interactionitem.BuyChristmasFurniture", args, arg.rewardId)
end

function InteractionItemService:_BuyChristmasFurnitureRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get BuyFurnitureItems Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
  Logic.interactionItemLogic:GetFurnitureReward(state)
end

function InteractionItemService:ClickSpringPaperFlower(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TINTERACTIONITEMARG)
  self:SendNetEvent("interactionitem.GetSpringPaperFlowerReward", args, arg.interactionItem)
end

function InteractionItemService:_GetClickSpringPaperFlowerRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get ClickSpringPaperFlower Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
  Logic.interactionItemLogic:GetClickNoEventReward(state)
end

function InteractionItemService:SetCrystalBallToyState(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TINTERACTIONBALLTOYARG)
  self:SendNetEvent("interactionitem.SetCrystalBallToy", args, arg.ballId)
end

function InteractionItemService:_SetCrystalBallToyStateRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _SetCrystalBallToyStateRet err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
end

function InteractionItemService:SetBagItemVisible(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TINTERACTIONITEMARG)
  self:SendNetEvent("interactionitem.SetBagItemVisible", args, arg.interactionItem)
end

function InteractionItemService:_GetBagItemVisibleRet(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get BagItemVisibleRet Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
end

function InteractionItemService:SetMutexBagGroupState(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TDECORATEMUTEXBAGGROUPARG)
  self:SendNetEvent("interactionitem.SetMutexBagGroupState", args)
end

function InteractionItemService:_GetSetMutexBagGroupState(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get SetMutexBagGroupState Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  end
end

function InteractionItemService:SetPosters(arg)
  local args = dataChangeManager:LuaToPb(arg, interactionitem_pb.TPOSTERSTATEARG)
  self:SendNetEvent("interactionitem.SetPosterState", args)
end

function InteractionItemService:_GetSetDecoratePoster(ret, state, err, errmsg)
  if err ~= 0 then
    logError("_Get SetDecoratePoster Ret err " .. errmsg)
    noticeManager:ShowTip(UIHelper.GetString(330001))
    return
  else
    noticeManager:ShowTip(UIHelper.GetString(3500009))
  end
end

function InteractionItemService:_RefreshInteractionItems(ret, state, err, errmsg)
  if err ~= 0 then
    logError(" _Refresh InteractionItems err : " .. errmsg)
    return
  end
  local info = dataChangeManager:PbToLua(ret, interactionitem_pb.TINTERACTIONITEMRET)
  Data.interactionItemData:SetData(info)
end

return InteractionItemService
