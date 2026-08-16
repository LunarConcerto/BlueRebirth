local BarragePage = class("UI.BarragePage", LuaUIPage)
local BarrageTrack = require("ui.page.Barrage.BarrageTrack")

function BarragePage:DoInit()
  BarragePage.instance = self
end

function BarragePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_input, self.ShowInput, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.input_close, self.HideInput, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_send, self.SendBarrage, self)
  self:RegisterEvent(LuaEvent.GetBarrage, self._OnGetBarrageData, self)
  self:RegisterEvent(LuaEvent.OnBarrageChanged, self._OnBarrageChanged, self)
  self:RegisterEvent(LuaEvent.ShowOneBarrage, self._OnShowOneBarrage, self)
  self:RegisterEvent(LuaEvent.SendBarrage, self._OnSendBarrage, self)
  self:RegisterEvent(LuaEvent.BarrageInput, self.ShowInput, self)
end

function BarragePage:DoOnOpen()
  self.cdTime = 0
  self.trackCount = 10
  self.pageCount = 51
  self:CreateTracks()
  self:InitInputText()
  self:UpdateLibrary(self.param or {})
end

function BarragePage:InitInputText()
  local widgets = self.tab_Widgets
  local maxWords = configManager.GetDataById("config_parameter", 134).value
  widgets.input_text.onValueChanged:AddListener(function(msg)
    local res, ischarUp = Logic.chatLogic:MsgCut(msg, maxWords)
    if ischarUp then
      noticeManager:ShowTip(UIHelper.GetString(941001))
    end
    widgets.input_text.text = res
  end)
  widgets.txt_cd.gameObject:SetActive(false)
  self:StartCDTimer()
end

function BarragePage:SendBarrage()
  self:HideInput()
  if self.cdTime > 0 then
    noticeManager:ShowTip(UIHelper.GetString(941002))
    return
  end
  local content = self.tab_Widgets.input_text.text
  if string.len(content) == 0 then
    noticeManager:ShowTip(UIHelper.GetString(941004))
    return
  end
  Service.chatService:SendBarrage(self.barrageRec.chat_id, 0, content)
  self.tab_Widgets.input_text.text = ""
  Logic.chatLogic:SetBarrageCD()
  self:StartCDTimer()
end

function BarragePage:StartCDTimer()
  self.cdTime = Logic.chatLogic:GetBarrageCD()
  if self.cdTime == 0 then
    return
  end
  self.tab_Widgets.txt_cd.gameObject:SetActive(true)
  UIHelper.SetText(self.tab_Widgets.txt_cd, string.format("(%ds)", self.cdTime))
  self.cdTimer = self:CreateTimer(function()
    self.cdTime = self.cdTime - 1
    UIHelper.SetText(self.tab_Widgets.txt_cd, string.format("(%ds)", self.cdTime))
    if self.cdTime <= 0 then
      self:StopTimer(self.cdTime)
      self.cdTime = 0
      self.tab_Widgets.txt_cd.gameObject:SetActive(false)
    end
  end, 1, self.cdTime)
  self:StartTimer(self.cdTimer)
end

function BarragePage:_OnSendBarrage(args)
  self:AppendHead(args.Content)
end

function BarragePage:UpdateLibrary(args)
  if self.barrageRec and args.sceneId == self.barrageRec.scene_id then
    return
  end
  self.datas = {}
  self.totalCount = 0
  self.showedCount = 0
  self.isEmpty = false
  local btype = args.btype or BarrageType.Plot
  local sceneId = args.sceneId or 1000101
  self.barrageRec = Logic.chatLogic:GetBarrageRec(sceneId, btype)
  self.enabledTracks = {}
  local trackClosed = self.barrageRec.track_closed
  for i, track in pairs(self.tracks) do
    local enabled = true
    for _, idx in pairs(trackClosed) do
      if i == idx then
        enabled = false
        break
      end
    end
    track:SetEnabled(enabled)
    if enabled then
      table.insert(self.enabledTracks, track)
    end
  end
  local state = Logic.chatLogic:GetBarrageState()
  if state == 1 then
    self:GetOnePage()
  end
end

function BarragePage:GetOnePage()
  local beginIndex = #self.datas
  local chatId = self.barrageRec.chat_id
  Service.chatService:GetBarrages(chatId, beginIndex, self.pageCount)
end

function BarragePage:_SendFake(chatId)
  local contents = {
    "66666",
    "\229\176\143\230\160\183\229\132\191\231\156\159\229\136\171\232\135\180",
    "\228\184\141\231\159\165\233\129\147\229\133\182\228\187\150\229\140\186\231\154\132\229\176\143\228\188\153\228\188\180\230\156\137\230\178\161\230\156\137\229\143\145\232\191\135\229\188\185\229\185\149",
    "\229\143\141\230\173\163\230\136\145\232\167\137\229\190\151\229\164\132",
    "\231\172\172\228\184\128\227\128\129\231\172\172\229\135\160\227\128\129\231\172\172\229\135\160\227\128\129\231\172\172\228\184\128\231\154\132\233\131\189\230\152\175\230\136\145x",
    "\230\150\176\231\149\170\231\149\153\229\144\141\239\188\140\229\174\140\231\187\147\230\146\146\232\138\177\226\128\166\226\128\166",
    "\231\154\132\229\188\185\229\185\149\231\154\132\230\132\143\228\185\137\231\168\141\229\190\174\231\154\132\230\156\137\231\130\185\228\184\141\229\144\140",
    "\232\191\153\231\149\170\230\136\145\231\156\139\229\174\140\228\186\134",
    "2018\229\185\18011\230\156\13611\230\151\165"
  }
  math.randomseed(os.clock())
  for i = 1, 100 do
    local idx = math.random(#contents)
    local content = contents[math.floor(idx)] .. tostring(chatId)
    if content then
      Service.chatService:SendBarrage(chatId, 0, content)
    end
  end
end

function BarragePage:_FakeData()
  local datas = {}
  for i = 1, 50 do
    local barrage = {
      Value = "test barrage"
    }
    table.insert(datas, barrage)
  end
  return datas
end

function BarragePage:_OnGetBarrageData(datas)
  local barrageList = datas.BarrageList
  for k, barrage in pairs(barrageList) do
    self:AppendBarrage(k, barrage.Value, barrage.Param)
    self.totalCount = self.totalCount + 1
    self.datas[self.totalCount] = barrage
  end
  self.isEmpty = #barrageList < self.pageCount
end

function BarragePage:_OnBarrageChanged(args)
  for k, track in pairs(self.tracks) do
    track:ClearQueue()
  end
  self:UpdateLibrary(args)
end

function BarragePage:_OnShowOneBarrage()
  self.showedCount = self.showedCount + 1
  if self.totalCount - self.showedCount == 10 and not self.isEmpty then
    self:GetOnePage()
  end
end

function BarragePage:CreateTracks()
  self.tracks = {}
  local trackSpeed = configManager.GetDataById("config_parameter", 136).arrValue
  local spacings = configManager.GetDataById("config_parameter", 137).arrValue
  local delays = configManager.GetDataById("config_parameter", 138).arrValue
  local widgets = self.tab_Widgets
  UIHelper.CreateSubPart(widgets.track, widgets.content, self.trackCount, function(index, part)
    local track = BarrageTrack:new()
    track:Init({
      page = self,
      part = part,
      spacing = spacings[index],
      speed = trackSpeed[index],
      delay = delays[index]
    })
    self.tracks[index] = track
  end)
end

function BarragePage:AppendHead(content)
  local trackCount = #self.enabledTracks
  local idx = math.random(trackCount)
  local track = self.enabledTracks[idx]
  local uid = Data.userData:GetUserUid()
  track:AppendHead({
    content = content,
    params = {uid = uid}
  })
end

function BarragePage:AppendBarrage(idx, content, paramStr)
  local params = Logic.chatLogic:ParseBarrageParam(paramStr)
  local trackCount = #self.enabledTracks
  local index = idx % trackCount + 1
  local track = self.enabledTracks[index]
  track:Append({content = content, params = params})
end

function BarragePage:ShowInput()
  self.tab_Widgets.input:SetActive(true)
  self.tab_Widgets.input_text:ActivateInputField()
end

function BarragePage:HideInput()
  self.tab_Widgets.input:SetActive(false)
end

function BarragePage:DoOnClose()
  self:StopAllTimer()
  for k, track in pairs(self.tracks) do
    track:Destroy()
  end
  self.tracks = {}
  BarragePage.instance = nil
  self.tab_Widgets.input_text.onValueChanged:RemoveAllListeners()
end

function BarragePage:_CloseSelf()
  UIHelper.ClosePage(self:GetName())
end

return BarragePage
