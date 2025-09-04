local utils = require("dap-profiler.utils")
local dap = require("dap")

local M = {}

local ns = vim.api.nvim_create_namespace("dap_profiler")

--- @class window_details
--- @field id integer Id of the window
--- @field config vim.api.keyset.win_config Configuration of the window

--- @class buffer_details
--- @field id integer The Id of the buffer

--- @class windows_state
--- @field left? window_details Left window configuration
--- @field right? window_details Right window configuration

--- @class buffers_state
--- @field left? buffer_details The left buffer details
--- @field right? buffer_details The right buffer details

--- @class ui_state
--- @field windows windows_state The state of the current windows
--- @field buffers buffers_state The state of the buffers
--- @field open boolean Whether the current windows are open or closed
--- @field language_configs table<string, language_configurations> The current dap-language configs

--- @class dap_configuration
--- @field name string The name of the dap configuration

--- @class language_configurations
--- @field expanded? boolean If the list of configs is expanded
--- @field dap_configurations? dap_configuration[] List of Dap configurations

--- @type ui_state
--- @diagnostic disable missing-fields
M.state = {
  buffers = {},
  windows = {},
  language_configs = {},
  open = false,
}

local function create_left_buffer()
  local buf = vim.api.nvim_create_buf(true, false)

  M.state.buffers.left = { id = buf }
  return buf
end

local function create_right_buffer()
  local buf = vim.api.nvim_create_buf(true, false)

  M.state.buffers.right = { id = buf }
  return buf
end

local function close_windows()
  local left_win_id = M.state.windows.left.id
  local right_win_id = M.state.windows.right.id

  if
    (left_win_id == nil or right_win_id == nil)
    or not vim.api.nvim_win_is_valid(left_win_id)
    or not vim.api.nvim_win_is_valid(right_win_id)
  then
    return
  end

  vim.api.nvim_win_close(M.state.windows.left.id, true)
  vim.api.nvim_win_close(M.state.windows.right.id, true)
end

local function center_text(text, width)
  if text == nil or width <= 0 then
    return ""
  end

  local padding = math.floor((width - #text) / 2)
  return string.rep(" ", padding) .. text
end

--- @class window_configs
--- @field left_window vim.api.keyset.win_config
--- @field right_window vim.api.keyset.win_config

--- Creates the initial configs for the windows by calculating their appropriate positions
--- @return window_configs
local function default_window_configs()
  local ui_height = vim.o.lines
  local ui_width = vim.o.columns
  local ui_half = math.floor(ui_width / 2)

  local win_width = math.floor(ui_half * 0.4)
  local win_height = math.floor(ui_height * 0.7)

  local outer_margin = math.floor(ui_half - win_width)

  -- left window
  local left_col = math.floor((ui_width - (2 * win_width)) - 1 - outer_margin)
  local left_row = math.floor((ui_height - win_height) / 2)

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

function M.toggle_expand()
  local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]
  local line = vim.api.nvim_buf_get_lines(M.state.buffers.left.id, row - 1, row, false)[1]

  if not line then
    return
  end

  local symbol, lang = line:match("^(▸) (.+)$")
  if not symbol then
    symbol, lang = line:match("^(▾) (.+)$")
  end

  local language_config = M.state.language_configs[lang]

  if lang and symbol and language_config then
    language_config.expanded = not language_config.expanded
    M.render()
  end
end

function M.load_configs()
  if M.state.language_configs and next(M.state.language_configs) then
    return
  end

  if not dap.configurations or vim.tbl_isempty(dap.configurations) then
    vim.notify("No DAP configurations found", vim.log.levels.WARN)
    return
  end

  M.state.language_configs = M.state.language_configs or {}

  for lang, configs in pairs(dap.configurations) do
    --- @type language_configurations
    local entry = {
      expanded = false,
      dap_configurations = {},
    }

    for _, cfg in ipairs(configs) do
      --- @type dap_configuration
      local dap_cfg = {
        name = cfg.name or "<unnamed>",
      }

      table.insert(entry.dap_configurations, dap_cfg)
    end

    M.state.language_configs[lang] = entry
  end
end

function M.render()
  local lines = {}

  for lang, config in pairs(M.state.language_configs) do
    local icon = config.expanded and "▾" or "▸"
    table.insert(lines, icon .. " " .. lang)

    if config.expanded then
      for _, cfg in ipairs(config.dap_configurations) do
        table.insert(lines, "  " .. cfg.name)
      end
    end
  end

  utils.write_to_unmodifiable_buf(M.state.buffers.left.id, lines)
end

--- Create windows with buffers and add them to the `state` global variable
--- @return windows_state
local function open_windows()
  local configs = default_window_configs()

  local left_buf = create_left_buffer()
  local left_window_id = vim.api.nvim_open_win(left_buf, true, configs.left_window)
  vim.api.nvim_set_option_value("cursorline", true, {
    win = left_window_id,
  })
  M.state.windows.left = { id = left_window_id, config = configs.left_window }

  local right_buf = create_right_buffer()
  local right_window_id = vim.api.nvim_open_win(right_buf, false, configs.right_window)
  M.state.windows.right = { id = right_window_id, config = configs.right_window }

  M.render()
end

function M.setup_keymaps()
  local close_function = function()
    close_windows()
    M.state.open = false
  end

  local exit_keymaps = { "q", "<Esc><Esc>" }

  for _, keymap in pairs(exit_keymaps) do
    vim.keymap.set("n", keymap, "", {
      callback = close_function,
      buffer = M.state.buffers.right.id,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", keymap, "", {
      callback = close_function,
      buffer = M.state.buffers.left.id,
      noremap = true,
      silent = true,
    })
  end

  vim.keymap.set("n", "<CR>", function()
    M.toggle_expand()
  end, { buffer = M.state.buffers.left.id, noremap = true, silent = true })
end

--- Toggle the UI, if its closed it will open it and vice-versa
function M.toggle_profiler()
  if M.state.open then
    close_windows()
    M.state.open = false
    return
  end

  M.load_configs()

  open_windows()

  M.render()

  M.setup_keymaps()

  M.state.open = true
end

return M
