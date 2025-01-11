---@diagnostic disable: undefined-global, lowercase-global, undefined-field

local eq = assert.are.same
local is_true = assert.is.True

describe("`createautocmd`", function()
  -- Setup environment for tests
  before_each(function()
    opts = {
      autouse = true,
      directories = {
        vim.fn.resolve(
          vim.fn.fnamemodify(vim.fn.getcwd() .. "/" .. "../scripts/skeletons", ":p")
        ),
      },
      patterns = { "lua", "README" },
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

    autocmds = require("esqueleto.autocmd")
  end)

  it("should create autocmds", function()
    autocmds.createautocmd(opts)

    -- Expected behaviour
    expected_events = { "BufNewFile", "BufReadPost", "FileType" }
    expected_patterns = { "lua", "README" }

    -- Observed behaviour
    local group_name = "esqueleto"
    local existing_autocmds = vim.api.nvim_get_autocmds({
      group = group_name,
    })

    -- Check if observed and expected behaviours are equal
    for _, cmd in ipairs(existing_autocmds) do
      eq(cmd["group_name"], group_name)
      is_true(vim.tbl_contains(expected_patterns, cmd["pattern"], {}))
      is_true(vim.tbl_contains(expected_events, cmd["event"], {}))
    end
  end)
end)
