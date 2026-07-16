package.path = package.path .. ";./?.lua"
local PathGrid = require("lib.pathgrid")
local t = require("tests.testutil")

-- straight line (same row)
local g1 = PathGrid.new()
PathGrid.add(g1, "a", 1, 1, 4, 1, "vertical_first")
local route1 = PathGrid.path_route(g1, "a")
t.assert_eq(#route1, 4, "straight horizontal route has 4 cells")
t.assert_eq(route1[4].x, 4, "straight route ends at x=4")
t.assert_eq(route1[4].y, 1, "straight route stays on y=1")

-- vertical-first elbow: (1,1) -> (4,3)
local g2 = PathGrid.new()
PathGrid.add(g2, "b", 1, 1, 4, 3, "vertical_first")
local route2 = PathGrid.path_route(g2, "b")
-- vertical first: (1,1),(1,2),(1,3) then horizontal: (2,3),(3,3),(4,3)
t.assert_eq(#route2, 6, "elbow route has 6 cells, corner counted once")
t.assert_eq(route2[3].x, 1, "3rd cell is still on the start column")
t.assert_eq(route2[3].y, 3, "3rd cell is the corner, on the end row")
t.assert_eq(route2[6].x, 4, "last cell reaches end x")
t.assert_eq(route2[6].y, 3, "last cell reaches end y")

-- horizontal-first elbow: (1,1) -> (4,3)
local g3 = PathGrid.new()
PathGrid.add(g3, "c", 1, 1, 4, 3, "horizontal_first")
local route3 = PathGrid.path_route(g3, "c")
t.assert_eq(route3[4].x, 4, "corner reaches end column first")
t.assert_eq(route3[4].y, 1, "corner stays on start row")
t.assert_eq(route3[6].y, 3, "last cell reaches end row")

-- decision cell: two paths crossing at (2,2)
local g4 = PathGrid.new()
PathGrid.add(g4, "h", 1, 2, 4, 2, "horizontal_first")  -- straight row 2
PathGrid.add(g4, "v", 2, 1, 2, 4, "vertical_first")    -- straight col 2
t.assert_true(PathGrid.is_decision_cell(g4, 2, 2), "crossing cell is a decision cell")
t.assert_eq(#PathGrid.occurrences_at(g4, 2, 2), 2, "crossing cell has 2 occurrences")
t.assert_true(not PathGrid.is_decision_cell(g4, 1, 2), "non-crossing cell is not a decision cell")

-- removing a path clears only its own occurrences
PathGrid.remove(g4, "h")
t.assert_true(not PathGrid.is_decision_cell(g4, 2, 2), "decision cell resolves after one path removed")
t.assert_eq(#PathGrid.occurrences_at(g4, 2, 2), 1, "one occurrence remains after removal")
t.assert_true(not PathGrid.has(g4, "h"), "removed path id no longer present")

-- root detection
local g5 = PathGrid.new()
PathGrid.add(g5, "x", 3, 3, 3, 5, "vertical_first")
t.assert_true(PathGrid.is_root(g5, 3, 3), "start cell of a path is a root")
t.assert_true(not PathGrid.is_root(g5, 3, 5), "end cell alone is not a root")
t.assert_eq(#PathGrid.paths_starting_at(g5, 3, 3), 1, "one path starts at the root")

-- straight lines normalize their stored orientation to match their axis,
-- regardless of what's passed in
local g6 = PathGrid.new()
PathGrid.add(g6, "row", 1, 5, 4, 5, "vertical_first")
t.assert_eq(g6.paths["row"].orientation, "horizontal_first", "same-row path normalizes to horizontal_first")

local g7 = PathGrid.new()
PathGrid.add(g7, "col", 5, 1, 5, 4, "horizontal_first")
t.assert_eq(g7.paths["col"].orientation, "vertical_first", "same-column path normalizes to vertical_first")

-- clear
PathGrid.clear(g5)
t.assert_true(not PathGrid.has(g5, "x"), "clear removes all paths")
t.assert_eq(#PathGrid.all_cells(g5), 0, "clear empties all cells")

t.report()
