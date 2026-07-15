package.path = package.path .. ";./?.lua"
local PathGrid = require("lib.pathgrid")
local t = require("tests.testutil")

-- straight line (same row)
local g1 = PathGrid.new()
g1:add("a", 1, 1, 4, 1, "vertical_first")
local route1 = g1:path_route("a")
t.assert_eq(#route1, 4, "straight horizontal route has 4 cells")
t.assert_eq(route1[4].x, 4, "straight route ends at x=4")
t.assert_eq(route1[4].y, 1, "straight route stays on y=1")

-- vertical-first elbow: (1,1) -> (4,3)
local g2 = PathGrid.new()
g2:add("b", 1, 1, 4, 3, "vertical_first")
local route2 = g2:path_route("b")
-- vertical first: (1,1),(1,2),(1,3) then horizontal: (2,3),(3,3),(4,3)
t.assert_eq(#route2, 6, "elbow route has 6 cells, corner counted once")
t.assert_eq(route2[3].x, 1, "3rd cell is still on the start column")
t.assert_eq(route2[3].y, 3, "3rd cell is the corner, on the end row")
t.assert_eq(route2[6].x, 4, "last cell reaches end x")
t.assert_eq(route2[6].y, 3, "last cell reaches end y")

-- horizontal-first elbow: (1,1) -> (4,3)
local g3 = PathGrid.new()
g3:add("c", 1, 1, 4, 3, "horizontal_first")
local route3 = g3:path_route("c")
t.assert_eq(route3[4].x, 4, "corner reaches end column first")
t.assert_eq(route3[4].y, 1, "corner stays on start row")
t.assert_eq(route3[6].y, 3, "last cell reaches end row")

-- decision cell: two paths crossing at (2,2)
local g4 = PathGrid.new()
g4:add("h", 1, 2, 4, 2, "horizontal_first")  -- straight row 2
g4:add("v", 2, 1, 2, 4, "vertical_first")    -- straight col 2
t.assert_true(g4:is_decision_cell(2, 2), "crossing cell is a decision cell")
t.assert_eq(#g4:occurrences_at(2, 2), 2, "crossing cell has 2 occurrences")
t.assert_true(not g4:is_decision_cell(1, 2), "non-crossing cell is not a decision cell")

-- removing a path clears only its own occurrences
g4:remove("h")
t.assert_true(not g4:is_decision_cell(2, 2), "decision cell resolves after one path removed")
t.assert_eq(#g4:occurrences_at(2, 2), 1, "one occurrence remains after removal")
t.assert_true(not g4:has("h"), "removed path id no longer present")

-- root detection
local g5 = PathGrid.new()
g5:add("x", 3, 3, 3, 5, "vertical_first")
t.assert_true(g5:is_root(3, 3), "start cell of a path is a root")
t.assert_true(not g5:is_root(3, 5), "end cell alone is not a root")
t.assert_eq(#g5:paths_starting_at(3, 3), 1, "one path starts at the root")

-- straight lines normalize their stored orientation to match their axis,
-- regardless of what's passed in
local g6 = PathGrid.new()
g6:add("row", 1, 5, 4, 5, "vertical_first")
t.assert_eq(g6.paths["row"].orientation, "horizontal_first", "same-row path normalizes to horizontal_first")

local g7 = PathGrid.new()
g7:add("col", 5, 1, 5, 4, "horizontal_first")
t.assert_eq(g7.paths["col"].orientation, "vertical_first", "same-column path normalizes to vertical_first")

-- clear
g5:clear()
t.assert_true(not g5:has("x"), "clear removes all paths")
t.assert_eq(#g5:all_cells(), 0, "clear empties all cells")

t.report()
