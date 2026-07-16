-- vendored from norns' lua/lib/tabutil.lua — only tab.count, the one
-- function tests/vendor/params/option.lua needs.
local tab = {}

tab.count = function(t)
  local c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
end

return tab
