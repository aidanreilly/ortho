package.path = package.path .. ";./?.lua"
local NoteOut = require("lib.midiout")
local t = require("tests.testutil")

local calls = {}
local fake_device = {
  note_on = function(_, note, vel, ch) calls[#calls + 1] = { "on", note, vel, ch } end,
  note_off = function(_, note, ch) calls[#calls + 1] = { "off", note, ch } end,
}
local scheduled = nil
local function fake_schedule(seconds, fn)
  scheduled = { seconds = seconds, fn = fn }
end

local note_out = NoteOut.new(fake_device, fake_schedule)
NoteOut.fire(note_out, 60, 100, 0.25, 3)

t.assert_eq(#calls, 1, "note_on fires immediately")
t.assert_eq(calls[1][1], "on", "first call is note_on")
t.assert_eq(calls[1][2], 60, "note_on note number")
t.assert_eq(calls[1][3], 100, "note_on velocity")
t.assert_eq(calls[1][4], 3, "note_on channel")
t.assert_eq(scheduled.seconds, 0.25, "note_off scheduled after gate_seconds")

scheduled.fn() -- simulate the gate elapsing
t.assert_eq(#calls, 2, "note_off fires once the schedule elapses")
t.assert_eq(calls[2][1], "off", "second call is note_off")
t.assert_eq(calls[2][2], 60, "note_off note number matches")
t.assert_eq(calls[2][3], 3, "note_off channel matches")

-- channel is no longer stored on note_out, so a channel change between two
-- fires is picked up immediately on the next call
NoteOut.fire(note_out, 62, 90, 0.1, 7)
t.assert_eq(calls[3][4], 7, "note_on uses the channel passed to this call, not a stored value")

t.report()
