local M = {}

local utils = require("esqueleto.core")

---Creates a new template based on user input and current buffer state.
---@param opts Esqueleto.Config Configuration options for template creation
---@return nil
M.create_template = function(opts)
  vim.notify("\nesqueleto :: Entering template creation!", vim.log.levels.WARN)
  local state = {}

  -- Ask if new template is (i) based in current buffer or (ii) from scratch
  vim.ui.select({ "current", "empty" }, {
    prompt = " ‼ Create a new template with:",
    format_item = function(item) return item .. " buffer" end,
  }, function(choice)
    -- NOTE: This is pretty hacky but works. Basically, we will always populate the template
    --       file with something, either nothing or the contents of the current buffer.
    state.source = vim.fn.tempname()

    -- Save current buffer contents to temporal file if template source if current buffer
    if choice == "current" then vim.cmd("silent w " .. state.source) end
  end)
  if not state.source then
    vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
    return nil
  end

  -- Ask if new template is triggered by (i) file type or (ii) file name
  vim.ui.select({ "type", "name" }, {
    prompt = "\n ‼ Trigger template insertion using:",
    format_item = function(item) return "file" .. item end,
  }, function(trigger)
    -- Escape function if user decides to exit
    if trigger == nil then return end

    -- Automatically detect filetype/filename
    local detected = nil
    if trigger == "type" then
      detected = vim.bo.filetype
    elseif trigger == "name" then
      detected = vim.fn.expand("%:p:t")
    end

    -- Prompt for trigger input (prefilled with current buffer information)
    vim.ui.input(
      { prompt = "\n\n ‼ Set trigger as file " .. trigger .. " = ", default = detected },
      function(input) state.trigger = input end
    )

    -- Warn user if trigger is not currently tracked
    if not vim.tbl_contains(opts.patterns, state.trigger) then
      vim.notify(
        "\nesqueleto :: Trigger not currently recognized by esqueleto!",
        vim.log.levels.WARN
      )
    end
  end)
  if not state.trigger then
    vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
    return nil
  end

  -- Ask for template directory, skip if only 1 template directory exists
  if vim.tbl_count(opts.directories) > 1 then
    vim.ui.select(
      opts.directories,
      { prompt = "\nTemplate directory:" },
      function(choice) state.directory = choice end
    )
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
  vim.cmd("0r " .. state.source)
  vim.cmd("cd " .. state.directory .. "/" .. state.trigger)
  vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
end

--- Create excommands for `esqueleto.nvim`
---@param opts Esqueleto.Config Plugin configuration table
M.createexcmd = function(opts)
  -- create ex-command for on-demand use
  vim.api.nvim_create_user_command("EsqueletoInsert", function()
    _G.esqueleto_inserted[vim.fn.expand("%:p")] = false
    utils.insert_template(opts)
  end, {})

  vim.api.nvim_create_user_command("EsqueletoNew", function() M.create_template(opts) end, {})
end

return M
