---@module "esqueleto.core"
---@author Carlos Vigil-Vásquex
---@license MIT

local M = {}

--- Write template contents to current buffer
---@param file string Template file path
---@param opts Esqueleto.Config Plugin configuration table
local write_template = function(file, opts)
  local function read_file(file_path)
    local uv = vim.uv or vim.loop
    local handler, message = io.open(uv.fs_realpath(file_path), "r")
    if not handler then return nil, message end
    local content = handler:read("*a"):gsub("\r\n?", "\n"):gsub("\n$", "")
    handler:close()
    return content
  end

  local function process_content(content, opts)
    local wildcards = require("esqueleto.helpers.wildcards")
    if opts.wildcards.expand then
      return wildcards.parse_wildcard_string(content, opts.wildcards.lookup)
    else
      return vim.split(content, "\n", { plain = true }), nil
    end
  end

  local function set_cursor_position(cursor_pos)
    if cursor_pos then
      vim.api.nvim_win_set_cursor(0, cursor_pos)
    else
      vim.cmd("norm! gg")
    end
  end

  local log = opts.advanced.logging.func

  if not file then return nil end

  local content, error_message = read_file(file)
  if not content then
    log.error(error_message)
    return
  end

  local lines, cursor_pos = process_content(content, opts)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  set_cursor_position(cursor_pos)
end

--- Get available templates for current buffer
---@param pattern string Pattern to use to find templates
---@param opts Esqueleto.Config Plugin configuration table
---@return table templates Available templates for current buffer
local get_templates = function(pattern, opts)
  ---Creates a function to check if a file should be ignored based on given options.
  ---@param opts Esqueleto.Config Options table containing advanced settings
  ---@return function Function that takes a filepath and returns a boolean indicating if it should be ignored
  ---@see esqueleto.constants
  local function create_ignore_checker(opts)
    local log = opts.advanced.logging.func
    local filters = require("esqueleto.helpers.filters")
    local constants = require("esqueleto.constants")

    local ignored_template_patterns = {}

    if opts.advanced.ignore_rules.templates.include_os_files then
      ignored_template_patterns =
        vim.tbl_extend("force", {}, ignored_template_patterns, constants.ignored_os_patterns)
    end

    local extra_ignore_func = function(_) return false end

    log.trace("Extra ignores type: " .. type(opts.advanced.ignore_rules.templates.extras))
    if type(opts.advanced.ignore_rules.templates.extras) == "function" then
      extra_ignore_func = opts.advanced.ignore_rules.templates.extras --[[@as function]]
    elseif type(opts.advanced.ignore_rules.templates.extras) == "table" then
      ignored_template_patterns = vim.tbl_extend(
        "force",
        {},
        ignored_template_patterns,
        opts.advanced.ignore_rules.templates.extras
      )
    end
    log.trace("Ignored template patterns: " .. table.concat(ignored_template_patterns, ", "))

    -- Construct
    return function(filepath)
      local dir = vim.fn.fnamemodify(filepath, ":p:h")
      log.trace("Checking filepath: " .. filepath)
      log.trace("In directory: " .. dir)

      local is_ignored = extra_ignore_func(dir)
        or filters.match_patterns(filepath, ignored_template_patterns, opts)

      log.trace("Is ignored: " .. tostring(is_ignored))
      return is_ignored
    end
  end

  local log = opts.advanced.logging.func
  local templates = {}
  local is_ignored = create_ignore_checker(opts)

  local pattern_dirs = vim
    .iter(opts.directories)
    :map(function(dir)
      local pattern_dir = vim.fn.fnamemodify(dir, ":p") .. pattern .. "/"
      log.trace("Found pattern directory: " .. pattern_dir)
      return pattern_dir
    end)
    :filter(function(dir) return vim.fn.isdirectory(dir) == 1 end)
    :totable()

  log.trace("Pattern directories: " .. table.concat(pattern_dirs, ", "))

  for _, directory in ipairs(pattern_dirs) do
    local template_paths = vim
      .iter(vim.fn.globpath(directory, "*", true, true, true))
      :filter(function(t) return not is_ignored(t) end)
      :totable()

    log.info(string.format("Found %d templates in directory %s", #template_paths, directory))

    local use_full_path = #pattern_dirs > 1
    for _, path in ipairs(template_paths) do
      local name = use_full_path
          and (vim.fn.simplify(directory) .. " -> " .. vim.fs.basename(path))
        or vim.fs.basename(path)
      templates[name] = path
      log.info(string.format("Added template: %s (%s)", name, path))
    end
  end

  return templates
end

--- Select template to insert on current buffer
---@param templates table Available template table
---@param opts Esqueleto.Config Plugin configuration table
local select_template = function(templates, opts)
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
    write_template(templates[templatenames[1]], opts)
    return nil
  end

  -- Select template
  vim.ui.select(templatenames, { prompt = "Select skeleton to use:" }, function(choice)
    if templates[choice] then
      ---@diagnostic disable-next-line: undefined-field
      write_template(vim.loop.fs_realpath(templates[choice]), opts)
    else
      log.info("No template selected, leaving buffer empty.")
    end
  end)
end

--- Insert template on current buffer
---@param opts Esqueleto.Config Plugin configuration table
M.insert_template = function(opts)
  local filters = require("esqueleto.helpers.filters")
  local log = opts.advanced.logging.func

  -- Get pattern alternatives for current file
  local filepath = vim.fn.expand("%:p")
  local filename = vim.fn.expand("%:t")
  local filetype = vim.bo.filetype

  log.trace("filepath = " .. filepath)
  log.trace("filename = " .. filename)
  log.trace("filetype = " .. filetype)

  -- Checl whether the filename or filetype is ignored
  if filters.match_patterns(filepath, opts.advanced.ignore_rules.filenames, opts) then
    log.info("Ignored pattern (file name) found, early exiting")
    return nil
  elseif filters.match_patterns(filetype, opts.advanced.ignore_rules.filetypes, opts) then
    log.info("Ignored pattern (file type) found, early exiting")
    return nil
  end

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
    local templates = get_templates(pattern, opts)

    -- Pop-up selection UI
    select_template(templates, opts)
    _G.esqueleto_inserted[filepath] = true
  end
end

return M
