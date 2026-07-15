package.path = package.path .. ";./?.lua"
local PathGrid = require("lib.pathgrid")
local Traveler = require("lib.traveler")
local render = require("lib.render")
local t = require("tests.testutil")

local pg = PathGrid.new()
pg:add("p", 1, 1, 4, 1, "vertical_first") -- straight line, root at (1,1), end at (4,1)

local traveler = Traveler.new(1, 1)
traveler.x, traveler.y = 3, 1 -- pretend it's mid-path

local levels = render.compute_led_grid(pg, { traveler }, nil)

t.assert_eq(levels[1][1], render.BRIGHTNESS.mid, "root cell is mid brightness")
t.assert_eq(levels[1][4], render.BRIGHTNESS.dim, "end cell is dim, not mid")
t.assert_eq(levels[1][3], render.BRIGHTNESS.full, "traveler's current cell is full brightness")
t.assert_eq(levels[2], nil, "untouched row has no entries")

local levels_held = render.compute_led_grid(pg, {}, { x = 8, y = 8 })
t.assert_eq(levels_held[8][8], render.BRIGHTNESS.mid, "held node lights at mid brightness")

t.report()
