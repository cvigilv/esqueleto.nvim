local utils = require('esqueleto.utils')

local M = {}

M.createautocmd = function(opts)
  -- create autocommands for skeleton insertion
  local group = vim.api.nvim_create_augroup(
    "esqueleto",
    { clear = true }
  )

  vim.api.nvim_create_autocmd(
    { "BufWinEnter", "BufReadPost", "FileType" },
    {
      group = group,
      desc = "esqueleto.nvim :: Insert template",
      pattern = opts.patterns,
      callback = function()
        local filepath = vim.fn.expand("%")
        local emptyfile = vim.fn.getfsize(filepath) < 4
        if emptyfile then utils.inserttemplate(opts) end
      end
    }
  )
end


return M
