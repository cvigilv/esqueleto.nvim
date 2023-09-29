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

M.getunignoredtemplates = function(pattern, opts)
  local list_ignored = function (dir, ignored_pats)
    return vim.tbl_flatten(vim.tbl_map(function (pat)
      return vim.fn.globpath(dir, pat, true, true, true)
    end, ignored_pats))
  end

  local list_os_ignored_files = function (dir)
    return list_ignored(dir, require('esqueleto.constants').ignored_patterns)
  end

  local list_user_ignored_files = list_ignored

  local templates = {}
  local use_os_ignore = opts.use_os_ignore
  local extra_ignore_pats, extra_ignore_func = (function ()
    if type(opts.extra_ignore) == 'function' then
      return {}, opts.extra_ignore
    else
      return opts.extra_ignore, function (_) return false end
    end
  end)()
  local alldirectories = vim.tbl_map(function (f)
    return vim.fn.fnamemodify(f, ':p')
  end, opts.directories)

  -- Count directories that contain templates for pattern
  local ndirs = 0
  for _, directory in pairs(alldirectories) do
    ndirs = ndirs + vim.fn.isdirectory(directory .. pattern .. '/')
  end

  -- Get templates for pattern
  for _, directory in ipairs(alldirectories) do
    local pattern_dir = directory .. pattern .. '/'
    local exists_dir = vim.fn.isdirectory(pattern_dir) == 1
    if exists_dir then
      local os_ignored_files = use_os_ignore and list_os_ignored_files(pattern_dir) or {}
      local user_ignored_files = list_user_ignored_files(pattern_dir, extra_ignore_pats)
      for basename in vim.fs.dir(pattern_dir) do
        local filepath = vim.fs.normalize(pattern_dir .. basename)
        local ignored = extra_ignore_func(filepath) or vim.tbl_contains(os_ignored_files, filepath) or vim.tbl_contains(user_ignored_files, filepath)
        if not ignored then
          local name = vim.fs.basename(filepath)
          if ndirs > 1 then
            name = vim.fn.simplify(directory) .. " :: " .. name
          end
          templates[name] = filepath
        end
      end
    end
  end

  return templates
end

M.selecttemplate = function(templates, opts)
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
  if #templatenames == 1 and opts.autouse then
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
    local templates = M.getunignoredtemplates(pattern, opts)

    -- Pop-up selection UI
    M.selecttemplate(templates, opts)
    _G.esqueleto_inserted[filepath] = true
  end
end


return M
