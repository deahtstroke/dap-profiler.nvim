vim.api.nvim_create_user_command("DapProfilerToggle", function()
  require("dap-profiler.state").load_dap_configs()

  require("dap-profiler.keymaps")
  require("dap-profiler.ui").toggle()
end, {})
