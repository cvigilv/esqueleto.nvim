local autocmd = require('esqueleto.autocmd')
local excmd = require('esqueleto.excmd')
local config = require('esqueleto.config')

local M = {}

M.setup = function(opts)
  -- update defaults
  opts = config.updateconfig(opts)

  -- Module functionality
  autocmd.createautocmd(opts)
  excmd.createexcmd(opts)
end

return M
