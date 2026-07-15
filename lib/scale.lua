local Scale = {}

Scale.SCALES = {
  {name = "Major", intervals = {0, 2, 4, 5, 7, 9, 11, 12}},
  {name = "Natural Minor", intervals = {0, 2, 3, 5, 7, 8, 10, 12}},
  {name = "Harmonic Minor", intervals = {0, 2, 3, 5, 7, 8, 11, 12}},
  {name = "Melodic Minor", intervals = {0, 2, 3, 5, 7, 9, 11, 12}},
  {name = "Dorian", intervals = {0, 2, 3, 5, 7, 9, 10, 12}},
  {name = "Phrygian", intervals = {0, 1, 3, 5, 7, 8, 10, 12}},
  {name = "Lydian", intervals = {0, 2, 4, 6, 7, 9, 11, 12}},
  {name = "Mixolydian", intervals = {0, 2, 4, 5, 7, 9, 10, 12}},
  {name = "Locrian", intervals = {0, 1, 3, 5, 6, 8, 10, 12}},
  {name = "Whole Tone", intervals = {0, 2, 4, 6, 8, 10, 12}},
  {name = "Major Pentatonic", intervals = {0, 2, 4, 7, 9, 12}},
  {name = "Minor Pentatonic", intervals = {0, 3, 5, 7, 10, 12}},
  {name = "Major Bebop", intervals = {0, 2, 4, 5, 7, 8, 9, 11, 12}},
  {name = "Altered Scale", intervals = {0, 1, 3, 4, 6, 8, 10, 12}},
  {name = "Dorian Bebop", intervals = {0, 2, 3, 4, 5, 7, 9, 10, 12}},
  {name = "Mixolydian Bebop", intervals = {0, 2, 4, 5, 7, 9, 10, 11, 12}},
  {name = "Blues Scale", intervals = {0, 3, 5, 6, 7, 10, 12}},
  {name = "Diminished Whole Half", intervals = {0, 2, 3, 5, 6, 8, 9, 11, 12}},
  {name = "Diminished Half Whole", intervals = {0, 1, 3, 4, 6, 7, 9, 10, 12}},
  {name = "Neapolitan Major", intervals = {0, 1, 3, 5, 7, 9, 11, 12}},
  {name = "Hungarian Major", intervals = {0, 3, 4, 6, 7, 9, 10, 12}},
  {name = "Harmonic Major", intervals = {0, 2, 4, 5, 7, 8, 11, 12}},
  {name = "Hungarian Minor", intervals = {0, 2, 3, 6, 7, 8, 11, 12}},
  {name = "Lydian Minor", intervals = {0, 2, 4, 6, 7, 8, 10, 12}},
  {name = "Neapolitan Minor", intervals = {0, 1, 3, 5, 7, 8, 11, 12}},
  {name = "Major Locrian", intervals = {0, 2, 4, 5, 6, 8, 10, 12}},
  {name = "Leading Whole Tone", intervals = {0, 2, 4, 6, 8, 10, 11, 12}},
  {name = "Six Tone Symmetrical", intervals = {0, 1, 4, 5, 8, 9, 11, 12}},
  {name = "Balinese", intervals = {0, 1, 3, 7, 8, 12}},
  {name = "Persian", intervals = {0, 1, 4, 5, 6, 8, 11, 12}},
  {name = "East Indian Purvi", intervals = {0, 1, 4, 6, 7, 8, 11, 12}},
  {name = "Oriental", intervals = {0, 1, 4, 5, 6, 9, 10, 12}},
  {name = "Double Harmonic", intervals = {0, 1, 4, 5, 7, 8, 11, 12}},
  {name = "Enigmatic", intervals = {0, 1, 4, 6, 8, 10, 11, 12}},
  {name = "Overtone", intervals = {0, 2, 4, 6, 7, 9, 10, 12}},
  {name = "Eight Tone Spanish", intervals = {0, 1, 3, 4, 5, 6, 8, 10, 12}},
  {name = "Prometheus", intervals = {0, 2, 4, 6, 9, 10, 12}},
  {name = "Gagaku Rittsu Sen Pou", intervals = {0, 2, 5, 7, 9, 10, 12}},
  {name = "In Sen Pou", intervals = {0, 1, 5, 2, 8, 12}},
  {name = "Okinawa", intervals = {0, 4, 5, 7, 11, 12}},
  {name = "Chromatic", intervals = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}},
}

local NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

-- vendored from norns' musicutil.lua (v1.1.2) generate_scale_array: walks
-- the interval list, bumping the root up an octave (the trailing 12 in
-- `intervals`) each time it wraps, instead of computing degree index and
-- octave count separately. Stops early (returning fewer than `length`
-- notes) if a note would exceed the MIDI range.
local function generate_scale_array(root_num, intervals, length)
  local out = {}
  local scale_len = #intervals
  local i = 0
  while #out < length do
    if i > 0 and i % scale_len == 0 then
      root_num = root_num + intervals[scale_len]
    else
      local note_num = root_num + intervals[i % scale_len + 1]
      if note_num > 127 then break end
      out[#out + 1] = note_num
    end
    i = i + 1
  end
  return out
end

-- col/row are 1-indexed grid coordinates (col 1-16, row 1-8). root is a raw
-- MIDI note number for col1/row1. scale_index selects Scale.SCALES (the
-- same index params:get("scale_type") returns directly). octave_span
-- (1-8) controls how many octaves the 8 rows cover; wrapping past the
-- scale's degree count also advances an octave (via generate_scale_array),
-- so pitch keeps ascending left-to-right instead of repeating the same
-- octave every wrap. Never returns a note above 127, even when root,
-- scale_index, and col would otherwise combine to overshoot it.
function Scale.note_for_cell(col, row, root, scale_index, octave_span)
  local column_notes = generate_scale_array(root, Scale.SCALES[scale_index].intervals, col)
  local row_octaves = math.floor((row - 1) * octave_span / 8)
  local note = (column_notes[col] or 127) + 12 * row_octaves
  return math.min(note, 127)
end

-- vendored from norns' musicutil.lua note_num_to_name(note_num, true)
function Scale.note_name(note_num)
  local name = NOTE_NAMES[note_num % 12 + 1]
  return name .. math.floor(note_num / 12 - 2)
end

return Scale
