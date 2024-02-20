local new_buffer_lines_tracker =
  require("dynamic-column.buffers-tracker.lines-tracker").new

----------------------------------------------------------------------
---@class DynamicColumn_BuffersTracker
local Buffers_tracker = {}
Buffers_tracker.__index = Buffers_tracker

---@param buffer_id number
---@param from_line? number
---@param to_line? number
function Buffers_tracker:get_width(buffer_id, from_line, to_line)
  if from_line == nil then
    from_line = 1
  end

  if to_line == nil then
    to_line = vim.api.nvim_buf_line_count(buffer_id)
  end

  local buffer_lines_tracker = self._buffer_lines_trackers[buffer_id]
  if buffer_lines_tracker == nil then
    error("There is no such buffer: " .. tostring(buffer_id))
  end
  buffer_lines_tracker:get_max_width(from_line, to_line)
end

---@param buffer_id number
---@param line number
function Buffers_tracker:get_line_width(buffer_id, line)
  local buffer_lines_tracker = self._buffer_lines_trackers[buffer_id]
  if buffer_lines_tracker == nil then
    error("There is no such buffer: " .. tostring(buffer_id))
  end

  return buffer_lines_tracker.line_widths[line]
end

function Buffers_tracker:stop()
  self._running = false
  for _, line_tracker in ipairs(self._buffer_lines_trackers) do
    line_tracker:stop()
  end
end

----------------------------------------------------------------------
---@return DynamicColumn_BuffersTracker
local new = function()
  ---@class DynamicColumn_BuffersTracker
  local tracker = {
    _running = true,
    _buffer_lines_trackers = {},
  }
  setmetatable(tracker, Buffers_tracker)

  vim.api.nvim_create_autocmd({ "BufNew", "BufWipeout" }, {
    callback = function(event)
      if not tracker._running then
        return true
      end

      if event.event == "BufNew" then
        tracker._buffer_lines_trackers[event.buf] =
          new_buffer_lines_tracker(event.buf)
      elseif event.event == "BufWipeout" then
        tracker._buffer_lines_trackers[event.buf]:stop()
        tracker._buffer_lines_trackers[event.buf] = nil
      else
        error("Unreachable: Unexpected event: " .. event.event)
      end
    end,
  })

  local buffer_ids = vim.api.nvim_list_bufs()
  for _, id in ipairs(buffer_ids) do
    tracker._buffer_lines_trackers[id] = new_buffer_lines_tracker(id)
  end

  return tracker
end

return {
  new = new,
}
