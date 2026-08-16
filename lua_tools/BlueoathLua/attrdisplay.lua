function basicattr_display(user, params, ProgramParam)
  local Basic_Attr_Id = params[1]
  
  local Percent_Attr_Id = params[2]
  local Basic_Attr = ProgramParam[Basic_Attr_Id]
  local Percent_Attr = ProgramParam[Percent_Attr_Id]
  if Basic_Attr ~= nil and Percent_Attr ~= nil then
    local Attr = Basic_Attr * (1 + Percent_Attr / 10000)
    return math.ceil(Attr)
  else
    return math.ceil(Basic_Attr)
  end
end

function defense_display(user, params, ProgramParam)
  local Advance_Attr_Id = params[1]
  local Basic_Attr_Id = params[2]
  local Percent_Attr_Id = params[3]
  local Basic_Attr = ProgramParam[Basic_Attr_Id]
  local Advance_Attr = ProgramParam[Advance_Attr_Id]
  local Percent_Attr = ProgramParam[Percent_Attr_Id]
  local Attr = 0
  if Advance_Attr ~= nil then
    Attr = Advance_Attr + Basic_Attr
  else
    Attr = Basic_Attr
  end
  if Percent_Attr ~= nil then
    local Final_Attr = Attr * (1 + Percent_Attr)
    return Final_Attr
  end
  return math.ceil(Attr)
end

function specialattr_display(user, params, ProgramParam)
  local Special_Attr_Id = params[1]
  local Special_Attr = ProgramParam[Special_Attr_Id]
  return Special_Attr
end

function range_display(user, params, ProgramParam)
  local range_Attr_Id = params[1]
  local range_Attr = ProgramParam[range_Attr_Id]
  if range_Attr == 1 then
    local tab_1 = configManager.GetDataById("config_language", 1500019)
    return tab_1.content
  elseif range_Attr == 2 then
    local tab_2 = configManager.GetDataById("config_language", 1500020)
    return tab_2.content
  elseif range_Attr == 3 then
    local tab_3 = configManager.GetDataById("config_language", 1500021)
    return tab_3.content
  else
    local tab_4 = configManager.GetDataById("config_language", 1500022)
    return tab_4.content
  end
end

function storeplane_display(user, params, ProgramParam)
  local storeplane_Id_1 = params[1]
  local storeplane_Id_2 = params[2]
  local storeplane_Id_3 = params[3]
  local storeplane_num_1 = ProgramParam[storeplane_Id_1]
  local storeplane_num_2 = ProgramParam[storeplane_Id_2]
  local storeplane_num_3 = ProgramParam[storeplane_Id_3]
  local storeplane_num = storeplane_num_3 + storeplane_num_2 + storeplane_num_1
  return storeplane_num_3
end

function speed_display(user, params, ProgramParam)
  local speed_Attr_Id = params[1]
  local speed_Attr = ProgramParam[speed_Attr_Id]
  local speed_Attr_show = math.floor(speed_Attr / 0.65 / 100)
  return speed_Attr_show
end

function variable_1_display(user, params, ProgramParam)
  local variable_Id_1 = params[1]
  local variable_Id_2 = params[2]
  local variable_1 = ProgramParam[variable_Id_1]
  local variable_2 = ProgramParam[variable_Id_2]
  if variable_1 ~= nil and variable_2 ~= nil then
    local variable_show = variable_1 + variable_2
    return variable_show
  else
    return variable_1
  end
end

function variable_2_display(user, params, ProgramParam)
  local variable_Id_1 = params[1]
  local variable_Id_2 = params[2]
  local variable_1 = ProgramParam[variable_Id_1]
  local variable_2 = ProgramParam[variable_Id_2]
  local tab_1 = configManager.GetDataById("config_language", 1500023)
  if variable_1 ~= nil and variable_2 ~= nil then
    local variable_show_1 = (variable_1 + variable_2 * 1000) / 1000
    return math.ceil(variable_show_1)
  else
    local variable_show_2 = variable_1 / 1000
    return math.ceil(variable_show_2)
  end
end

function spareplan_display(user, params, ProgramParam)
  local spareplan_Id_1 = params[1]
  local spareplan_Id_2 = params[2]
  local spareplan_Id_3 = params[3]
  local spareplan_Id_4 = params[4]
  local spareplan_1 = ProgramParam[spareplan_Id_1]
  local spareplan_2 = ProgramParam[spareplan_Id_2]
  local spareplan_3 = ProgramParam[spareplan_Id_3]
  local spareplan_4 = ProgramParam[spareplan_Id_4]
  if spareplan_1 == nil then
    spareplan_1 = 0
  end
  if spareplan_2 == nil then
    spareplan_2 = 0
  end
  if spareplan_3 == nil then
    spareplan_3 = 0
  end
  if spareplan_4 == nil then
    spareplan_4 = 0
  end
  return spareplan_1 + spareplan_2 + spareplan_3 + spareplan_4 * 3
end

function ValueEffectScript_1(user, params, level)
  local initial_value = params[1]
  local growth_value = params[2]
  return initial_value + growth_value * (level - 1)
end

function ValueEffectScript_2(user, params, level)
  local attr = level[1]
  local value = params[1]
  return math.ceil(attr * value)
end

function ValueEffectScript_3(user, params, level)
  local attr = level[2]
  local value = params[1]
  return math.ceil(attr * value)
end

function ValueEffectScript_4(user, params, level)
  local attr = level[3]
  local value = params[1]
  return math.ceil(attr * value)
end

function ValueEffectScript_5(user, params, level)
  local attr = level[4]
  local value = params[1]
  return math.ceil(attr * value)
end

function ValueEffectScript_6(user, params, level)
  local attr = level[5]
  local value = params[1]
  return math.ceil(attr * value)
end
