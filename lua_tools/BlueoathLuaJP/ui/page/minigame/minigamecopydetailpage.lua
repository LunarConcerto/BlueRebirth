local MinigameCopyDetailPage = class("UI.MiniGame.MinigameCopyDetailPage", LuaUIPage)

function MinigameCopyDetailPage:DoInit()
end

function MinigameCopyDetailPage:DoOnOpen()
  self:OpenTopPageNoTitle("MinigameCopyDetailPage", 1)
  local widgets = self:GetWidgets()
  local config = configManager.GetData("config_minigame_infinite_copy")
  UIHelper.CreateSubPart(widgets.item, widgets.Content, #config, function(index, tabPart)
    local data = config[index]
    UIHelper.SetText(tabPart.txt_name, data.name)
    UIHelper.SetImage(tabPart.im_icon, data.image)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_plot, self.btn_mini_game, self, config[index].id)
  end)
end

function MinigameCopyDetailPage:btn_mini_game(go, chapterId)
  local config = configManager.GetDataById("config_minigame_infinite_copy", chapterId)
  UIHelper.OpenPage("MiniGamePage", {
    chapterId = chapterId,
    gameId = config.copy_id,
    typ = Game2dPlayType.UnLimit
  })
end

function MinigameCopyDetailPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_rank, self.btn_rank, self)
end

function MinigameCopyDetailPage:btn_rank(go, gameId)
  UIHelper.OpenPage("RankPage", {
    RankType = RankType.MiniGame
  })
end

return MinigameCopyDetailPage
