-- vendored from norns' lua/lib/util.lua — only the functions
-- tests/vendor/controlspec.lua and tests/vendor/params/*.lua call
-- (clamp, round, linlin) plus linexp/explin for completeness (unused by
-- this project's own controlspecs, which are all "lin" warp, but kept so
-- the vendored controlspec.lua doesn't have a silently-missing warp type).
-- On real norns this is a preloaded global, not a required module — test
-- files assign the return value to the global `util` before requiring
-- anything that depends on it.
local util = {}

function util.clamp(n, min, max)
  return math.min(max, (math.max(n, min)))
end

function util.linlin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return (f - slo) / (shi - slo) * (dhi - dlo) + dlo
  end
end

function util.linexp(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return math.pow(dhi / dlo, (f - slo) / (shi - slo)) * dlo
  end
end

function util.explin(slo, shi, dlo, dhi, f)
  if f <= slo then
    return dlo
  elseif f >= shi then
    return dhi
  else
    return math.log(f / slo) / math.log(shi / slo) * (dhi - dlo) + dlo
  end
end

function util.round(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number / (quant or 1) + 0.5) * (quant or 1)
  end
end

return util
