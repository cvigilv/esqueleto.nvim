local M = {}

_G.esqueleto_inserted = {}

-- Write template contents to buffer
M.writetemplate = function(file)
  if file ~= nil then
    vim.cmd("0r " .. file)
  end
end

-- List ignored files under a directory, given a list of glob patterns
local listignored = function(dir, ignored_patterns)
  return vim.tbl_flatten(vim.tbl_map(function(patterns)
    return vim.fn.globpath(dir, patterns, true, true, true)
  end, ignored_patterns))
end

-- Returns a ignore checker
local getignorechecker = function(opts)
  local os_ignore_pats = opts.advanced.ignore_os_files and require('esqueleto.constants').ignored_os_patterns or {}
  local extra = opts.advanced.ignored
  local extra_ignore_pats, extra_ignore_func = (function()
    if type(extra) == 'function' then
      return {}, extra
    else
      assert(type(extra) == 'table')
      return extra, function(_) return false end
    end
  end)()

  return function(filepath)
    local dir = vim.fn.fnamemodify(filepath, ':p:h')
    return extra_ignore_func(dir)
      or vim.tbl_contains(listignored(dir, os_ignore_pats), filepath)
      or vim.tbl_contains(listignored(dir, extra_ignore_pats), filepath)
  end
end

M.gettemplates = function(pattern, opts)
  local templates = {}
  local isignored = getignorechecker(opts)

  local alldirectories = vim.tbl_map(function(f)
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
      for basename in vim.fs.dir(pattern_dir) do
        local filepath = vim.fs.normalize(pattern_dir .. basename)
        -- Check if pattern is ignored
        if not isignored(filepath) then
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

-- List ignored files under a directory, given a list of glob patterns
local listignored = function(dir, ignored_pats)
  return vim.tbl_flatten(vim.tbl_map(function(pat)
    return vim.fn.globpath(dir, pat, true, true, true)
  end, ignored_pats))
end

-- Returns a ignore checker
local getignorechecker = function(opts)
  local os_ignore_pats = opts.use_os_ignore and require('esqueleto.constants').ignored_patterns or {}
  local extra = opts.extra_ignore
  local extra_ignore_pats, extra_ignore_func = (function()
    if type(extra) == 'function' then
      return {}, extra
    else
      assert(type(extra) == 'table')
      return extra, function(_) return false end
    end
  end)()

  return function(filepath)
    local dir = vim.fn.fnamemodify(filepath, ':p:h')
    return extra_ignore_func(dir) or vim.tbl_contains(listignored(dir, os_ignore_pats), filepath)
      or vim.tbl_contains(listignored(dir, extra_ignore_pats), filepath)
  end
end

M.getunignoredtemplates = function(pattern, opts)
  local templates = {}
  local isignored = getignorechecker(opts)

  local alldirectories = vim.tbl_map(function(f)
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
      for basename in vim.fs.dir(pattern_dir) do
        local filepath = vim.fs.normalize(pattern_dir .. basename)
        if not isignored(filepath) then
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
<<<<<<< HEAD
    local templates = M.getunignoredtemplates(pattern, opts)
=======
    local templates = M.gettemplates(pattern, opts)
>>>>>>> origin/main

    -- Pop-up selection UI
    M.selecttemplate(templates, opts)
    _G.esqueleto_inserted[filepath] = true
  end
end


return M
