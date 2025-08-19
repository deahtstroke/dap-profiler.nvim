vim.api.nvim_create_user_command("DapProfilerOpen", function()
  package.loaded["dap-profiler"] = nil
  require("dap-profiler").toggle()
end, {})
