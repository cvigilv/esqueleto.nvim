local M = {}

local utils = require('esqueleto.utils')

M.createexcmd = function(opts)
-- create ex-command for on-demand use
  vim.api.nvim_create_user_command(
    'Esqueleto',
    function() utils.inserttemplate(opts) end,
    {}
  )
end

return M
