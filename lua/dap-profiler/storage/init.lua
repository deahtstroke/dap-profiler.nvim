local M = {}

local data_dir = vim.fn.stdpath("data")
local profiles_file = data_dir .. "profiles.json"

---Load dap-profiles from storage
---@return table<string, DapConfiguration[]> managed_profiles
function M.load_from_storage()
  local file = io.open(profiles_file, "r")
  if not file then
    return {}
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.fn.json_decode, content)
  if not ok then
    vim.notify("[dap-profiler] Failed to decode profiles.json", vim.log.levels.ERROR)
    return {}
  end

  return decoded
end

---Write a table of dap_configurations to JSON
---@param profiles table<string, DapConfiguration[]>
function M.write_profiles(profiles)
  vim.fn.mkdir(data_dir, "p")

  local json = vim.fn.json_encode(profiles)
  local file = assert(io.open(profiles_file, "w"))
  file:write(json)
  file:close()
end

return M
