package.path = package.path .. ";./?.lua"
local Scale = require("lib.scale")
local t = require("tests.testutil")

-- major (Scale.SCALES[1]), root=48 (C2), octave_span=8: row 1 col 1 is the root itself
t.assert_eq(Scale.note_for_cell(1, 1, 48, 1, 8), 48, "col1 row1 is root")

-- col 2 = next scale degree (major: +2 semitones)
t.assert_eq(Scale.note_for_cell(2, 1, 48, 1, 8), 50, "col2 is major 2nd")

-- col 8 wraps the 7-degree major scale once, adding an octave
t.assert_eq(Scale.note_for_cell(8, 1, 48, 1, 8), 60, "col8 wraps +1 octave")

-- row 2 with octave_span=8 adds exactly one octave
t.assert_eq(Scale.note_for_cell(1, 2, 48, 1, 8), 60, "row2 span8 is +1 octave")

-- row 2 with octave_span=1 stays in the same octave as row 1
t.assert_eq(Scale.note_for_cell(1, 2, 48, 1, 1), 48, "row2 span1 stays put")

-- row 5 with octave_span=4 spans 8 rows across 4 octaves, 2 rows per octave
t.assert_eq(Scale.note_for_cell(1, 5, 48, 1, 4), 48 + 12 * 2, "row5 span4 is +2 octaves")

-- a scale with a different degree count than major/minor's 7: Major
-- Pentatonic (index 11), intervals {0,2,4,7,9,12} = 5 unique degrees.
-- col6 lands exactly on the octave-close interval (12), wrapping +1 octave.
t.assert_eq(Scale.note_for_cell(1, 1, 48, 11, 8), 48, "pentatonic col1 is root")
t.assert_eq(Scale.note_for_cell(6, 1, 48, 11, 8), 60, "pentatonic col6 wraps +1 octave (5 degrees)")

-- 127 ceiling: root=127 col=16 major would overshoot without the guard
-- (generate_scale_array stops after the first note, since root+2 > 127)
t.assert_eq(Scale.note_for_cell(16, 1, 127, 1, 8), 127, "note is clamped to 127, never sent out of MIDI range")

-- Scale.note_name formats a MIDI note number, matching musicutil's octave convention
t.assert_eq(Scale.note_name(60), "C3", "note_name formats note 60 as C3")
t.assert_eq(Scale.note_name(61), "C#3", "note_name formats a sharp")

t.report()
