local utils = require("dap-profiler.utils")
local dap = require("dap")
local format = require("dap-profiler.format")
local metadata = require("dap-profiler.metadata")

local M = {}

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

--- @class dap_configuration
--- @field name string The name of the dap configuration

--- @class language_configurations
--- @field expanded? boolean If the list of configs is expanded
--- @field dap_configurations? dap_configuration[] List of Dap configurations

---@class ui_state
---@field windows windows_state The state of the current windows
---@field buffers buffers_state The state of the buffers
---@field open boolean The whether the current windows are open or closed
---@field language_configs table<string, language_configurations> The current dap-language configs
---@field line_metadata table<integer, line_metadata> The current line metadata

--- @type ui_state
--- @diagnostic disable missing-fields
M.state = {
  buffers = {},
  windows = {},
  language_configs = {},
  line_metadata = {},
  open = false,
}

local function create_left_buffer()
  if M.state.buffers.left and vim.api.nvim_buf_is_valid(M.state.buffers.left.id) then
    return M.state.buffers.left.id
  end
  local buf = vim.api.nvim_create_buf(true, false)

  M.state.buffers.left = { id = buf }

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = M.state.buffers.left.id,
    callback = function()
      M.render_right_window_preview()
    end,
  })
  return buf
end

local function create_right_buffer()
  if M.state.buffers.right and vim.api.nvim_buf_is_valid(M.state.buffers.right.id) then
    return M.state.buffers.right.id
  end
  local buf = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_name(buf, "dap-profiler://preview")
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "hide"

  M.state.buffers.right = { id = buf }

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- TODO: Parse lines back into M.state.language_configs
      vim.notify("Saved dap-profiler state", vim.log.levels.INFO)
    end,
  })
  return buf
end

--- Finds the language for the given configuration name
--- @return string language The language that a config belongs to
local function find_lang_for_config(cfg_name)
  for lang, entry in pairs(M.state.language_configs) do
    for _, cfg in ipairs(entry.dap_configurations) do
      if cfg.name == cfg_name then
        return lang
      end
    end
  end

  return nil
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

function M.toggle_expand_or_select_config()
  local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]

  local line_metadata = M.state.line_metadata[row]
  if not line_metadata then
    return
  end

  local language_config = M.state.language_configs[line_metadata.lang]

  if line_metadata.type == "lang" then
    language_config.expanded = not language_config.expanded
    M.render()
  elseif line_metadata.type == "config" then
    if M.state.windows.right and vim.api.nvim_win_is_valid(M.state.windows.right.id) then
      vim.api.nvim_set_current_win(M.state.windows.right.id)
    end
  end
end

--- Load all DAP configurations saved in memory
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

--- Render all lines needed in each buffer
function M.render()
  local lines = {}
  M.state.line_metadata = {}

  for lang, config in pairs(M.state.language_configs) do
    local icon = config.expanded and "▾" or "▸"
    metadata.insert(M.state.line_metadata, lines, { type = "lang", lang = lang }, icon .. " " .. lang)

    if config.expanded then
      for _, cfg in ipairs(config.dap_configurations) do
        metadata.insert(
          M.state.line_metadata,
          lines,
          { type = "config", lang = lang, config_name = cfg.name },
          "   " .. cfg.name
        )
      end
    end
  end

  utils.write_to_unmodifiable_buf(M.state.buffers.left.id, lines)
end

--- Create windows and buffers, add them to the global state
--- and render lines in the buffers managed by the state
--- @return windows_state
function M.open_windows()
  local win_configs = default_window_configs()

  local left_buf = create_left_buffer()
  local left_window_id = vim.api.nvim_open_win(left_buf, true, win_configs.left_window)
  vim.api.nvim_set_option_value("cursorline", true, {
    win = left_window_id,
  })
  M.state.windows.left = { id = left_window_id, config = win_configs.left_window }

  local right_buf = create_right_buffer()
  local right_window_id = vim.api.nvim_open_win(right_buf, false, win_configs.right_window)
  M.state.windows.right = { id = right_window_id, config = win_configs.right_window }

  M.render()

  M.state.open = true
end

local function focus_left_window()
  local curr = vim.api.nvim_get_current_win()
  if curr ~= M.state.windows.left.id and vim.api.nvim_win_is_valid(M.state.windows.left.id) then
    vim.api.nvim_set_current_win(M.state.windows.left.id)
  end
end

local function focus_right_window()
  local curr = vim.api.nvim_get_current_win()
  if curr ~= M.state.windows.right.id and vim.api.nvim_win_is_valid(M.state.windows.right.id) then
    vim.api.nvim_set_current_win(M.state.windows.right.id)
  end
end

--- Close all windows stored in the global state
function M.close_windows()
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

  M.state.open = false
end

--- Setup default keymaps for the buffers
function M.setup_keymaps()
  local close_function = function()
    M.close_windows()
    M.state.open = false
  end

  local exit_keymaps = { "q", "<Esc>" }
  for _, keymap in pairs(exit_keymaps) do
    vim.keymap.set("n", keymap, "", {
      callback = close_function,
      buffer = M.state.buffers.right.id,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", keymap, close_function, {
      buffer = M.state.buffers.left.id,
      noremap = true,
      silent = true,
    })
  end

  vim.keymap.set("n", "<Esc>", focus_left_window, {
    buffer = M.state.buffers.right.id,
    noremap = true,
    desc = "Focus left window",
  })

  vim.keymap.set("n", "<CR>", function()
    M.toggle_expand_or_select_config()
  end, { buffer = M.state.buffers.left.id, noremap = true, silent = true })

  vim.keymap.set("n", "a", function()
    local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]

    local line_metadata = M.state.line_metadata[row]
    if not line_metadata then
      return
    end

    if line_metadata.type == "lang" then
      local new_name = vim.fn.input("New DAP config name: ")
      if new_name ~= "" then
        --- @type dap_configuration
        local config = {
          name = new_name,
          type = line_metadata.lang,
        }

        table.insert(M.state.language_configs[line_metadata.lang].dap_configurations, config)
        vim.notify("Added config to: " .. line_metadata.lang .. ": " .. new_name, vim.log.levels.INFO)
        M.render()
      end
    elseif line_metadata.type == "config" then
      local new_name = vim.fn.input("New language name: ")
      if new_name ~= "" then
        ---@type dap_configuration
        local config = {
          name = new_name,
        }

        table.insert(M.state.language_configs[line_metadata.lang].dap_configurations, config)
        M.render()
        vim.notify("Added config to: " .. line_metadata.lang .. ": " .. new_name, vim.log.levels.INFO)
      end
    else
      vim.notify("No language found under cursor", vim.log.levels.WARN)
    end
  end, { buffer = M.state.buffers.left.id })

  vim.keymap.set("n", "d", function()
    local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]
    local line_metadata = M.state.line_metadata[row]

    if not line_metadata then
      return
    end

    if line_metadata.type == "config" then
      local choice = vim.fn.confirm("Are you sure want to delete this config?", "&Yes\n&No", 2)
      if choice == 1 then
        local config
        for i, cfg in ipairs(M.state.language_configs[line_metadata.lang].dap_configurations) do
          if line_metadata.config_name == cfg.name then
            table.remove(M.state.language_configs[line_metadata.lang].dap_configurations, i)
            break
          end
        end

        M.render()
      end
    end
  end, { buffer = M.state.buffers.left.id, noremap = true, silent = true })
end

function M.render_right_window_preview()
  local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]

  local line_metadata = M.state.line_metadata[row]
  if not line_metadata then
    return
  end

  local lines = {}
  if line_metadata.type == "lang" then
    lines = format.center_block_in_window(
      M.state.windows.right.id,
      { "Language: " .. line_metadata.lang, "Expand to see configs." }
    )
  elseif line_metadata.type == "config" then
    for _, cfg in pairs(dap.configurations[line_metadata.lang] or {}) do
      if line_metadata.config_name == cfg.name then
        lines = format.pad_lines_space(vim.split(vim.inspect(cfg), "\n"), 1)
        break
      end
    end
  else
    lines = format.center_block_in_window(M.state.windows.right.id, { "No configuration selected" })
  end

  vim.api.nvim_buf_set_lines(M.state.buffers.right.id, 0, -1, false, lines)
end

function M.toggle_profiler()
  if M.state.open then
    M.close_windows()
    return
  end

  M.load_configs()

  M.open_windows()

  M.render()

  M.setup_keymaps()
end

return M
