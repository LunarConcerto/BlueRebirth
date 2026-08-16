local BathNoticePage = class("UI.Bathroom.BathNoticePage")
local bathPage, callBack

function BathNoticePage:Init(owner)
  bathPage = owner
end

function BathNoticePage:OpenNotice(content, okCall)
  bathPage.tab_Widgets.obj_hint:SetActive(true)
  bathPage.tab_Widgets.txt_content.text = content
  UGUIEventListener.AddButtonOnClick(bathPage.tab_Widgets.btn_ok, self._ClickSure)
  UGUIEventListener.AddButtonOnClick(bathPage.tab_Widgets.btn_cancel, self._CloseNotice)
  UGUIEventListener.AddButtonToggleChanged(bathPage.tab_Widgets.tog_hint, self._NotHint)
  callBack = okCall
end

function BathNoticePage:_ClickSure()
  BathNoticePage:_CloseNotice()
  if callBack ~= nil then
    callBack()
  end
end

function BathNoticePage:_CloseNotice()
  UGUIEventListener.ClearButtonEventListener(bathPage.tab_Widgets.btn_ok.gameObject)
  UGUIEventListener.ClearButtonEventListener(bathPage.tab_Widgets.btn_cancel.gameObject)
  UGUIEventListener.ClearButtonEventListener(bathPage.tab_Widgets.tog_hint.gameObject)
  bathPage.tab_Widgets.obj_hint:SetActive(false)
end

function BathNoticePage:_NotHint()
  local closeHint = 0
  if bathPage.tab_Widgets.tog_hint.isOn then
    closeHint = 1
  else
    closeHint = 0
  end
  PlayerPrefs.SetInt("BathHintState", closeHint)
  PlayerPrefs.SetInt("BathHintTime", os.time())
end

return BathNoticePage
