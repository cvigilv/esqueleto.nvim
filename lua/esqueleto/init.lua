_G.esqueleto_inserted = {}

local autocmd = require('esqueleto.autocmd')
local excmd = require('esqueleto.excmd')
local config = require('esqueleto.config')

local M = {}

--- Setup `esqueleto.nvim`
---@param opts table User configuration table
M.setup = function(opts)
  -- update defaults
  opts = config.updateconfig(opts)

  -- Module functionality
  autocmd.createautocmd(opts)
  excmd.createexcmd(opts)
end

return M
