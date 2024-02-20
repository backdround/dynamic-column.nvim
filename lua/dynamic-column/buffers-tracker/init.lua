local new_buffer_lines_tracker =
  require("dynamic-column.buffers-tracker.lines-tracker").new

----------------------------------------------------------------------
---@class DynamicColumn_BuffersTracker
local Buffers_tracker = {}
Buffers_tracker.__index = Buffers_tracker

---@param buffer_id number
---@param from_line? number
---@param to_line? number
---@return number
function Buffers_tracker:get_width(buffer_id, from_line, to_line)
  local lines_tracker = self:_get_lines_tracker(buffer_id)
  if not lines_tracker then
    return 0
  end

  if from_line == nil then
    from_line = 1
  end

  if to_line == nil then
    to_line = vim.api.nvim_buf_line_count(buffer_id)
  end

  return lines_tracker:get_max_length(from_line, to_line)
end

---@param buffer_id number
---@param line number
function Buffers_tracker:get_line_width(buffer_id, line)
  return self:get_width(buffer_id, line, line)
end

---@return DynamicColumn_BufferLinesTracker?
function Buffers_tracker:_get_lines_tracker(buffer_id)
  if buffer_id == 0 then
    buffer_id = vim.api.nvim_get_current_buf()
  end

  local lines_tracker = self._buffer_lines_trackers[buffer_id]
  if lines_tracker then
    return lines_tracker
  end

  if not vim.fn.bufexists(buffer_id) then
    return nil
  end

  if not vim.fn.bufloaded(buffer_id) then
    return nil
  end

  lines_tracker = new_buffer_lines_tracker(buffer_id)
  local attach_status = vim.api.nvim_buf_attach(buffer_id, false, {
    on_lines = function(_, _, _, from, original_to, new_to)
      if not self._running then
        return true
      end

      local tracker = self._buffer_lines_trackers[buffer_id]
      if not tracker then
        return true
      end

      tracker:update_lines(from + 1, original_to, new_to)
    end,

    on_reload = function()
      if not self._running then
        return
      end

      local tracker = self._buffer_lines_trackers[buffer_id]
      if not tracker then
        return
      end

      tracker:reload()
    end,
  })
  assert(attach_status, "Unreachable: nvim_buf_attach failed")

  self._buffer_lines_trackers[buffer_id] = lines_tracker
  return lines_tracker
end

function Buffers_tracker:stop()
  self._running = false
  self._buffer_lines_trackers = {}
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

  vim.api.nvim_create_autocmd("BufUnload", {
    callback = function(event)
      if not tracker._running then
        return true
      end

      tracker._buffer_lines_trackers[event.buf] = nil
    end,
  })

  return tracker
end

return {
  new = new,
}
