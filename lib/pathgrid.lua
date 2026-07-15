local PathGrid = {}
PathGrid.__index = PathGrid

function PathGrid.new()
  return setmetatable({ paths = {}, cells = {} }, PathGrid)
end

local function cell_key(x, y)
  return x .. "," .. y
end

-- ascending or descending inclusive integer range
local function inclusive_range(a, b)
  local list = {}
  local step = (b >= a) and 1 or -1
  for v = a, b, step do
    list[#list + 1] = v
  end
  return list
end

-- returns an ordered, inclusive list of {x=,y=} cells from (x1,y1) to
-- (x2,y2). Straight lines walk whichever axis differs; elbows bend at the
-- corner implied by `orientation`, counting the corner cell exactly once.
local function compute_route(x1, y1, x2, y2, orientation)
  local cells = {}
  if x1 == x2 then
    for _, y in ipairs(inclusive_range(y1, y2)) do
      cells[#cells + 1] = { x = x1, y = y }
    end
    return cells
  elseif y1 == y2 then
    for _, x in ipairs(inclusive_range(x1, x2)) do
      cells[#cells + 1] = { x = x, y = y1 }
    end
    return cells
  end

  if orientation == "vertical_first" then
    for _, y in ipairs(inclusive_range(y1, y2)) do
      cells[#cells + 1] = { x = x1, y = y }
    end
    local xs = inclusive_range(x1, x2)
    for i = 2, #xs do
      cells[#cells + 1] = { x = xs[i], y = y2 }
    end
  else
    for _, x in ipairs(inclusive_range(x1, x2)) do
      cells[#cells + 1] = { x = x, y = y1 }
    end
    local ys = inclusive_range(y1, y2)
    for i = 2, #ys do
      cells[#cells + 1] = { x = x2, y = ys[i] }
    end
  end
  return cells
end

function PathGrid:add(path_id, x1, y1, x2, y2, orientation)
  -- straight lines always run along one axis; normalize their stored
  -- orientation to match it (ignoring whatever the caller passed), so a
  -- naive caller default doesn't mislabel gate length, and so double-tap
  -- elbow-toggle is naturally a no-op for them (§3: "nothing to toggle").
  if x1 == x2 then
    orientation = "vertical_first"
  elseif y1 == y2 then
    orientation = "horizontal_first"
  end
  local route = compute_route(x1, y1, x2, y2, orientation)
  self.paths[path_id] = { route = route, x1 = x1, y1 = y1, x2 = x2, y2 = y2, orientation = orientation }
  for index, cell in ipairs(route) do
    local key = cell_key(cell.x, cell.y)
    self.cells[key] = self.cells[key] or {}
    table.insert(self.cells[key], { path_id = path_id, index = index })
  end
end

function PathGrid:remove(path_id)
  local path = self.paths[path_id]
  if not path then return end
  for _, cell in ipairs(path.route) do
    local key = cell_key(cell.x, cell.y)
    local occupants = self.cells[key]
    if occupants then
      for i = #occupants, 1, -1 do
        if occupants[i].path_id == path_id then
          table.remove(occupants, i)
        end
      end
      if #occupants == 0 then
        self.cells[key] = nil
      end
    end
  end
  self.paths[path_id] = nil
end

function PathGrid:has(path_id)
  return self.paths[path_id] ~= nil
end

function PathGrid:occurrences_at(x, y)
  return self.cells[cell_key(x, y)] or {}
end

function PathGrid:is_decision_cell(x, y)
  return #self:occurrences_at(x, y) > 1
end

function PathGrid:path_route(path_id)
  local path = self.paths[path_id]
  return path and path.route or nil
end

function PathGrid:paths_starting_at(x, y)
  local ids = {}
  for path_id, path in pairs(self.paths) do
    if path.x1 == x and path.y1 == y then
      ids[#ids + 1] = path_id
    end
  end
  return ids
end

function PathGrid:is_root(x, y)
  return #self:paths_starting_at(x, y) > 0
end

function PathGrid:all_cells()
  local list = {}
  for key in pairs(self.cells) do
    local xs, ys = key:match("^(%-?%d+),(%-?%d+)$")
    list[#list + 1] = { x = tonumber(xs), y = tonumber(ys) }
  end
  return list
end

function PathGrid:clear()
  self.paths = {}
  self.cells = {}
end

return PathGrid
