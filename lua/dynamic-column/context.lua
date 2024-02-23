---@class DynamicColumn_Scope
---@field buffer number
---@field visible number
---@field line number
---@field cursor number

---@class DynamicColumn_Context
---@field buffer_id number
---@field filetype string
---@field buftype string
---@field modifiable boolean
---@field scope DynamicColumn_Scope

---@param buffers_tracker DynamicColumn_BuffersTracker
---@param window_id number
---@param buffer_id number
---@return DynamicColumn_Context
local generate = function(buffers_tracker, window_id, buffer_id)
  local scope = {}
  scope.buffer = buffers_tracker:get_width(buffer_id)

  local current_line = vim.api.nvim_win_get_cursor(window_id)[1]
  scope.line = buffers_tracker:get_line_width(buffer_id, current_line)

  scope.cursor = vim.api.nvim_win_get_cursor(window_id)[2]

  local top = nil
  local bottom = nil
  vim.api.nvim_win_call(window_id, function()
    top = vim.fn.line('w0')
    bottom = vim.fn.line('w$')
  end)

  scope.visible = buffers_tracker:get_width(buffer_id, top, bottom)

  return {
    window_id = window_id,
    buffer_id = buffer_id,
    filetype = vim.bo[buffer_id].filetype,
    buftype = vim.bo[buffer_id].buftype,
    modifiable = vim.bo[buffer_id].modifiable,
    scope = scope,
  }
end

return {
  generate = generate,
}
