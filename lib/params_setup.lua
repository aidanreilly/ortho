local Scale = include("lib/scale")

local params_setup = {}

local DIVISIONS = { "1/4", "1/8", "1/16", "1/32" }
local DIVISION_BEATS = { 1, 0.5, 0.25, 0.125 }

function params_setup.division_beats(index)
  return DIVISION_BEATS[index]
end

local function scale_names()
  local names = {}
  for i, scale in ipairs(Scale.SCALES) do
    names[i] = string.lower(scale.name)
  end
  return names
end

local SCALE_NAMES = scale_names()

-- norns exposes up to 16 MIDI device slots (see midi.vports)
local MIDI_DEVICES = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16" }

-- params:get on an option param returns the selected index, not its label;
-- this maps that index back to the scale name Scale.note_for_cell expects.
function params_setup.scale_name(index)
  return SCALE_NAMES[index]
end

-- registers every travel param (spec section 7) onto `p`, which is norns'
-- real `params` global at runtime or a fake recorder in tests.
function params_setup.add_all(p)
  p:add_option("clock_division", "clock division", DIVISIONS, 3) -- default 1/16
  p:add_option("scale_type", "scale", SCALE_NAMES, 1)
  p:add_number("root_note", "root note", 0, 127, 48)
  p:add_number("octave_span", "octave span", 1, 8, 4)
  p:add_number("midi_channel", "midi channel", 1, 16, 1)
  p:add_number("velocity_ceiling", "velocity ceiling", 1, 127, 127)
  p:add_number("velocity_floor", "velocity floor", 1, 127, 20)
  p:add_control("gate_staccato", "gate (staccato)", controlspec.new(0.02, 1, "lin", 0, 0.08, "s"))
  p:add_control("gate_legato", "gate (legato)", controlspec.new(0.02, 4, "lin", 0, 0.4, "s"))
  p:add_option("midi_device", "midi device", MIDI_DEVICES, 1)
end

return params_setup
