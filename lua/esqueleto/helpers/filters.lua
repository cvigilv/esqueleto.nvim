---@module "esqueleto.helpers.filters"
---@author Carlos Vigil-Vásquez
---@license MIT 2024

local M = {}

M.match_patterns = function(str, patterns, opts)
  for _, pattern in ipairs(patterns) do
    if string.find(str, pattern) then
      local log = opts.advanced.logging.func

      log.trace(pattern .. " in " .. str .. " = " .. string.find(str, pattern))

      return true
    end
  end
  return false
end

return M
