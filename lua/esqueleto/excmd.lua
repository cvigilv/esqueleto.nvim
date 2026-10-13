local M = {}

local utils = require("esqueleto.core")

local exit_creation = function()
  vim.notify("\nesqueleto :: Exiting template creation!", vim.log.levels.WARN)
end

--- Create the template directory and open a new buffer for the template in the window
--- showing `bufnr`.
---@param bufnr integer Buffer `EsqueletoNew` was called from
---@param state table Answers: `source` (file or nil), `trigger`, `directory`
local function open_template_buffer(bufnr, state)
  local template_dir = vim.fs.joinpath(state.directory, state.trigger)
  if vim.fn.isdirectory(template_dir) == 0 then vim.fn.mkdir(template_dir, "p") end

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then win = vim.api.nvim_get_current_win() end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
  if state.source then vim.cmd("0r " .. vim.fn.fnameescape(state.source)) end
  vim.cmd("cd " .. vim.fn.fnameescape(template_dir))
  vim.notify(
    "\nesqueleto :: Write this buffer to save the template in " .. template_dir,
    vim.log.levels.INFO
  )
end

---Creates a new template based on user input and current buffer state.
---
---Each question is asked from the previous answer's callback, so this works with
---`vim.ui.select`/`vim.ui.input` implementations that return before the user answers.
---@param opts Esqueleto.Config Configuration options for template creation
---@return nil
local function create_template(opts)
  vim.notify("\nesqueleto :: Entering template creation!", vim.log.levels.WARN)
  local bufnr = vim.api.nvim_get_current_buf()
  local state = {}

  -- Ask for template directory, skip if only 1 template directory exists
  local ask_directory = function()
    if vim.tbl_count(opts.directories) <= 1 then
      state.directory = opts.directories[1]
      open_template_buffer(bufnr, state)
      return
    end
    vim.ui.select(opts.directories, { prompt = "\nTemplate directory:" }, function(choice)
      if choice == nil then return exit_creation() end
      state.directory = choice
      open_template_buffer(bufnr, state)
    end)
  end

  -- Ask if new template is triggered by (i) file type or (ii) file name
  local ask_trigger = function()
    vim.ui.select({ "type", "name" }, {
      prompt = "\n ‼ Trigger template insertion using:",
      format_item = function(item) return "file" .. item end,
    }, function(trigger)
      if trigger == nil then return exit_creation() end

      -- Prefill the trigger with the originating buffer's filetype/filename
      local detected
      if trigger == "type" then
        detected = vim.bo[bufnr].filetype
      else
        detected = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
      end

      vim.ui.input(
        { prompt = "\n\n ‼ Set trigger as file " .. trigger .. " = ", default = detected },
        function(input)
          if input == nil or input == "" then return exit_creation() end
          state.trigger = input

          -- Warn user if trigger is not currently tracked
          if not vim.tbl_contains(opts.patterns, state.trigger) then
            vim.notify(
              "\nesqueleto :: Trigger not currently recognized by esqueleto!",
              vim.log.levels.WARN
            )
          end
          ask_directory()
        end
      )
    end)
  end

  -- Ask if new template is (i) based in current buffer or (ii) from scratch
  vim.ui.select({ "current", "empty" }, {
    prompt = " ‼ Create a new template with:",
    format_item = function(item) return item .. " buffer" end,
  }, function(choice)
    if choice == nil then return exit_creation() end
    if choice == "current" then
      state.source = vim.fn.tempname()
      vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true), state.source)
    end
    ask_trigger()
  end)
end

--- Create excommands for `esqueleto.nvim`
---@param opts Esqueleto.Config Plugin configuration table
M.createexcmd = function(opts)
  -- create ex-command for on-demand use
  vim.api.nvim_create_user_command("EsqueletoInsert", function()
    _G.esqueleto_inserted[vim.fn.expand("%:p")] = false
    utils.inserttemplate(opts)
  end, {})

  vim.api.nvim_create_user_command("EsqueletoNew", function() create_template(opts) end, {})
end

return M
