RichTextUtil = {}
RichTextUtil.Match = {
  "<[Bb]>.+</[Bb]>",
  "<[Ii]>.+</[Ii]>",
  "<[Ss][Ii][Zz][Ee]=%d+>.+</[Ss][Ii][Zz][Ee]>",
  "<[Cc][Oo][Ll][Oo][Rr]=.%w+>.+</[Cc][Oo][Ll][Oo][Rr]>",
  "<[Mm][Aa][Tt][Ee][Rr][Ii][Aa][Ll]=%d+>.+</[Mm][Aa][Tt][Ee][Rr][Ii][Aa][Ll]>",
  "<[Qq][Uu][Aa][Dd]=%w+>.+</[Qq][Uu][Aa][Dd]>"
}
RichTextUtil.Atom = {
  ["<[Bb]>"] = "***",
  ["</[Bb]>"] = "****",
  ["<[Ii]>"] = "***",
  ["</[Ii]>"] = "****",
  ["<[Ss][Ii][Zz][Ee]=%d+>"] = "********",
  ["</[Ss][Ii][Zz][Ee]>"] = "*******",
  ["<[Cc][Oo][Ll][Oo][Rr]=.%w+>"] = "*********",
  ["</[Cc][Oo][Ll][Oo][Rr]>"] = "********",
  ["<[Mm][Aa][Tt][Ee][Rr][Ii][Aa][Ll]=%d+>"] = "************",
  ["</[Mm][Aa][Tt][Ee][Rr][Ii][Aa][Ll]>"] = "***********",
  ["<[Qq][Uu][Aa][Dd]=%w+>"] = "********",
  ["</[Qq][Uu][Aa][Dd]>"] = "*******"
}

function RichTextUtil.Remove(msg)
  return RichTextUtil.Replace(msg, "")
end

function RichTextUtil.Have(msg)
  local richs = RichTextUtil.Match
  local res
  for _, rich in ipairs(richs) do
    res = string.match(msg, rich)
    if res then
      return true
    end
  end
  return false
end

function RichTextUtil.Replace(msg, dr)
  local richs = RichTextUtil.Match
  local frichs = RichTextUtil.Atom
  local res, mcach, num = msg
  local filter = function(text)
    for m, r in pairs(frichs) do
      dr = dr or r
      text = string.gsub(text, m, dr)
    end
    return text
  end
  for _, rich in ipairs(richs) do
    mcach, num = string.gsub(msg, rich, filter)
    if 0 < num then
      msg = mcach
      res = mcach
    end
  end
  return res
end
