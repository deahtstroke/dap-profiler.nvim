local M = {}

--- @class window_configs
--- @field left_window vim.api.keyset.win_config
--- @field right_window vim.api.keyset.win_config

--- Creates the initial configs for the windows by calculating their appropriate positions
--- @return window_configs
function M.create_default_configs()
  local ui_height = vim.o.lines
  local ui_width = vim.o.columns
  local ui_half = math.floor(ui_width / 2)

  local win_width = math.floor(ui_half * 0.4)
  local win_height = math.floor(ui_height * 0.7)

  local outer_margin = math.floor(ui_half - win_width)

  -- left window
  local left_col = math.floor((ui_width - (2 * win_width)) - 1 - outer_margin)
  local left_row = math.floor((ui_height - win_height) / 2)

  -- right window
  local right_col = math.floor((ui_width - win_width) + 1 - outer_margin)
  local right_row = math.floor((ui_height - win_height) / 2)

  return {
    left_window = {
      relative = "editor",
      style = "minimal",
      width = win_width,
      height = win_height,
      col = left_col,
      row = left_row,
      border = "rounded",
      title = "Dap Profiler",
      title_pos = "center",
    },
    right_window = {
      relative = "editor",
      style = "minimal",
      width = win_width,
      height = win_height,
      row = right_row,
      col = right_col,
      border = "rounded",
      title = "Profile Details",
      title_pos = "center",
    },
  }
end

return M
