local FunctionCheckLogic = class("logic.FunctionCheckLogic")

function FunctionCheckLogic:initialize()
end

function FunctionCheckLogic:Check(functionId, isShowTip, ...)
  if not moduleManager:CheckFunc(functionId, isShowTip) then
    return false
  end
  local arg = {
    ...
  }
  if functionId == FunctionID.ActPlotCopy then
    return Logic.copyChapterLogic:IsOpenByChapterType(arg[1], isShowTip)
  elseif functionId == FunctionID.ActSeaCopy then
    return Logic.copyChapterLogic:IsOpenByChapterType(arg[1], isShowTip)
  elseif functionId == FunctionID.Rank then
    return Logic.rankLogic:IsOpenById(arg[1], isShowTip)
  else
    if functionId == FunctionID.Shop then
      return Logic.shopLogic:IsOpenByShopId(arg[1], isShowTip)
    else
    end
  end
end

return FunctionCheckLogic
