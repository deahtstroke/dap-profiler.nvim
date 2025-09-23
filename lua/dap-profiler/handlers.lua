local M = {}

local state = require("dap-profiler.state")
local ui = require("dap-profiler.ui")

function M.toggle_expand_or_select()
  state.toggle_expand_or_select_config()
end

function M.add_config()
  state.add_configuration()
end

function M.add_language()
  state.add_language()
end

function M.delete()
  state.delete()
end

function M.open()
  ui.open()
end

function M.force_close()
  ui.force_close()
end

function M.close()
  ui.close()
end

function M.toggle()
  ui.toggle()
end

return M
