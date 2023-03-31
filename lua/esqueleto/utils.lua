local M = {}

_G.esqueleto_inserted = {}

M.writetemplate = function(file)
  if file ~= nil then
    vim.cmd("0r " .. file)
  end
end

M.gettemplates = function(pattern, alldirectories)
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

M.selecttemplate = function(templates)
  -- Check if templates exist
  if vim.tbl_isempty(templates) then
    vim.notify(
      "[WARNING] No templates found for this file! Pattern is known by `esqueleto` but could not find any template file",
      vim.log.levels.WARN
    )
    return nil
  end

  -- Alphabetically sort template names for a more pleasing experience
  local templatenames = vim.tbl_keys(templates)
  table.sort(templatenames, function(a, b) return a:lower() < b:lower() end)

  -- If only one template, write and return early
  if #templatenames == 1 and M._defaults.autouse then
    M.writetemplate(templates[templatenames[1]])
    return nil
  end

  -- Select template
  vim.ui.select(
    templatenames,
    { prompt = 'Select skeleton to use:', },
    function(choice)
      M.writetemplate(templates[choice])
    end
  )
end

M.inserttemplate = function(opts)
  -- Get pattern alternatives for current file
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  -- Identify if pattern matches user configuration
  local pattern = nil
  if not _G.esqueleto_inserted[filepath] then
    -- match either filename or extension. Filename has priority
    if vim.tbl_contains(opts.patterns, filename) then
      pattern = filename
    elseif vim.tbl_contains(opts.patterns, filetype) then
      pattern = filetype
    end

    -- Get templates for selected pattern
    local templates = M.gettemplates(pattern, opts.directories)

    -- Pop-up selection UI
    M.selecttemplate(templates)
    _G.esqueleto_inserted[filepath] = true
  end
end


return M
