local utils = require("esqueleto.utils")

local M = {}

--- Create autocommands for `esqueleto.nvim`
---@param opts table Plugin configuration table
M.createautocmd = function(opts)
  -- create autocommands for skeleton insertion
  local group = vim.api.nvim_create_augroup("esqueleto", { clear = true })

  if type(opts.patterns) == "function" then
    if type(opts.directories) == "table" then
      opts.patterns = vim
        .iter(opts.directories)
        :map(function(dir) return opts.patterns(dir) end)
        :flatten()
        :totable()
    else
      opts.patterns = opts.patterns(opts.directories)
    end
  end

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "FileType" }, {
    group = group,
    desc = "esqueleto.nvim :: Insert template",
    pattern = opts.patterns,
    callback = function()
      if vim.bo.buftype == "nofile" then return nil end
      local filepath = vim.fn.expand("%")
      local emptyfile = vim.fn.getfsize(filepath) < 4
      if emptyfile then utils.inserttemplate(opts) end
    end,
  })
end

return M
