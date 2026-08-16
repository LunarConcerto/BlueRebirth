UGUIEventListener = {}

function UGUIEventListener.AddButtonOnClick(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnClickLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnClickPosition(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnClickPositonLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnDelayPress(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnDelayPressLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnLongPress(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnLongPressLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnPointUp(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnPointUpLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnPointDown(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnPointDownLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonToggleChanged(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnToggleChangedLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddEffectFinishCallBack(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetEffectFinishLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddOnDrag(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnDragLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddOnEndDrag(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnEndDragLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddOnSliderChanged(obj_GameObj, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnSliderChangedLuaEvent(obj_GameObj.gameObject, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddGropButtonOnClick(tabEvent)
  BabelTime_GD_UI_UGUIEventListener.SetGroupOnClickLuaEventSettleMentService(tabEvent)
end

function UGUIEventListener.ClearButtonEventListener(obj_GameObj)
  BabelTime_GD_UI_UGUIEventListener.ClearListener(obj_GameObj)
end

function UGUIEventListener.ClearDragListener(obj_GameObj)
  BabelTime_GD_UI_UGUIEventListener.ClearDragListener(obj_GameObj)
end

function UGUIEventListener.AddDropDownOnSelect(btn_babelbtn, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetOnDrapDownChangedLuaEvent(btn_babelbtn, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.AddButtonOnClickCB(btn_babelbtn, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetLuaButtonClick(btn_babelbtn, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.ClearBabelButtonEventListener(btn_babelbtn)
  BabelTime_GD_UI_UGUIEventListener.ClearButtonCB(btn_babelbtn)
end

function UGUIEventListener.AddOnSliderChangedCB(slider, callBackFun, target, param)
  BabelTime_GD_UI_UGUIEventListener.SetLuaSliderValueChange(slider, UGUIEventListener.Wrapper(callBackFun, target, param))
end

function UGUIEventListener.ClearSliderEventListener(slider)
  BabelTime_GD_UI_UGUIEventListener.ClearSliderCB(slider)
end

function UGUIEventListener.RemoveButtonOnPointUpListener(obj_GameObj)
  BabelTime_GD_UI_UGUIEventListener.ClearPointerUp(obj_GameObj.gameObject)
end

function UGUIEventListener.Wrapper(callback, target, ...)
  local originParma = {
    ...
  }
  local finalFunc = function(...)
    local preParam = {
      ...
    }
    for i, v in ipairs(originParma) do
      table.insert(preParam, v)
    end
    if target then
      callback(target, table.unpack(preParam))
    else
      callback(table.unpack(preParam))
    end
  end
  return finalFunc
end

return UGUIEventListener
