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
  if raw then return s end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", "")
  return s
end

--- Write template contents to current buffer
---@param file string Template file path
---@param opts Esqueleto.Config Plugin configuration table
M.write_template = function(file, opts)
  local log = opts.advanced.logging.func

  if file == nil then
    -- Do an early return if no files are specified
    return
  end

  local uv = vim.uv or vim.loop
  ---@diagnostic disable-next-line: undefined-field
  local handler, message = io.open(uv.fs_realpath(file), "r")
  if handler == nil then
    -- Print error message and abort if no file handlers are created
    log.error(message)
    return
  end

  -- Read the file, convert EOL to LF and remove the new line at EOF
  local content = handler:read("*a"):gsub("\r\n?", "\n"):gsub("\n$", "")

  local lines, cursor_pos
  if opts.wildcards.expand then
    -- Place the contents of the file with the wildcards expanded
    lines, cursor_pos = wildcards.parse(content, opts.wildcards.lookup)
  else
    -- ... or place them directly
    lines = vim.split(content, "\n", { plain = true })
  end

  -- Replace the buffer with the given lines
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)

  if cursor_pos ~= nil then
    -- If a cursor wildcard was found, place the cursor there
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  else
    -- If not, move the cursor to the last line
    vim.cmd("norm! G")
  end
end

-- List ignored files under a directory, given a list of glob patterns
local list_ignored = function(dir, ignored_patterns)
  return vim
    .iter(ignored_patterns)
    :map(function(patterns) return vim.fn.globpath(dir, patterns, true, true, true) end)
end

-- Returns a ignore checker
local get_ignore_checker = function(opts)
  local log = opts.advanced.logging.func

  local os_ignore_pats = opts.advanced.ignore_os_files
      and require("esqueleto.constants").ignored_os_patterns
    or {}
  log.trace("os_ignore_pats = { " .. table.concat(os_ignore_pats, ", ") .. " }")
  local extra = opts.advanced.ignored
  local extra_ignore_pats, extra_ignore_func = (function()
    if type(extra) == "function" then
      return {}, extra
    else
      assert(type(extra) == "table")
      return extra, function(_) return false end
    end
  end)()

  return function(filepath)
    local dir = vim.fn.fnamemodify(filepath, ":p:h")
    return extra_ignore_func(dir)
      or vim.tbl_contains(list_ignored(dir, os_ignore_pats), filepath)
      or vim.tbl_contains(list_ignored(dir, extra_ignore_pats), filepath)
  end
end

--- Get available templates for current buffer
---@param pattern string Pattern to use to find templates
---@param opts Esqueleto.Config Plugin configuration table
---@return table templates Available templates for current buffer
M.get_templates = function(pattern, opts)
  local templates = {}
  local is_ignored = get_ignore_checker(opts)

  local alldirectories = vim.tbl_map(
    function(f) return vim.fn.fnamemodify(f, ":p") end,
    opts.directories --[[@as table<string>]]
  )

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
        if not is_ignored(filepath) then
          local name = vim.fs.basename(filepath)
          if ndirs > 1 then name = vim.fn.simplify(directory) .. " :: " .. name end
          templates[name] = filepath
        end
      end
    end
  end

  return templates
end

--- Select template to insert on current buffer
---@param templates table Available template table
---@param opts Esqueleto.Config Plugin configuration table
M.select_template = function(templates, opts)
  local log = opts.advanced.logging.func

  -- Check if templates exist
  if vim.tbl_isempty(templates) then
    log.fatal("Buffer has a recognized pattern but not templates found for it, exiting.")
    return nil
  end

  -- Alphabetically sort template names for a more pleasing experience
  local templatenames = vim.tbl_keys(templates)
  table.sort(templatenames, function(a, b) return a:lower() < b:lower() end)

  -- If only one template, write and return early
  if #templatenames == 1 and opts.autouse then
    M.write_template(templates[templatenames[1]], opts)
    return nil
  end

  -- Select template
  vim.ui.select(templatenames, { prompt = "Select skeleton to use:" }, function(choice)
    if templates[choice] then
      ---@diagnostic disable-next-line: undefined-field
      M.write_template(vim.loop.fs_realpath(templates[choice]), opts)
    else
      log.info("No template selected, leaving buffer empty.")
    end
  end)
end

--- Insert template on current buffer
---@param opts Esqueleto.Config Plugin configuration table
M.insert_template = function(opts)
  -- Get pattern alternatives for current file
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  -- Identify if pattern matches user configuration
  local pattern
  if not _G.esqueleto_inserted[filepath] then
    -- match either filename or extension. Filename has priority
    if
      vim.tbl_contains(opts.patterns --[[@as table]], filename)
    then
      pattern = filename
    elseif
      vim.tbl_contains(opts.patterns --[[@as table]], filetype)
    then
      pattern = filetype
    end

    -- Get templates for selected pattern
    local templates = M.get_templates(pattern, opts)

    -- Pop-up selection UI
    M.select_template(templates, opts)
    _G.esqueleto_inserted[filepath] = true
  end
end

return M
