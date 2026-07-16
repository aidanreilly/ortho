local M = {}

local total = 0
local failures = 0

function M.assert_eq(actual, expected, msg)
  total = total + 1
  if actual ~= expected then
    failures = failures + 1
    print(string.format("FAIL: %s (expected %s, got %s)", msg or "?", tostring(expected), tostring(actual)))
  end
end

function M.assert_true(value, msg)
  M.assert_eq(value and true or false, true, msg)
end

function M.report()
  print(string.format("%d/%d assertions passed", total - failures, total))
  if failures > 0 then
    os.exit(1)
  end
end

return M
