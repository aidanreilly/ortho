package.path = package.path .. ";./?.lua"
local Scale = require("lib.scale")
local t = require("tests.testutil")

-- major scale, root=48 (C2), octave_span=8: row 1 col 1 is the root itself
t.assert_eq(Scale.note_for_cell(1, 1, 48, "major", 8), 48, "col1 row1 is root")

-- col 2 = next scale degree (major: +2 semitones)
t.assert_eq(Scale.note_for_cell(2, 1, 48, "major", 8), 50, "col2 is major 2nd")

-- col 8 wraps the 7-degree major scale once, adding an octave
t.assert_eq(Scale.note_for_cell(8, 1, 48, "major", 8), 60, "col8 wraps +1 octave")

-- row 2 with octave_span=8 adds exactly one octave
t.assert_eq(Scale.note_for_cell(1, 2, 48, "major", 8), 60, "row2 span8 is +1 octave")

-- row 2 with octave_span=1 stays in the same octave as row 1
t.assert_eq(Scale.note_for_cell(1, 2, 48, "major", 1), 48, "row2 span1 stays put")

-- row 5 with octave_span=4 spans 8 rows across 4 octaves, 2 rows per octave
t.assert_eq(Scale.note_for_cell(1, 5, 48, "major", 4), 48 + 12 * 2, "row5 span4 is +2 octaves")

t.report()
