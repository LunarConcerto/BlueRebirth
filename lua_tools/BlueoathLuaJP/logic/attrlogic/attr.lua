local Attr = class("logic.AttrLogic.Attr")

function Attr:AddAttr(dict, type, value)
  if nil == dict then
    return
  end
  if nil == dict[type] then
    dict[type] = value
  else
    dict[type] = dict[type] + value
  end
end

function Attr:GetAttr(dict, type)
  if nil == dict then
    return 0
  end
  if nil ~= dict[type] then
    return dict[type]
  end
  return 0
end

return Attr
