local buffer_update_tracker =
  require("dynamic-column.buffers-tracker.update-tracker")

----------------------------------------------------------------------
---@class DynamicColumn_BufferLinesTracker
local Buffer_lines_tracker = {}
Buffer_lines_tracker.__index = Buffer_lines_tracker

---Update lines that were changed
---@param from number first changed line
---@param original_to number last changed line in the original range
---@param new_to number last changed line in the new range
function Buffer_lines_tracker:_update_lines(from, original_to, new_to)
  local count_of_original_lines = #self.line_widths

  -- Shift existing data
  local shift = new_to - original_to
  if shift > 0 then
    for i = count_of_original_lines, original_to + 1, -1 do
      self.line_widths[i + shift] = self.line_widths[i]
    end
  elseif shift < 0 then
    for i = original_to + 1, count_of_original_lines do
      self.line_widths[i + shift] = self.line_widths[i]
    end
    -- Shrink array
    for i = count_of_original_lines + shift + 1, count_of_original_lines do
      self.line_widths[i] = nil
    end
  end

  -- Recalculate changed line widths
  if from > new_to then
    return
  end

  local lines =
    vim.api.nvim_buf_get_lines(self._buffer_id, from - 1, new_to, true)

  vim.api.nvim_buf_call(self._buffer_id, function()
    for i, line in ipairs(lines) do
      self.line_widths[i + from - 1] = vim.fn.strdisplaywidth(line)
    end
  end)
end

function Buffer_lines_tracker:_reset()
  self.line_widths = {}

  if not self._update_tracker:loaded() then
    return
  end

  local count_of_lines = vim.api.nvim_buf_line_count(self._buffer_id)
  self:_update_lines(1, 1, count_of_lines)
end

---@param from number
---@param to number
---@return number
function Buffer_lines_tracker:get_max_width(from, to)
  local count_of_lines = #(self.line_widths)
  if from < 1 or from > to or to > count_of_lines then
    local context = {
      from = from,
      to = to,
      count_of_lines = count_of_lines,
    }
    error("Invalid parameters: " .. vim.inspect(context))
  end

  local max_width = 0
  for i = from, to do
    if self.line_widths[i] > max_width then
      max_width = self.line_widths[i]
    end
  end
  return max_width
end

function Buffer_lines_tracker:stop()
  self._update_tracker:stop()
end

----------------------------------------------------------------------
---@param buffer_id number
---@return DynamicColumn_BufferLinesTracker
local new = function(buffer_id)
  vim.validate({ buffer_id = { buffer_id, "number" } })

  if buffer_id == 0 then
    buffer_id = vim.api.nvim_get_current_buf()
  end

  ---@class DynamicColumn_BufferLinesTracker
  local tracker = {
    _buffer_id = buffer_id,
    line_widths = {},
  }
  setmetatable(tracker, Buffer_lines_tracker)

  tracker._update_tracker = buffer_update_tracker.new({
    buffer_id = tracker._buffer_id,
    on_reset = function()
      tracker:_reset()
    end,
    on_update = function(...)
      tracker:_update_lines(...)
    end,
  })

  tracker:_reset()

  return tracker
end

return {
  new = new,
}
