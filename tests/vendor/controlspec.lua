-- vendored, verbatim, from norns' lua/core/controlspec.lua. References the
-- global `util` (test files must set it before requiring this). Preserves
-- a real upstream quirk at ControlSpec.new's `s.default = default or minval`
-- line: `minval` is not a declared local there (the parameter is named
-- `min`), so on real norns this only matters when `default` is falsy — not
-- "fixed" here, since the whole point of vendoring is testing against real
-- norns behavior, bugs included. This project's own controlspecs always
-- pass an explicit non-nil default, so the quirk never triggers here.

local LinearWarp = {}
function LinearWarp.map(spec, value)
  return util.linlin(0, 1, spec.minval, spec.maxval, value)
end

function LinearWarp.unmap(spec, value)
  return util.linlin(spec.minval, spec.maxval, 0, 1, value)
end

local ExponentialWarp = {}
function ExponentialWarp.map(spec, value)
  return util.linexp(0, 1, spec.minval, spec.maxval, value)
end

function ExponentialWarp.unmap(spec, value)
  return util.explin(spec.minval, spec.maxval, 0, 1, value)
end

local function ampdb(amp)
  return math.log10(amp) * 20.0
end

local function dbamp(db)
  return math.pow(10.0, db * 0.05)
end

local DbFaderWarp = {}

function DbFaderWarp.map(spec, value)
  local minval = spec.minval
  local maxval = spec.maxval
  local range = dbamp(maxval) - dbamp(minval)
  if range >= 0 then
    return ampdb(value * value * range + dbamp(minval))
  else
    return ampdb((1 - (1 - value) * (1 - value)) * range + dbamp(minval))
  end
end

function DbFaderWarp.unmap(spec, value)
  local minval = spec.minval
  local maxval = spec.maxval
  if spec:range() >= 0 then
    return math.sqrt((dbamp(value) - dbamp(minval)) / (dbamp(maxval) - dbamp(minval)))
  else
    return 1 - math.sqrt(1 - ((dbamp(value) - dbamp(minval)) / (dbamp(maxval) - dbamp(minval))))
  end
end

local ControlSpec = {}
ControlSpec.__index = ControlSpec

function ControlSpec.new(min, max, warp, step, default, units, quantum, wrap)
  local s = setmetatable({}, ControlSpec)
  s.minval = min or 0
  s.maxval = max or 1
  if type(warp) == "string" then
    if warp == 'exp' then
      s.warp = ExponentialWarp
    elseif warp == 'db' then
      s.warp = DbFaderWarp
    else
      s.warp = LinearWarp
    end
  else
    s.warp = LinearWarp
  end
  s.step = step or 0
  s.default = default or minval
  s.units = units or ""
  s.quantum = quantum or 0.01
  s.wrap = wrap or false
  return s
end

function ControlSpec.def(args)
  return ControlSpec.new(args.min, args.max, args.warp, args.step, args.default, args.units, args.quantum, args.wrap)
end

function ControlSpec:cliphi()
  return math.max(self.minval, self.maxval)
end

function ControlSpec:cliplo()
  return math.min(self.minval, self.maxval)
end

function ControlSpec:map(value)
  local clamped = util.clamp(value, 0, 1)
  return util.round(self.warp.map(self, clamped), self.step)
end

function ControlSpec:unmap(value)
  local cliplo = self:cliplo()
  local cliphi = self:cliphi()
  local clamped = util.clamp(util.round(value, self.step), cliplo, cliphi)
  return self.warp.unmap(self, clamped)
end

function ControlSpec:constrain(value)
  return util.round(util.clamp(value, self:cliplo(), self:cliphi()), self.step)
end

function ControlSpec:range()
  return self.maxval - self.minval
end

function ControlSpec:ratio()
  if self.minval == 0 then return 1 end
  return self.maxval / self.minval
end

function ControlSpec:copy()
  local s = setmetatable({}, ControlSpec)
  for k, v in pairs(self) do s[k] = v end
  return s
end

return ControlSpec
