local FoodComposeData = class("data.FoodComposeData", Data.BaseData)

function FoodComposeData:initialize()
  self:ResetData()
end

function FoodComposeData:ResetData()
  self.data = nil
  self.m_Recipes = {}
  self.m_Dishes = {}
  self.m_LastRecipeId = 0
end

function FoodComposeData:SetData(data)
  self:SetFoodComposeInfo(data)
end

function FoodComposeData:SetFoodComposeInfo(data)
  self.data = data
  if data.FoodRecipeInfo and #data.FoodRecipeInfo > 0 then
    for _, v in pairs(data.FoodRecipeInfo) do
      local tmp = {
        ComposeTimes = v.ComposeTimes,
        RewardTimes = v.RewardTimes
      }
      self.m_Recipes[v.RecipeID] = tmp
    end
  end
  if data.FoodDishInfo and 0 < #data.FoodDishInfo then
    for _, v in pairs(data.FoodDishInfo) do
      self.m_Dishes[v.DishID] = v.GainTimes
    end
  end
  if data.LastRecipeId then
    self.m_LastRecipeId = data.LastRecipeId
  end
end

function FoodComposeData:GetFoodRecipeInfo()
  return self.m_Recipes or {}
end

function FoodComposeData:GetFoodDishInfo()
  return self.m_Dishes or {}
end

function FoodComposeData:GetRecipeComposeTById(id)
  return self.m_Recipes[id] and self.m_Recipes[id].ComposeTimes or 0
end

function FoodComposeData:GetRecipeRewardTById(id)
  return self.m_Recipes[id] and self.m_Recipes[id].RewardTimes or 0
end

function FoodComposeData:GetDishTimeById(id)
  return self.m_Dishes[id] or 0
end

function FoodComposeData:GetLastRecipeId()
  return self.m_LastRecipeId or 0
end

function FoodComposeData:GetFoodComposeDataFreshData()
  return self.data
end

return FoodComposeData
