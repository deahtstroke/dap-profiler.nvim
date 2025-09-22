local M = {}

local ProfilerEvent = require("dap-profiler.state.events").ProfilerEvent

--- @class WindowDetails
--- @field id integer Id of the window
--- @field config vim.api.keyset.win_config Configuration of the window

--- @class BufferDetails
--- @field id integer The Id of the buffer

--- @class WindowState
--- @field left? WindowDetails Left window configuration
--- @field right? WindowDetails Right window configuration

--- @class BufferState
--- @field left? BufferDetails The left buffer details
--- @field right? BufferDetails The right buffer details

---@alias DapConfiguration DapConfigurationGo|table<string,string>

--- @class LanguageConfigurations
--- @field expanded? boolean If the list of configs is expanded
--- @field dap_configurations? DapConfiguration[] List of Dap configurations

---@class StateContainer
---@field windows WindowState The state of the current windows
---@field buffers BufferState The state of the buffers
---@field open boolean The whether the current windows are open or closed
---@field language_configs table<string, LanguageConfigurations> The current dap-language configs
---@field line_metadata table<integer, LineMetadata> The current line metadata
---@field events EventEmitter
local State = {}
State.__index = State

---Create a new state container
---@return StateContainer
function State:new()
  return setmetatable({
    line_metadata = {},
    buffers = {},
    windows = {},
    language_configs = {},
    open = false,
    events = require("dap-profiler.state.events").EventEmitter:new(),
  }, self)
end

---@type StateContainer
local state = State:new()

---Fetches the current state of the Profiler
---@return StateContainer
function M.get()
  return state
end

--- Load all DAP configurations
function M.load_dap_configs()
  local dap = require("dap")
  if state.language_configs and next(state.language_configs) then
    return
  end

  if not dap.configurations or vim.tbl_isempty(dap.configurations) then
    vim.notify("No DAP configurations found", vim.log.levels.WARN)
    return
  end

  state.language_configs = state.language_configs or {}

  function M.toggle_expand_or_select_config()
    local row = vim.api.nvim_win_get_cursor(state.windows.left.id)[1]

    local line_metadata = state.line_metadata[row]
    if not line_metadata then
      return
    end

    local language_config = state.language_configs[line_metadata.lang]

    if line_metadata.type == "lang" then
      language_config.expanded = not language_config.expanded
    elseif line_metadata.type == "config" then
      if state.windows.right and vim.api.nvim_win_is_valid(state.windows.right.id) then
        vim.api.nvim_set_current_win(state.windows.right.id)
      end
    end
  end

  for lang, configs in pairs(dap.configurations) do
    --- @type LanguageConfigurations
    local entry = {
      expanded = false,
      dap_configurations = {},
    }

    for _, cfg in ipairs(configs) do
      local config = vim.deepcopy(cfg, true)
      table.insert(entry.dap_configurations, config)
    end

    state.language_configs[lang] = entry
  end
end

---Insert line metadata into the corresponding table whilst syncing changes into the physical lines array
---@param metadata_table table<integer, LineMetadata>
---@param lines string[]
---@param meta LineMetadata
---@param line string the physical line to insert into the buffer
---@return integer inserted_line the line number where it was inserted
function M.add_line(metadata_table, lines, meta, line)
  local line_num = #lines + 1
  lines[line_num] = line

  metadata_table[line_num] = meta
  return line_num
end

---Add a config to the state
function M.add_config()
  local row = vim.api.nvim_win_get_cursor(state.windows.left.id)[1]

  local line_metadata = state.line_metadata[row]
  if not line_metadata then
    return
  end

  if line_metadata.type == "lang" then
    local new_name = vim.fn.input("New DAP config name: ")
    if new_name ~= "" then
      --- @type DapConfiguration
      local config = {
        name = new_name,
        type = line_metadata.lang,
      }

      table.insert(state.language_configs[line_metadata.lang].dap_configurations, config)
      vim.notify("Added config to: " .. line_metadata.lang .. ": " .. new_name, vim.log.levels.INFO)
      state.events:emit(ProfilerEvent.ConfigAdded)
    end
  elseif line_metadata.type == "config" then
    local new_name = vim.fn.input("New language name: ")
    if new_name ~= "" then
      ---@type DapConfiguration
      local config = {
        name = new_name,
      }

      table.insert(state.language_configs[line_metadata.lang].dap_configurations, config)
      vim.notify("Added config to: " .. line_metadata.lang .. ": " .. new_name, vim.log.levels.INFO)
      state.events:emit(ProfilerEvent.ConfigAdded)
    end
  else
    vim.notify("No language found under cursor", vim.log.levels.WARN)
  end
end

return M
