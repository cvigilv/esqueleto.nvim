local M = {}

local _create_selection_pane = function(old_win)
  local height = vim.api.nvim_win_get_height(old_win)

  vim.cmd("split")
  local new_win = vim.api.nvim_get_current_win()
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_buf(new_win, new_buf)
  vim.api.nvim_set_current_win(old_win)
  vim.api.nvim_command("resize " .. math.floor(0.2 * height))

  return new_win
end

M.default = function(templates)
  local selection = nil
  local templatenames = vim.tbl_keys(templates)
  table.sort(templatenames, function(a, b) return a:lower() < b:lower() end)
  vim.ui.select(
    templatenames,
    { prompt = 'Select skeleton to use:', },
    function(choice) selection = choice end
  )

  return templates[selection]

end

M.ivy = function(templates)
  _create_selection_pane(vim.api.nvim_get_current_win())

end

-- Template selector
-- TODO: Add description
M.select = function(templates, options)
  if templates == nil then
    vim.notify("[WARNING] No skeletons found for this file!\nPattern is known by `esqueleto` but could not find any template file")
    return nil
  end

  local template = nil
  if options.prompt == "ivy" then
    template = M.ivy(templates)
  elseif options.prompt == "default" then
    template = M.default(templates)
  end
  return template
end


return M
