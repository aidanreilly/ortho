-- vendored, verbatim except the require path, from norns'
-- lua/core/params/control.lua. References the globals `util` and `norns`
-- (see option.lua's note above).
local ControlSpec = require 'tests.vendor.controlspec'

local Control = {}
Control.__index = Control

local tCONTROL = 3

function Control.new(id, name, controlspec, formatter, allow_pmap)
  local p = setmetatable({}, Control)
  p.t = tCONTROL
  if not controlspec then controlspec = ControlSpec.UNIPOLAR end
  p.id = id
  p.name = name
  p.controlspec = controlspec
  p.formatter = formatter
  p.action = function(x) end
  if allow_pmap == nil then p.allow_pmap = true else p.allow_pmap = allow_pmap end

  if controlspec.default then
    p.raw = controlspec:unmap(controlspec.default)
  else
    p.raw = 0
  end
  return p
end

function Control:map_value(value)
  return self.controlspec:map(value)
end

function Control:get()
  return self:map_value(self.raw)
end

function Control:get_raw()
  return self.raw
end

function Control:unmap_value(value)
  return self.controlspec:unmap(util.round(value, self.controlspec.step))
end

function Control:set(value, silent)
  self:set_raw(self:unmap_value(value), silent)
end

function Control:set_raw(value, silent)
  local silent = silent or false
  if self.controlspec.wrap then
    while value > 1 do
      value = value - 1
    end
    while value < 0 do
      value = value + 1
    end
  end
  local clamped_value = util.clamp(value, 0, 1)
  if self.raw ~= clamped_value then
    self.raw = clamped_value
    if silent == false then self:bang() end
  end
  if norns.pmap.data[self.id] ~= nil then
    local midi_prm = norns.pmap.data[self.id]
    midi_prm.value = util.round(util.linlin(midi_prm.out_lo, midi_prm.out_hi, midi_prm.in_lo, midi_prm.in_hi, self.raw))
    if midi_prm.echo then
      local port = norns.pmap.data[self.id].dev
      midi.vports[port]:cc(midi_prm.cc, midi_prm.value, midi_prm.ch)
    end
  end
end

function Control:get_delta()
  return self.controlspec.quantum
end

function Control:delta(d)
  self:set_raw(self.raw + d * self:get_delta())
end

function Control:set_default()
  self:set(self.controlspec.default)
end

function Control:bang()
  self.action(self:get())
end

function Control:get_range()
  local r = { self.controlspec.minval, self.controlspec.maxval }
  return r
end

function Control:string()
  if self.formatter then
    return self.formatter(self)
  else
    local a = util.round(self:get(), 0.01)
    return a .. " " .. self.controlspec.units
  end
end

return Control
