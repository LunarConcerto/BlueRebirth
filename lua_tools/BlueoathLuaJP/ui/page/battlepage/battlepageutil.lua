BattlePageUtil = class("UI.BattlePageUtil")

function BattlePageUtil:DoLoad(gameObject)
  self:Init()
end

function BattlePageUtil:Init()
  self.objBattlePage = self.gameObject:GetComponent("BabelTime.GD.UI.BattlePage")
end

function BattlePageUtil:DoOpen(gameObject)
end

function BattlePageUtil:DoShow(gameObject)
end

function BattlePageUtil:DoHide(gameObject)
end

function BattlePageUtil:DoClose(gameObject)
  self.objBattlePage.effectBindV2:UnReadyImmediately()
end

function BattlePageUtil:DoBack(gameObject)
end

function BattlePageUtil:DoDestroy(gameObject)
end

function BattlePageUtil:DoFront(gameObject)
end

return BattlePageUtil
