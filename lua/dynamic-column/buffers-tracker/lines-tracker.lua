----------------------------------------------------------------------
---It Tracks the lengths of lines in the buffer.
---It assumes that the tracked buffer is loaded.
---@class DynamicColumn_BufferLinesTracker
local Buffer_lines_tracker = {}
Buffer_lines_tracker.__index = Buffer_lines_tracker

---Update lines that were changed
---@param from number first changed line
---@param original_to number last changed line in the original range
---@param new_to number last changed line in the new range
function Buffer_lines_tracker:update_lines(from, original_to, new_to)
  local count_of_original_lines = #self.line_lengths

  -- Special case: The entire buffer was removed.
  if original_to == count_of_original_lines and new_to == 0 then
    self.line_lengths = { 0 }
    return
  end

  -- Shift existing data
  local shift = new_to - original_to
  if shift > 0 then
    for i = count_of_original_lines, original_to + 1, -1 do
      self.line_lengths[i + shift] = self.line_lengths[i]
    end
  elseif shift < 0 then
    for i = original_to + 1, count_of_original_lines do
      self.line_lengths[i + shift] = self.line_lengths[i]
    end
    -- Shrink array
    for i = count_of_original_lines + shift + 1, count_of_original_lines do
      self.line_lengths[i] = nil
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
      self.line_lengths[i + from - 1] = vim.fn.strdisplaywidth(line)
    end
  end)
end

---Update lengths, implying that the whole buffer was changed.
function Buffer_lines_tracker:reload()
  self.line_lengths = { 0 }
  local count_of_lines = vim.api.nvim_buf_line_count(self._buffer_id)
  self:update_lines(1, 1, count_of_lines)
end

---@param from_line number
---@param to_line number
---@return number
function Buffer_lines_tracker:get_max_length(from_line, to_line)
  local count_of_lines = #self.line_lengths

  if from_line < 1 or from_line > to_line or to_line > count_of_lines then
    local context = {
      from_line = from_line,
      to_line = to_line,
      count_of_tracked_lines = count_of_lines,
      count_of_real_lines = vim.api.nvim_buf_line_count(self._buffer_id),
      buffer_id = self._buffer_id,
    }
    error("Invalid parameters: " .. vim.inspect(context))
  end

  local max_width = 0
  for i = from_line, to_line do
    if self.line_lengths[i] > max_width then
      max_width = self.line_lengths[i]
    end
  end
  return max_width
end

----------------------------------------------------------------------
---@param buffer_id number
---@return DynamicColumn_BufferLinesTracker
local new = function(buffer_id)
  vim.validate({ buffer_id = { buffer_id, "number" } })

  if not vim.api.nvim_buf_is_loaded(buffer_id) then
    error("The given buffer isn't loaded")
  end

  if buffer_id == 0 then
    buffer_id = vim.api.nvim_get_current_buf()
  end

  ---@class DynamicColumn_BufferLinesTracker
  local tracker = {
    _buffer_id = buffer_id,
    line_lengths = {},
  }
  setmetatable(tracker, Buffer_lines_tracker)

  tracker:reload()

  return tracker
end

return {
  new = new,
}
