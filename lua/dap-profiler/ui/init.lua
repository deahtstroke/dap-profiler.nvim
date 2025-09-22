local M = {}

local utils = require("dap-profiler.utils")
local buffers = require("dap-profiler.ui.buffers")
local state = require("dap-profiler.state")
local ProfilerEvent = require("dap-profiler.state.events").ProfilerEvent
local window_configs = require("dap-profiler.ui.window_configs")

local function draw()
  local lines = {}
  local snapshot = state.get()

  -- Clean metadata on redraw
  snapshot.line_metadata = {}

  for lang, config in pairs(snapshot.language_configs) do
    local icon = config.expanded and "▾" or "▸"
    state.add_line(snapshot.line_metadata, lines, { type = "lang", lang = lang }, icon .. " " .. lang)

    if config.expanded then
      for _, cfg in ipairs(config.dap_configurations) do
        ---@type LineMetadata
        local meta = { type = "config", lang = lang, config_name = cfg.name }
        state.add_line(snapshot.line_metadata, lines, meta, "   " .. cfg.name)
      end
    end
  end

  utils.write_to_unmodifiable_buf(snapshot.buffers.left.id, lines)
end

-- Redraw events
state.get().events:on({
  ProfilerEvent.ConfigAdded,
  ProfilerEvent.ConfigDeleted,
  ProfilerEvent.ConfigRenamed,
  ProfilerEvent.ProfilerTreeExpand,
  ProfilerEvent.ProfilerOpen,
}, draw)

function M.open()
  local win_configs = window_configs.create_default_configs()

  local left_buf = buffers.create_left_buffer()
  local left_window_id = vim.api.nvim_open_win(left_buf, true, win_configs.left_window)
  vim.api.nvim_set_option_value("cursorline", true, {
    win = left_window_id,
  })
  state.get().windows.left = { id = left_window_id, config = win_configs.left_window }

  local right_buf = buffers.create_right_buffer()
  local right_window_id = vim.api.nvim_open_win(right_buf, false, win_configs.right_window)
  state.get().windows.right = { id = right_window_id, config = win_configs.right_window }

  state.get().open = true

  state.get().events:emit(ProfilerEvent.ProfilerOpen)
end

local function focus_left_window()
  local curr = vim.api.nvim_get_current_win()
  if curr ~= M.state.windows.left.id and vim.api.nvim_win_is_valid(M.state.windows.left.id) then
    vim.api.nvim_set_current_win(M.state.windows.left.id)
  end
end

--- Close all windows stored in the global state
function M.close()
  local left_win_id = state.get().windows.left.id
  local right_win_id = state.get().windows.right.id

  if
    (left_win_id == nil or right_win_id == nil)
    or not vim.api.nvim_win_is_valid(left_win_id)
    or not vim.api.nvim_win_is_valid(right_win_id)
  then
    return
  end

  vim.api.nvim_win_close(state.get().windows.left.id, true)
  vim.api.nvim_win_close(state.get().windows.right.id, true)

  state.get().open = false
end

--- Setup default keymaps for the buffers
function M.setup_keymaps()
  local close_function = function()
    M.close()
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

  vim.keymap.set("n", "A", function()
    local row = vim.api.nvim_win_get_cursor(M.state.windows.left.id)[1]

    local new_lang = vim.fn.input("New DAP language: ")
    if new_lang ~= "" then
      ---@type LanguageConfigurations
      local config = {
        expanded = false,
        dap_configurations = {},
      }

      if not M.state.language_configs[new_lang] then
        M.state.language_configs[new_lang] = config
        vim.notify("Added DAP language: " .. new_lang, vim.log.levels.INFO)
        draw()
        return
      end
    end
  end, { buffer = M.state.buffers.left.id, noremap = true, silent = true })

  vim.keymap.set("n", "a", function()
    state.add_config()
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

function M.toggle()
  if M.state.open then
    M.close()
    return
  end

  M.open()

  M.render()
end

return M
