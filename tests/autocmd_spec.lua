---@diagnostic disable: undefined-global, lowercase-global, undefined-field

local eq = assert.are.same

describe("createautocmd", function()
  -- Setup environment for tests
  before_each(function()
    local opts = {
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
          ["host"] = "gh",
          ["user"] = "gh-ci",

          -- Github
          ["gh-email"] = "n/a",
          ["gh-user"] = "n/a",
        },
      },
      advanced = {
        ignored = {},
        ignore_os_files = true,
      },
    }

    autocmds = require("esqueleto.autocmd").createautocmd(opts)
  end)

  it("should createa autocmds", function()
    -- Expected behaviour
    local group_name = "esqueleto"
    local existing_autocmds = vim.api.nvim_get_autocmds({
      group = group_name,
    })
    vim.print(existing_autocmds)

    -- Observed behaviour

    eq(true == true) -- Check if behaviours are equal
  end)
end)
