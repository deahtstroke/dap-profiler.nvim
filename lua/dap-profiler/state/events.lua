local M = {}

---List of all possible events that could fire off on a user action in the profiler
---@alias ProfilerEvent
---| "language_added"
---| "language_deleted"
---| "config_added"
---| "config_deleted"
---| "config_renamed"
---| "tree_expand"
---| "profiler_open"
---| "profiler_close"
M.ProfilerEvent = {
  LanguageAdded = "language_added",
  LanguageDeleted = "language_deleted",
  ConfigAdded = "config_added",
  ConfigDeleted = "config_deleted",
  ConfigRenamed = "config_renamed",
  ProfilerTreeExpand = "tree_expand",
  ProfilerOpen = "profiler_open",
  ProfilerClose = "profiler_close",
}

---@alias EventCallback fun(...: any)

---@class EventEmitter
---@field private listeners table<ProfilerEvent, EventCallback[]>
local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter:new()
  return setmetatable({ listeners = {} }, self)
end

---Register an event callback
---@param event ProfilerEvent|ProfilerEvent[] event(s) to listen to
---@param fn EventCallback
function EventEmitter:on(event, fn)
  if type(event) == "table" then
    for _, e in ipairs(event) do
      self:on(e, fn)
    end
    return
  end

  if not self.listeners[event] then
    self.listeners[event] = {}
  end
  table.insert(self.listeners[event], fn)
end

---Emit an event
---@param event ProfilerEvent
---@param ... any
function EventEmitter:emit(event, ...)
  local callbacks = self.listeners[event]
  if not callbacks then
    return
  end
  for _, fn in ipairs(callbacks) do
    fn(...)
  end
end

M.EventEmitter = EventEmitter

return M
