local M = {}

--- Capture output of command
---@param cmd string Command to run
---@param raw boolean Whether the function returns the raw string
---@return string output Command standard output
M.capture_cmd_output = function(cmd, raw)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))
  f:close()
  if raw then return s end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", "")
  return s
end

--- Parse template contents in order to expand wildcards
---@param str string String to parse
---@param lookup table Wildcards lookup table
---@return table parsed_str Table containing all lines with wildcards expanded table
---@return table cursor_pos Row-column position tuple of the last cursor wildcard found.
M.parse_wildcard_string = function(str, lookup)
  local parsedstr = {}
  for _, l in ipairs(vim.split(str, "\n", { plain = true })) do
    for wildcard in l:gmatch("${([^{,^}]+)}") do
      local expansion = nil

      if vim.tbl_contains(vim.tbl_keys(lookup), wildcard) then
        expansion = lookup[wildcard]
      elseif string.find(wildcard, "lua:") then
        local cmdstr = l:gsub(".*${lua:([^{,^}]+)}.*", "%1")
        local cmdout = load("return " .. cmdstr)()
        expansion = cmdout
      else
        expansion = "${" .. wildcard .. "}"
      end

      l = l:gsub("${" .. wildcard:gsub("([^%w])", "%%%1") .. "}", expansion)
    end
    table.insert(parsedstr, l)
  end

  -- Find cursor wildcard
  local cursor_pos = nil
  for row, l in ipairs(parsedstr) do
    local col, _ = string.find(l, "${cursor}")
    if col ~= nil then cursor_pos = { row, col } end
    parsedstr[row] = parsedstr[row]:gsub("${cursor}", "")
  end

  return parsedstr, cursor_pos
end

---Table of built-in wildcards.
---@type table<string, function>
M.builtin = {
  -- File
  ["filename"] = function() return vim.fn.expand("%:t:r") end,
  ["fileabspath"] = function() return vim.fn.expand("%:p") end,
  ["filerelpath"] = function() return vim.fn.expand("%:p:~") end,
  ["fileext"] = function() return vim.fn.expand("%:e") end,
  ["filetype"] = function() return vim.bo.filetype end,

  -- Date and time
  ["date"] = function() return os.date("%Y%m%d", os.time()) end,
  ["year"] = function() return os.date("%Y", os.time()) end,
  ["month"] = function() return os.date("%m", os.time()) end,
  ["day"] = function() return os.date("%d", os.time()) end,
  ["time"] = function() return os.date("%T", os.time()) end,

  -- System
  ["host"] = function() return M.capture_cmd_output("hostname", false) end,
  ["user"] = function() return os.getenv("USER") end,

  -- Github
  ["gh-email"] = function() return M.capture_cmd_output("git config user.email", false) end,
  ["gh-user"] = function() return M.capture_cmd_output("git config user.name", false) end,
}

return M
