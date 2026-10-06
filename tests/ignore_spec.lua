---@diagnostic disable: undefined-global

local eq = assert.are.same
local is_false = assert.is_false
local is_true = assert.is_true

local autocmd = require("esqueleto.autocmd")
local config = require("esqueleto.config")
local core = require("esqueleto.core")
local excmd = require("esqueleto.excmd")

local original_inserttemplate
local tempdir
local test_buffer

local function options(advanced)
  return config.update_config({
    directories = { tempdir .. "/templates" },
    patterns = { "esqueleto_test" },
    advanced = vim.tbl_extend("force", {
      ignored_templates = {},
      ignored_patterns = {},
      ignore_os_files = false,
    }, advanced or {}),
  })
end

local function open_test_buffer(relative_path)
  test_buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(test_buffer, tempdir .. "/" .. relative_path)
  vim.api.nvim_set_current_buf(test_buffer)
  return test_buffer
end

describe("ignore options", function()
  before_each(function()
    tempdir = vim.fn.tempname()
    vim.fn.mkdir(tempdir .. "/templates/lua", "p")
    original_inserttemplate = core.inserttemplate
    _G.esqueleto_inserted = {}
    pcall(vim.api.nvim_del_user_command, "EsqueletoInsert")
    pcall(vim.api.nvim_del_user_command, "EsqueletoNew")
  end)

  after_each(function()
    core.inserttemplate = original_inserttemplate
    if test_buffer and vim.api.nvim_buf_is_valid(test_buffer) then
      vim.api.nvim_buf_delete(test_buffer, { force = true })
    end
    test_buffer = nil
    pcall(vim.api.nvim_del_augroup_by_name, "esqueleto")
    pcall(vim.api.nvim_del_user_command, "EsqueletoInsert")
    pcall(vim.api.nvim_del_user_command, "EsqueletoNew")
    vim.fn.delete(tempdir, "rf")
  end)

  it("filters template files with `ignored_templates`", function()
    vim.fn.writefile({ "default" }, tempdir .. "/templates/lua/default")
    vim.fn.writefile({ "backup" }, tempdir .. "/templates/lua/backup.bak")

    local templates = core.gettemplates("lua", options({ ignored_templates = { "*.bak" } }))

    is_true(templates.default:match("/default$") ~= nil)
    is_false(vim.tbl_contains(vim.tbl_keys(templates), "backup.bak"))
  end)

  it("suppresses automatic insertion for matching destination paths", function()
    local calls = 0
    core.inserttemplate = function() calls = calls + 1 end
    local opts = options({ ignored_patterns = { "Claudio", "folder with spaces" } })
    autocmd.createautocmd(opts)

    open_test_buffer("folder with spaces/Claudio/example.lua")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "esqueleto_test", modeline = false })

    eq(calls, 0)
  end)

  it("inserts automatically for nonmatching destination paths", function()
    local calls = 0
    core.inserttemplate = function() calls = calls + 1 end
    local opts = options({ ignored_patterns = { "Claudio" } })
    autocmd.createautocmd(opts)

    open_test_buffer("other/example.lua")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "esqueleto_test", modeline = false })

    eq(calls, 1)
  end)

  it("allows `EsqueletoInsert` to override destination ignores", function()
    local calls = 0
    core.inserttemplate = function(received)
      calls = calls + 1
      eq(received.advanced.ignored_patterns, { "Claudio" })
    end
    local opts = options({ ignored_patterns = { "Claudio" } })
    open_test_buffer("Claudio/example.lua")
    excmd.createexcmd(opts)

    vim.cmd("EsqueletoInsert")

    eq(calls, 1)
  end)
end)
