local M = {}

--- Parse template contents in order to expand wildcards
---@param str string String to parse
---@param lookup table Wildcards lookup table
---@return table parsed_str Table containing all lines with wildcards expanded table
----@return table cursor_pos Row-column position tuple of the last cursor wildcard found.
M.parse = function(str, lookup)
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
  local cursor_count = 0
  for row, l in ipairs(parsedstr) do
    local col, _ = string.find(l, "${cursor}")
    if col ~= nil then
      parsedstr[row] = parsedstr[row]:gsub("${cursor}", "$" .. cursor_count)
      cursor_count = cursor_count + 1
    end
  end

  return parsedstr
end

return M
