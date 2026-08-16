local cameraManager2d = class("game2d.cameraManager2d")

function cameraManager2d:InitData(cam, callback)
  self.state = 1
  self.cam = cam
  self:Move()
  LateUpdateBeat:Add(self.__tick, self)
end

function cameraManager2d:__tick()
  if self.state == 0 then
    return
  end
  local cameraLimit = GameManager2d:GetCameraLimit()
  local left = cameraLimit[1][1]
  local right = cameraLimit[1][2]
  local down = cameraLimit[2][1]
  local up = cameraLimit[2][2]
  local left_up = Vector3.New(left, up, self.cam.transform.position.z)
  local right_up = Vector3.New(right, up, self.cam.transform.position.z)
  local right_down = Vector3.New(right, down, self.cam.transform.position.z)
  local left_down = Vector3.New(left, down, self.cam.transform.position.z)
  local gameConfig = GameManager2d:GetConfig()
  local camera_speed = gameConfig.camera_speed
  if self.state == 1 then
    local from_to = right_up - self.cam.transform.position
    if from_to.magnitude < Time.deltaTime * camera_speed then
      self.cam.transform.position = right_up
      self.state = 2
    else
      self.cam.transform.position = self.cam.transform.position + Vector3.New(1, 0, 0) * Time.deltaTime * camera_speed
    end
  elseif self.state == 2 then
    local from_to = right_down - self.cam.transform.position
    if from_to.magnitude < Time.deltaTime * camera_speed then
      self.cam.transform.position = right_down
      self.state = 3
    else
      self.cam.transform.position = self.cam.transform.position + Vector3.New(0, -1, 0) * Time.deltaTime * camera_speed
    end
  elseif self.state == 3 then
    local from_to = left_down - self.cam.transform.position
    if from_to.magnitude < Time.deltaTime * camera_speed then
      self.cam.transform.position = left_down
      self.state = 0
      self:Update()
      if self.callback then
        self.callback()
      end
    else
      self.cam.transform.position = self.cam.transform.position + Vector3.New(-1, 0, 0) * Time.deltaTime * camera_speed
    end
  end
end

function cameraManager2d:Move(callback)
  self.state = 1
  self.callback = callback
  local cameraLimit = GameManager2d:GetCameraLimit()
  local left = cameraLimit[1][1]
  local right = cameraLimit[1][2]
  local down = cameraLimit[2][1]
  local up = cameraLimit[2][2]
  local left_up = Vector3.New(left, up, self.cam.transform.position.z)
  self.cam.transform.position = left_up
end

function cameraManager2d:Update()
  if self.state > 0 then
    return
  end
  local pos = PlayerManager2d:GetPlayerPos()
  local x = pos.x
  local y = pos.y
  local cameraLimit = GameManager2d:GetCameraLimit()
  if x > cameraLimit[1][2] then
    x = cameraLimit[1][2]
  end
  if x < cameraLimit[1][1] then
    x = cameraLimit[1][1]
  end
  if y > cameraLimit[2][2] then
    y = cameraLimit[2][2]
  end
  if y < cameraLimit[2][1] then
    y = cameraLimit[2][1]
  end
  self.cam.transform.position = Vector3.New(x, y, self.cam.transform.position.z)
end

function cameraManager2d:Destroy()
  LateUpdateBeat:Remove(self.__tick, self)
  self.cam = nil
end

return cameraManager2d
