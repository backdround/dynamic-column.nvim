local buffers_tracker = require("dynamic-column.buffers-tracker")
local context = require("dynamic-column.context")
local drawer = require("dynamic-column.drawer")
local user_column_utils = require("dynamic-column.user-column-utils")

local M = {}

M.namespace = vim.api.nvim_create_namespace("DynamicColumn")

---@param options table
M.setup = function(options)
  vim.validate({ options = { options, { "table", "nil" } } })
  options = options or {}

  M.get_columns = options.get_columns or function(_) end

  M.stop()

  M.buffers_tracker = buffers_tracker.new()
  M.drawer = drawer.new(M.namespace, M.buffers_tracker)

  vim.api.nvim_set_decoration_provider(M.namespace, {
    on_win = function(_, window_id, buffer_id, topline, botline)
      local ctx = context.generate(M.buffers_tracker, window_id, buffer_id)
      local user_columns = M.get_columns(ctx)
      user_columns = user_column_utils.normalize_columns(user_columns)
      M.drawer:draw_window(window_id, buffer_id, topline, botline, user_columns)
    end,

    on_end = function()
      local something_has_changed = M.drawer:finish()

      if something_has_changed then
        vim.schedule(function()
          vim.cmd.redraw({ bang = true })
        end)
      end
    end,
  })
end

M.stop = function()
  if M.drawer ~= nil then
    M.drawer = nil
  end

  if M.buffers_tracker ~= nil then
    M.buffers_tracker:stop()
    M.buffers_tracker = nil
  end

  vim.api.nvim_set_decoration_provider(M.namespace, {})
  vim.cmd.redraw({ bang = true })
end

return M
