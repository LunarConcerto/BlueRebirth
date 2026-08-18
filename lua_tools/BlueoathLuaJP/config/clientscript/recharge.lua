function ReturnParam(user, params)
  return params[1]
end

function ReturnOrderByDays(user, params)
  local mydays = user:GetCreateDay()
  if mydays <= params[1] then
    return params[2]
  else
    return params[3]
  end
end

function SupperMonthCardOrder(user, params)
  local haveCard = user:CheckBigMonthCard()
  if haveCard then
    return params[1]
  else
    return params[2]
  end
end
