local MathLogic = class("logic.MathLogic")

function MathLogic:initialize()
end

function MathLogic:FormatNumber(num)
  local a, b = math.modf(num)
  if 0 < b then
    return num
  else
    return a
  end
end

return MathLogic
