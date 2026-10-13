---@diagnostic disable: undefined-global, lowercase-global, undefined-field

-- NOTE: refer to https://github.com/lunarmodules/luassert/tree/master for more info and examples
local eq = assert.are.same
local is_true = assert.is_true
local throws_error = assert.has.errors

describe("`createexcmd`", function()
  before_each(function()
    defaults = {
      autouse = true,
      directories = { vim.fn.stdpath("config") .. "/skeletons" },
      patterns = function(dir) return vim.fn.readdir(dir) end,
      wildcards = {
        expand = true,
        lookup = {},
      },
      advanced = {
        ignored_templates = {},
        ignored_patterns = {},
        ignore_os_files = true,
      },
    }

    excmd = require("esqueleto.excmd")
  end)

  it("should create excommands", function()
    excmd.createexcmd(defaults)
    local function command_exists(cmd) return vim.fn.exists(":" .. cmd) ~= 0 end
    vim.print(command_exists("EsqueletoInsert"))
    vim.print(command_exists("EsqueletoNew"))
  end)
end)

describe("`EsqueletoNew`", function()
  local config = require("esqueleto.config")

  local original = {}
  local tempdir, pending, notes, initial_bufs, source_buf

  -- Prompts return before the user answers, like telescope-ui-select
  local function async_ui()
    vim.ui.select = function(items, _, cb) table.insert(pending, { items = items, cb = cb }) end
    vim.ui.input = function(o, cb) table.insert(pending, { default = o.default, cb = cb }) end
  end

  -- Prompts answer before returning, like the built-in `inputlist()`
  local function sync_ui(answers)
    vim.ui.select = function(_, _, cb) cb(table.remove(answers, 1)) end
    vim.ui.input = function(_, cb) cb(table.remove(answers, 1)) end
  end

  local function answer(value)
    local prompt = table.remove(pending, 1)
    assert(prompt, "no prompt is waiting for an answer")
    prompt.cb(value)
    return prompt
  end

  local function exited() return vim.tbl_contains(notes, "\nesqueleto :: Exiting template creation!") end

  local function setup(directories)
    excmd.createexcmd(config.update_config({ directories = directories, patterns = { "lua" } }))
  end

  before_each(function()
    excmd = require("esqueleto.excmd")
    pcall(vim.api.nvim_del_augroup_by_name, "esqueleto")
    original = { select = vim.ui.select, input = vim.ui.input, notify = vim.notify, cwd = vim.fn.getcwd() }
    tempdir = vim.fn.tempname()
    vim.fn.mkdir(tempdir .. "/src", "p")
    -- Resolved so cwd comparisons hold where the temp dir is a symlink (macOS /var)
    tempdir = vim.uv.fs_realpath(tempdir)
    pending, notes = {}, {}
    vim.notify = function(msg) table.insert(notes, msg) end
    initial_bufs = vim.api.nvim_list_bufs()

    source_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(source_buf, tempdir .. "/src/example.lua")
    vim.api.nvim_buf_set_lines(source_buf, 0, -1, true, { "local x = 1" })
    vim.bo[source_buf].filetype = "lua"
    vim.api.nvim_set_current_buf(source_buf)
  end)

  after_each(function()
    vim.ui.select, vim.ui.input, vim.notify = original.select, original.input, original.notify
    vim.cmd("cd " .. vim.fn.fnameescape(original.cwd))
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if not vim.tbl_contains(initial_bufs, buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    pcall(vim.api.nvim_del_user_command, "EsqueletoInsert")
    pcall(vim.api.nvim_del_user_command, "EsqueletoNew")
    vim.fn.delete(tempdir, "rf")
  end)

  it("asks each question after the previous asynchronous answer", function()
    async_ui()
    setup({ tempdir .. "/templates" })

    vim.cmd("EsqueletoNew")
    eq(#pending, 1)
    is_true(not exited())

    eq(answer("current").items, { "current", "empty" })
    eq(answer("type").items, { "type", "name" })
    eq(answer("lua").default, "lua")
    eq(#pending, 0)

    local template_dir = tempdir .. "/templates/lua"
    eq(vim.fn.isdirectory(template_dir), 1)
    eq(vim.uv.fs_realpath(vim.fn.getcwd()), template_dir)
    is_true(vim.api.nvim_get_current_buf() ~= source_buf)
    eq(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "local x = 1", "" })
    is_true(not exited())
  end)

  for step = 1, 3 do
    it("stops when the asynchronous prompt " .. step .. " is cancelled", function()
      async_ui()
      setup({ tempdir .. "/templates" })
      local answers = { "current", "type", "lua" }

      vim.cmd("EsqueletoNew")
      for i = 1, step - 1 do
        answer(answers[i])
      end
      answer(nil)

      is_true(exited())
      eq(#pending, 0)
      eq(vim.fn.isdirectory(tempdir .. "/templates"), 0)
      eq(vim.api.nvim_get_current_buf(), source_buf)
    end)
  end

  it("works when prompts answer synchronously", function()
    local second = tempdir .. "/other"
    sync_ui({ "empty", "name", "custom", second })
    setup({ tempdir .. "/templates", second })

    vim.cmd("EsqueletoNew")

    eq(vim.fn.isdirectory(second .. "/custom"), 1)
    eq(vim.fn.isdirectory(tempdir .. "/templates"), 0)
    eq(vim.api.nvim_buf_get_lines(0, 0, -1, true), { "" })
    is_true(not exited())
  end)
end)
