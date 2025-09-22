local ui = require("dap-profiler.ui")
local state = require("dap-profiler.state")
local storage = require("dap-profiler.storage")

local M = {}

state.load_dap_configs()

M.setup = function()
  -- nothing
end

function M.toggle()
  ui.toggle()
end

return M
