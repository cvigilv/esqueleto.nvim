local M = {}

--- Parse template contents in order to expand wildcards
---@param str string String to parse
---@param lookup Wildcard Wildcards lookup table
M.parse = function(str, lookup)
  local parsedstr = {}
  for _, l in ipairs(vim.split(str, "\n", { plain = true })) do
    for wildcard in l:gmatch("${([^{,^}]+)}") do
      local expansion = nil
---@return string[] parsed_str Table containing all lines with wildcards expanded table
---@return nil | [integer, integer] cursor_pos Row-column position tuple of the last cursor wildcard found.

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
    if col ~= nil then
      cursor_pos = {row, col}
    end
    parsedstr[row] = parsedstr[row]:gsub("${cursor}", "")
  end

  return parsedstr, cursor_pos
end

return M
