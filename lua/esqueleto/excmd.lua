local M = {}

local utils = require("esqueleto.utils")

M.create_template = function(opts)
  local state = {}

  -- Ask if new template is (i) based in current buffer or (ii) from scratch
  vim.ui.select(
    { "current", "empty" },
    {
      prompt = "Create a new template with:",
      format_item = function(item) return item .. " buffer" end
    },
    function(choice)
      vim.print(choice)
      if choice == "source" then
        state.source = vim.fn.tempname()
        vim.cmd("w " .. state.source)
      else
        state.source = choice
      end
    end
  )
  if not state.source then
    vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
    return nil
  end

  -- Ask if new template is triggered by (i) file type or (ii) file name
  vim.ui.select(
    { "File type", "File name" },
    { prompt = "\nTrigger template insertion using:" },
    function(choice)
      vim.ui.input({ prompt = "\nTemplate " .. choice:lower() .. ": " }, function(input)
        state.trigger = input
        if not vim.tbl_contains(opts.patterns, input) then
          vim.notify(
            "\nesqueleto :: Trigger not currently recognized by esqueleto!",
            vim.log.levels.WARN
          )
        end
      end)
    end
  )
  if not state.trigger then
    vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
    return nil
  end

  -- Ask for template directory
  if vim.tbl_count(opts.directories) > 1 then
    vim.ui.select(opts.directories, { prompt = "\nTemplate directory:" }, function(choice)
      state.directory = choice
    end)
    if not state.directory then
      vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
      return nil
    end
  else
    state.directory = opts.directories[1]
  end

  -- Create paths
  if vim.fn.isdirectory(state.directory .. "/" .. state.trigger) == 0 then
    vim.fn.mkdir(state.directory .. "/" .. state.trigger)
  end

  -- Open buffer to customize template
  local current_win = vim.api.nvim_get_current_win()
  local template_buf = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_win_set_buf(current_win, template_buf)
  if state.source ~= "empty" then
    vim.cmd("0r " .. state.source)
  end
  vim.cmd("cd " .. state.directory .. "/" .. state.trigger)
end

M.createexcmd = function(opts)
  -- create ex-command for on-demand use
  vim.api.nvim_create_user_command("EsqueletoInsert", function()
    utils.inserttemplate(opts)
  end, {})

  vim.api.nvim_create_user_command("EsqueletoNew", function()
    M.create_template(opts)
  end, {})
end

return M
