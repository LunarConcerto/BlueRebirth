NoticePage = class("UI.NoticePage", LuaUIPage)

function NoticePage:DoInit()
end

function NoticePage:DoOnOpen()
end

function NoticePage:RegisterAllEvent()
end

function NoticePage:DoOnShowContent()
  local timer = FrameTimer.New(function()
    self:_SetAlign()
  end, 1, 1)
  timer:Start()
end

function NoticePage:_SetAlign()
  local widgets = self:GetWidgets()
  local row = widgets.tx_content.cachedTextGenerator.lineCount
  if row == 1 then
    UIHelper.SetTextAlign(widgets.tx_content, ETextAnchor.MiddleCenter)
  elseif 1 < row then
    UIHelper.SetTextAlign(widgets.tx_content, ETextAnchor.MiddleLeft)
  end
end

function NoticePage:DoOnHide()
end

function NoticePage:DoOnClose()
end

return NoticePage
