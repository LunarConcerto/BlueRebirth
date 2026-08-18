local m = {}

function m.Release()
end

function m:CreateOneBtnBox(content, btnName, callBack, layer)
end

function m:CreateTwoBtnBox(content, yes, no, callBack, layer)
end

function m:ForceCloseBox()
end

function m:CloseBox()
end

function m:CreateOneButtonBoxForAllTime(btnName, content, callback, forceWaitCallBackTime)
end

function m:CreatOneButtonBox(btnName, content, callBack)
end

function m:CreatYesAndNoBox(yes, no, content, callBack, isChange)
end

function m:CreateNormalBox(text)
end

function m:CreateOneButtonBox(text, btnCallBack)
end

function m:Tips(text)
end

function m:CloseTips()
end

function m:CloseAllOpenBox()
end

function m:DestroyAllBox()
end

return m
