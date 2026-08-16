local Pathfinder = class("logic.Pathfinder")

function Pathfinder:__Preheat()
  typeof(CS.Pathfinding.TriangleMeshNode)
  typeof(CS.Pathfinding.ABPath)
  typeof(CS.Unity.Mathematics.double3)
  typeof(CS.Pathfinding.NNInfo)
  typeof(CS.Pathfinding.NavmeshBase)
  typeof(CS.Pathfinding.NavmeshCut)
  typeof(CS.Pathfinding.VersionedMonoBehaviour)
  typeof(CS.Pathfinding.NavmeshClipper)
  typeof(CS.Pathfinding.Path)
  xlua.private_accessible(CS.AstarPath)
  xlua.private_accessible(CS.Pathfinding.Seeker)
  self.__pixelsPeruUnit = 100
  self.__pixelsPeruUnitInvert = 0.01
end

function Pathfinder:LoadMap(mapid)
  self.__GUID = 0
  self.__ob = {}
  self:__AStarInitialize(mapid)
  self.__astarPath = CS.AstarPath.active
  self.__astarPath.logPathResults = 4
  self:__NewSeeker()
  self.tileTrees = {}
  self.tile = nil
  for i = 0, self.__astarPath.graphs.Length - 1 do
    local navmesh = self.__astarPath.graphs[i]
    cast(navmesh, typeof(CS.Pathfinding.NavmeshBase))
    self.tile = navmesh:GetTiles()[0]
    table.insert(self.tileTrees, self.tile.bbTree)
  end
  local from = self:GetNearest(Vector3.New(0, 0, 0))
  local to = self:GetNearest(Vector3.New(3000, 3000, 0))
  self:FindPath(from, to)
  self:PointOnNavmesh(Vector3.New(1, 0, 0))
end

function Pathfinder:__NewSeeker()
  self.__seeker = CS.UnityEngine.Object.FindObjectOfType(typeof(CS.Pathfinding.Seeker))
end

function Pathfinder:FindPath(from, to)
  local LogEnable = CS.UnityEngine.Debug.unityLogger.logEnabled
  CS.UnityEngine.Debug.unityLogger.logEnabled = false
  local nodes = {}
  from = self:__ToWorld(from)
  to = self:__ToWorld(to)
  local v
  local path = self.__seeker:StartPath(from, to)
  CS.AstarPath.active:Update()
  local vp = path.vectorPath
  if vp ~= nil and vp.Count > 1 then
    for i = 0, vp.Count - 1 do
      v = vp[i]
      table.insert(nodes, Vector3.New(v.x, v.z, 0) * self.__pixelsPeruUnitInvert)
    end
  end
  CS.UnityEngine.Debug.unityLogger.logEnabled = LogEnable
  return nodes
end

function Pathfinder:CaculatePathImmediately()
  CS.AstarPath.active:PerformBlockingActions()
  CS.AstarPath.active.pathProcessor:TickNonMultithreaded()
  CS.AstarPath.active.pathReturnQueue:ReturnPaths(true)
end

function Pathfinder:UnLoad()
  self.__astarPath = nil
  self.__seeker = nil
  self.__ob = nil
  self.tileTrees = nil
  self.tile = nil
  self:__EndDebugMesh()
end

function Pathfinder:PointOnNavmesh(pos)
  pos = self:__ToWorld(pos)
  if self.tileTrees[1] ~= nil then
    local node = self.tileTrees[1]:QueryInside(pos, nil)
    return node ~= nil
  end
  return false
end

function Pathfinder:GetNearest(pos)
  pos = self:__ToWorld(pos)
  local info = CS.AstarPath.active:GetNearest(pos)
  return Vector3.New(info.position.x, info.position.z, 0) * self.__pixelsPeruUnitInvert
end

function Pathfinder:AddObstacle(pos, size)
  pos = self:__ToWorld(pos)
  local go = GameObject("ob")
  local cut = go:AddComponent(typeof(CS.Pathfinding.NavmeshCut))
  cut.type = 0
  cut.center = Vector3.New(0, 0, 0)
  cut.rectangleSize = size
  go.transform.position = pos
  go.transform:SetParent(self.__astarPath.transform)
  local guid = self:NewGUID()
  self.__ob[guid] = cut
  return guid
end

function Pathfinder:RemoveObstacle(guid)
  if self.__ob[guid] ~= nil then
    self.__ob[guid].gameObject:SetActive(false)
  end
  self.__ob[guid] = nil
end

function Pathfinder:MoveObstacle(guid, pos)
  pos = self:__ToWorld(pos)
  if self.__ob[guid] ~= nil then
    self.__ob[guid].transform.position = pos
  end
end

function Pathfinder:GetObstaclePosition(guid)
  if self.__ob[guid] ~= nil then
    local pos = self.__ob[guid].transform.position
    return Vector3.New(pos.x, pos.z, 0) * self.__pixelsPeruUnitInvert
  end
  return nil
end

function Pathfinder:NewGUID()
  self.__GUID = self.__GUID + 1
  return self.__GUID
end

function Pathfinder:__ToWorld(pos)
  local pos = pos * self.__pixelsPeruUnit
  return Vector3.New(pos.x, 0, pos.y)
end

function Pathfinder:initialize()
  self:__Preheat()
end

function Pathfinder:__AStarInitialize(mapID)
  if CS.AstarPath.active.threadCount ~= 0 then
    CS.AstarPath.active.threadCount = 0
    CS.AstarPath.active.scanOnStartup = false
    CS.AstarPath.active:Awake()
  end
  local data = configManager.GetDataById("config_nav2d", mapID)
  local bytes = CS.System.Convert.FromBase64String(data.data)
  CS.AstarPath.active.data:DeserializeGraphs(bytes)
end

local socket = require("socket")

function Pathfinder:__TestFinder()
  self:LoadMap("10003")
  logError("TriangleMeshNode num = " .. self.tile.nodes.Length)
  local t = socket.gettime()
  for i = 0, 10 do
    local x = math.random(0, 730)
    local z = math.random(0, 570)
    local nodes = self:FindPath(Vector2.New(x, 1), Vector2.New(z, z))
  end
  logError(socket.gettime() - t)
  t = socket.gettime()
  for i = 0, 10 do
    local x = math.random(0, 730)
    local z = math.random(0, 570)
    local nodes = self:FindPath(Vector2.New(x, 1), Vector2.New(z, z))
  end
  logError(socket.gettime() - t)
  t = socket.gettime()
  for i = 0, 1 do
    self:PointOnNavmesh(Vector2.New(math.random(0, 730), math.random(0, 570)))
  end
  logError(socket.gettime() - t)
  t = socket.gettime()
  local nodes = self:FindPath(Vector2.New(1482.2, 392.5625), Vector2.New(125, 874))
  for i = 1, #nodes do
    logError(nodes[i])
  end
  logError(socket.gettime() - t)
  local guid = self:AddObstacle(Vector3.New(1089, 658), Vector3.New(200, 200))
  self:MoveObstacle(guid, Vector2.New(0, 200))
  logError(self:GetObstaclePosition(guid))
  logError(self:__ToWorld(Vector2.New(5.34, 2.36)))
  logError(self:GetNearest(Vector2.New(-100, 2.36)))
  local __temptarget = GameObject.Find("__temptarget")
  local __temprole = GameObject.Find("__temprole")
  local __temprolemodel = GameObject.Find("__temprole/maurymodel")
  local __temptime = 0
  local __tempNodeIndex = 1
  local __tempSpeed = 2
  local __tempDeltatime = 0.03
  local __temptargetPos
  local __tempNodes = {}
  local __tempnodesCount = 0
  local time = Timer.New(function()
    if __temptargetPos ~= __temptarget.transform.position then
      __tempNodes = self:FindPath(__temprole.transform.position, __temptarget.transform.position)
      __tempNodeIndex = 1
      __tempnodesCount = #__tempNodes
      logError(string.format("node count = %d", __tempnodesCount))
      if __tempnodesCount == 0 then
        return
      end
      __temptargetPos = __temptarget.transform.position
      __temprole.transform.position = __tempNodes[__tempNodeIndex]
    end
    if __tempnodesCount <= __tempNodeIndex then
      return
    end
    local distance = __tempSpeed * __tempDeltatime
    while 0 < distance and __tempnodesCount >= __tempNodeIndex + 1 do
      local from = __tempNodes[__tempNodeIndex]
      local to = __tempNodes[__tempNodeIndex + 1]
      local offset = to - __temprole.transform.position
      local direct = Vector3.Normalize(offset)
      local pos = direct * distance + __temprole.transform.position
      if 0 < Vector3.Dot(Vector3.Normalize(pos - from), Vector3.Normalize(to - pos)) then
        __temprole.transform.position = pos
        distance = 0
      else
        __temprole.transform.position = to
        distance = distance - Vector3.Distance(__temprole.transform.position, to)
        __tempNodeIndex = __tempNodeIndex + 1
      end
      local forward = 1
      local rforward = 0
      if 0 > (__temprole.transform.position - from).x then
        forward = -1
        rforward = 180
      end
      __temprolemodel.transform.rotation = Quaternion.AngleAxis(rforward, Vector3.New(0, 10, 0))
    end
  end, __tempDeltatime, -1)
  time:Start()
end

function Pathfinder:__EndDebugMesh()
  if self.__draw ~= nil then
    self.__draw:Stop()
  end
  self.__draw = nil
end

function Pathfinder:__BeginDebugMesh()
  self:__CopyNodes()
  self.__draw = Timer.New(function()
    self:__DrawMesh()
  end, 0, -1)
  self.__draw:Start()
end

function Pathfinder:__CopyNodes()
  self.__nodes = {}
  for i = 0, self.tile.nodes.Length - 1 do
    local node = self.tile.nodes[i]
    local v0, v1, v2 = node:GetVertices()
    local v = {}
    v.v0 = Vector3.New(v0.x, v0.z, 0) * 1.0E-5
    v.v1 = Vector3.New(v1.x, v1.z, 0) * 1.0E-5
    v.v2 = Vector3.New(v2.x, v2.z, 0) * 1.0E-5
    table.insert(self.__nodes, v)
  end
end

function Pathfinder:__DrawMesh()
  local node, v0, v1, v2
  for i = 1, #self.__nodes do
    v0 = self.__nodes[i].v0
    v1 = self.__nodes[i].v1
    v2 = self.__nodes[i].v2
    CS.UnityEngine.Debug.DrawLine(v0, v1, CS.UnityEngine.Color.red)
    CS.UnityEngine.Debug.DrawLine(v1, v2, CS.UnityEngine.Color.red)
    CS.UnityEngine.Debug.DrawLine(v2, v0, CS.UnityEngine.Color.red)
  end
end

return Pathfinder
