local M = {}

---@class DynamicColumn_UserColumn
---@field column number
---@field char string
---@field highlight string

---Checks, sorts and returns a copy of received from a user columns.
---@param user_columns? DynamicColumn_UserColumn[]|DynamicColumn_UserColumn
---@return DynamicColumn_UserColumn[]
M.normalize_columns = function(user_columns)
  if user_columns == nil then
    return {}
  end

  if type(user_columns) ~= "table" then
    local message = "User_columns should be a table or nil, but it is: "
      .. vim.inspect(user_columns)
    vim.notify_once(message, vim.log.levels.ERROR)
    return {}
  end

  local is_user_column = function(c)
    return type(c) == "table"
      and #c == 0
      and type(c.column) == "number"
      and type(c.char) == "string"
      and type(c.highlight) == "string"
  end

  if is_user_column(user_columns) then
    return { vim.deepcopy(user_columns) }
  end

  local normalized_columns = {}
  for _, user_column in ipairs(user_columns) do
    if not is_user_column(user_column) then
      local message = "User_column expected, but got: "
        .. vim.inspect(user_column)
      vim.notify_once(message, vim.log.levels.ERROR)
      return {}
    end
    table.insert(normalized_columns, vim.deepcopy(user_columns))
  end

  for i = 2, #normalized_columns do
    if normalized_columns[i].column == normalized_columns[i - 1].column then
      local message = "Several user_columns are on the same column:"
        .. vim.inspect(normalized_columns)
      vim.notify_once(message, vim.log.levels.ERROR)
      return {}
    end
  end

  table.sort(user_columns, function(a, b)
    return a.column < b.column
  end)

  return normalized_columns
end

return M
