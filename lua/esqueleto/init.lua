_G.esqueleto_inserted = {}

local M = {}

--- Setup `esqueleto.nvim`
---@param opts Esqueleto.Config User configuration table
M.setup = function(opts)
  local autocmd = require("esqueleto.autocmd")
  local config = require("esqueleto.config")
  local excmd = require("esqueleto.excmd")

  -- update defaults
  opts = config.update_config(opts)

  -- Module functionality
  autocmd.createautocmd(opts)
  excmd.createexcmd(opts)
end

return M
