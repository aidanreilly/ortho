local NoteOut = {}
NoteOut.__index = NoteOut

-- device needs :note_on(note, velocity, channel) and :note_off(note, channel).
-- schedule_off(seconds, fn) arranges fn to run after `seconds` have elapsed
-- (norns' clock.run + clock.sleep in production, a fake in tests).
function NoteOut.new(device, channel, schedule_off)
  return setmetatable({ device = device, channel = channel, schedule_off = schedule_off }, NoteOut)
end

function NoteOut:fire(note, velocity, gate_seconds)
  self.device:note_on(note, velocity, self.channel)
  self.schedule_off(gate_seconds, function()
    self.device:note_off(note, self.channel)
  end)
end

return NoteOut
