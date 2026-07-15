package.path = package.path .. ";./?.lua"
local PathGrid = require("lib.pathgrid")
local Traveler = require("lib.traveler")
local t = require("tests.testutil")

-- rng that always returns the lowest option (deterministic "first" pick)
local function rng_first(lo, hi) return lo end
-- rng that always returns the highest option (deterministic "last" pick)
local function rng_last(lo, hi) return hi end

-- simple 3-cell path, no branching: fires a note on the 2nd step, then resets
local g1 = PathGrid.new()
g1:add("p", 1, 1, 3, 1, "vertical_first") -- straight line, 3 cells
local tr1 = Traveler.new(1, 1)

local r1 = tr1:step(g1, rng_first) -- resolves root, no movement yet
t.assert_eq(r1.note, false, "first step just resolves root, no note")
t.assert_eq(tr1.x, 1, "still sitting at root after resolve")

local r2 = tr1:step(g1, rng_first) -- moves to cell 2
t.assert_eq(r2.note, false, "middle cell is not a dead end")
t.assert_eq(tr1.x, 2, "moved to 2nd cell")

local r3 = tr1:step(g1, rng_first) -- moves to cell 3 (dead end)
t.assert_eq(r3.note, true, "reaching the last cell fires a note")
t.assert_eq(r3.x, 3, "note fires at the dead-end cell")
t.assert_eq(r3.orientation, "horizontal_first", "dead-end result carries the finishing path's orientation")
t.assert_eq(tr1.path_id, nil, "traveler is unresolved again after firing")

local r4 = tr1:step(g1, rng_first) -- re-resolves root
t.assert_eq(r4.note, false, "re-resolving root fires no note")
t.assert_eq(tr1.x, 1, "back at root")

-- branching: root (1,1) has two outgoing paths, to (3,1) and to (1,3)
local g2 = PathGrid.new()
g2:add("to-b", 1, 1, 3, 1, "vertical_first")
g2:add("to-c", 1, 1, 1, 3, "vertical_first")

local tr_first = Traveler.new(1, 1)
tr_first:step(g2, rng_first) -- occurrences_at root sorted by insertion: to-b added first
t.assert_eq(tr_first.path_id, "to-b", "rng_first picks the first-inserted occurrence")

local tr_last = Traveler.new(1, 1)
tr_last:step(g2, rng_last)
t.assert_eq(tr_last.path_id, "to-c", "rng_last picks the last-inserted occurrence")

-- crossing: path "h" (row 2, x1..4) and path "v" (col 2, y1..4) cross at (2,2)
local g3 = PathGrid.new()
g3:add("h", 1, 2, 4, 2, "horizontal_first")
g3:add("v", 2, 1, 2, 4, "vertical_first")
local tr3 = Traveler.new(1, 2) -- starts on path h
tr3:step(g3, rng_first) -- resolve root (only occurrence is h, index1)
t.assert_eq(tr3.path_id, "h", "root of h has only one occurrence")
tr3:step(g3, rng_last) -- step to (2,2), a decision cell; rng_last picks the later-inserted occurrence (v)
t.assert_eq(tr3.x, 2, "landed on the crossing cell")
t.assert_eq(tr3.path_id, "v", "rng_last rerouted onto path v at the crossing")

t.report()
