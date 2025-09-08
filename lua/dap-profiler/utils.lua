local M = {}

--- Writes lines to an unmodifiable buffer
--- @param buf		number			The buffer to write to
--- @param lines string[]		The lines to write to the buffer
function M.write_to_unmodifiable_buf(buf, lines)
  if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

return M
