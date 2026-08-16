local BarrageText = class("UI.BarrageText")
local PrefabPath = "ui/pages/barragetext"

function BarrageText:Init(options)
  local parent = options.parent
  if not parent then
    return
  end
  self.page = options.page
  self.onDestroy = options.onDestroy
  options.content = options.content or "66666"
  self.obj = GR.objectPoolManager:LuaGetGameObject(PrefabPath)
  self.border = self.obj:GetComponentInChildren(UIImage.GetClassType())
  self.border.enabled = tonumber(options.params.uid) == Data.userData:GetUserUid()
  self.tween = self.obj:GetComponent(TweenPosition.GetClassType())
  self.text = self.obj:GetComponent(UIText.GetClassType())
  if options.color and options.size then
    local content = UIHelper.SetColor(options.content, options.color)
    UIHelper.SetTextSize(self.text, content, options.size)
  else
    UIHelper.SetText(self.text, options.content)
  end
  self.rightPos = parent.right.localPosition
  self.width = self.text.preferredWidth
  local leftPos = parent.left.localPosition
  leftPos.x = leftPos.x - self.width
  self.leftPos = leftPos
  local speed = options.speed
  local totalWidth = self.rightPos.x - self.leftPos.x
  self.duration = totalWidth / speed
end

function BarrageText:GetWidth()
  return self.width
end

function BarrageText:Update(options)
  if options.color and options.size then
    local content = UIHelper.SetColor(options.content, options.color)
    UIHelper.SetTextSize(self.text, content, options.size)
  end
end

function BarrageText:Move()
  self.tween:ResetToInit()
  self.tween.from = self.rightPos
  self.tween.to = self.leftPos
  self.tween.duration = self.duration
  self.tween:Play(true)
  self.page:PerformDelay(self.duration, function()
    self:Destroy()
  end)
end

function BarrageText:Destroy()
  if self.obj then
    GR.objectPoolManager:LuaUnspawn(self.obj)
    self.obj = nil
    self.border = nil
    self.text = nil
    self.page = nil
  end
  if self.onDestroy then
    self.onDestroy(self)
  end
end

return BarrageText
