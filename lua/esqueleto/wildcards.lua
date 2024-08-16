local M = {}

--- Parse template contents in order to expand wildcards
---@param str string String to parse
---@param lookup Wildcard Wildcards lookup table
---@return string[] parsed_str Table containing all lines with wildcards expanded table
---@return nil | [integer, integer] cursor_pos Row-column position tuple of the last cursor wildcard found.
M.parse = function(str, lookup)
  ---@type string[]
  local parsedstr = {}
  for _, l in ipairs(vim.split(str, "\n", { plain = true })) do
    for wildcard in l:gmatch("${([^{,^}]+)}") do
      ---@type string
      local expansion
      if vim.tbl_contains(vim.tbl_keys(lookup), wildcard) then
        local wild = lookup[wildcard]
        if type(wild) == "function" then
          expansion = wild()
        else
          expansion = wild
        end
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

return M
