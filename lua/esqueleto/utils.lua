local wildcards = require("esqueleto.wildcards")

local M = {}

--- Capture output of command
---@param cmd string Command to run
---@param raw boolean Whether the function returns the raw string
---@return string output Command standard output
M.capture = function(cmd, raw)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))
  f:close()
  if raw then
    return s
  end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", "")
  return s
end

--- Map function over each entry in table
---@param tbl table Table to map
---@param f function Function to map
---@return table mapped_tbl Function-mapped table
M.map = function(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

--- Write template contents to current buffer
---@param file string Template file path
---@param opts table Plugin configuration table
M.writetemplate = function(file, opts)
  if file ~= nil and not opts.wildcards.expand then
    -- Place contents of template directly to buffer
    vim.cmd("0r " .. file)
    vim.cmd("norm G")
  elseif file ~= nil and opts.wildcards.expand then
    -- Expand wildcards from template and place contents in buffer
    local content = io.open(file, "r"):read("*a")
    local parsed_content, cursor_pos = wildcards.parse(content, opts.wildcards.lookup)
    if content ~= nil then
      vim.api.nvim_buf_set_lines(0, 0, -1, true, parsed_content)
    end
    -- If a cursor wildcard was found, place cursor there
    if cursor_pos ~= nil then
      vim.api.nvim_win_set_cursor(0, cursor_pos)
    else
      vim.cmd("norm G")
    end
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
  local os_ignore_pats = opts.advanced.ignore_os_files
      and require("esqueleto.constants").ignored_os_patterns
      or {}
  local extra = opts.advanced.ignored
  local extra_ignore_pats, extra_ignore_func = (function()
    if type(extra) == "function" then
      return {}, extra
    else
      assert(type(extra) == "table")
      return extra, function(_)
        return false
      end
    end
  end)()

  return function(filepath)
    local dir = vim.fn.fnamemodify(filepath, ":p:h")
    return extra_ignore_func(dir)
        or vim.tbl_contains(listignored(dir, os_ignore_pats), filepath)
        or vim.tbl_contains(listignored(dir, extra_ignore_pats), filepath)
  end
end

--- Get available templates for current buffer
---@param pattern string Pattern to use to find templates
---@param opts table Plugin configuration table
---@return table templates Available templates for current buffer
M.gettemplates = function(pattern, opts)
  local templates = {}
  local isignored = getignorechecker(opts)

  local alldirectories = vim.tbl_map(function(f)
    return vim.fn.fnamemodify(f, ":p")
  end, opts.directories)

  -- Count directories that contain templates for pattern
  local ndirs = 0
  for _, directory in pairs(alldirectories) do
    ndirs = ndirs + vim.fn.isdirectory(directory .. pattern .. "/")
  end

  -- Get templates for pattern
  for _, directory in ipairs(alldirectories) do
    local pattern_dir = directory .. pattern .. "/"
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

--- Select template to insert on current buffer
---@param templates table Available template table
---@param opts table Plugin configuration table
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
  table.sort(templatenames, function(a, b)
    return a:lower() < b:lower()
  end)

  -- If only one template, write and return early
  if #templatenames == 1 and opts.autouse then
    M.writetemplate(templates[templatenames[1]], opts)
    return nil
  end

  -- Select template
  vim.ui.select(templatenames, { prompt = "Select skeleton to use:" }, function(choice)
    M.writetemplate(templates[choice], opts)
  end)
end

--- Insert template on current buffer
---@param opts table Plugin configuration table
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
    local templates = M.gettemplates(pattern, opts)

    -- Pop-up selection UI
    M.selecttemplate(templates, opts)
    _G.esqueleto_inserted[filepath] = true
  end
end

return M
