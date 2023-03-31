local M = {}

M.createexcmd = function(fn, opts)
-- create ex-command for on-demand use
  vim.api.nvim_create_user_command(
    'Esqueleto',
    function() fn(opts) end,
    {}
  )
end

return M
