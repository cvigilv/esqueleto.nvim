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
        ignored = {},
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
