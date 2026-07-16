package.path = package.path .. ";./?.lua"
-- these three globals mirror what norns' own runtime provides to every
-- script; the vendored modules under tests/vendor/ reference them as
-- bare globals, exactly like the real norns source they're copied from.
util = require("tests.vendor.util")
norns = { pmap = { data = {} } }
controlspec = require("tests.vendor.controlspec")
local ParamSet = require("tests.vendor.paramset")
local t = require("tests.testutil")

-- add() stores the action but does NOT fire it — this is the exact
-- behavior the original hand-written test fake got wrong.
local ps1 = ParamSet.new()
local fired = {}
ps1:add{type = "option", id = "mode", name = "mode", options = {"a", "b", "c"}, default = 2,
  action = function(v) fired[#fired + 1] = v end}
t.assert_eq(#fired, 0, "action does not fire on add (matches real norns, not the old test fake)")
t.assert_eq(ps1:get("mode"), 2, "get() returns the default index even though action never fired")

-- bang() fires every registered action with its current value
ps1:bang()
t.assert_eq(#fired, 1, "bang() fires the action exactly once")
t.assert_eq(fired[1], 2, "bang() fires with the current (default) value")

-- set() fires the action too (not silent)
ps1:set("mode", 3)
t.assert_eq(#fired, 2, "set() fires the action")
t.assert_eq(fired[2], 3, "set() fires with the new value")
t.assert_eq(ps1:get("mode"), 3, "set() updates the stored value")

-- set() with silent=true does not fire
ps1:set("mode", 1, true)
t.assert_eq(#fired, 2, "silent set() does not fire the action")
t.assert_eq(ps1:get("mode"), 1, "silent set() still updates the stored value")

-- add_number: registers, clamps to [min,max]
local ps2 = ParamSet.new()
ps2:add_number("count", "count", 1, 10, 5)
t.assert_eq(ps2:get("count"), 5, "add_number default")
ps2:set("count", 99)
t.assert_eq(ps2:get("count"), 10, "add_number clamps above max")
ps2:set("count", -5)
t.assert_eq(ps2:get("count"), 1, "add_number clamps below min")

-- add_control: registers, get() returns the mapped default via controlspec
local ps3 = ParamSet.new()
ps3:add_control("gate", "gate", controlspec.new(0.02, 1, "lin", 0, 0.08, "s"))
t.assert_true(math.abs(ps3:get("gate") - 0.08) < 0.001, "add_control get() returns the controlspec default")

-- generic add{} with a formatter (root_note-style usage)
local ps4 = ParamSet.new()
ps4:add{type = "number", id = "n", name = "n", min = 0, max = 127, default = 48,
  formatter = function(param) return "val:" .. param:get() end}
t.assert_eq(ps4:lookup_param("n").formatter(ps4:lookup_param("n")), "val:48", "formatter is stored and callable")

t.report()
