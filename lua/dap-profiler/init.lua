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
		local result = ui.create_main_window({ buf = state.main.buf })
		state.main.buf = result.buf
	end
end

return M
