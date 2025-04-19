local utils = require("esqueleto.core")

local M = {}

--- Create autocommands for `esqueleto.nvim`
---@param opts Esqueleto.Config Plugin configuration table
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

  -- Skip if (i) no patterns where found or (ii) trying to run always.
  -- NOTE: This patterns are incompatible with the plugin in it's current state, since it
  -- doesn't have a way to merge templates from different patterns.
  if
    type(opts.patterns) == "table" and next(opts.patterns --[[@as table]]) == nil
  then
    error("Empty pattern (`pattern={}`) is incompatible with esqueleto.nvim")
  end
  if opts.patterns == "*" then
    error("Global pattern (`pattern=\"*\"`) is incompatible with esqueleto.nvim")
  end

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "FileType" }, {
    group = group,
    desc = "esqueleto.nvim :: Insert template",
    pattern = opts.patterns --[[ @as string[] ]],
    callback = function()
      local filepath = vim.fn.expand("%")
      if vim.bo.buftype == "nofile" then return nil end
      for _, pattern in ipairs(opts.advanced.ignore_patterns) do
        if filepath:match(pattern) then return nil end
      end
      local emptyfile = vim.fn.getfsize(filepath) < 4
      if emptyfile then utils.inserttemplate(opts) end
    end,
  })
end

return M
