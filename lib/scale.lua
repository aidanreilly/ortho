local Scale = {}

Scale.SCALES = {
  major      = {0, 2, 4, 5, 7, 9, 11},
  minor      = {0, 2, 3, 5, 7, 8, 10},
  pentatonic = {0, 2, 4, 7, 9},
  chromatic  = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11},
}

-- col/row are 1-indexed grid coordinates (col 1-16, row 1-8).
-- root is a raw MIDI note number for col1/row1. octave_span (1-8) controls
-- how many octaves the 8 rows cover; wrapping past the scale's degree count
-- also advances an octave, so pitch keeps ascending left-to-right instead
-- of repeating the same octave every wrap.
function Scale.note_for_cell(col, row, root, scale_name, octave_span)
  local degrees = Scale.SCALES[scale_name]
  local degree_count = #degrees
  local degree_index = (col - 1) % degree_count
  local column_octaves = math.floor((col - 1) / degree_count)
  local row_octaves = math.floor((row - 1) * octave_span / 8)
  return root + degrees[degree_index + 1] + 12 * (column_octaves + row_octaves)
end

return Scale
