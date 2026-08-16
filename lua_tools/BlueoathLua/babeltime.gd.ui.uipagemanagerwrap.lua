local m = {}

function m:Open(pageName, param, layer, toStack)
end

function m:Close(pageName, param)
end

function m:HasShowPages(pageName)
end

function m:HasShowSubPage(pPageName, sPageName)
end

function m:GetPageFromHistory(pageName)
end

function m:CloseByLayer(layer, toStack)
end

function m:IsExistPage(name)
end

function m:GetPage(name, layer, to)
end

function m:GetCurrFullScreenPage()
end

function m:GetReturnPageName()
end

function m:CloseAll()
end

return m
