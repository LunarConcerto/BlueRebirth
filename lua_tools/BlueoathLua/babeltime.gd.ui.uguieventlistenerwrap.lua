local m = {}

function m.getListener(go)
end

function m:OnSubmit(eventData)
end

function m:OnPointerEnter(eventData)
end

function m:OnPointerClick(eventData)
end

function m:CheckCanClick()
end

function m:CheckCanClickPos()
end

function m:CheckCanToggleChanged()
end

function m:OnPointerExit(eventData)
end

function m:OnPointerUp(eventData)
end

function m:OnPointerDown(eventData)
end

function m:OnDrag(eventData)
end

function m:OnSelect(eventData)
end

function m:OnUpdateSelected(eventData)
end

function m:OnDeselect(eventData)
end

function m:OnEndDrag(eventData)
end

function m:OnScrollRectChanged(vec2)
end

function m.Get(go)
end

function m.SetLuaButtonClick(btn, func)
end

function m.ClearButtonCB(btn)
end

function m.SetLuaSliderValueChange(slider, func)
end

function m.ClearSliderCB(slider)
end

function m.SetOnClickLuaEvent(obj_go, func)
end

function m.SetOnClickPositonLuaEvent(obj_go, func)
end

function m.SetOnSubmitLuaEvent(obj_go, func)
end

function m.SetOnHoverLuaEvent(obj_go, func)
end

function m.SetOnToggleChangedLuaEvent(obj_go, func)
end

function m.SetOnSliderChangedLuaEvent(obj_go, func)
end

function m.SetOnScrollbarChangedLuaEvent(obj_go, func)
end

function m.SetOnDrapDownChangedLuaEvent(obj_go, func)
end

function m.SetOnInputFieldChangedLuaEvent(obj_go, func)
end

function m.SetOnLongPressLuaEvent(obj_go, func)
end

function m.SetOnPointUpLuaEvent(obj_go, func)
end

function m.SetOnPointDownLuaEvent(obj_go, func)
end

function m.SetOnDragLuaEvent(obj_go, func)
end

function m.SetOnEndDragLuaEvent(obj_go, func)
end

function m.SetOnScrollRectChangedLuaEvent(obj_go, func)
end

function m.SetGroupOnClickLuaEvent(tabEvent)
end

function m.ClearPointerUp(obj_go)
end

function m.ClearListener(obj_go)
end

function m.ClearDragListener(obj_go)
end

function m.SetEffectFinishLuaEvent(obj_go, func)
end

return m
