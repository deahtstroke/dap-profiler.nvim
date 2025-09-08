local M = {}

---@class line_metadata_lang
---@field type "lang"
---@field lang string

---@class line_metadata_config
---@field type "config"
---@field lang string
---@field config_name string

---@class line_metadata_empty
---@field type "empty"

---@alias line_metadata line_metadata_lang | line_metadata_config | line_metadata_empty

---Insert line metadata into the corresponding table whilst syncing changes into the physical lines array
---@param metadata_table table<integer, line_metadata>
---@param lines string[]
---@param meta line_metadata
---@param line string the physical line to insert into the buffer
---@return integer inserted_line the line number where it was inserted
function M.insert(metadata_table, lines, meta, line)
  local line_num = #lines + 1
  lines[line_num] = line

  metadata_table[line_num] = meta
  return line_num
end

return M
