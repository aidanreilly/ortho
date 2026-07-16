local Scale = include("lib/scale")

local params_setup = {}

local DIVISIONS = { "1/4", "1/8", "1/16", "1/32" }
local DIVISION_BEATS = { 1, 0.5, 0.25, 0.125 }

function params_setup.division_beats(index)
  return DIVISION_BEATS[index]
end

-- scale option list must stay in Scale.SCALES's array order: params:get on
-- an option returns the selected index, and Scale.note_for_cell uses that
-- same index directly against Scale.SCALES, so this must not re-sort it.
local function scale_names()
  local names = {}
  for i, s in ipairs(Scale.SCALES) do
    names[i] = s.name:lower()
  end
  return names
end

local SCALE_NAMES = scale_names()

local function midi_device_names(midi_vports)
  local names = {}
  for i = 1, #midi_vports do
    local name = midi_vports[i].name
    names[i] = i .. ": " .. (#name > 15 and name:sub(1, 15) or name)
  end
  return names
end

-- registers every ortho param onto `p` (norns' real `params` global at
-- runtime, or a fake recorder in tests). midi_vports is norns' real
-- midi.vports global at runtime, or a fake array of {name=} tables in
-- tests. on_midi_device_change(vport_index) is invoked whenever the
-- midi_device param changes; norns does NOT fire it on registration by
-- itself, so the caller must apply defaults with params:bang() (see
-- ortho.lua's init()).
function params_setup.add_all(p, midi_vports, on_midi_device_change)
  p:add_option("clock_division", "clock division", DIVISIONS, 3) -- default 1/16
  p:add_option("scale_type", "scale", SCALE_NAMES, 1)
  p:add{type = "number", id = "root_note", name = "root note", min = 0, max = 127, default = 48,
    formatter = function(param) return Scale.note_name(param:get()) end}
  p:add_number("octave_span", "octave span", 1, 8, 4)
  p:add_number("midi_channel", "midi channel", 1, 16, 1)
  p:add_number("velocity_ceiling", "velocity ceiling", 1, 127, 127)
  p:add_number("velocity_floor", "velocity floor", 1, 127, 20)
  p:add_control("gate_staccato", "gate (staccato)", controlspec.new(0.02, 1, "lin", 0, 0.08, "s"))
  p:add_control("gate_legato", "gate (legato)", controlspec.new(0.02, 4, "lin", 0, 0.4, "s"))
  p:add{type = "option", id = "midi_device", name = "midi device",
    options = midi_device_names(midi_vports), default = 1,
    action = function(value) on_midi_device_change(value) end}
end

return params_setup
