local Gesture = {}
Gesture.__index = Gesture

-- (1,1) is reserved for clear-all (spec's human-facing "(0,0)").
Gesture.CLEAR_X = 1
Gesture.CLEAR_Y = 1

local function is_clear_button(x, y)
  return x == Gesture.CLEAR_X and y == Gesture.CLEAR_Y
end

function Gesture.new(double_tap_window)
  return setmetatable({
    held = nil,
    pending_dest = nil,
    did_action_while_held = false,
    last_tap = nil,
    double_tap_window = double_tap_window,
  }, Gesture)
end

function Gesture:key(x, y, z, now)
  if z == 1 then
    return self:on_press(x, y)
  else
    return self:on_release(x, y, now)
  end
end

function Gesture:on_press(x, y)
  if self.held == nil then
    self.held = { x = x, y = y }
    self.did_action_while_held = false
  else
    -- a 3rd+ concurrent press displaces any earlier pending destination;
    -- simultaneous chords beyond hold+tap are explicitly out of scope.
    self.pending_dest = { x = x, y = y }
  end
  return nil
end

function Gesture:on_release(x, y, now)
  if self.held and self.held.x == x and self.held.y == y then
    return self:release_origin(x, y)
  elseif self.pending_dest and self.pending_dest.x == x and self.pending_dest.y == y then
    return self:release_destination(x, y, now)
  end
  return nil
end

function Gesture:release_origin(x, y)
  local action = nil
  -- only a plain tap (nothing else happened, no pending destination still
  -- down) counts as reset/clear; releasing an origin mid-gesture is a
  -- deliberately silent cancel, not a plain tap.
  if not self.did_action_while_held and self.pending_dest == nil then
    if is_clear_button(x, y) then
      action = { type = "clear_grid" }
    else
      action = { type = "reset_traveler", x = x, y = y }
    end
  end
  self.held = nil
  self.pending_dest = nil
  self.did_action_while_held = false
  return action
end

function Gesture:release_destination(x, y, now)
  local ox, oy = self.held.x, self.held.y
  local action
  if self.last_tap and self.last_tap.x == x and self.last_tap.y == y
      and (now - self.last_tap.time) <= self.double_tap_window then
    action = { type = "toggle_elbow", x1 = ox, y1 = oy, x2 = x, y2 = y }
    self.last_tap = nil
  else
    action = { type = "toggle_path", x1 = ox, y1 = oy, x2 = x, y2 = y }
    self.last_tap = { x = x, y = y, time = now }
  end
  self.did_action_while_held = true
  self.pending_dest = nil
  return action
end

return Gesture
