package.path = package.path .. ";./?.lua"
-- include() is a norns global (path-relative module loader); stub it as a
-- require() wrapper so lib modules that call include() to load each other
-- are loadable under plain lua for testing. util/norns/controlspec mirror
-- what norns' own runtime provides to every script — see
-- tests/vendor/paramset.lua and its dependents.
include = function(path) return require((path:gsub("/", "."))) end
util = require("tests.vendor.util")
norns = { pmap = { data = {} } }
controlspec = require("tests.vendor.controlspec")
local ParamSet = require("tests.vendor.paramset")
local params_setup = require("lib.params_setup")
local t = require("tests.testutil")

local ps = ParamSet.new()

local fake_vports = { { name = "fake device one" }, { name = "a very long device name here" } }
local device_change_calls = {}
local function fake_on_midi_device_change(value)
  device_change_calls[#device_change_calls + 1] = value
end

params_setup.add_all(ps, fake_vports, fake_on_midi_device_change)

local expected_ids = {
  "clock_division", "scale_type", "root_note", "octave_span",
  "midi_device", "midi_channel", "velocity_ceiling", "velocity_floor",
  "gate_staccato", "gate_legato",
}
for _, id in ipairs(expected_ids) do
  t.assert_true(ps.lookup[id] ~= nil, "param registered: " .. id)
end

t.assert_eq(ps:lookup_param("scale_type").t, ParamSet.tOPTION, "scale_type is an option list")
local scale_options = ps:lookup_param("scale_type").options
t.assert_eq(#scale_options, 41, "scale_type lists all 41 musicutil scales")
t.assert_eq(scale_options[1], "major", "scale index 1 is major, lowercased, matching Scale.SCALES[1]")

t.assert_eq(ps:lookup_param("midi_device").t, ParamSet.tOPTION, "midi_device is an option list")
local midi_options = ps:lookup_param("midi_device").options
t.assert_eq(#midi_options, 2, "midi_device options built from injected midi_vports")
t.assert_eq(midi_options[1], "1: fake device one", "midi device option labels index+name")
t.assert_eq(midi_options[2], "2: a very long dev", "long device names truncate to 15 chars")

-- this is the assertion that would have caught the Critical bug: real
-- norns does NOT fire an option's action on registration, only via
-- set()/bang(). If add_all wrongly relied on add-time firing again, this
-- would catch it (0, not 1) before it ever reached a device.
t.assert_eq(#device_change_calls, 0, "on_midi_device_change does NOT fire on registration (real norns behavior)")

ps:bang()
t.assert_eq(#device_change_calls, 1, "on_midi_device_change fires once ps:bang() is called (mirrors ortho.lua's init())")
t.assert_eq(device_change_calls[1], 1, "on_midi_device_change fires with the default value (1)")

local root_note_param = ps:lookup_param("root_note")
t.assert_eq(root_note_param.t, ParamSet.tNUMBER, "root_note is a number param")
t.assert_eq(root_note_param.formatter(root_note_param), "C2", "root_note's formatter calls Scale.note_name on its current value (default 48 -> C2, per Scale.note_name's octave math: 48%12=0 -> \"C\", floor(48/12-2)=2)")

t.report()
