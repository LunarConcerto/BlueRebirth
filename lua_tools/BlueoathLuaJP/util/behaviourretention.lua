local BehaviourRetention = class("util.BehaviourRetention")
local weak_table = {}
setmetatable(weak_table, {__kv = "k"})
BehaviourRetentResultType = {
  Complete = 0,
  Interrupt = 1,
  Skip = 2,
  Other = 9
}
local RecordBehaviour = {
  click_sp = true,
  get_3d = true,
  turn = true,
  click1 = true,
  click2 = true,
  click3 = true,
  wait = true,
  login = true,
  mvp = true,
  defeat = true,
  get = true,
  learn_start = true,
  learn_complete = true,
  learn_click1 = true,
  learn_click2 = true
}

function BehaviourRetention.CreateHandler(shipgirl, behaviourName)
  if weak_table[shipgirl] and weak_table[shipgirl] ~= self then
    weak_table[shipgirl]:BeIntterupt()
    weak_table[shipgirl] = nil
  end
  if not RecordBehaviour[behaviourName] then
    return nil
  end
  return BehaviourRetention:new(shipgirl, behaviourName)
end

function BehaviourRetention.SkipAll()
  for k, handler in pairs(weak_table) do
    handler:Skip()
  end
end

function BehaviourRetention.OtherEndAll()
  for k, handler in pairs(weak_table) do
    handler:OtherEnd()
  end
end

function BehaviourRetention.SkipGirl(shipgirl)
  local handler = weak_table[shipgirl]
  if handler then
    handler:Skip()
  end
end

function BehaviourRetention.OtherEndGirl(shipgirl)
  local handler = weak_table[shipgirl]
  if handler then
    handler:OtherEnd()
  end
end

function BehaviourRetention:initialize(shipgirl, behaviourName)
  self:SetData(shipgirl, behaviourName)
end

function BehaviourRetention:SetData(shipgirl, behaviourName)
  local si_id = shipgirl.showID
  local shipShow = configManager.GetDataById("config_ship_show", si_id)
  local shipInfo = Logic.shipLogic:GetShipInfoBySsId(si_id)
  local name = shipInfo.ship_name
  local model = shipShow.model_id
  local dapoId = configManager.GetDataById("config_ship_model", model).standard_dapo
  local dressupId = shipgirl.dressID
  local behaviourData = {}
  behaviourData.behavior_name = behaviourName
  behaviourData.ship_name = name
  behaviourData.damaged = dapoId == dressupId and 1 or 0
  self.m_data = behaviourData
  self:Begin(shipgirl)
end

function BehaviourRetention:Begin(shipgirl)
  self.beginTime = CSUIHelper.GetNowMillisecond()
  if weak_table[shipgirl] and weak_table[shipgirl] ~= self then
    weak_table[shipgirl]:BeIntterupt()
  end
  weak_table[shipgirl] = self
end

function BehaviourRetention:End(result)
  local data = self.m_data
  self.endTime = CSUIHelper.GetNowMillisecond()
  data.result = result
  data.time = (self.endTime - self.beginTime) / 1000
  RetentionHelper.Retention(PlatformDotType.behavior, data)
  for k, v in pairs(weak_table) do
    if v == self then
      weak_table[k] = nil
    end
  end
end

function BehaviourRetention:Complete()
  self:End(BehaviourRetentResultType.Complete)
end

function BehaviourRetention:BeIntterupt()
  self:End(BehaviourRetentResultType.Interrupt)
end

function BehaviourRetention:Skip()
  self:End(BehaviourRetentResultType.Skip)
end

function BehaviourRetention:OtherEnd()
  self:End(BehaviourRetentResultType.Other)
end

return BehaviourRetention
