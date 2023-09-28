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

local any = function (f, t)
  for _, e in pairs(t) do
    if f(e) then
      return true
    end
  end

  return false
end

-- Determine if a file matches a gitignore glob pattern
-- by converting to regex, then vim.regex API.
local match_gitignore = function (filepath, gitignore_pattern)
  local regpat = vim.fn.glob2regpat(gitignore_pattern):sub(2)  -- manually remove ^; hackish
  local start, finish = vim.regex(regpat):match_str(filepath)
  local res = (function ()
    if start == nil or finish == nil then return false end
    if start == finish then return false end  -- empty match, won't do
    return finish == #filepath
  end)()

  return res
end

-- Determine if a file should be ignored,
-- according to user's choice
local isignored = function (filepath, extra_ignore, use_os_ignore)
  local is_user_ignored = (function ()
    if type(extra_ignore) == 'function' then
      return extra_ignore(filepath)
    else
      return any(function (pat) return match_gitignore(filepath, pat) end, extra_ignore)
    end
  end)()

  local is_os_ignored = (function ()
    if not use_os_ignore then return false end
    local os_ignore = require('esqueleto.constants').ignored_files
    return any(function (pat) return match_gitignore(filepath, pat) end, os_ignore)
  end)()

  return is_user_ignored or is_os_ignored
end

M.getunignoredtemplates = function(pattern, opts)
  local templates = {}
  local alldirectories = opts.directories
  local extra_ignore = opts.extra_ignore
  local use_os_ignore = opts.use_os_ignore

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
        local ignored = isignored(filepath, extra_ignore, use_os_ignore)
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
