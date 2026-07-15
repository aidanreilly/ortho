local Gesture = {}

-- (1,1) is reserved for clear-all (spec's human-facing "(0,0)").
Gesture.CLEAR_X = 1
Gesture.CLEAR_Y = 1

local function is_clear_button(x, y)
  return x == Gesture.CLEAR_X and y == Gesture.CLEAR_Y
end

function Gesture.new(double_tap_window)
  return {
    held = nil,
    pending_dest = nil,
    did_action_while_held = false,
    last_tap = nil,
    double_tap_window = double_tap_window,
  }
end

function Gesture.key(gesture, x, y, z, now)
  if z == 1 then
    return Gesture.on_press(gesture, x, y)
  else
    return Gesture.on_release(gesture, x, y, now)
  end
end

function Gesture.on_press(gesture, x, y)
  if gesture.held == nil then
    gesture.held = { x = x, y = y }
    gesture.did_action_while_held = false
  else
    -- a 3rd+ concurrent press displaces any earlier pending destination;
    -- simultaneous chords beyond hold+tap are explicitly out of scope.
    gesture.pending_dest = { x = x, y = y }
  end
  return nil
end

function Gesture.on_release(gesture, x, y, now)
  if gesture.held and gesture.held.x == x and gesture.held.y == y then
    return Gesture.release_origin(gesture, x, y)
  elseif gesture.pending_dest and gesture.pending_dest.x == x and gesture.pending_dest.y == y then
    return Gesture.release_destination(gesture, x, y, now)
  end
  return nil
end

function Gesture.release_origin(gesture, x, y)
  local action = nil
  -- only a plain tap (nothing else happened, no pending destination still
  -- down) counts as reset/clear; releasing an origin mid-gesture is a
  -- deliberately silent cancel, not a plain tap.
  if not gesture.did_action_while_held and gesture.pending_dest == nil then
    if is_clear_button(x, y) then
      action = { type = "clear_grid" }
    else
      action = { type = "reset_traveler", x = x, y = y }
    end
  end
  gesture.held = nil
  gesture.pending_dest = nil
  gesture.did_action_while_held = false
  return action
end

function Gesture.release_destination(gesture, x, y, now)
  local ox, oy = gesture.held.x, gesture.held.y
  gesture.pending_dest = nil
  -- the reserved clear-all cell is never a path endpoint, on either side
  if is_clear_button(ox, oy) or is_clear_button(x, y) then
    return nil
  end

  local action
  if gesture.last_tap and gesture.last_tap.x == x and gesture.last_tap.y == y
      and (now - gesture.last_tap.time) <= gesture.double_tap_window then
    action = { type = "toggle_elbow", x1 = ox, y1 = oy, x2 = x, y2 = y }
    gesture.last_tap = nil
  else
    action = { type = "toggle_path", x1 = ox, y1 = oy, x2 = x, y2 = y }
    gesture.last_tap = { x = x, y = y, time = now }
  end
  gesture.did_action_while_held = true
  return action
end

return Gesture
