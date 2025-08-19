local utils = require("dap-profiler.utils")
local dap = require("dap")

local M = {}

local ns = vim.api.nvim_create_namespace("dap_profiler")

function M.create_main_window(opts)
	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.7)

	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf = nil
	if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
	else
		buf = vim.api.nvim_create_buf(false, true)
	end

	M.write_main_section(buf, width)

	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		title = "Dap Profiler",
		title_pos = "center",
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}
	local win = vim.api.nvim_open_win(buf, true, win_config)

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })

	vim.keymap.set("n", "g?", function()
		M.write_help_section(buf)
	end, { buffer = buf })

	return { buf = buf, win = win }
end

function M.write_help_section(buf)
	local lines = {
		"",
		"Press 'q' to quit",
		"Press '<shift-A> to add profile",
	}
	utils.write_to_unmodifiable_buf(buf, lines)
end

-- Center a string within a given width
-- @param text	string	The text to center
-- @param width number	The width of the buffer
-- @return string				The centered text
local function center_text(text, width)
	if text == nil or width <= 0 then
		return ""
	end

	local padding = math.floor((width - #text) / 2)
	return string.rep(" ", padding) .. text
end

function M.write_main_section(buf, width)
	local helpLine = center_text("Press g? for help", width)
	local lines = {
		helpLine,
		"",
	}

	for lang, configs in pairs(dap.configurations) do
		table.insert(lines, "• " .. lang)

		for _, cfg in ipairs(configs) do
			table.insert(lines, "  └─ " .. cfg.name)
		end

		table.insert(lines, "")
	end

	utils.write_to_unmodifiable_buf(buf, lines)
	utils.apply_extmark_to_buf(buf, ns, helpLine, "Comment")
end

return M
