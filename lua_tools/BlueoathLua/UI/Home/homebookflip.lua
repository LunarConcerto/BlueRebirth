local HomeBookFlip = class("UI.Home.HomeBookFlip")
local HomeScene = require("Game.GameState.Home.HomeMainState")

function HomeBookFlip:initialize(...)
end

function HomeBookFlip:Init()
  local pageDownType = configManager.GetDataById("config_parameter", 360).value
  self.isFlipFromLeft = pageDownType == 1
  self.pageFlipTime = configManager.GetDataById("config_parameter", 358).value / 1000
  local obj_homeScene = HomeScene:GetSceneObj()
  if obj_homeScene == nil then
    return
  end
  local trans_homeScene = obj_homeScene.transform
  self.obj_book = self.isFlipFromLeft and UIHelper.TryFindChildTransform(trans_homeScene, "UI_book_01") or UIHelper.TryFindChildTransform(trans_homeScene, "UI_book_02")
  if self.obj_book == nil then
    return
  end
  self.tween_book = self.isFlipFromLeft and self.obj_book:GetComponent(TweenPosition.GetClassType()) or nil
  self.flip_page = self.isFlipFromLeft and UIHelper.TryFindChildTransform(self.obj_book, "UI_book_01_02") or UIHelper.TryFindChildTransform(self.obj_book, "UI_book_02_02")
  self.left_page = self.isFlipFromLeft and UIHelper.TryFindChildTransform(self.obj_book, "UI_book_01_03") or UIHelper.TryFindChildTransform(self.obj_book, "UI_book_02_01")
  self.right_page = self.isFlipFromLeft and UIHelper.TryFindChildTransform(self.obj_book, "UI_book_01_01") or UIHelper.TryFindChildTransform(self.obj_book, "UI_book_02_03")
  self.flip_page = self.flip_page.gameObject
  self.left_page = self.left_page.gameObject
  self.right_page = self.right_page.gameObject
  self.mat_flip = self.flip_page:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).sharedMaterial
  self.mat_left = self.left_page:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).sharedMaterial
  self.mat_right = self.right_page:GetComponent(typeof(CS.UnityEngine.MeshRenderer)).sharedMaterial
  self.curtIndex = 1
  self.leftIndex = self.isFlipFromLeft and 0 or 1
  self.rightIndex = self.isFlipFromLeft and 1 or 0
  self.obj_book.gameObject:SetActive(true)
  self.flip_page:SetActive(false)
  self.left_page:SetActive(not self.isFlipFromLeft)
  self.right_page:SetActive(self.isFlipFromLeft)
  UpdateBeat:Add(self.__tick, self)
  self.inited = true
end

function HomeBookFlip:Destroy()
  self.obj_homeScene = nil
  self.textures = {}
  if not self.inited then
    return
  end
  self.inited = false
  self.obj_book.gameObject:SetActive(false)
  self.obj_book = nil
  self.tween_book = nil
  self.flip_page = nil
  self.left_page = nil
  self.right_page = nil
  self.mat_flip = nil
  self.mat_left = nil
  self.mat_right = nil
  self.endCallBack = nil
  UpdateBeat:Remove(self.__tick, self)
end

function HomeBookFlip:SetTextures(textureIds)
  if not self.inited then
    return
  end
  self.textures = {}
  for i = 1, #textureIds do
    local magazinePageConfig = configManager.GetDataById("config_magazine_page", textureIds[i])
    local tex = CS.TexturePackerManager.Instance:GetMainTexture(magazinePageConfig.image, self.obj_book.gameObject)
    table.insert(self.textures, tex)
  end
end

function HomeBookFlip:_OpenBookAnim()
  if self.tween_book ~= nil then
    self.tween_book:ResetToInit()
    self.tween_book:Play(true)
  end
end

function HomeBookFlip:_CloseBookAnim()
  if self.tween_book ~= nil then
    self.tween_book:Play(false)
  end
end

function HomeBookFlip:SetPageIndex(leftIndex, rightIndex, onCallBack)
  if not self.inited then
    return
  end
  self.endCallBack = onCallBack
  if self.leftIndex == 0 or self.rightIndex == 0 then
    self:_OpenBookAnim()
  end
  self.isForward = leftIndex < self.leftIndex
  if leftIndex == 0 or rightIndex == 0 then
    if rightIndex == 0 and not self.isFlipFromLeft then
      self.right_page:SetActive(false)
    end
    if leftIndex == 0 and self.isFlipFromLeft then
      self.left_page:SetActive(false)
    end
    self:_CloseBookAnim()
  end
  SoundManager.Instance:PlayAudio("Effect_fanshu")
  if self.isFlipFromLeft then
    if self.isForward then
      self.mat_flip:SetTexture("_MainTex", self.textures[rightIndex])
      self.mat_flip:SetTexture("_BackTex", self.textures[self.leftIndex])
      self.mat_left.mainTexture = self.textures[leftIndex]
    else
      self.mat_flip:SetTexture("_MainTex", self.textures[self.rightIndex])
      self.mat_flip:SetTexture("_BackTex", self.textures[leftIndex])
      self.mat_right.mainTexture = self.textures[rightIndex]
    end
  elseif self.isForward then
    self.mat_flip:SetTexture("_MainTex", self.textures[leftIndex])
    self.mat_flip:SetTexture("_BackTex", self.textures[self.rightIndex])
    self.mat_right.mainTexture = self.textures[rightIndex]
  else
    self.mat_flip:SetTexture("_MainTex", self.textures[self.leftIndex])
    self.mat_flip:SetTexture("_BackTex", self.textures[rightIndex])
    self.mat_left.mainTexture = self.textures[leftIndex]
  end
  self.mat_flip:SetInt("_FlipForwrd", self.isForward and 1 or 0)
  self.mat_flip:SetInt("_FlipFromLeft", self.isFlipFromLeft and 1 or 0)
  self.flip_page:SetActive(true)
  self.deltaTime = 0
  self.leftIndex = leftIndex
  self.rightIndex = rightIndex
  self.flipping = true
end

function HomeBookFlip:__tick()
  if self.flipping then
    if self.deltaTime < self.pageFlipTime then
      self.deltaTime = self.deltaTime + Time.deltaTime
      if self.deltaTime > self.pageFlipTime then
        self.deltaTime = self.pageFlipTime
      end
      local percent = self.isForward and 1 - self.deltaTime / self.pageFlipTime or self.deltaTime / self.pageFlipTime
      self.mat_flip:SetFloat("_CurPageAngle", percent)
    else
      self.flipping = false
      self.flip_page:SetActive(false)
      if self.isForward then
        if self.isFlipFromLeft then
          self.mat_right.mainTexture = self.textures[self.rightIndex]
        else
          self.mat_left.mainTexture = self.textures[self.leftIndex]
        end
      elseif self.isFlipFromLeft then
        self.left_page:SetActive(true)
        self.mat_left.mainTexture = self.textures[self.leftIndex]
      else
        self.right_page:SetActive(true)
        self.mat_right.mainTexture = self.textures[self.rightIndex]
      end
      if self.endCallBack then
        self.endCallBack()
        self.endCallBack = nil
      end
    end
  end
end

return HomeBookFlip
