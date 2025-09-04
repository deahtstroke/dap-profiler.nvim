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

-- Applies an extension mark to a buffer
--- @param buf	number			The buffer to apply the marks
--- @param ns		number			The namespace to use when applying the marks
--- @param line	string			The lines to apply the extension mark to
--- @param hl		string			The highlight group to apply
function M.apply_extmark_to_buf(buf, ns, line, hl)
  if buf == nil or ns == -1 then
    return
  end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    hl_group = vim.api.nvim_get_hl_id_by_name(hl),
    end_line = 0,
    end_col = #line,
  })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

return M
