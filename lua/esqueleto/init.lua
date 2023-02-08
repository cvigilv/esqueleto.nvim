local ui = require('esqueleto.ui')

local M = {}

-- Template retriever
-- TODO: Add description
M.get = function(pattern, alldirectories)
  local templates = {}

  -- Count directories that contain templates for pattern
  local ndirs = 0
  for _, directory in pairs(alldirectories) do
    directory = vim.fn.fnamemodify(directory, ':p') -- expand path
    ndirs = ndirs + vim.fn.isdirectory(directory .. pattern .. '/')
  end

  -- Get templates for pattern
  for _, directory in ipairs(alldirectories) do
    directory = vim.fn.fnamemodify(directory, ':p') -- expand path
    if vim.fn.isdirectory(directory .. pattern .. '/') == 1 then
      for filepath in vim.fs.dir(directory .. pattern .. '/') do
        filepath = directory .. pattern .. "/" .. filepath
        local name = vim.fs.basename(filepath)
        if ndirs > 1 then
          name = vim.fn.simplify(directory) .. " :: " .. name
        end
        templates[name] = filepath
      end
    end
  end

  return templates
end

-- Template inserter
-- TODO(Carlos): Add description
M.insert = function(pattern, options)
  local templates = M.get(pattern, options.directories)
  local file = ui.select(templates, options)

  if file ~= nil then
    vim.cmd("0r " .. file)
  end
end

-- Defaults
M._defaults = {
  patterns = {},
  directories = {vim.fn.stdpath("config") .. "/skeletons"},
  prompt = "ivy",
}

M._template_inserted = {}

M.Esqueleto = function(opts)
  -- only prompt if template hasn't been inserted
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  if not M._template_inserted[filepath] then
    -- match either filename or extension. Filename has priority
    if vim.tbl_contains(opts.patterns, filename) then
      M.insert(filename, opts)
    elseif vim.tbl_contains(opts.patterns, filetype) then
      M.insert(filetype, opts)
    end

    M._template_inserted[filepath] = true
  end
end

M.setup = function(opts)
  -- update defaults
  if opts ~= nil then
    for key, value in pairs(opts) do
      M._defaults[key] = value
    end
  end

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
      pattern = M._defaults.patterns,
      callback = function()
        local filepath = vim.fn.expand("%")
        local emptyfile = vim.fn.getfsize(filepath) < 4
        if emptyfile then M.Esqueleto(M._defaults) end
      end
    }
  )

  -- create ex-command for om-demand use
  vim.api.nvim_create_user_command(
    'Esqueleto',
    function() M.Esqueleto(M._defaults) end,
    {}
  )
end

return M
