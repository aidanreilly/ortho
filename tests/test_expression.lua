package.path = package.path .. ";./?.lua"
local Expression = require("lib.expression")
local t = require("tests.testutil")

t.assert_eq(Expression.velocity_for_row(1, 127, 20), 127, "row1 (top) is the ceiling")
t.assert_eq(Expression.velocity_for_row(8, 127, 20), 20, "row8 (bottom) is the floor")
-- linear interpolation, 7 steps between row1 and row8
local expected_row4 = math.floor(127 - (127 - 20) * 3 / 7 + 0.5)
t.assert_eq(Expression.velocity_for_row(4, 127, 20), expected_row4, "row4 interpolates linearly")

t.assert_eq(Expression.gate_for_orientation("vertical_first", 0.05, 0.4), 0.05, "vertical_first is staccato")
t.assert_eq(Expression.gate_for_orientation("horizontal_first", 0.05, 0.4), 0.4, "horizontal_first is legato")

t.report()
