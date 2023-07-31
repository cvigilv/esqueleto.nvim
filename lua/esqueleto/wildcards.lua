local M = {}

M.parse = function(str, lookup)
  local parsedstr = {}

  for _, l in ipairs(vim.split(str, "\n", { plain = true })) do
    for wildcard in l:gmatch("${([%w,%p]+)}") do
      local expansion = nil

      if vim.tbl_contains(vim.tbl_keys(lookup), wildcard) then
        expansion = lookup[wildcard]
      elseif string.find(wildcard, "lua:") then
        local cmdstr = l:gsub(".*${lua:([%w,%p]+)}.*", "%1")
        local cmdout = load("return " .. cmdstr)()
        expansion = cmdout
      else
        expansion = "${" .. wildcard .. "}"
      end

      l = l:gsub("${" .. wildcard:gsub("([^%w])", "%%%1") .. "}", expansion)
    end
    table.insert(parsedstr, l)
  end

  return parsedstr
end

return M
