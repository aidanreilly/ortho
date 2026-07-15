local NoteOut = {}

-- device needs :note_on(note, velocity, channel) and :note_off(note, channel).
-- schedule_off(seconds, fn) arranges fn to run after `seconds` have elapsed
-- (norns' clock.run + clock.sleep in production, a fake in tests).
function NoteOut.new(device, channel, schedule_off)
  return { device = device, channel = channel, schedule_off = schedule_off }
end

function NoteOut.fire(note_out, note, velocity, gate_seconds)
  note_out.device:note_on(note, velocity, note_out.channel)
  note_out.schedule_off(gate_seconds, function()
    note_out.device:note_off(note, note_out.channel)
  end)
end

return NoteOut
