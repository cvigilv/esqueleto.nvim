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
  if file == nil then
    -- Do an early return if no files are specified
    return
  end

  local handler, message = io.open(file, "r")
  if handler == nil then
    -- Print error message and abort if no file handlers are created
    vim.notify(message, vim.log.levels.ERROR)
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
local listignored = function(dir, ignored_patterns)
  return vim.tbl_flatten(
    vim.tbl_map(
      function(patterns) return vim.fn.globpath(dir, patterns, true, true, true) end,
      ignored_patterns
    )
  )
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
      return extra, function(_) return false end
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

  local alldirectories = vim.tbl_map(
    function(f) return vim.fn.fnamemodify(f, ":p") end,
    opts.directories
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
        if not isignored(filepath) then
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
  table.sort(templatenames, function(a, b) return a:lower() < b:lower() end)

  -- If only one template, write and return early
  if #templatenames == 1 and opts.autouse then
    M.writetemplate(vim.loop.fs_realpath(templates[templatenames[1]]), opts)
    return nil
  end

  -- Select template
  vim.ui.select(templatenames, { prompt = "Select skeleton to use:" }, function(choice)
    if templates[choice] then
      M.writetemplate(vim.loop.fs_realpath(templates[choice]), opts)
    else
      vim.notify("[esqueleto] No template selected, leaving buffer empty", vim.log.levels.INFO)
    end
  end)
end

function M.builtin_finder(templates, opts)
  local templatenames = vim.tbl_keys(templates)
  vim.ui.select(templatenames, { prompt = "Select skeleton to use:" }, function(choice)
    if templates[choice] then
      M.writetemplate(vim.loop.fs_realpath(templates[choice]), opts)
    else
      vim.notify("[esqueleto] No template selected, leaving buffer empty", vim.log.levels.INFO)
    end
  end)
end

function M.telescope_finder(templates, opts)
  local telescope_exist, pickers = pcall(require, "telescope_pickers")
  if not telescope_exist then
    return vim.notify("[esqueleto] Telescope does not exist", vim.log.levels.WARN)
  end
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local templatenames = {}
  for key in pairs(templates) do
    table.insert(templatenames, key)
  end
  pickers
    .new({}, {
      prompt_title = "Select skeleton to use",
      previewer = _TelescopeConfigurationValues.file_previewer({}),
      finder = finders.new_table({
        results = templatenames,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry,
            ordinal = entry,
            filename = templates[templatenames],
          }
        end,
      }),
      sorter = _TelescopeConfigurationValues.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          M.writetemplate(selection.filename, opts)
        end)
        return true
      end,
    })
    :find()
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
