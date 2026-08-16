local m = {}

function m:UpdateExternalTexture(nativeTex)
end

function m:SetPixels32(colors)
end

function m:GetRawTextureData()
end

function m:GetPixels()
end

function m:GetPixels32(miplevel)
end

function m:PackTextures(textures, padding, maximumAtlasSize, makeNoLongerReadable)
end

function m:Compress(highQuality)
end

function m:ClearRequestedMipmapLevel()
end

function m:IsRequestedMipmapLevelLoaded()
end

function m.CreateExternalTexture(width, height, format, mipChain, linear, nativeTex)
end

function m:SetPixel(x, y, color)
end

function m:SetPixels(x, y, blockWidth, blockHeight, colors, miplevel)
end

function m:GetPixel(x, y)
end

function m:GetPixelBilinear(x, y)
end

function m:LoadRawTextureData(data, size)
end

function m:Apply(updateMipmaps, makeNoLongerReadable)
end

function m:Resize(width, height)
end

function m:ReadPixels(source, destX, destY, recalculateMipMaps)
end

function m.GenerateAtlas(sizes, padding, atlasSize, results)
end

return m
