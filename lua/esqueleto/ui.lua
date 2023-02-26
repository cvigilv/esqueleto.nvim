local M = {}

-- Create new window
local _newpane = function(old_win, ratio)
  local height = vim.api.nvim_win_get_height(old_win)
  vim.api.nvim_command("split | resize " .. math.floor(ratio * height))
  return vim.api.nvim_get_current_win()
end

-- Setup "ivy" selection pane
local _ivyselection = function(win)
  -- Initialize selection window
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)

  -- Configure buffer
  vim.api.nvim_buf_set_name(buf, "esqueleto :: selection template ('q' to exit, '<CR>' to select)")
  vim.bo.filetype = "esqueleto.ivy.selection"
  vim.bo.buftype = "nofile"
  vim.wo.number = true
  vim.wo.colorcolumn = 0
  vim.wo.relativenumber = false
  vim.wo.cursorline = true

  -- Add and clean-up information to buffer
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.api.nvim_del_current_line()
  vim.api.nvim_set_current_win(win)

  return buf
end

-- Prompt 'default' selection pane
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

-- Prompt 'ivy' selection pane
M.ivy = function(templates)
  -- Prepare UI
  local preview_win = vim.api.nvim_get_current_win()
  local preview_buf = vim.api.nvim_get_current_buf()

  local selection_win = _newpane(preview_win, 0.2)
  local selection_buf = _ivyselection(selection_win)

  -- Add available templates to selection pane
  local templatenames = vim.tbl_keys(templates)
  vim.api.nvim_buf_set_lines(selection_buf, 0, -1, false, templatenames)
  vim.bo[selection_buf].modifiable = false


  -- Setup behavior
  local augroup = vim.api.nvim_create_augroup("esqueleto.ivy", {})

  local closepreview = function(selected)
    if not selected then
      vim.api.nvim_set_current_win(preview_win)
      vim.cmd("normal ggdG")
    end
    vim.api.nvim_win_close(selection_win, true)
    vim.api.nvim_buf_delete(selection_buf, { force = true })
  end

  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorHold" },
    {
      group = augroup,
      desc = "esqueleto.ivy.selection.updatepreview",
      buffer = selection_buf,
      callback = function()
        -- Get selected template
        local template_name = vim.api.nvim_get_current_line()
        local template_path = templates[template_name]

        -- Place template contents in preview window
        local f = assert(io.open(template_path, "rb"))
        local content = {}
        for line in f:lines() do
          table.insert(content, line);
        end
        f:close()

        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, content)
      end
    }
  )
  vim.keymap.set(
    'n',
    'q',
    function() closepreview(false) end,
    {
      buffer = selection_buf,
      desc = "Quit 'esqueleto' selection pane without selecting a template"
    }
  )
  vim.keymap.set(
    'n',
    '<CR>',
    function() closepreview(true) end,
    {
      buffer = selection_buf,
      desc = "Select current template"
    }
  )
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
