local M = {}

local settings = require("dap-profiler.settings")
local handlers = require("dap-profiler.handlers")
local state = require("dap-profiler.state")
local ProfilerEvent = require("dap-profiler.state.events").ProfilerEvent

---Setup keymaps with their respective handlers
local function setup()
  local buf_left = state.get().buffers.left.id
  local buf_right = state.get().buffers.right.id

  for action, keybinds in pairs(settings.current.ui.keymaps) do
    local fn = handlers[action]
    if not fn then
      vim.notify("No handler found for action: " .. action, vim.logs.levels.WARN)
    else
      local keys = type(keybinds) and { keybinds } or keybinds
      for _, key in ipairs(keys) do
        vim.keymap.set("n", key, fn, {
          buffer = buf_left,
          noremap = true,
          silent = true,
          desc = ("Profiler %s"):format(action),
        })
      end
    end
  end

  -- Be able to close windows with <ESC><ESC>
  vim.keymap.set("n", "<ESC>", handlers.close, {
    buffer = buf_right,
    noremap = true,
    silent = true,
    desc = "Profiler Close",
  })

  vim.keymap.set("n", "q", handlers.force_close, {
    buffer = buf_right,
    noremap = true,
    silent = true,
    desc = "Profiler Force Close",
  })
end

state.get().events:on(ProfilerEvent.ProfilerOpen, setup)

return M
