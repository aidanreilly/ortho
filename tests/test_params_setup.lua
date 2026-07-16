package.path = package.path .. ";./?.lua"
-- include() is a norns global (path-relative module loader); stub it as a
-- require() wrapper so lib modules that call include() to load each other
-- are loadable under plain lua for testing.
include = function(path) return require((path:gsub("/", "."))) end
local params_setup = require("lib.params_setup")
local t = require("tests.testutil")

-- fake params recorder: mimics just enough of norns' params API to observe
-- which ids get registered, without needing the real norns runtime. NOTE:
-- unlike real norns (which only fires action via params:set()/bang(), never
-- on add() itself), this fake's generic add() form fires action(default)
-- immediately for test convenience. This divergence is exactly what let a
-- real bug slip through once (see git history) and is slated to be closed
-- by vendoring norns' real paramset.lua as the test double.
local fake = { registered = {} }
function fake:add_option(id, name, options, default) self.registered[id] = { kind = "option", options = options } end
function fake:add_number(id, name, min, max, default) self.registered[id] = { kind = "number", min = min, max = max } end
function fake:add_control(id, name, controlspec) self.registered[id] = { kind = "control" } end
function fake:add(opts)
  self.registered[opts.id] = { kind = opts.type, options = opts.options, min = opts.min, max = opts.max }
  if opts.action then opts.action(opts.default) end
end

-- controlspec is a norns global; stub it minimally so this file is loadable
-- under plain lua for testing.
controlspec = { new = function(...) return { ... } end }

local fake_vports = { { name = "fake device one" }, { name = "a very long device name here" } }
local device_change_calls = {}
local function fake_on_midi_device_change(value)
  device_change_calls[#device_change_calls + 1] = value
end

params_setup.add_all(fake, fake_vports, fake_on_midi_device_change)

local expected_ids = {
  "clock_division", "scale_type", "root_note", "octave_span",
  "midi_device", "midi_channel", "velocity_ceiling", "velocity_floor",
  "gate_staccato", "gate_legato",
}
for _, id in ipairs(expected_ids) do
  t.assert_true(fake.registered[id] ~= nil, "param registered: " .. id)
end

t.assert_eq(fake.registered.scale_type.kind, "option", "scale_type is an option list")
local scale_options = fake.registered.scale_type.options
t.assert_eq(#scale_options, 41, "scale_type lists all 41 musicutil scales")
t.assert_eq(scale_options[1], "major", "scale index 1 is major, lowercased, matching Scale.SCALES[1]")

t.assert_eq(fake.registered.midi_device.kind, "option", "midi_device is an option list")
local midi_options = fake.registered.midi_device.options
t.assert_eq(#midi_options, 2, "midi_device options built from injected midi_vports")
t.assert_eq(midi_options[1], "1: fake device one", "midi device option labels index+name")
t.assert_eq(midi_options[2], "2: a very long dev", "long device names truncate to 15 chars")

t.assert_eq(#device_change_calls, 1, "on_midi_device_change fires once on registration")
t.assert_eq(device_change_calls[1], 1, "on_midi_device_change fires with the default value (1) on registration")

t.report()
