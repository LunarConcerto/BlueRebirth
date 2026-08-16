UIHelper = {}

function UIHelper.OpenPage(pagename, param, layer, tostack)
  local page
  local fromPage = UIPageManager:GetCurrFullScreenPage()
  UIHelper.SwitchPage(fromPage, pagename, function()
    page = UIHelper.OpenPageImp(pagename, param, layer, tostack)
  end)
  return page
end

function UIHelper.GetCurMainPageName()
  return UIPageManager:GetCurrFullScreenPage()
end

function UIHelper.OpenPageImp(pagename, param, layer, tostack)
  local temp = OCDictionary("luaParam", param)
  layer = layer or 1
  if tostack == nil then
    tostack = true
  end
  local page = UIPageManager:Open(pagename, temp, layer, tostack)
  eventManager:SendEvent(LuaEvent.OpenPage, pagename)
  return page
end

function UIHelper.BaseOpen(name, param, layer)
  local temp = OCDictionary("luaParam", param)
  UIPageManager:BaseOpen(name, temp, layer)
  return page
end

function UIHelper.PagePop()
  UIPageManager:PagePop()
end

function UIHelper.ClosePage(pagename, closeParam)
  local toPage = UIPageManager:GetReturnPageName()
  if UIHelper.checkReturnPage(pagename, toPage, closeParam) then
    UIHelper.SwitchPage(pagename, toPage, function()
      UIHelper.ClosePageImp(pagename, closeParam)
    end)
  end
end

function UIHelper.ClosePageImp(pagename, closeParam)
  local temp = OCDictionary("luaParam", closeParam)
  UIPageManager:Close(pagename, temp)
  collectgarbage("collect")
end

function UIHelper.Back(closeParam)
  local fromPage = UIPageManager:GetCurrFullScreenPage()
  local toPage = UIPageManager:GetReturnPageName()
  if UIHelper.checkReturnPage(fromPage, toPage) then
    UIHelper.SwitchPage(fromPage, toPage, function()
      local temp = OCDictionary("luaParam", closeParam)
      UIPageManager:Close(fromPage, temp)
      collectgarbage("collect")
    end)
  end
end

function UIHelper.GetCloseParam()
  local param = UIPageManager:GetLuaCloseParam()
  return param
end

function UIHelper.CloseCurrentPage(closeParam)
  local fromPage = UIPageManager.CurrPageName
  local toPage = UIPageManager:GetReturnPageName()
  if UIHelper.checkReturnPage(fromPage, toPage, closeParam) then
    UIHelper.SwitchPage(fromPage, toPage, function()
      UIHelper.CloseCurrPageImp(closeParam)
    end)
  end
end

function UIHelper.checkReturnPage(fromPage, toPage, closeParam)
  if toPage == nil or toPage == "" then
    UIHelper.ClosePageImp(fromPage, closeParam)
    return false
  end
  return true
end

function UIHelper.CloseCurrPageImp(closeParam)
  local temp = OCDictionary("luaParam", closeParam)
  UIPageManager:CloseCurrPage(temp)
  collectgarbage("collect")
end

function UIHelper.CloseByLayer(layer)
  UIPageManager:CloseByLayer(layer)
end

function UIHelper.GetStackPageCount()
  return UIPageManager.StackPageCount
end

function UIHelper.CloseAllPage(doClose)
  doClose = doClose ~= nil and doClose or false
  UIPageManager:CloseAll()
end

function UIHelper.GetReturnPageName()
  local temp = UIPageManager:GetReturnPageName()
  if temp == "" then
    temp = "HomePage"
  end
  return temp
end

function UIHelper.CreateSubPart(objSource, transParent, totalNum, exeFunc)
  totalNum = totalNum == nil and 0 or totalNum
  CSUIHelper.CreatePart(objSource, transParent, totalNum, exeFunc)
end

function UIHelper.SetImage(image, path, bNativeSize)
  if not path or path == "" then
    logError("UIHelper.SetImage error, image:%s, path:%s", image, path)
  end
  CSUIHelper.SetImage(image, path, bNativeSize or false)
end

function UIHelper.SetImageByQuality(image, qualityId)
  CSUIHelper.SetImage(image, QualityIcon[qualityId])
end

function UIHelper.SetTexture(name, go, prefab)
  CSUIHelper.SetTexture(name, go, prefab)
end

function UIHelper.AddToggleGroupChangeValueEvent(objToggleGroup, lt, param, callback)
  objToggleGroup:RegisterActiveToggleChange(function(nIndex)
    callback(lt, nIndex, param)
  end)
end

function UIHelper.CreateGameObject(source, parent, bSetOtherCanvas)
  bSetOtherCanvas = bSetOtherCanvas or false
  return CSUIHelper.CreateObj(source, parent, bSetOtherCanvas)
end

function UIHelper.DisableButton(btn, disabled)
  btn.interactable = not disabled
  local obj = btn.gameObject
  local ev = obj:GetComponent(BabelTime_GD_UI_UGUIEventListener.GetClassType())
  if ev == nil then
    return
  end
  ev.enabled = not disabled
end

function UIHelper.SetLayer(go, layer)
  go.layer = layer
  local transform = go.transform
  local childs = transform:GetComponentsInChildren(Transform.GetClassType(), true)
  for i = 0, childs.Length - 1 do
    childs[i].gameObject.layer = layer
  end
end

function UIHelper.Create3DModel(createParam, rawImg, cameraParam)
  return UI3DModelManager.Create3DModel(UI3DModelType.ShipGirl, createParam, rawImg, cameraParam)
end

function UIHelper.Create3DModelNoRT(createParam, cameraParam, renderToGlobal, tex, dx, dy)
  local model = UI3DModelManager.Create3DModel(UI3DModelType.ShipGirl, createParam, nil, cameraParam, true, renderToGlobal)
  if tex ~= nil then
    model:SetBackgroundSize(dx or 1, dy or 1)
    model:SetBackgroundTex(tex)
    model:SetPostEffect()
  end
  return model
end

function UIHelper.CreateOther3DModel(createParam, rawImg, cameraParam)
  return UI3DModelManager.Create3DModel(UI3DModelType.Other, createParam, rawImg, cameraParam)
end

function UIHelper.CreateOther3DModelNoRT(createParam, cameraParam, renderToGlobal, tex, dx, dy, commonCamParam)
  local model = UI3DModelManager.Create3DModel(UI3DModelType.Other, createParam, nil, cameraParam, true, renderToGlobal, commonCamParam)
  if tex ~= nil then
    model:SetBackgroundSize(dx or 1, dy or 1)
    model:SetBackgroundTex(tex)
    model:SetPostEffect()
  end
  return model
end

function UIHelper.Close3DModel(model)
  UI3DModelManager.Close3DModel(model)
end

function UIHelper.GetString(strId)
  local str = configManager.GetDataById("config_language", strId)
  if str == nil then
    logError("strId is error: " .. strId)
    return ""
  else
    return str.content
  end
end

function UIHelper.SetUILock(bIsLock)
  CSUIHelper.SetUILock(bIsLock)
end

function UIHelper.SetText(txt, str)
  txt.text = NonBreakingSpaceReplace(str)
end

function UIHelper.SetLocText(txt, strId, ...)
  local str = UIHelper.GetString(strId)
  str = NonBreakingSpaceReplace(str)
  txt.text = string.format(str, ...)
end

function UIHelper.GetLocString(strId, ...)
  local str = UIHelper.GetString(strId)
  return string.format(str, ...)
end

function UIHelper.SetInfiniteItemParam(iilCom, objSource, totalNum, exeFunc)
  totalNum = totalNum == nil and 0 or totalNum
  iilCom:SetParam(objSource, function(objCBParam)
    exeFunc(objCBParam.tblParts, objCBParam.startIndex, objCBParam.endIndex)
  end, totalNum)
end

function UIHelper.RefreshInfiniteItem(iilCom)
  iilCom:Refresh()
end

function UIHelper.SetTableViewParam(tableView, objPrefab, totalCount, minHeight, fillItemCB, getHeightCB)
  totalCount = totalCount == nil and 0 or totalCount
  tableView:SetParam(objPrefab, totalCount, minHeight, fillItemCB, getHeightCB)
end

function UIHelper.GetCountDownStr(left)
  local sec = left % 60
  left = math.floor(left / 60)
  local min = left % 60
  left = math.floor(left / 60)
  local hour = left
  return string.format("%02d:%02d:%02d", hour, min, sec)
end

function UIHelper.GetTimeStr(left)
  local str = ""
  local sec = Mathf.ToInt(left % 60)
  left = math.floor(left / 60)
  local min = Mathf.ToInt(left % 60)
  left = math.floor(left / 60)
  local hour = Mathf.ToInt(left % 24)
  if 0 < hour then
    str = hour .. "\229\176\143\230\151\182"
  end
  if 0 < min then
    str = str .. min .. "\229\136\134"
  end
  if 0 < sec then
    str = str .. sec .. "\231\167\146"
  end
  return str
end

function UIHelper.SetTextColor(txt, str, Color)
  str = "<color=#" .. Color .. ">" .. str .. "</color>"
  txt.text = NonBreakingSpaceReplace(str)
end

function UIHelper.SetTextColorByBool(txt, str, ColorA, ColorB, Bool)
  Bool = Bool or false
  local Color
  if Bool then
    local config = configManager.GetDataById("config_color", ColorA)
    Color = config.rgba
  else
    local config = configManager.GetDataById("config_color", ColorB)
    Color = config.rgba
  end
  str = "<color=#" .. Color .. ">" .. str .. "</color>"
  txt.text = NonBreakingSpaceReplace(str)
end

function UIHelper.SetColor(str, Color)
  return "<color=#" .. Color .. ">" .. str .. "</color>"
end

function UIHelper.SetTextSize(txt, str, Size)
  str = "<size=" .. Size .. ">" .. str .. "</size>"
  txt.text = NonBreakingSpaceReplace(str)
end

function UIHelper.SetTextAlign(txt, align)
  txt.alignment = align
end

function UIHelper.SetStar(obj, trans, count)
  UIHelper.CreateSubPart(obj, trans, count, function(nIndex, tabPart)
  end)
end

function UIHelper.SetEquipStar(obj, trans, count)
  UIHelper.CreateSubPart(obj, trans, count, function(nIndex, tabPart)
  end)
end

function UIHelper.GetIntroduce(content, num)
  if num < utf8.len(content) then
    return utf8.sub(content, 1, num) .. "..."
  else
    return content
  end
end

function UIHelper.SwitchPage(fromPage, toPage, func)
  local switchType = UIHelper.GetSwitchType(fromPage, toPage)
  if switchType then
    TransitionManager.Open(TransitionType.Switch, {switchType, func})
  else
    func()
  end
end

function UIHelper.GetSwitchType(fromPage, toPage)
  local configTable = UIHelper.SwitchTable()
  if configTable[fromPage] ~= nil then
    return configTable[fromPage][toPage]
  end
  return nil
end

function UIHelper.SwitchTable()
  local srcTable = configManager.GetData("config_page_switch_animation")
  local resTable = {}
  for k, v in pairs(srcTable) do
    if resTable[v.from_page] == nil then
      resTable[v.from_page] = {}
    end
    resTable[v.from_page][v.to_page] = v.switch_type
  end
  return resTable
end

function UIHelper.CreateUIEffect(resPath, transParent)
  local eff = GR.objectPoolManager:LuaGetGameObject(resPath)
  if transParent then
    eff.transform:SetParent(transParent, false)
  end
  return eff
end

function UIHelper.DestroyUIEffect(effectObj)
  GR.objectPoolManager:LuaUnspawn(effectObj)
end

function UIHelper.IsExistPage(pageName)
  return UIPageManager:IsExistPage(pageName)
end

function UIHelper.AddTween(obj, tweenType)
  local tween
  if tweenType == ETweenType.ETT_POSITION then
    tween = obj:AddComponent(TweenPosition.GetClassType())
  elseif tweenType == ETweenType.ETT_ALPHA then
    tween = obj:AddComponent(TweenAlpha.GetClassType())
  elseif tweenType == ETweenType.ETT_SCALE then
    tween = obj:AddComponent(TweenScale.GetClassType())
  elseif tweenType == ETweenType.ETT_ROTATION then
    tween = obj:AddComponent(TweenRotation.GetClassType())
  elseif tweenType == ETweenType.ETT_NUMBER then
    tween = obj:AddComponent(TweenNumber.GetClassType())
  elseif tweenType == ETweenType.ETT_SIZEDELTA then
    tween = obj:AddComponent(TweenSizeDelta.GetClassType())
  end
  return tween
end

function UIHelper.RemoveTween(tween)
  GameObject.Destroy(tween)
end

function UIHelper.GetTween(obj, tweenType, tweenName)
  return CSUIHelper.GetTweener(obj, tweenType, tweenName)
end

function UIHelper.VibrateTrigger()
  CSUIHelper.VibrateTrigger()
end

function UIHelper.GetUIRootTrans()
  return UIManager.rootUI:GetComponent(RectTransform.GetClassType())
end

function UIHelper.AdapteShipRT(trans)
  local curHeight = UIHelper.GetUIRootTrans().rect.height
  local orgHeight = trans.rect.height
  local factor = curHeight / orgHeight
  trans.localScale = Vector3.New(factor, factor, 1)
end

function UIHelper.CaptureScreen()
  return CSUIHelper.CaptureScreen()
end

function UIHelper.GetShareIcon()
  return CSUIHelper.GetShareIcon()
end

function UIHelper.LoadShareIcon()
  return CSUIHelper.LoadShareIcon()
end

function UIHelper.GetAdapt2DPosition(pos)
  local factorX = pos.x / Screen.width
  local factorY = pos.y / Screen.height
  return Vector2.New(factorX * UIManager:GetUIWidth(), factorY * UIManager:GetUIHeight())
end

function UIHelper.Check3dTouch()
  return CSUIHelper.Check3dTouch()
end

function UIHelper.GetScondCount(left)
  local sec = left % 60
  left = math.floor(left / 60)
  local min = left % 60
  return string.format("%02d:%02d", min, sec)
end

function UIHelper.TryFindChildTransform(baseTrans, name)
  for i = 0, baseTrans.childCount - 1 do
    if baseTrans:GetChild(i).name == name then
      return baseTrans:GetChild(i)
    else
      local trans = UIHelper.TryFindChildTransform(baseTrans:GetChild(i), name)
      if trans ~= nil then
        return trans
      end
    end
  end
  return nil
end

function UIHelper.GenerateQRImageConstantSize(url)
  if UIHelper.QRImg == nil then
    UIHelper.QRImg = CSUIHelper.GenerateQRImageConstantSize(url)
  end
  return UIHelper.QRImg
end

function UIHelper.ShowReward(reward, textNum, imgIcon, imgQuality, textName)
  local num = reward.Num
  local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
  local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
  if textNum then
    UIHelper.SetText(textNum, num)
  end
  UIHelper.SetImage(imgIcon, display.icon)
  UIHelper.SetImageByQuality(imgQuality, display.quality)
  if textName then
    UIHelper.SetText(textName, display.name)
  end
end

function UIHelper.IsSubPageOpen(pPageName, sPageName)
  return UIPageManager:HasShowSubPage(pPageName, sPageName)
end

function UIHelper.IsPageOpen(strPageName)
  return UIPageManager:HasShowPages(strPageName)
end

function UIHelper.GetTabPart(luapartObj)
  CSUIHelper.ClearLuaItemListner(luapartObj)
  local tabPart = luapartObj:GetLuaTableParts()
  return tabPart
end

function UIHelper.InitAndPlayVideo(strPath, objDisplayUGUI, fucnCB, funcDefault)
  local funcCallBack = function()
    local dotInfo = {info = strPath}
    RetentionHelper.Retention(PlatformDotType.cgFinish, dotInfo)
    if fucnCB then
      fucnCB()
    end
  end
  local objProcess = VideoPlayManager:InitAndPlay(strPath, funcCallBack, funcDefault, objDisplayUGUI)
  return objProcess
end

function UIHelper.InitAndPlayVideoOnMat2(strPath, objMat, funcCB, funcDefault)
  local msgPort = CS.BabelTime.GD.Video.NormalLuaPlayerMessagePort(funcCB, funcDefault)
  local objProcess = VideoPlayManager:InitAndPlay(strPath, msgPort)
  local mediaPlayer = objProcess:GetMediaPlayer()
  objMat._media = mediaPlayer
  objMat.enabled = true
  return objProcess
end

function UIHelper.InitAndPlayVideoOnMat(strPath, objMat, funcCB, funcDefault, objDisplayUGUI)
  local objProcess = VideoPlayManager:InitAndPlay(strPath, funcCB, funcDefault, objDisplayUGUI)
  local mediaPlayer = objProcess:GetMediaPlayer()
  objMat.Player = mediaPlayer
  objMat.enabled = true
  objDisplayUGUI._mediaPlayer = nil
  return objProcess
end

function UIHelper.ContinueVideo(objVideoPlayProcess)
  VideoPlayManager:Continue(objVideoPlayProcess)
end

function UIHelper.PauseVideo(objVideoPlayProcess)
  VideoPlayManager:Pause(objVideoPlayProcess)
end

function UIHelper.StopVideo(objVideoPlayProcess)
  VideoPlayManager:Stop(objVideoPlayProcess)
end

function UIHelper.DestroyVideoProcess(objVideoPlayProcess)
  VideoPlayManager:Destroy(objVideoPlayProcess)
end

function UIHelper.PlayNewVideo(objVideoPlayProcess, strPath)
  local mediaPlayer = objVideoPlayProcess:GetMediaPlayer()
  local assetPath = CS.HotPatchPathGetter.GetAssetPath(strPath)
  mediaPlayer:OpenVideoFromFile(mediaPlayer.m_VideoLocation, assetPath)
end

function UIHelper.SetVideoLoop(objVideoPlayProcess, bLoop)
  if IsNil(objVideoPlayProcess) then
    return
  end
  local mediaPlayer = objVideoPlayProcess:GetMediaPlayer()
  mediaPlayer.Control:SetLooping(bLoop)
end

function UIHelper.IsVideoPause(objVideoPlay)
  if IsNil(objVideoPlay) then
    return
  end
  local mediaPlayer = objVideoPlay:GetMediaPlayer()
  if IsNil(mediaPlayer) == nil then
    return
  end
  local objControl = mediaPlayer.Control
  if IsNil(objControl) then
    return
  end
  local bPaused = objControl:IsPaused()
  return bPaused
end

function UIHelper.GetColor(colorString)
  local r = tonumber(string.sub(colorString, 1, 2), 16) / 255
  local g = tonumber(string.sub(colorString, 3, 4), 16) / 255
  local b = tonumber(string.sub(colorString, 5, 6), 16) / 255
  return Color.New(r, g, b)
end

function UIHelper.SetDDCaptionText(ddwidget, str)
  ddwidget.captionText.text = NonBreakingSpaceReplace(str)
end

function UIHelper.AddDDOptions(ddwidget, names)
  CSUIHelper.SetDropdownOptions(ddwidget, names)
end

function UIHelper.AddDDOptionsWithImg(ddwidget, names, images)
  CSUIHelper.SetDropdownOptions(ddwidget, names, images)
end

function UIHelper.AddDDValue(ddwidget, value)
  ddwidget.value = value
end
