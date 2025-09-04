vim.api.nvim_create_user_command("DapProfilerToggle", function()
  package.loaded["dap-profiler"] = nil
  require("dap-profiler").toggle()
end, {})
