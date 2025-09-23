local M = {}

local state = require("dap-profiler.state")
require("dap-profiler.keymaps")
require("dap-profiler.ui")

state.load_dap_configs()

M.setup = function()
  -- nothing
end

return M
