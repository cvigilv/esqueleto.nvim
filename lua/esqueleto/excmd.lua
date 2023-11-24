local M = {}

local utils = require('esqueleto.utils')

--- Create excommands for `esqueleto.nvim`
---@param opts table Plugin configuration table
M.createexcmd = function(opts)
-- create ex-command for on-demand use
  vim.api.nvim_create_user_command(
    'Esqueleto',
    function() utils.inserttemplate(opts) end,
    {}
  )
end

return M
