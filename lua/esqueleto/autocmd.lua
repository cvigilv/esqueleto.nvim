---@module "esqueleto.autocmd"
---@author Carlos Vigil-Vásquez
---@license MIT

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

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
    group = group,
    desc = "Insert skeleton",
    pattern = "*",
    callback = function(args)
      -- Get information of file to insert template
      local filepath = vim.fn.fnamemodify(args.file, ":p")
      local filename = vim.fn.fnamemodify(args.file, ":t")
      local filetype = vim.filetype.match({ filename = filename })
      -- If buftype is not a normal buffer, skip
      if vim.bo.buftype == "nofile" then return nil end
      -- If pattern is ignored, skip
      for _, pattern in ipairs(opts.advanced.ignore_patterns) do
        if filepath:match(pattern) then return nil end
      end
      -- If file is not empty, skip
      local isempty = vim.fn.getfsize(filepath) < 4
      if not isempty then return nil end
      -- If already attempted to insert template, skip
      if _G.esqueleto_inserted[filepath] then return nil end
      -- If filename matches pattern or filetype, insert template
      local pattern
      if
        vim.tbl_contains(opts.patterns --[[@as table]], filename)
      then
        pattern = filename
      elseif
        vim.tbl_contains(opts.patterns --[[@as table]], filetype)
      then
        pattern = filetype
      end

      if pattern ~= nil then
        -- Get templates for selected pattern
        utils.inserttemplate(filepath, pattern, opts)

        _G.esqueleto_inserted[filepath] = true
      end
    end,
  })
end

return M
