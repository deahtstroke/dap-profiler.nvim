local M = {}

local state = require("dap-profiler.state")
local utils = require("dap-profiler.ui.utils.format")

local function render_right_window_preview()
  local row = vim.api.nvim_win_get_cursor(state.get().windows.left.id)[1]

  local line_metadata = state.get().metadata[row]
  if not line_metadata then
    return
  end

  local lines = {}
  if line_metadata.type == "lang" then
    lines = utils.center_block_in_window(
      state.get().windows.right.id,
      { "Language: " .. line_metadata.lang, "Expand to see configs." }
    )
  elseif line_metadata.type == "config" then
    local dap_configs = state.get().languages[line_metadata.lang].dapProfiles or {}
    for _, cfg in pairs(dap_configs) do
      if line_metadata.config_name == cfg.name then
        lines = utils.pad_lines_space(vim.split(vim.inspect(cfg), "\n"), 1)
        break
      end
    end
  else
    lines = utils.center_block_in_window(state.get().windows.right.id, { "No configuration selected" })
  end

  vim.api.nvim_buf_set_lines(state.get().buffers.right.id, 0, -1, false, lines)
end

---Creates the left buffer for the ui
---@return integer buf Id of the buffer
function M.create_left_buffer()
  if state.get().buffers.left and vim.api.nvim_buf_is_valid(state.get().buffers.left.id) then
    return state.get().buffers.left.id
  end
  local buf = vim.api.nvim_create_buf(true, false)

  state.get().buffers.left = { id = buf }

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = state.get().buffers.left.id,
    callback = function()
      render_right_window_preview()
    end,
  })
  return buf
end

---Creates the right buffer for the ui
---@return integer buf Id of the buffer
function M.create_right_buffer()
  local right_buffer = state.get().buffers.right
  if right_buffer and vim.api.nvim_buf_is_valid(right_buffer.id) then
    return right_buffer.id
  end
  local buf = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_name(buf, "dap-profiler://preview")
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].filetype = "lua"

  state.get().buffers.right = { id = buf }

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      -- TODO: Parse lines back into M.state.language_configs
      vim.notify("Saved dap-profiler state", vim.log.levels.INFO)
    end,
  })
  return buf
end

return M
