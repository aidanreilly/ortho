local Traveler = {}
Traveler.__index = Traveler

function Traveler.new(root_x, root_y)
  return setmetatable({
    root_x = root_x, root_y = root_y,
    x = root_x, y = root_y,
    path_id = nil, index = nil,
  }, Traveler)
end

local function pick_occurrence(occurrences, rng)
  return occurrences[rng(1, #occurrences)]
end

-- Advances the traveler by exactly one grid-step per call, except the call
-- that resolves an unresolved (fresh/just-reset) traveler at its root,
-- which only picks a starting path and does not move (spec's deliberate
-- one-tick dwell at the root between loops).
function Traveler:step(pathgrid, rng)
  if self.path_id == nil then
    local occurrences = pathgrid:occurrences_at(self.root_x, self.root_y)
    if #occurrences == 0 then
      return { note = false }
    end
    local chosen = pick_occurrence(occurrences, rng)
    self.path_id, self.index = chosen.path_id, chosen.index
    self.x, self.y = self.root_x, self.root_y
    return { note = false }
  end

  local route = pathgrid:path_route(self.path_id)
  if not route then
    -- path was deleted out from under this traveler; re-resolve next tick
    self.path_id, self.index = nil, nil
    self.x, self.y = self.root_x, self.root_y
    return { note = false }
  end

  self.index = self.index + 1
  local cell = route[self.index]
  self.x, self.y = cell.x, cell.y

  local occurrences = pathgrid:occurrences_at(cell.x, cell.y)
  if #occurrences > 1 then
    local chosen = pick_occurrence(occurrences, rng)
    self.path_id, self.index = chosen.path_id, chosen.index
    route = pathgrid:path_route(self.path_id)
  end

  if self.index >= #route then
    -- Read the finishing path's orientation before clearing path_id: a
    -- later task's clock loop reads this off the dead-end result to pick
    -- gate length, so it must come from the path that just finished, not
    -- from whatever self.path_id resolves to after we clear it.
    local finishing_path = pathgrid.paths[self.path_id]
    local orientation = finishing_path and finishing_path.orientation
    self.path_id, self.index = nil, nil
    return { note = true, x = cell.x, y = cell.y, orientation = orientation }
  end

  return { note = false }
end

return Traveler
