---It draws user columns in the given window-buffer.
---@class DynamicColumn_WindowBufferDrawer
local Drawer = {}
Drawer.__index = Drawer

---@param topline number
---@param botline number
---@param user_column DynamicColumn_UserColumn
function Drawer:_draw_column(topline, botline, user_column)
  local virt_text = { { user_column.char, user_column.highlight } }
  for line = topline, botline do
    vim.api.nvim_buf_set_extmark(self._buffer_id, self._namespace, line, 0, {
      virt_text_win_col = user_column.column - 1,
      virt_text = virt_text,
      virt_text_pos = "overlay",
      priority = 1,
      ephemeral = true,
    })
  end
end

---@param topline number
---@param botline number
---@param user_columns DynamicColumn_UserColumn[]
---@return boolean Something has changed
function Drawer:draw(topline, botline, user_columns)
  for _, user_column in ipairs(user_columns) do
    self:_draw_column(topline, botline, user_column)
  end

  local columns_are_same = vim.deep_equal(user_columns, self._last_drawn_columns)
  self._last_drawn_columns = vim.deepcopy(user_columns)

  return columns_are_same == false
end

---@param window_id number
---@param buffer_id number
---@param namespace number
---@param buffers_tracker DynamicColumn_BuffersTracker
---@return DynamicColumn_WindowBufferDrawer
local new = function(window_id, buffer_id, namespace, buffers_tracker)
  ---@class DynamicColumn_WindowBufferDrawer
  local drawer = {
    _window_id = window_id,
    _buffer_id = buffer_id,
    _namespace = namespace,
    _buffers_tracker = buffers_tracker,
    _last_drawn_columns = {},
  }
  setmetatable(drawer, Drawer)

  return drawer
end

return {
  new = new
}
