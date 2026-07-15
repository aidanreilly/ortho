local render = {}

render.BRIGHTNESS = { dim = 4, mid = 8, full = 15, off = 0 }

-- pathgrid: a lib/pathgrid.lua instance. travelers: a list of lib/traveler.lua
-- instances. held: {x=,y=} or nil (the node currently held mid-gesture).
function render.compute_led_grid(pathgrid, travelers, held)
  local levels = {}

  for _, cell in ipairs(pathgrid:all_cells()) do
    levels[cell.y] = levels[cell.y] or {}
    levels[cell.y][cell.x] = pathgrid:is_root(cell.x, cell.y) and render.BRIGHTNESS.mid or render.BRIGHTNESS.dim
  end

  for _, traveler in ipairs(travelers) do
    levels[traveler.y] = levels[traveler.y] or {}
    levels[traveler.y][traveler.x] = render.BRIGHTNESS.full
  end

  if held then
    levels[held.y] = levels[held.y] or {}
    if (levels[held.y][held.x] or render.BRIGHTNESS.off) < render.BRIGHTNESS.mid then
      levels[held.y][held.x] = render.BRIGHTNESS.mid
    end
  end

  return levels
end

return render
