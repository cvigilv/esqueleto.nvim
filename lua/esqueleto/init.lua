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
    function(choice) selection = choice end
  )

  return templates[selection]
end

-- Template retriever
-- TODO: Add description
M.get = function(pattern)
  -- get all templates available for pattern
  local templates = M._scandir(vim.fs.normalize(M._defaults.directory), pattern)
  if vim.tbl_isempty(templates) then return nil end

  -- create table with template types for pattern
  local types = {}
  for _, template in pairs(templates) do
    local _file = vim.fs.basename(template)
    types[template] = M._defaults.directory .. pattern .. "/" .. _file
  end

  return types
end

-- Template inserter
-- TODO(Carlos): Add description
M.insert = function(pattern)
  local templates = M.get(pattern)
  local file = M.select(templates)

  if file ~= nil then
    vim.cmd("0r " .. file)
  end
end

-- Defaults
M._defaults = {
  patterns = {},
  directory = vim.fn.stdpath("config") .. "/skeletons",
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
