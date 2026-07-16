-- Trimmed, verified port of norns' lua/core/paramset.lua (ParamSet), kept
-- to exactly what this project's tests need: add/add_option/add_number/
-- add_control, get, set, bang, lookup_param. Dropped relative to the real
-- source: dispatch for file/taper/trigger/binary/group/text/separator
-- param types (never used in this project), the ID-collision-detection
-- branch (only matters with a fixed system_param_ids list, irrelevant to
-- fresh per-test paramsets with unique ids), and the MIDI-pmap-echo block
-- in add() (the vendored option/number/control set() methods still have
-- their own pmap-echo blocks, made safely inert by an empty
-- norns.pmap.data global — see tests/vendor/params/option.lua).
--
-- The one behavior this vendoring exists to get right, verified directly
-- against the real source: add() stores `action` but never calls it; only
-- set() and bang() do (bang() calls every registered param's own :bang(),
-- which calls self.action(self:get())).
local number = require 'tests.vendor.params.number'
local option = require 'tests.vendor.params.option'
local control = require 'tests.vendor.params.control'

local ParamSet = {}
ParamSet.__index = ParamSet

ParamSet.tNUMBER = 1
ParamSet.tOPTION = 2
ParamSet.tCONTROL = 3

function ParamSet.new(id, name)
  local ps = setmetatable({}, ParamSet)
  ps.id = id or ""
  ps.name = name or ""
  ps.params = {}
  ps.count = 0
  ps.hidden = {}
  ps.lookup = {}
  ps.group = 0
  return ps
end

function ParamSet:add(args)
  local param = args.param
  if param == nil then
    if args.type == nil then
      print("paramset.add() error: type required")
      return nil
    elseif args.id == nil then
      print("paramset.add() error: id required")
      return nil
    end

    local id = args.id
    local name = args.name or id

    if args.type == "number" then
      param = number.new(id, name, args.min, args.max, args.default, args.formatter, args.wrap, args.allow_pmap)
    elseif args.type == "option" then
      param = option.new(id, name, args.options, args.default, args.allow_pmap)
    elseif args.type == "control" then
      param = control.new(id, name, args.controlspec, args.formatter, args.allow_pmap)
    else
      print("paramset.add() error: type '" .. tostring(args.type) .. "' is not vendored for tests (only number/option/control are)")
      return nil
    end
  end

  table.insert(self.params, param)
  self.count = self.count + 1
  self.lookup[param.id] = self.count
  self.hidden[self.count] = false
  if args.action then
    param.action = args.action
  end
end

function ParamSet:add_number(id, name, min, max, default, formatter, wrap)
  self:add { param = number.new(id, name, min, max, default, formatter, wrap) }
end

function ParamSet:add_option(id, name, options, default)
  self:add { param = option.new(id, name, options, default) }
end

function ParamSet:add_control(id, name, controlspec, formatter)
  self:add { param = control.new(id, name, controlspec, formatter) }
end

function ParamSet:lookup_param(index)
  if type(index) == "string" and self.lookup[index] then
    return self.params[self.lookup[index]]
  elseif self.params[index] then
    return self.params[index]
  else
    error("invalid paramset index: " .. tostring(index))
  end
end

function ParamSet:get(index)
  return self:lookup_param(index):get()
end

function ParamSet:set(index, v, silent)
  return self:lookup_param(index):set(v, silent)
end

function ParamSet:bang()
  for _, v in pairs(self.params) do
    v:bang()
  end
end

return ParamSet
