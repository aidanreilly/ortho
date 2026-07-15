local NoteOut = {}

-- device needs :note_on(note, velocity, channel) and :note_off(note, channel).
-- schedule_off(seconds, fn) arranges fn to run after `seconds` have elapsed
-- (norns' clock.run + clock.sleep in production, a fake in tests).
function NoteOut.new(device, schedule_off)
  return { device = device, schedule_off = schedule_off }
end

-- channel is a per-call argument rather than stored state, so a live
-- midi_channel param change takes effect on the very next fired note with
-- no reconnect/wiring needed.
function NoteOut.fire(note_out, note, velocity, gate_seconds, channel)
  note_out.device:note_on(note, velocity, channel)
  note_out.schedule_off(gate_seconds, function()
    note_out.device:note_off(note, channel)
  end)
end

return NoteOut
