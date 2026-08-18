local RefreshTorpedoBtn = class("game.Guide.guidebehaviours.RefreshTorpedoBtn", GR.requires.BehaviourBase)

function RefreshTorpedoBtn:doBehaviour()
  self.timer = Timer.New(function()
    self.timer:Stop()
    UIManager:FireUIEvent(BabelTime.GD.UIEvent.FreshSkillBtnState)
    self:onDone()
  end, 0.01, 1)
  self.timer:Start()
end

return RefreshTorpedoBtn
