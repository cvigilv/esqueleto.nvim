---@diagnostic disable: undefined-global

local eq = assert.are.same
local is_nil = assert.is_nil
local is_true = assert.is_true

local config = require("esqueleto.config")
local core = require("esqueleto.core")

local original_select
local tempdir
local buffers

local function new_buffer(name)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, tempdir .. "/" .. name)
  table.insert(buffers, buf)
  return buf
end

describe("`selecttemplate`", function()
  before_each(function()
    tempdir = vim.fn.tempname()
    vim.fn.mkdir(tempdir, "p")
    vim.fn.writefile({ "first", "second" }, tempdir .. "/first")
    vim.fn.writefile({ "other" }, tempdir .. "/other")
    original_select = vim.ui.select
    buffers = {}
  end)

  after_each(function()
    vim.ui.select = original_select
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end
    vim.fn.delete(tempdir, "rf")
  end)

  it("opens the picker outside the caller's buffer context", function()
    local on_choice
    vim.ui.select = function(_, _, cb) on_choice = cb end
    local opts = config.update_config({ autouse = false, wildcards = { expand = false } })
    local templates = { first = tempdir .. "/first", other = tempdir .. "/other" }

    local target = new_buffer("target.txt")
    vim._with({ buf = target }, function() core.selecttemplate(templates, opts) end)
    is_nil(on_choice)

    is_true(vim.wait(1000, function() return on_choice ~= nil end))
  end)

  it("writes the chosen template into the buffer that requested it", function()
    local on_choice
    vim.ui.select = function(_, _, cb) on_choice = cb end
    local opts = config.update_config({ autouse = false, wildcards = { expand = false } })
    local templates = { first = tempdir .. "/first", other = tempdir .. "/other" }

    local target = new_buffer("target.txt")
    local unrelated = new_buffer("unrelated.txt")
    vim.api.nvim_set_current_buf(target)
    core.selecttemplate(templates, opts)
    is_true(vim.wait(1000, function() return on_choice ~= nil end))

    vim.api.nvim_set_current_buf(unrelated)
    on_choice("first")

    eq(vim.api.nvim_buf_get_lines(target, 0, -1, true), { "first", "second" })
    eq(vim.api.nvim_buf_get_lines(unrelated, 0, -1, true), { "" })
  end)
end)
