local M = {}

---@class ProfilerSettings
local defaults = {
  ui = {
    keymaps = {
      toggle_expand_or_select = "<CR>",
      add_config = "a",
      add_language = "A",
      delete_action = "d",
    },
  },
}

M._defaults = defaults
M.current = M._defaults

---@param opts ProfilerSettings
function M.set(opts)
  M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.current), opts)
end

return M
