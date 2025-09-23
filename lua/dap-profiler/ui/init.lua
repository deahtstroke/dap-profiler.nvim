local M = {}

local buffers = require("dap-profiler.ui.buffers")
local state = require("dap-profiler.state")
local ProfilerEvent = require("dap-profiler.state.events").ProfilerEvent
local window_configs = require("dap-profiler.ui.configs")

--- Writes lines to an unmodifiable buffer
--- @param buf		number			The buffer to write to
--- @param lines string[]		The lines to write to the buffer
local function write_to_unmodifiable_buf(buf, lines)
  if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function draw()
  local lines = {}
  local snapshot = state.get()

  -- Clean metadata on redraw
  snapshot.metadata = {}

  for lang, config in pairs(snapshot.languages) do
    local icon = config.expanded and "▾" or "▸"
    state.add_line(snapshot.metadata, lines, { type = "lang", lang = lang }, icon .. " " .. lang)

    if config.expanded then
      for _, cfg in ipairs(config.dapProfiles) do
        ---@type LineMetadata
        local meta = { type = "config", lang = lang, config_name = cfg.name }
        state.add_line(snapshot.metadata, lines, meta, "   " .. cfg.name)
      end
    end
  end

  write_to_unmodifiable_buf(snapshot.buffers.left.id, lines)
end

-- Redraw events
state.get().events:on({
  ProfilerEvent.LanguageAdded,
  ProfilerEvent.ConfigAdded,
  ProfilerEvent.ConfigDeleted,
  ProfilerEvent.ConfigRenamed,
  ProfilerEvent.ProfilerTreeExpand,
  ProfilerEvent.ProfilerOpen,
}, draw)

function M.open()
  local snapshot = state.get()
  local win_configs = window_configs.create_default_configs()

  local left_buf = buffers.create_left_buffer()
  local left_window_id = vim.api.nvim_open_win(left_buf, true, win_configs.left_window)
  vim.api.nvim_set_option_value("cursorline", true, {
    win = left_window_id,
  })
  snapshot.windows.left = { id = left_window_id, config = win_configs.left_window }

  local right_buf = buffers.create_right_buffer()
  local right_window_id = vim.api.nvim_open_win(right_buf, false, win_configs.right_window)
  snapshot.windows.right = { id = right_window_id, config = win_configs.right_window }

  snapshot.open = true

  snapshot.events:emit(ProfilerEvent.ProfilerOpen, snapshot)
end

function M.close()
  local left_win_id = state.get().windows.left.id
  local right_win_id = state.get().windows.right.id
  local current_win = vim.api.nvim_get_current_win()
  if not current_win or current_win == nil then
    return
  end

  if
    current_win == state.get().windows.right.id
    and vim.api.nvim_win_is_valid(right_win_id)
    and vim.api.nvim_win_is_valid(left_win_id)
  then
    vim.api.nvim_set_current_win(left_win_id)
    return
  else
    M.force_close()
  end
end

--- Close all windows stored in the global state
function M.force_close()
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

function M.toggle()
  if state.get().open then
    M.force_close()
    return
  end

  M.open()
end

return M
