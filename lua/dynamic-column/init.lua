local M = {}

--- Places the given ephemeral character by the coordinates
---@param bufnr integer
---@param line integer
---@param column integer
---@param char string
---@param hl_group string
M.place_char = function(bufnr, line, column, char, hl_group)
  vim.api.nvim_buf_set_extmark(bufnr, M.namespace, line, 0, {
    virt_text_win_col = column - 1,
    virt_text = { { char, hl_group } },
    virt_text_pos = "overlay",
    ephemeral = true,
    priority = 1,
  })
end

--- Render an ephemeral column for a specific buffer
---@param bufnr number
---@param topline number
---@param botline number
M.render_column = function(bufnr, topline, botline)
  for i = topline, botline do
    M.place_char(bufnr, i, 82, "|", "Identifier")
  end
end

---@param options table
M.setup = function(options)
  M.namespace = vim.api.nvim_create_namespace("DynamicColumn")
  vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)

  vim.api.nvim_set_decoration_provider(M.namespace, {
    on_win = function(_, _, bufnr, topline, botline)
      M.render_column(bufnr, topline, botline)
    end
  })
end

return M
