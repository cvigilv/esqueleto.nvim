local M = {}

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

M.hastemplates = function(templates)
  if vim.tbl_isempty(templates) then
    vim.notify(
      "[WARNING] Pattern is known by `esqueleto` but could no templates where found",
      vim.log.levels.WARN
    )
    return false
  else
    return true
  end
end

return M
