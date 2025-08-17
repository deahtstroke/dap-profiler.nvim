local path = "/Users/danielvillavicencio/Projects/nvim-dap-profiler"
vim.opt.rtp:prepend(path)

local ui = require("nvim-dap-profiler.ui")

local M = {}

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

vim.api.nvim_create_user_command("DapProfilerOpen", M.toggle, {})

return M
