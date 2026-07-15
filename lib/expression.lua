local Expression = {}

-- row is 1-indexed (1 = top). Linearly interpolates from `ceiling` at row 1
-- down to `floor` at row 8.
function Expression.velocity_for_row(row, ceiling, floor)
  local t = (row - 1) / 7
  return math.floor(ceiling - (ceiling - floor) * t + 0.5)
end

function Expression.gate_for_orientation(orientation, staccato_seconds, legato_seconds)
  if orientation == "vertical_first" then
    return staccato_seconds
  end
  return legato_seconds
end

return Expression
