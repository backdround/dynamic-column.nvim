local window_buffer_drawer = require("dynamic-column.drawer.window-buffer")

---Draws user columns for any window-buffers
---@class DynamicColumn_Drawer
local Drawer = {}
Drawer.__index = Drawer

---@param window_id number
---@param buffer_id number
---@param topline number
---@param botline number
---@param user_columns DynamicColumn_UserColumn[]
function Drawer:draw_window(
  window_id,
  buffer_id,
  topline,
  botline,
  user_columns
)
  local key = tostring(window_id) .. "_" .. tostring(buffer_id)
  local window_buffer = self._window_buffers[key]
  if window_buffer == nil then
    window_buffer = window_buffer_drawer.new(
      window_id,
      buffer_id,
      self._namespace,
      self._buffers_tracker
    )
  end

  self._current_cycle_drawn_window_buffers[key] = window_buffer

  local changed = window_buffer:draw(topline, botline, user_columns)
  self._changed = self._changed or changed
end

---@return boolean
function Drawer:finish()
  self._window_buffers = self._current_cycle_drawn_window_buffers
  self._current_cycle_drawn_window_buffers = {}

  local something_has_changed = self._changed
  self._changed = false

  return something_has_changed
end

---@param namespace number
---@param buffers_tracker DynamicColumn_BuffersTracker
---@return DynamicColumn_Drawer
local new = function(namespace, buffers_tracker)
  ---@class DynamicColumn_Drawer
  local drawer = {
    _namespace = namespace,
    _buffers_tracker = buffers_tracker,
    _window_buffers = {},
    _current_cycle_drawn_window_buffers = {},
    _changed = true,
  }
  setmetatable(drawer, Drawer)

  return drawer
end

return {
  new = new
}
