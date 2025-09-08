local M = {}

--- Pads each line in the lines table by num amount of spaces
--- @param lines string[] The lines to pad
--- @param num integer The amount of spaces to pad the lines by
--- @return string[] padded
function M.pad_lines_space(lines, num)
  if type(lines) ~= "table" or #lines == 0 then
    return {}
  end

  local padded = {}
  for _, line in ipairs(lines) do
    table.insert(padded, string.rep(" ", num) .. tostring(line or ""))
  end

  return padded
end

--- Center lines in a window
--- @param win_id integer the window ID where to center them
--- @param lines string[]  Lines to center
--- @return string[] centered Centered lines
function M.center_block_in_window(win_id, lines)
  local width = vim.api.nvim_win_get_width(win_id)
  local height = vim.api.nvim_win_get_height(win_id)
  if lines == nil or width <= 0 or height <= 0 then
    return {}
  end

  local max_len = 0
  for _, line in ipairs(lines) do
    max_len = math.max(max_len, #line)
  end

  local pad = math.max(0, math.floor((width - max_len) / 2))

  local padded_lines = {}
  for _, line in ipairs(lines) do
    table.insert(padded_lines, string.rep(" ", pad) .. line)
  end

  local top_pad = math.max(0, math.floor((height - #padded_lines) / 2))

  local final_lines = {}
  for _ = 1, top_pad do
    table.insert(final_lines, "")
  end

  vim.list_extend(final_lines, padded_lines)
  return final_lines
end

return M
