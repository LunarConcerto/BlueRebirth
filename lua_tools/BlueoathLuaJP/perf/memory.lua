local TYPE_NAME = {
  "GLOBAL",
  "REGISTRY",
  "UPVALUE",
  "LOCAL"
}

local function report_output_line(rp)
  local size = string.format("%7i", rp.size)
  return string.format("%-40.40s: %-12s: %-12s: %-12s: %s\n", rp.name, size, TYPE_NAME[rp.type], rp.pointer, rp.used_in)
end

local function snapshot()
  local ss = perf.snapshot()
  local FORMAT_HEADER_LINE = "%-40s: %-12s: %-12s: %-12s: %s\n"
  local header = string.format(FORMAT_HEADER_LINE, "NAME", "SIZE", "TYPE", "ID", "INFO")
  table.sort(ss, function(a, b)
    return a.size > b.size
  end)
  local output = header
  for i, rp in ipairs(ss) do
    output = output .. report_output_line(rp)
  end
  return output
end

local function total()
  return collectgarbage("count")
end

return {snapshot = snapshot, total = total}
