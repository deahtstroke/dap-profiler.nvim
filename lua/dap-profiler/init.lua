local ui = require("dap-profiler.ui")

local M = {}

M.setup = function()
  -- nothing
end

local state = {
  main = {
    buf = -1,
    win = -1,
  },
  expanded = {},
}

function M.toggle()
  if not vim.api.nvim_win_is_valid(state.main.win) then
    ui.toggle_profiler()
  end
end

return M
