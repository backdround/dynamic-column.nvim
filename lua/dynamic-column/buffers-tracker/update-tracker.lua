----------------------------------------------------------------------
---Tracks buffer state and shoots reset and update events.
---@class DynamicColumn_BufferUpdateTracker
local Buffer_update_tracker = {}
Buffer_update_tracker.__index = Buffer_update_tracker

---@param mute_event? boolean
function Buffer_update_tracker:_move_to_loaded_state(mute_event)
  if not self:loaded() then
    local template = "Can't move to loaded state. The buffer %s is unloaded"
    error(template:format(self._buffer_id))
  end

  if not mute_event then
    self._on_reset()
  end

  local attach_status = vim.api.nvim_buf_attach(self._buffer_id, false, {
    on_lines = function(_, _, _, from, original_to, new_to)
      if not self._running then
        return true
      end
      self._on_update(from + 1, original_to, new_to)
    end,

    on_detach = function()
      if self._running then
        self:_move_to_unloaded_state()
      end
    end,

    on_reload = function()
      if self._running then
        self._on_reset()
      end
    end,
  })

  assert(attach_status, "Unreachable: nvim_buf_attach failed")
end

---@param mute_event? boolean
function Buffer_update_tracker:_move_to_unloaded_state(mute_event)
  if self:loaded() then
    local template = "Can't move to unloaded state. The buffer %s is loaded"
    error(template:format(self._buffer_id))
  end

  if not mute_event then
    self._on_reset()
  end

  -- Wait for buffer loading.
  vim.api.nvim_create_autocmd("BufRead", {
    callback = function(event)
      if not self._running then
        return true
      end

      if event.buf ~= self._buffer_id then
        return
      end

      self:_move_to_loaded_state()
      return true
    end
  })
end

---Is buffer loaded.
---@return boolean
function Buffer_update_tracker:loaded()
  return vim.api.nvim_buf_is_loaded(self._buffer_id)
end

---Stops track for the buffer.
function Buffer_update_tracker:stop()
  self._running = false
end

----------------------------------------------------------------------
---@class DynamicColumn_BufferUpdateTrackerOptions
---@field buffer_id number
---@field on_reset fun()
---@field on_update fun(from: number, original_to: number, new_to: number)

---@param options DynamicColumn_BufferUpdateTrackerOptions
---@return DynamicColumn_BufferUpdateTracker
local new = function(options)
  vim.validate({
    buffer_id = { options.buffer_id, "number" },
    on_reset = { options.on_reset, "function" },
    on_update = { options.on_update, "function" },
  })

  ---@class DynamicColumn_BufferUpdateTracker
  local tracker = {
    _running = true,
    _buffer_id = options.buffer_id,
    _on_reset = options.on_reset,
    _on_update = options.on_update,
  }

  if tracker._buffer_id == 0 then
    tracker._buffer_id = vim.api.nvim_get_current_buf()
  end
  setmetatable(tracker, Buffer_update_tracker)

  if tracker:loaded() then
    tracker:_move_to_loaded_state(true)
  else
    tracker:_move_to_unloaded_state(true)
  end

  return tracker
end

return {
  new = new,
}
