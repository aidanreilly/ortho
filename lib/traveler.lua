local PathGrid = include("lib/pathgrid")

local Traveler = {}

function Traveler.new(root_x, root_y)
  return {
    root_x = root_x, root_y = root_y,
    x = root_x, y = root_y,
    path_id = nil, index = nil,
  }
end

local function pick_occurrence(occurrences, rng)
  return occurrences[rng(1, #occurrences)]
end

-- Advances the traveler by exactly one grid-step per call, except the call
-- that resolves an unresolved (fresh/just-reset) traveler at its root,
-- which only picks a starting path and does not move (spec's deliberate
-- one-tick dwell at the root between loops).
function Traveler.step(traveler, pathgrid, rng)
  if traveler.path_id == nil then
    local occurrences = PathGrid.occurrences_at(pathgrid, traveler.root_x, traveler.root_y)
    if #occurrences == 0 then
      return { note = false }
    end
    local chosen = pick_occurrence(occurrences, rng)
    traveler.path_id, traveler.index = chosen.path_id, chosen.index
    traveler.x, traveler.y = traveler.root_x, traveler.root_y
    return { note = false }
  end

  local route = PathGrid.path_route(pathgrid, traveler.path_id)
  if not route then
    -- path was deleted out from under this traveler; re-resolve next tick
    traveler.path_id, traveler.index = nil, nil
    traveler.x, traveler.y = traveler.root_x, traveler.root_y
    return { note = false }
  end

  traveler.index = traveler.index + 1
  local cell = route[traveler.index]
  traveler.x, traveler.y = cell.x, cell.y

  local occurrences = PathGrid.occurrences_at(pathgrid, cell.x, cell.y)
  if #occurrences > 1 then
    local chosen = pick_occurrence(occurrences, rng)
    traveler.path_id, traveler.index = chosen.path_id, chosen.index
    route = PathGrid.path_route(pathgrid, traveler.path_id)
  end

  if traveler.index >= #route then
    -- Read the finishing path's orientation before clearing path_id: a
    -- later task's clock loop reads this off the dead-end result to pick
    -- gate length, so it must come from the path that just finished, not
    -- from whatever traveler.path_id resolves to after we clear it.
    local finishing_path = pathgrid.paths[traveler.path_id]
    local orientation = finishing_path and finishing_path.orientation
    traveler.path_id, traveler.index = nil, nil
    return { note = true, x = cell.x, y = cell.y, orientation = orientation }
  end

  return { note = false }
end

return Traveler
