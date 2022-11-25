local M = {}

local function _scandir(directory, pattern)
  local i, t, popen = 0, {}, io.popen
  for filename in popen('ls -1 ' .. directory .. pattern):lines() do
    i = i + 1
    t[i] = filename
  end
  return t
end

M._defaults = {
  patterns = { },
  directory = vim.fs.normalize("~/.config/nvim/skeletons/"),
}

M._template_inserted = {}

M.select = function(templates)
  if templates == nil then
    vim.notify("[WARNING] No skeletons found for this file!\nPattern is known by `esqueleto` but could not find any template file")
    return nil
  end

  local selection = nil
  vim.ui.select(
    vim.tbl_keys(templates),
    { prompt = 'Select skeleton to use:', },
    function(choice) selection = choice end
  )

  return templates[selection]
end

M.get = function(pattern)
  -- get all templates available for pattern
  local templates = _scandir(vim.fs.normalize(M._defaults.directory), pattern)
  if vim.tbl_isempty(templates) then return nil end

  -- create table with template types for pattern
  local types = {}
  for _, template in pairs(templates) do
    local _file = vim.fs.basename(template)
    local _type = vim.split(_file, ".", { plain = true, trimempty = true })[2]

    if vim.tbl_contains(M._defaults.patterns, _file) then
      _type = _file
    elseif "*." .. _type == pattern then
      _type = "default"
    end

    types[_type] = template
  end
  table.sort(types)
  return types
end

M.insert = function(pattern)
  local templates = M.get(pattern)
  local file = M.select(templates)

  if file ~= nil then
    vim.cmd("0r " .. file)
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
    "BufNewFile",
    {
      group = group,
      desc = "Insert skeleton",
      pattern = M._defaults.patterns,
      -- once = true,
      callback = function()
        -- only prompt if template hasn't been inserted
        local filename = vim.fn.expand("<amatch>")
        if not M._template_inserted[filename] then
          local filebase = vim.fs.basename(filename)
          local fileextension = "*" .. filebase:match("^.+(%..+)$")

          -- match either filename or extension. Filename has priority
          if vim.tbl_contains(M._defaults.patterns, filebase) then
            M.insert(filebase)
          elseif vim.tbl_contains(M._defaults.patterns, fileextension) then
            M.insert(fileextension)
          end

          M._template_inserted[filename] = true
        end
      end
    }
  )
end

return M
