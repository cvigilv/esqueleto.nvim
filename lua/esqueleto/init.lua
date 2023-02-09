local M = {}

-- Directory scanner
-- TODO: Add description
M._scandir = function(directory, pattern)
  local i = 0
  local t = {}
  for filepath in vim.fs.dir(directory .. pattern) do
    i = i + 1
    t[i] = filepath
  end
  return t
end

-- Template writer
M.write = function (file)
  vim.cmd("0r " .. file)
end

-- Template selector
-- TODO: Add description
M.select = function(templates)
  if templates == nil then
    vim.notify("[WARNING] No skeletons found for this file!\nPattern is known by `esqueleto` but could not find any template file")
    return nil
  end

  local selection = nil
  local templatenames = vim.tbl_keys(templates)
  table.sort(templatenames, function(a, b) return a:lower() < b:lower() end)
  vim.ui.select(
    templatenames,
    { prompt = 'Select skeleton to use:', },
    function(choice) 
      local file = templates[choice]
      if  file ~= nil then
        M.write(file)
      end
    end
  )
end

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
M.insert = function(pattern)
  local templates = M.get(pattern, M._defaults.directories)
  M.select(templates)
end

-- Defaults
M._defaults = {
  patterns = {},
  directories = {vim.fn.stdpath("config") .. "/skeletons"},
}

M._template_inserted = {}

M.Esqueleto = function()
  -- only prompt if template hasn't been inserted
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  if not M._template_inserted[filepath] then
    -- match either filename or extension. Filename has priority
    if vim.tbl_contains(M._defaults.patterns, filename) then
      M.insert(filename)
    elseif vim.tbl_contains(M._defaults.patterns, filetype) then
      M.insert(filetype)
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
        if emptyfile then M.Esqueleto() end
      end
    }
  )

  -- create ex-command for om-demand use
  vim.api.nvim_create_user_command(
    'Esqueleto',
    function() M.Esqueleto() end,
    {}
  )
end

return M
