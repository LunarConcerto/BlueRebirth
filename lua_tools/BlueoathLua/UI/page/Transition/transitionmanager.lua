local TransitionManager = class("ui.page.Transition.TransitionManager")
TransitionType = {Loading = 0, Switch = 1}
TransitionName = {
  [TransitionType.Loading] = "LoadingTransition",
  [TransitionType.Switch] = "SwitchTransition"
}
TransitionManager.m_loadingTip = {}

function TransitionManager.Open(tType, args)
  local tostack = tType == TransitionType.Switch and true or false
  UIHelper.OpenPage(TransitionName[tType], args, 3, tostack)
end

function TransitionManager.SetLoadingTexture(id)
  TransitionManager.m_loadingTextureId = id
end

function TransitionManager.GetLoadingTexture()
  return TransitionManager.m_loadingTextureId or 0
end

function TransitionManager.GetLoadingTipConfig(pl)
  local merge = function(orgin, add, pl)
    if pl == 0 then
      return orgin
    end
    for id, data in pairs(add) do
      orgin[id] = data
    end
    return orgin
  end
  local cache = TransitionManager.m_loadingTip
  if next(cache) ~= nil then
    return merge(cache[0], cache[pl], pl)
  end
  local orgin = configManager.GetData("config_loading_tips")
  local config = {}
  local plTemp
  for id, data in pairs(orgin) do
    for _, pl in ipairs(data.pl) do
      plTemp = pl
      if config[plTemp] then
        config[plTemp][id] = data
      else
        config[plTemp] = {
          [id] = data
        }
      end
    end
  end
  TransitionManager.m_loadingTip = config
  return merge(config[0], config[pl], pl)
end

return TransitionManager
