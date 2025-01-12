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
        lookup = {
          -- File
          ["filename"] = function() return vim.fn.expand("%:t:r") end,
          ["fileabspath"] = function() return vim.fn.expand("%:p") end,
          ["filerelpath"] = function() return vim.fn.expand("%:p:~") end,
          ["fileext"] = function() return vim.fn.expand("%:e") end,
          ["filetype"] = function() return vim.bo.filetype end,

          -- Date and time
          ["date"] = function() return os.date("%Y%m%d", os.time()) end,
          ["year"] = function() return os.date("%Y", os.time()) end,
          ["month"] = function() return os.date("%m", os.time()) end,
          ["day"] = function() return os.date("%d", os.time()) end,
          ["time"] = function() return os.date("%T", os.time()) end,

          -- System
          ["host"] = function() return utils.capture("hostname", false) end,
          ["user"] = function() return os.getenv("USER") end,

          -- Github
          ["gh-email"] = function() return utils.capture("git config user.email", false) end,
          ["gh-user"] = function() return utils.capture("git config user.name", false) end,
        },
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
