-- travel: a grid-based generative MIDI sequencer.
-- See docs/superpowers/specs/2026-07-14-travel-design.md for the full design.

local Scale = include("lib/scale")
local PathGrid = include("lib/pathgrid")
local Traveler = include("lib/traveler")
local Gesture = include("lib/gesture")
local Expression = include("lib/expression")
local NoteOut = include("lib/midiout")
local render = include("lib/render")
local params_setup = include("lib/params_setup")

local DOUBLE_TAP_WINDOW = 0.3

local g = nil
local pathgrid = PathGrid.new()
local gesture = Gesture.new(DOUBLE_TAP_WINDOW)
local travelers = {} -- key "x,y" -> Traveler
local note_out = nil
local clock_id = nil

local function traveler_key(x, y)
  return x .. "," .. y
end

-- keeps exactly one traveler per root cell, adding/removing as paths change
local function sync_travelers()
  local roots = {}
  for _, path in pairs(pathgrid.paths) do
    roots[traveler_key(path.x1, path.y1)] = { x = path.x1, y = path.y1 }
  end
  for key in pairs(travelers) do
    if not roots[key] then travelers[key] = nil end
  end
  for key, root in pairs(roots) do
    if not travelers[key] then travelers[key] = Traveler.new(root.x, root.y) end
  end
end

local function redraw_grid()
  -- render.compute_led_grid expects an array; travelers is keyed by "x,y"
  local traveler_list = {}
  for _, traveler in pairs(travelers) do
    traveler_list[#traveler_list + 1] = traveler
  end
  local levels = render.compute_led_grid(pathgrid, traveler_list, gesture.held)
  for y = 1, 8 do
    for x = 1, 16 do
      g:led(x, y, (levels[y] and levels[y][x]) or render.BRIGHTNESS.off)
    end
  end
  g:refresh()
end

local function path_id_for(x1, y1, x2, y2)
  return string.format("%d,%d->%d,%d", x1, y1, x2, y2)
end

local function flip_orientation(orientation)
  return (orientation == "vertical_first") and "horizontal_first" or "vertical_first"
end

-- a double-tap on an existing path arrives as two actions: tap 1's
-- toggle_path removes the path, then tap 2's toggle_elbow needs to restore
-- it flipped rather than leave it deleted. Stashed here between the two.
local removed_orientation = {}

local function handle_action(action)
  if not action then return end

  if action.type == "clear_grid" then
    pathgrid:clear()
    removed_orientation = {}
  elseif action.type == "reset_traveler" then
    local traveler = travelers[traveler_key(action.x, action.y)]
    if traveler then
      traveler.path_id, traveler.index = nil, nil
      traveler.x, traveler.y = traveler.root_x, traveler.root_y
    end
  elseif action.type == "toggle_path" then
    local id = path_id_for(action.x1, action.y1, action.x2, action.y2)
    if pathgrid:has(id) then
      removed_orientation[id] = pathgrid.paths[id].orientation
      pathgrid:remove(id)
    else
      pathgrid:add(id, action.x1, action.y1, action.x2, action.y2, "vertical_first")
    end
  elseif action.type == "toggle_elbow" then
    local id = path_id_for(action.x1, action.y1, action.x2, action.y2)
    local path = pathgrid.paths[id]
    if path then
      pathgrid:remove(id)
      pathgrid:add(id, action.x1, action.y1, action.x2, action.y2, flip_orientation(path.orientation))
    elseif removed_orientation[id] then
      pathgrid:add(id, action.x1, action.y1, action.x2, action.y2, flip_orientation(removed_orientation[id]))
      removed_orientation[id] = nil
    end
  end

  sync_travelers()
end

local function fire_note(x, y, path_orientation)
  local scale_name = params_setup.scale_name(params:get("scale_type"))
  local note = Scale.note_for_cell(x, y, params:get("root_note"), scale_name, params:get("octave_span"))
  local velocity = Expression.velocity_for_row(y, params:get("velocity_ceiling"), params:get("velocity_floor"))
  local gate = Expression.gate_for_orientation(path_orientation, params:get("gate_staccato"), params:get("gate_legato"))
  note_out:fire(note, velocity, gate)
end

local function clock_loop()
  while true do
    local beats = params_setup.division_beats(params:get("clock_division"))
    clock.sync(beats)
    for _, traveler in pairs(travelers) do
      local result = traveler:step(pathgrid, math.random)
      if result.note then
        fire_note(result.x, result.y, result.orientation)
      end
    end
    redraw_grid()
  end
end

function init()
  math.randomseed(os.time())
  params_setup.add_all(params)

  g = grid.connect()
  g.key = function(x, y, z)
    local action = gesture:key(x, y, z, util.time())
    handle_action(action)
    redraw_grid()
  end

  local midi_device = midi.connect(params:get("midi_device"))
  note_out = NoteOut.new(midi_device, params:get("midi_channel"), function(seconds, fn)
    clock.run(function()
      clock.sleep(seconds)
      fn()
    end)
  end)

  clock_id = clock.run(clock_loop)
  redraw_grid()
end

function cleanup()
  if clock_id then clock.cancel(clock_id) end
end

function redraw()
  screen.clear()
  screen.move(10, 32)
  screen.text("travel")
  screen.update()
end
