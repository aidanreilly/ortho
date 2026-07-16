package.path = package.path .. ";./?.lua"
local Gesture = require("lib.gesture")
local t = require("tests.testutil")

-- hold A, tap B: creates/toggles path A->B on B's release
local g1 = Gesture.new(0.3)
t.assert_eq(Gesture.key(g1, 2, 2, 1, 0.0), nil, "pressing origin fires no action")
t.assert_eq(Gesture.key(g1, 5, 2, 1, 0.1), nil, "pressing destination fires no action yet")
local a1 = Gesture.key(g1, 5, 2, 0, 0.2) -- destination released
t.assert_eq(a1.type, "toggle_path", "destination release toggles the path")
t.assert_eq(a1.x1, 2, "origin x recorded"); t.assert_eq(a1.y1, 2, "origin y recorded")
t.assert_eq(a1.x2, 5, "dest x recorded"); t.assert_eq(a1.y2, 2, "dest y recorded")
local a2 = Gesture.key(g1, 2, 2, 0, 0.3) -- origin released after
t.assert_eq(a2, nil, "releasing origin after a completed tap fires nothing extra")

-- double tap on the same destination within the window toggles the elbow
local g2 = Gesture.new(0.3)
Gesture.key(g2, 2, 2, 1, 0.0)
Gesture.key(g2, 5, 2, 1, 0.1); Gesture.key(g2, 5, 2, 0, 0.12) -- first tap: toggle_path
Gesture.key(g2, 5, 2, 1, 0.2)
local a3 = Gesture.key(g2, 5, 2, 0, 0.25) -- second tap, within 0.3s window
t.assert_eq(a3.type, "toggle_elbow", "quick second tap toggles elbow instead")
Gesture.key(g2, 2, 2, 0, 0.3)

-- second tap outside the window is just another toggle_path
local g3 = Gesture.new(0.3)
Gesture.key(g3, 2, 2, 1, 0.0)
Gesture.key(g3, 5, 2, 1, 0.1); Gesture.key(g3, 5, 2, 0, 0.12)
Gesture.key(g3, 5, 2, 1, 1.0)
local a4 = Gesture.key(g3, 5, 2, 0, 1.05) -- 0.93s later, well past the window
t.assert_eq(a4.type, "toggle_path", "second tap outside the window toggles path again, not elbow")
Gesture.key(g3, 2, 2, 0, 1.1)

-- multiple destinations from the same held origin
local g4 = Gesture.new(0.3)
Gesture.key(g4, 2, 2, 1, 0.0)
Gesture.key(g4, 5, 2, 1, 0.1)
local b1 = Gesture.key(g4, 5, 2, 0, 0.12)
Gesture.key(g4, 2, 5, 1, 0.2)
local b2 = Gesture.key(g4, 2, 5, 0, 0.22)
t.assert_eq(b1.x2, 5, "first destination toggled"); t.assert_eq(b1.y2, 2, "first destination toggled")
t.assert_eq(b2.x2, 2, "second destination toggled"); t.assert_eq(b2.y2, 5, "second destination toggled")
Gesture.key(g4, 2, 2, 0, 0.3)

-- plain tap (no hold) on a node resets its traveler
local g5 = Gesture.new(0.3)
Gesture.key(g5, 7, 7, 1, 0.0)
local c1 = Gesture.key(g5, 7, 7, 0, 0.05)
t.assert_eq(c1.type, "reset_traveler", "plain tap resets a traveler")
t.assert_eq(c1.x, 7, "reset traveler x"); t.assert_eq(c1.y, 7, "reset traveler y")

-- plain tap on the reserved (1,1) clears the grid instead
local g6 = Gesture.new(0.3)
Gesture.key(g6, 1, 1, 1, 0.0)
local c2 = Gesture.key(g6, 1, 1, 0, 0.05)
t.assert_eq(c2.type, "clear_grid", "plain tap on (1,1) clears the grid")

-- releasing the origin before the destination releases cancels the gesture cleanly
local g7 = Gesture.new(0.3)
Gesture.key(g7, 2, 2, 1, 0.0)
Gesture.key(g7, 5, 2, 1, 0.1)
local d1 = Gesture.key(g7, 2, 2, 0, 0.15) -- origin released first, destination still down
t.assert_eq(d1, nil, "releasing origin mid-tap fires nothing")
local d2 = Gesture.key(g7, 5, 2, 0, 0.2) -- destination's own later release is a no-op
t.assert_eq(d2, nil, "orphaned destination release is a no-op")

-- the reserved (1,1) cell is never a path endpoint, held as origin or tapped as destination
local g8 = Gesture.new(0.3)
Gesture.key(g8, 1, 1, 1, 0.0)
Gesture.key(g8, 5, 2, 1, 0.1)
local e1 = Gesture.key(g8, 5, 2, 0, 0.12) -- destination release with (1,1) held as origin
t.assert_eq(e1, nil, "holding the reserved cell as origin fires no path action")
Gesture.key(g8, 1, 1, 0, 0.2)

local g9 = Gesture.new(0.3)
Gesture.key(g9, 2, 2, 1, 0.0)
Gesture.key(g9, 1, 1, 1, 0.1)
local e2 = Gesture.key(g9, 1, 1, 0, 0.12) -- tapping the reserved cell as destination
t.assert_eq(e2, nil, "tapping the reserved cell as destination fires no path action")
Gesture.key(g9, 2, 2, 0, 0.2)

t.report()
