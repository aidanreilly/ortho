package.path = package.path .. ";./?.lua"
-- include() is a norns global (path-relative module loader); stub it as a
-- require() wrapper so lib modules that call include() to load each other
-- are loadable under plain lua for testing.
include = function(path) return require((path:gsub("/", "."))) end
local params_setup = require("lib.params_setup")
local t = require("tests.testutil")

-- fake params recorder: mimics just enough of norns' params API to observe
-- which ids get registered, without needing the real norns runtime.
local fake = { registered = {} }
function fake:add_option(id, name, options, default) self.registered[id] = { kind = "option", options = options } end
function fake:add_number(id, name, min, max, default) self.registered[id] = { kind = "number", min = min, max = max } end
function fake:add_control(id, name, controlspec) self.registered[id] = { kind = "control" } end

-- controlspec is a norns global; stub it minimally so this file is loadable
-- under plain lua for testing.
controlspec = { new = function(...) return { ... } end }

params_setup.add_all(fake)

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
local has_major = false
for _, name in ipairs(scale_options) do
  if name == "major" then has_major = true end
end
t.assert_true(has_major, "scale_type options include major")

t.report()
